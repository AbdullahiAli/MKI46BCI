import sklearn.linear_model
import skwrap

def fit(data, events, mapping=None):
    classifier = sklearn.linear_model.LogisticRegression()
    
    params = {"fit_intercept" : [True, False], "C": [0.001, 0.001, 0.01, 0.1, 1, 10]}             
    skwrap.fit(data, events, classifier, mapping, params, reducer="mean")
    return classifier
    
def predict(data, classifier):
    #global classifier
    return skwrap.predict(data, classifier, reducerdata="mean")
