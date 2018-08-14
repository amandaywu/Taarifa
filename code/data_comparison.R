library(dplyr)
library(stringr)

# First Dataset: From Taarifa Contest (training set data)
training_values <- read.csv('../data/training_set.csv', stringsAsFactors = FALSE)
training_labels <- read.csv('../data/training_labels.csv', stringsAsFactors = FALSE)
dat1 <- full_join(training_values, training_labels, by = 'id') %>% select(quantity, extraction_type, waterpoint_type, 
                                                                          construction_year, payment, source_type, population, 
                                                                          quality_group, management_group, status_group) 
# Select most important features that are replicable across different countries + well status
dat1$construction_year = as.integer(dat1$construction_year)

# Edit for consistency with dat2
dat1$payment = str_replace_all(dat1$payment, pattern = "pay when scheme fails", replacement = "on failure")
dat1$payment = str_replace_all(dat1$payment, pattern = "pay per bucket", replacement = "per bucket")
dat1$payment = str_replace_all(dat1$payment, pattern = "pay monthly", replacement = "monthly")
dat1$payment = str_replace_all(dat1$payment, pattern = "pay annually", replacement = "annually")
dat1$source = str_replace_all(dat1$source, pattern = "river|lake", replacement = "river/lake")

# Second Dataset: Found from Taarifa API
dat2 = read.csv('../data/merged.csv', stringsAsFactors = FALSE)
dat2 = dat2 %>% mutate(waterpoint_type = "unknown")
dat2 = dat2 %>% select(Quality_group, Extraction_group, waterpoint_type, Construction_year, Payment_group, 
                       Source_group, Pop_served, Quality_group.1, Management, Status_group) # Missing waterpoint type
dat2 = dat2 %>% rename(quantity = Quality_group, extraction_type = Extraction_group, construction_year = Construction_year, payment = Payment_group, 
                       source_type = Source_group, population = Pop_served, quality_group = Quality_group.1, management_group = Management, status_group = Status_group)
dat2$construction_year = as.integer(dat2$construction_year)
dat2$status_group = str_replace_all(dat2$status_group, pattern = "not functional", replacement = "non functional")
dat2$status_group = str_replace_all(dat2$status_group, pattern = "needs repair", replacement = "functional needs repair")
dat2$payment = str_replace_all(dat2$payment, pattern = "never pays", replacement = "never pay")

# Remove empty cells and replace with 'unknown' (only really 1 observation at present)
for (col in c('quantity','extraction_type','payment','source_type','status_group')) {
  dat2[dat2[,col] == '',col] = 'unknown'
}

prop_nf1 = round(nrow(dat1 %>% filter(status_group == 'non functional'))/nrow(training_labels)*100,2)
prop_nf2 = round(nrow(dat2 %>% filter(status_group == 'non functional'))/nrow(dat2)*100,2)

# Finds the proportion of wells by a given category label
compare <- function(label){
  prop1 = dat1 %>% group_by_(label) %>% summarise(proportion_contest = round(n()/nrow(dat1)*100,2))
  prop2 = dat2 %>% group_by_(label) %>% summarise(proportion_api = round(n()/nrow(dat2)*100,2))
  prop = full_join(prop1, prop2, by = label) %>% mutate(difference = round(proportion_contest - proportion_api,2)) %>% arrange(desc(difference))
  return(prop)
}

compare('quantity')

# Store proportions in a list
discrete_categories = c('quantity','extraction_type', 'waterpoint_type', 'payment','source_type','quality_group','management_group') # Name of columns with discrete variables
compare_proportions = numeric()
for(col in discrete_categories){
  compare_proportions = c(compare_proportions, list(compare(col)))
}
names(compare_proportions) <- discrete_categories
compare_proportions