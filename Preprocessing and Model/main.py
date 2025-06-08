import preprocessing
import csvHandler


def __main__():
    #First, combine the CSVs for each user.
    csvHandler.combineCSVs()


    #Then, run the preprocessing step on all the CSVs and combine into one large CSV.
    dataFrames = preprocessing.read_in_csvs()
    print(dataFrames[0], dataFrames[1], dataFrames[2])

    #Decide whether to take the ML or DL route for classification.
    modelType = 0
    while(modelType != 1 and modelType != 2):
        modelType = int(input("Type 1 for machine learning and 2 for deep learning."))
    if modelType == 1:
        print("Machine Learning Time:")
    elif modelType == 2:
        print("Deep Learning Time:")

__main__()