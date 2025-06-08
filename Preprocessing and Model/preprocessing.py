from sklearn.preprocessing import StandardScaler
import pandas as pd
import os as os


#-----Step 1-----
#Basically reading in all the labeled CSVs to be preprocessed and combined.
labeled = False

def read_in_csvs():
    #Find the directory the CSV files are in, appending each read in CSV to a dataframe to later concatenate.
    dfs = []
    folderName = "./Labeled CSVs"
    csvDirectory = os.path.dirname(__file__)
    folder = os.path.join(csvDirectory, folderName)

    for file in os.listdir(folder):
        if file.endswith('.csv'):
            file_path = os.path.join(folder, file)
            new = pd.read_csv(file_path, dtype={"Overshoot": str, "Undershoot": str})
            dfs.append(new)

    #If the first one contains a label, then we are looking at the labeled dataset, so different processes must be done.
    if "Label" in dfs[0]:
        print("True")
        labeled = True
    return cleaning(dfs, labeled)



#-----Step 2-----
#Preprocessing step; combining DF's, cleaning up the data points, and changing strings to ints.
def cleaning(dfs, labeled):
    #Creat the totalDF which merges all the player CSVs together
    totalDF = dfs[0]
    dfs.pop(0)
    for df in dfs:
        totalDF = pd.concat([totalDF, df], join="inner")

    #Cleaning the totalDF, dropping an unused column and converting strings to floats.
    print(totalDF.shape)
    totalDF = totalDF.drop(['Unnamed: 0'], axis=1)
    for column in totalDF:
        if (type(totalDF[column].values[0]) == type("")) and (totalDF[column].astype(str).str.contains("nan%").any()):
            totalDF[column] = totalDF[column].astype(str).str.strip()
            totalDF.loc[totalDF[column].str.contains("nan%"), column] = "0.00"
            totalDF[column] = totalDF[column].str.replace("%", "", regex=False)
            totalDF[column].astype(float)
        elif type(totalDF[column].values[0]) == type("") and "ms" in totalDF[column].values[0]:
            totalDF[column] = (totalDF[column].str.replace("ms", "", regex=False)).astype(float)
        elif type(totalDF[column].values[0]) == type("") and "%" in totalDF[column].values[0]:
            totalDF[column] = (totalDF[column].str.replace("%", "", regex=False)).astype(float)
        elif type(totalDF[column].values[0]) == type("") and column != "Label":
            totalDF[column] = (totalDF[column]).astype(float)


    return normalization(totalDF, labeled)



#-----Step 3-----
#Finally, normalize the data amongst all numbers, EXCEPT the label.
def normalization(totalDF, labeled):
    #Initialize the dataframes as lists to start.
    normalizationDF = []
    tempNormalizationDF = []
    labelDF = []

    #If it's labeled, then drop it and create a dataframe containing only the label column.
    if labeled:
        normalizationDF = totalDF.drop(['Label'], axis=1)
        tempNormalizationDF = totalDF.drop(['Label'], axis=1)
        labelDF = totalDF['Label']
    else:
        normalizationDF = totalDF

    #Scale all the columns together using StandardScaler.
    scaler = StandardScaler().fit_transform(normalizationDF)
    normalizationDF = pd.DataFrame(scaler, columns = normalizationDF.columns)

    #If it's labeled, then concatenate the normalized dataframe with the labeled one; otherwise, just set the totalDF to the normalized one.
    if labeled:
        totalDF = pd.concat([normalizationDF.reset_index(drop=True), labelDF.reset_index(drop=True)], axis=1)
    else:
        totalDF = normalizationDF

    return [normalizationDF, tempNormalizationDF, totalDF]