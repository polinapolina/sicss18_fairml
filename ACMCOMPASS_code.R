# The Role of In-Group Bias and Balanced Data:
# A Comparison of Human and Machine Recidivism Risk Predictions
# ACM COMPASS'20, June 15-17, 2020


# Setup

## Packages
library(tidyverse)
library(caret)
library(data.table)

## Settings
rel_text_size = 1

## Input data

### TurkPrime survey data merged with information about defendants
tp_data <- read.csv("turkprime_survey_data_clean.csv",
                    stringsAsFactors=FALSE) %>%
  mutate(resp_black = ifelse(resp_race == "African-American", 1, 0),
         def_black = ifelse(def_race == "African-American", 1, 0))

### Broward County data
# Source: https://farid.berkeley.edu/downloads/publications/scienceadvances17
recid <- read.csv("https://farid.berkeley.edu/downloads/publications/scienceadvances17/BROWARD_ORIGINAL.csv", 
                  head = TRUE, stringsAsFactors=FALSE)


# Analysis 1: balanced and unbalanced survey data ---------------

## Analysis of TurkPrime (balanced) survey data ----------
balanced_survey <- tp_data %>%
  group_by(resp_id, def_black) %>%
  summarise(
    tpos = mean(two_year_recid==1 & resp_decision==1),
    tneg = mean(two_year_recid==0 & resp_decision==0),
    fpos = mean(two_year_recid==0 & resp_decision==1),
    fneg = mean(two_year_recid==1 & resp_decision==0)) %>%
  mutate(accu = (tpos + tneg) / (tpos + tneg + fpos + fneg),
         fpos_rate = fpos / (fpos + tneg),
         fneg_rate = fneg / (fneg + tpos)) %>%
  mutate(def_race = case_when(
    def_black == 1 ~ "Black",
    def_black == 0 ~ "White"))%>%
  group_by(def_race)%>%
  summarize(me_accu = mean(accu),
            me_fpos = mean(fpos_rate),
            me_fneg = mean(fneg_rate)) %>%
  gather(indicator, value, 2:4) %>%
  mutate(est = substr(indicator, 1, 2),
         indicator = substr(indicator, 4, 7)) %>%
  spread(est, value) %>%
  mutate(indicator = case_when(
    indicator == "accu" ~ "Accuracy",
    indicator == "fpos" ~ "False positive rate",
    indicator == "fneg" ~ "False negative rate"),
    type = "Survey \nbalanced")


## Results for Dressel & Farid (unbalanced) survey data (Table 1, Dressel & Farid 2018)
unbalanced_survey <- balanced_survey[,1:2]
unbalanced_survey$me <- c(0.662, 0.301, 0.400, 0.676, 0.421, 0.262)
unbalanced_survey$type = "Survey \nunbalanced"

## Combining summaries of both surveys
analysis1_survey <- bind_rows(unbalanced_survey, balanced_survey)

## Figure 1
analysis1_survey %>%
  ggplot(., aes(x = type, y = me)) +
  geom_bar(aes(fill = def_race), position = "dodge", stat = "identity", colour="black") +
  facet_grid(.~indicator) +
  xlab("") + ylab("") +
  coord_cartesian(ylim = c(0,0.75)) +
  scale_fill_manual(name = "defendant's \nrace",
                    labels = c("Black", "White"),
                    #values = c("gray30", "gray80")) +
                    values = c("gray30", "white")) +
  theme_bw(14) +
  theme(axis.text = element_text(size = rel(rel_text_size)),
        axis.title=element_text(size=rel(rel_text_size),face="bold"),
        legend.text = element_text(size = rel(rel_text_size)),
        legend.title = element_text(size = rel(rel_text_size)),
        strip.text.x = element_text(size = 14),
        axis.text.x=element_text(colour="black"), 
        axis.text.y=element_text(colour="black"),
        strip.background = element_blank(),
        # legend.position = c(0.45, 0.775),
        legend.background = element_rect(fill = "white", colour = NA)
        )

ggsave("graph_analysis_survey_balanced_vs_unbalanced.pdf", width = 10, height = 5, units = "in", scale = 1)
ggsave("graph_analysis_survey_balanced_vs_unbalanced.png", width = 10, height = 5, units = "in", scale = 1)


# Analysis 2: statistical models with balanced and unbalanced data ---------------

#data preparation
data <- recid %>%
  filter(race %in% c("Caucasian", "African-American")) %>%
  select(id, sex, age, race, juv_fel_count, juv_misd_count, juv_other_count, 
         priors_count, c_charge_degree, two_year_recid) %>%
  mutate(c_charge_degree = as.numeric(c_charge_degree=="M"),
         sex = as.numeric(sex=="Male"),
         race = as.numeric(race=="African-American"),
         two_year_recid = as.factor(two_year_recid))

