# FPS_Aim_Classification

This software aims to classify the aiming style of users within a First Person Shooter video game.
Using different features extracted from an aim training simulation created from Godot, each trial
is labeled one of 5 aiming styles, with each aiming style has different pros and cons and certain 
distinguishing features. These aiming styles include:
- Calm Aim
- Tap Aim
- Flick Aim
- Reaction Aim
- Spray Aim

## Machine Learning Approach

Once these trials are labeled, they are run through multiple Machine Learning algorithms, including
XGBoost, RandomForest, SVM, and KNN to determine which algorithm has the highest accuracy. To
make the dataset more robust, synthetic data creation techniques were used and tested alongside
the original testing data to determine whether accuracy truly increased or not.

### Deep Learning Approach

While Machine Learning methods worked fine, we realized that labeling the dataset via user videos
gave us the option to attempt using neural networks for our project as well. Specifically, we
used a Convolutional Neural Network to classify the different aiming styles, and then compared
the accuracies of both the Machine Learning and Deep Learning approaches.
