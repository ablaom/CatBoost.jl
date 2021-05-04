module LearningToRank

using CatBoost
using DataFrames

train, test = load_dataset(:msrank_10k)
x_train = train.drop([0, 1]; axis=1).values
y_train = train[1].values
queries_train = train[2].values

x_test = test.drop([0, 1]; axis=1).values
y_test = test[1].values
queries_test = test[2].values

# Important dims.
num_documents, num_features = size(x_train)
num_queries = size(unique(queries_train))[1]
println("Data dims: $((num_documents, num_features))")
println("Num queries: $(num_queries)")

# Get relevance labels.
max_relevance = maximum(y_train)
y_train /= max_relevance
y_test /= max_relevance

# Create pools.
train = Pool(; data=x_train, label=y_train, group_id=queries_train)
test = Pool(; data=x_test, label=y_test, group_id=queries_test)

default_parameters = Dict("iterations" => 2000, "loss_function" => "RMSE",
                          "custom_metric" => ["MAP:top=10", "PrecisionAt:top=10",
                                              "RecallAt:top=10"], "verbose" => false,
                          "random_seed" => 314159)

function fit_model(params, train_pool, test_pool)
    model = catboost.CatBoost(params)
    model.fit(train_pool; eval_set=test_pool, plot=false)
    return model
end

println("Training with:")
display(default_parameters)
model = fit_model(default_parameters, train, test)

end # module