#split data into train and test (all data)
set.seed(124156)
trainingRows = createDataPartition(data$id, p=0.7, list=FALSE,times=1)
trainData <- data[trainingRows,]
trainData$id<-NULL
testData <- data[-trainingRows,]

#Use the entire training set for creating a model
ctrl <- trainControl(method = "repeatedcv", number = 10, savePredictions = TRUE)
mod_fit <- train(two_year_recid ~ .,  data=trainData, method="glm", family="binomial",
                 trControl = ctrl, tuneLength = 5)

#predict on test data
pred = predict(mod_fit, newdata=testData)
testData$pred<-pred
unbalanced_model <- testData %>% group_by(race) %>%
  summarise(tpos = mean(pred == 1 & two_year_recid == 1),
            fpos = mean(pred == 1 & two_year_recid == 0),
            tneg = mean(pred == 0 & two_year_recid == 0),
            fneg = mean(pred == 0 & two_year_recid == 1)) %>%
  mutate(accu = (tpos + tneg) / (tpos + tneg + fpos + fneg),
         fpos_rate = fpos / (fpos + tneg),
         fneg_rate = fneg / (fneg + tpos)) %>%
  mutate(def_race = case_when(
    race == 1 ~ "Black",
    race == 0 ~ "White")) %>%
  select(def_race, accu, fpos_rate, fneg_rate) %>%
  gather(indicator, me, 2:4) %>%
  mutate(indicator = case_when(
    indicator == "accu" ~ "Accuracy",
    indicator == "fpos_rate" ~ "False positive rate",
    indicator == "fneg_rate" ~ "False negative rate"),
    type= "Model \nunbalanced",
    se = 0)

#Use balanced training data (balanced fom all data)
set.seed(124156)
trainingRows = createDataPartition(data$id, p=0.7, list=FALSE,times=1)
trainData = data[trainingRows,]
r1y1<-trainData$race==1 & trainData$two_year_recid==1
r1y0<-trainData$race==1 & trainData$two_year_recid==0
r0y1<-trainData$race==0 & trainData$two_year_recid==1
r0y0<-trainData$race==0 & trainData$two_year_recid==0
trainData%>%group_by(race,two_year_recid)%>%summarize(count=n())

min_size<-min((trainData%>%group_by(race,two_year_recid)%>%summarize(count=n()))$count)

trainData<-rbind((trainData[r1y1,])[sample(1:sum(r1y1),5000, replace=TRUE),],
                 (trainData[r0y1,])[sample(1:sum(r0y1), 5000, replace=TRUE),],
                 (trainData[r1y0,])[sample(1:sum(r1y0), 5000, replace=TRUE),],
                 (trainData[r0y0,])[sample(1:sum(r0y0), 5000, replace=TRUE),])
trainData$id<-NULL
trainData<-trainData[sample(1:nrow(trainData), nrow(trainData)),]

ctrl <- trainControl(method = "repeatedcv", number = 100, savePredictions = TRUE)
mod_fit <- train(two_year_recid ~ .,  data=trainData, method="glm", family="binomial",
                 trControl = ctrl, tuneLength = 5)

pred = predict(mod_fit, newdata=testData)

testData$pred<-pred

balanced_model <- testData %>% group_by(race)%>%
  summarise(tpos = mean(pred == 1 & two_year_recid == 1),
            fpos = mean(pred == 1 & two_year_recid == 0),
            tneg = mean(pred == 0 & two_year_recid == 0),
            fneg = mean(pred == 0 & two_year_recid == 1)) %>%
  mutate(accu = (tpos + tneg) / (tpos + tneg + fpos + fneg),
         fpos_rate = fpos / (fpos + tneg),
         fneg_rate = fneg / (fneg + tpos)) %>%
  mutate(def_race = case_when(
    race == 1 ~ "Black",
    race == 0 ~ "White")) %>%
  select(def_race, accu, fpos_rate, fneg_rate) %>%
  gather(indicator, me, 2:4) %>%
  mutate(indicator = case_when(
    indicator == "accu" ~ "Accuracy",
    indicator == "fpos_rate" ~ "False positive rate",
    indicator == "fneg_rate" ~ "False negative rate"),
    type = "Model \nbalanced",
    se = 0)

## Combining summaries of both surveys

analysis1_model <- bind_rows(balanced_model, unbalanced_model)


## Figure 2

