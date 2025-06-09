from sklearn.model_selection import RandomizedSearchCV, GridSearchCV, train_test_split
from sklearn.metrics import classification_report, accuracy_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn import svm
import xgboost as xgb
import pandas as pd
import numpy as np

def splitData(DF):
    #Create the X and y dataframes.
    X = DF.drop(["Label"], axis=1)
    y = DF["Label"]
    y = LabelEncoder().fit_transform(y)

    # Split into training and test sets.
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    return modelSelection(X_train, X_test, y_train, y_test)


def modelSelection(X_train, X_test, y_train, y_test):
    #First, perform grid search with RandomForest to find the best hyperparameters for the algorithm.
    rf = RandomForestClassifier(random_state=42)

    rf_param_grid = {
        'n_estimators': [50, 100, 200, 300, 500],
        'max_depth': [None, 5, 10, 20, 30],
        'min_samples_split': [2, 5, 10],
        'min_samples_leaf': [1, 2, 4],
        'bootstrap': [True]
    }

    rf_random = RandomizedSearchCV(
        estimator=rf,
        param_distributions=rf_param_grid,
        n_iter=50,
        cv=5,
        verbose=1,
        random_state=42,
        n_jobs=-1
    )

    rf_random.fit(X_train, y_train)
    bestRF = rf_random.best_estimator_
    print("Best RF Params:", rf_random.best_params_)
    print("Random Forest Report:\n", classification_report(y_test, bestRF.predict(X_test)))

    print("RF accuracy for training is: ", bestRF.score(X_train, y_train))
    print("RF accuracy for testing is: ", bestRF.score(X_test, y_test))



    #Next, test KNN with different K values, retrieving the best hyperparameter again.
    KNNScores = {}
    kNeighborsList = [1, 3, 5, 7, 9]
    for k in kNeighborsList:
        knn = KNeighborsClassifier(n_neighbors=k)
        knn.fit(X_train, y_train)
        knn.predict(X_test)
        KNNScores.update({k: knn.score(X_test, y_test)})
    print(KNNScores)
    bestKNN = max(KNNScores, key=KNNScores.get)
    
    print(f"Best KNN parameter and accuracy is: {bestKNN, KNNScores[bestKNN]}")



    #Then, test SVM with different kernels.
    svmParams = [
        {'kernel': ['rbf', 'poly'], 'gamma': [0.0001, 0.001, 0.01, 0.1], 'C': [1, 10, 100, 1000],}
    ]

    svmModel = GridSearchCV(svm.SVC(), svmParams, cv=5)
    svmModel.fit(X_train, y_train)
    print("Best SVM model is: ", svmModel.best_score_)


    #Finally, test XGBoost with different hyperparameters and K-Fold validation.
    xgbParams = {
        "n_estimators": [50, 100, 200, 300],
        "max_depth": [None, 3, 4, 5, 7, 10, 20, 30],
        "learning_rate": [0.01, 0.1, 0.2],
        "reg_alpha": [0, 0.01, 0.1, 1, 10],
        "subsample": [0.5, 0.7, 1]
    }

    xgb_classifier_model = xgb.XGBClassifier(
        random_state=42
    )

    xgbGridSearch = RandomizedSearchCV(
        xgb_classifier_model, 
        xgbParams, 
        cv = 5, 
        scoring="accuracy",
        n_iter = 300, #This selects 100 different random combinations of the grid search parameters.
        n_jobs = -1, #I think this disables parallel processing?
        verbose = 2,
        random_state = 42
    )
        
    xgbGridSearch.fit(X_train, y_train)
    xgbBestCombination = xgbGridSearch.best_estimator_
    print("RF accuracy for testing is: ", bestRF.score(X_test, y_test))
    print(f"Best KNN parameter and accuracy is: {bestKNN, KNNScores[bestKNN]}")
    print("Best SVM model is: ", svmModel.best_score_)  
    print("Best parameter and score is: ", xgbGridSearch.best_score_)
