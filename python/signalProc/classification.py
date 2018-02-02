#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jan 31 19:42:17 2018

@author: abdullahi
"""
from scipy import signal
from sklearn.metrics import roc_auc_score
from sklearn.linear_model import LogisticRegression
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.svm import LinearSVC
from sklearn.decomposition import PCA
import skwrap
from sklearn.model_selection import train_test_split
# classification

def classification(target, nontarget, subject):
    jake =  loadmat('data_' + target + '_' + subject)
    raw_data, events = jake['data'], jake['devents']
    data, events = preprocess(raw_data, events, classification=True, matlab=True)
    
    X_train, X_test, y_train, y_test = train_test_split(data, events, test_size=0.3, random_state=42)
    # Training phase
    mapping = {('stimulus.hybrid', 'left'): -1, ('stimulus.hybrid', 'right'): 1}
    classifier = LinearDiscriminantAnalysis()
    
    params = {"solver":['svd', 'lsqr']}  
    skwrap.fit(X_train, y_train, classifier, mapping, params=params, reducer="mean")
    bufhelp.update()
    bufhelp.sendEvent("sigproc.training","done")
    
    # Test phase
    pred = skwrap.predict(X_test, classifier, reducerdata="mean")
    
    y_test = skwrap.createclasses(y_test, 1, mapping)[0]
    
    print(roc_auc_score(y_test, pred))