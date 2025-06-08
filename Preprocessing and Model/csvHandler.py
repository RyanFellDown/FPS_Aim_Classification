import pandas as pd
import os


def combineCSVs():
    #First, find all the files, storing the csvs to their respective dictionary keys.
    dfs = {}
    folderName = "./Separated CSVs"
    run = -1
    names = []

    csvDirectory = os.path.dirname(__file__)
    folder = os.path.join(csvDirectory, folderName)

    for dirpath, dirnames, filenames in os.walk(folder):
        print("This is run: ", run+2, dirpath, dirnames, filenames)
        if folderName in dirpath and "Results" not in dirpath:
            print("First round of walk, storing folder names...")
            names = dirnames
        else:
            iteration = 0
            for file in os.listdir(dirpath):
                if file.endswith('.csv'):
                    file_path = os.path.join(dirpath, file)
                    new = pd.read_csv(file_path)
                    if iteration == 0:
                        dfs.update({names[run]: [new]})
                    else:
                        dfs[names[run]].append(new)
                    iteration += 1
        run += 1

    #Then, for each user who did the trials, combine the files under their name in the dictionary and drop a single feature.
    df = []
    x=0
    for name in names:
        if len(dfs[name]) > 0:
            df.append(pd.concat(dfs[name]))
            if "Avg First Shot Accuracy" in df[x].columns:
                df[x] = df[x].drop("Avg First Shot Accuracy", axis=1)
            print(df[x].head())
        else:
            df[x] = []
        x+=1

    #Finally, generate all the newly concatenated CSVs into the main folder, but only if said CSV doesn't already exist.
    y = 0
    for name in names:
        csvDirectory = os.path.dirname(__file__)
        fileName = os.path.join(csvDirectory, f"Handled CSVs/{name}.csv")
        if not os.path.isfile(fileName):
            print(f"Doesn't exist, creating {name}.csv")
            df[y].to_csv(fileName)
        y += 1