analysis1_model %>%
  ggplot(., aes(x = type, y = me)) +
  geom_bar(aes(fill = def_race), position = "dodge", stat = "identity", colour="black") +
  facet_grid(.~indicator) +
  xlab("") + ylab("") +
  coord_cartesian(ylim = c(0,0.75)) +
  scale_fill_manual(name = "defendant's \nrace",
                    labels = c("Black", "White"),
                    values = c("gray30", "white")) +
  theme_bw(14) +
  theme(axis.text = element_text(size = rel(rel_text_size)),
        axis.title=element_text(size=rel(rel_text_size),face="bold"),
        legend.text = element_text(size = rel(rel_text_size)),
        legend.title = element_text(size = rel(rel_text_size)),
        strip.text.x = element_text(size = 14),
        axis.text.x=element_text(colour="black"), 
        axis.text.y=element_text(colour="black"),
        strip.background = element_blank(),
        # legend.position = c(0.9, 0.775),
        legend.background = element_rect(fill = "white", colour = NA))

ggsave("graph_analysis_model_balanced_vs_unbalanced.pdf", width = 10, height = 5, units = "in", scale = 1)
ggsave("graph_analysis_model_balanced_vs_unbalanced.png", width = 10, height = 5, units = "in", scale = 1)


# Analysis 3: race by race results ---------------

## Analysis of TurkPrime survey data ----------
race_by_race <- tp_data %>%
  group_by(resp_id, resp_black, def_black) %>%
  summarise(
    tpos = mean(two_year_recid==1 & resp_decision==1),
    tneg = mean(two_year_recid==0 & resp_decision==0),
    fpos = mean(two_year_recid==0 & resp_decision==1),
    fneg = mean(two_year_recid==1 & resp_decision==0)) %>%
  mutate(accu = (tpos + tneg) / (tpos + tneg + fpos + fneg),
         fpos_rate = fpos / (fpos + tneg),
         fneg_rate = fneg / (fneg + tpos)) %>%
  mutate(source = case_when(
    resp_black == 1 ~ "Resp. Black",
    resp_black == 0 ~ "Resp. White"),
    def_race = case_when(
      def_black == 1 ~ "Defendant Black",
      def_black == 0 ~ "Defendant White"))%>%
  group_by(source, def_race)%>%
  summarize(mean_accu = mean(accu),
            mean_fpos_rate = mean(fpos_rate),
            mean_fneg_rate = mean(fneg_rate),
            se_accu = sd(accu)/sqrt(n()),
            se_fpos_rate = sd(fpos_rate)/sqrt(n()),
            se_fneg_rate = sd(fneg_rate)/sqrt(n())) %>% 
  select(1:5) %>% 
  gather(indicator, value, 3:5) %>%
  mutate(indicator = case_when(
    indicator == "mean_accu" ~ "Accuracy",
    indicator == "mean_fpos_rate" ~ "False positive rate",
    indicator == "mean_fneg_rate" ~ "False negative rate"
  ))


## Analysis of COMPAS predictions
compas_def_race <- tp_data %>%
  group_by(def_black, def_id) %>%
  summarise(decile_score = mean(decile_score),
            two_year_recid = mean(two_year_recid)) %>%
  mutate(compas_hi_risk = as.numeric(decile_score > 4)) %>%
  group_by(def_black) %>%
  summarise(tpos = mean(compas_hi_risk == 1 & two_year_recid == 1),
            fpos = mean(compas_hi_risk == 1 & two_year_recid == 0),
            tneg = mean(compas_hi_risk == 0 & two_year_recid == 0),
            fneg = mean(compas_hi_risk == 0 & two_year_recid == 1)) %>%
  mutate(accu = (tpos + tneg) / (tpos + tneg + fpos + fneg),
         fpos_rate = fpos / (fpos + tneg),
         fneg_rate = fneg / (fneg + tpos)) %>%
  mutate(def_race = case_when(
    def_black == 1 ~ "Defendant Black",
    def_black == 0 ~ "Defendant White"),
    source = "COMPAS") %>%
  ungroup() %>%
  select(10, 9, 6, 7, 8) %>%
  gather(indicator, value, 3:5) %>%
  mutate(indicator = case_when(
    indicator == "accu" ~ "Accuracy",
    indicator == "fpos_rate" ~ "False positive rate",
    indicator == "fneg_rate" ~ "False negative rate"
  ))

## Figure 3

bind_rows(compas_def_race, race_by_race) %>%
  ggplot(., aes(x = source, y = value)) +
  geom_bar(aes(fill = def_race), position = "dodge", stat = "identity", colour="black") +
  facet_grid(.~indicator) +
  xlab("") + ylab("") +
  scale_fill_manual(name = "defendant's \nrace",
                    labels = c("Black", "White"),
                    values = c("gray30", "white")) +
  theme_bw(12) +
  theme(#text = element_text(size=12), 
        strip.background = element_blank(), 
        strip.text.x = element_text(size = 12), 
    axis.text.x=element_text(colour="black"), 
    axis.text.y=element_text(colour="black"))

ggsave("graph_analysis_COMPAS_vs_survey.pdf", width = 10, height = 3, units = "in", scale = 1)
ggsave("graph_analysis_COMPAS_vs_survey.png", width = 10, height = 3, units = "in", scale = 1)
