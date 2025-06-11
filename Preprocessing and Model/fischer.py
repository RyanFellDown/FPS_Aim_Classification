from skfeature.function.similarity_based import fisher_score
import pandas as pd
from sklearn.preprocessing import LabelEncoder

def fischer_score_df(df):
    features = ['Accuracy', 'Avg Precision', 'Avg Reaction Time', 'Missed Shots', 
                'Avg Max Mouse Speed', 'Overshoot', 'Undershoot']

    X = df[features].values
    y = df['Label'].values

    # Encode labels to integers
    y_encoded = LabelEncoder().fit_transform(y)

    # Compute Fisher scores
    scores = fisher_score.fisher_score(X, y_encoded)

    # Create and return sorted DataFrame
    fisher_df = pd.DataFrame({
        'Feature': features,
        'Fisher Score': scores
    }).sort_values(by='Fisher Score', ascending=False)

    return fisher_df
