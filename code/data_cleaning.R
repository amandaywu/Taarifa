library(dplyr)
library(stringr)

# First Dataset: From Taarifa Contest (training set data)
training_values <- read.csv('../data/training_set.csv', stringsAsFactors = FALSE)
training_labels <- read.csv('../data/training_labels.csv', stringsAsFactors = FALSE)
dat1 <- full_join(training_values, training_labels, by = 'id') %>% select(id, quantity, extraction_type, waterpoint_type, 
                                                                          construction_year, payment, source_type, population, 
                                                                          quality_group, management_group, status_group) 
# Select most important features that are replicable across different countries + well status
dat1$construction_year = as.integer(dat1$construction_year)

# Edit for consistency with dat2
dat1$payment = str_replace_all(dat1$payment, pattern = "pay when scheme fails", replacement = "on failure")
dat1$payment = str_replace_all(dat1$payment, pattern = "pay per bucket", replacement = "per bucket")
dat1$payment = str_replace_all(dat1$payment, pattern = "pay monthly", replacement = "monthly")
dat1$payment = str_replace_all(dat1$payment, pattern = "pay annually", replacement = "annually")
dat1$source_type = str_replace_all(dat1$source_type, pattern = "river|lake", replacement = "river/lake")

# Merge roads dataset by ID, then remove id
dat_roads = read.csv('../data/cleaned_distances.csv') %>% select(id, NEAR_DIST)
dat1_with_roads <- full_join(dat1, dat_roads, by = 'id') %>% select(-id)
dat1_with_roads$NEAR_DIST = as.numeric(dat1_with_roads$NEAR_DIST)

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
for (col in c('quantity','extraction_type','payment','source_type','status_group','quality_group','management_group')) {
  dat2[dat2[,col] == '',col] = 'unknown'
}

# Add median road distance from dat1 as distance to nearest road for dat2 as we don't have these values
median_road_distance = median(dat1_with_roads$NEAR_DIST, na.rm = TRUE)
dat2 = dat2 %>% mutate(NEAR_DIST = median_road_distance)
dat1_with_roads$NEAR_DIST[is.na(dat1_with_roads$NEAR_DIST)] = median_road_distance

dat = bind_rows(dat1_with_roads, dat2)

dat[is.na(dat)] <- "unknown" # Change all missing values to "unknown" for ML models

write.csv(dat, file = '../data/taarifa.csv', row.names = FALSE)
