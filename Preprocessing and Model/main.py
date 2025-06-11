import preprocessing
import csvHandler
import synth
import model
from fischer import fischer_score_df
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd

def __main__():
    #First, combine the CSVs for each user.
    csvHandler.combineCSVs()


    #Then, run the preprocessing step on all the CSVs and combine into one large CSV.
    dataFrames = preprocessing.read_in_csvs()
    print(dataFrames[0], dataFrames[1], dataFrames[2])

    
    #Create synthetic data points to make the data more robust.
    robustDF = synth.gaussian_synth(dataFrames[1], 7, seed=42)
    print(robustDF.shape)

    top_features = fischer_score_df(robustDF)
    print(top_features)

    #Plotted features using seaborn. Image saved to Pairplot.png 
    #pairplot = sns.pairplot(robustDF, hue='Label', diag_kind='kde', corner=True)
    #pairplot.figure.tight_layout()
    #pairplot.savefig("pairplot.png", dpi=300)

    print("Machine Learning Time:\n")
    model.splitData(robustDF)

__main__()
