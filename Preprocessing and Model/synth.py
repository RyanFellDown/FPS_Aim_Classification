import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from imblearn.over_sampling import SMOTE
from sklearn.model_selection import train_test_split


# Method 1: label-based distortion
def gaussian_synth(df, new_samples_to_create):
    #Scale the data, if synthetic was used.
    labeledColumn = df["Label"]
    df = df.drop(["Label"], axis=1)

    scaler = StandardScaler().fit_transform(df)
    df = pd.DataFrame(scaler, columns = df.columns)
    df = pd.concat([df.reset_index(drop=True), labeledColumn.reset_index(drop=True)], axis=1)

    print(df["Overshoot"])
    temp = []
    synths = []
    labels = df["Label"].unique()
    for label in labels:
        # making a new Dataframe with only the rows that have this label, and dropping the label column itself
        cluster = df[df["Label"] == label].drop(columns = ["Label"])
        # represents the like average point in the DF
        centroid = cluster.mean()
    
        for i in range(new_samples_to_create):
            # first arg: mean; second: std dev; third: shape of the output vector
            noise = np.random.normal(0, 0.1, size = 7)
            # add the noise with the modification of multiplying it all by the actual std. dev in this cluster
            new_sample = centroid + noise * cluster.std()
            temp.append(list(new_sample) + [label])

        synths.append(pd.DataFrame(temp, columns=list(cluster.columns) + ["Label"]))

    final_df = pd.concat(synths + [df], ignore_index=True)
    print(final_df.head(n=10), final_df.shape)
    print(final_df["Label"].value_counts())

    return final_df


# Method 2: SMOTE (OPTIONAL)
# since we have some imbalanced classes, it's kinda? justified to use this
def smote(df):
    features = df.drop(columns = ["Label"])
    target = df["Label"]
    X_train, X_test, y_train, y_test = train_test_split(features, target, test_size = 0.3, random_state = 42)
    sm = SMOTE()
    X_resampled, y_resampled = sm.fit_resample(X_train, y_train)

    # you would then have to use these resamples ^ instead of the old X_train and y_train from now on
