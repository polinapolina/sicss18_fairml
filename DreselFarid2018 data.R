
recid <- read.csv('C:/Users/mkolc/Google Drive/CONSIRT priv/Harmonia priv/Conferences, Workshop, Funding, Publications/SICSS Duke University June 2018/group project algorithmic fairness/DreselFarid2018/BROWARD_ORIGINAL.csv', 
                  head = TRUE, stringsAsFactors=FALSE)


chargeid <- read.csv('C:/Users/mkolc/Google Drive/CONSIRT priv/Harmonia priv/Conferences, Workshop, Funding, Publications/SICSS Duke University June 2018/group project algorithmic fairness/DreselFarid2018/CHARGE_ID.csv', 
                  head = TRUE, stringsAsFactors=FALSE)



#charge <- data.frame(table(recid$c_charge_desc))

recid <- filter(recid, c_charge_desc != "")

recid$race[which(recid$race == "African-American")] <- "AfricanAmerican"

recid %>% count(sex)

by_group <- recid %>% filter(sex != "Female", race %in% c("Caucasian", "AfricanAmerican")) %>%
  count(race, age_cat, c_charge_degree, two_year_recid) %>% mutate(group_id = rownames(.))

merge <- inner_join(recid, by_group, by = c("race", "age_cat", "c_charge_degree", "two_year_recid")) %>%
  filter(sex == "Male" & c_charge_desc != "arrest case no charge") %>%
  arrange(group_id, decile_score) %>% select(c(1,6,8,9,10,11,13,14,15,23,24,41,12,53,54,55)) %>%
  inner_join(chargeid, by = "c_charge_desc")

merge %>% count(group_id, mturk_charge_name) %>% filter(group_id == 13) %>% arrange(desc(nn))


hist(recid$decile_score)

