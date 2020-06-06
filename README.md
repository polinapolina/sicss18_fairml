# Balanced survey on recidivism risk prediction

This repository contains a survey dataset, gathered to study the bias and fairness in recidivism risk prediction. The survey was designed to investigate the differences in risk assessment of in- versus out-group members.

For the detailed description of the survey and the findings please see *The Role of In-Group Bias and Balanced Data: A Comparison of Human and Machine Recidivism Risk Predictions. Arpita Biswas, Marta Kołczyńska, Saana Rantanen, Polina Rozenshtein. ACM COMPASS 2020.*


The key features of this dataset are:

* This is a crowdsourced human recidivism risk assessment by a thousand respondents in a vignette survey conducted via [TurkPrime](www.turkprime.com), a platform that integrates with [Amazon’s Mechanical Turk](https://www.mturk.com) and offers more control over the profile of respondents (crowdworkers).
* The survey vignettes represented pre-trial defendants from Broward County, Florida, based on a dataset assembled by Jeff Larson, Surya Mattu, Lauren Kirchner, and Julia Angwin. 2016. How We Analyzed the COMPAS Recidivism Algorithm. Technical Report. ProPublica.
https://www.propublica.org/article/how-we-analyzed-the-compas-recidivism-algorithm
* The vignettes were short descriptions of the defendants, including their sex, race, age, current charge and prior convictions. Respondents were expected to assess whether each defendant would commit another crime within the next two years.
* Each respondent assessed 20 vignettes. There were 50 versions of the questionnaire, for a total of 1000 different vignettes (defendants).
* The defendants to be described in vignettes were selected in a way to ensure diversity. In the survey each respondent evaluated the risk of recidivism of 20 defendants, of whom 10 were white and 10 were black. In each of the two racial groups, half—five defendants—did indeed recidivate, and five did not recidivate.
* The quotas were placed on the racial composition of our survey respondents to ensure a 50 : 50 ratio of black and white respondents.

### Files
* turkprime_survey_data_clean.csv -- the dataset of responces
* turkprime_survey_codebook.txt -- the description of the fields in the dataset csv
* ACMCOMPASS_code.R -- R code used to produce comparative analysis with COMPAS automated recidivism scores and with survey from *Julia Dressel and Hany Farid. 2018. The accuracy, fairness, and limits of predicting recidivism. Science Advances 4, 1 (2018), 1–6.* 

If you use this dataset in your research, please cite our corresponding paper. *The Role of In-Group Bias and Balanced Data: A Comparison of Human and Machine Recidivism Risk Predictions. Arpita Biswas, Marta Kolczynska, Saana Rantanen, Polina Rozenshtein. ACM COMPASS 2020.*
[//]: # (bibtex entry:)
