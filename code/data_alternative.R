library(dplyr)
library(stringr)

training_labels <- read.csv('../data/training_labels.csv', stringsAsFactors = FALSE)
training_values <- read.table('../data/training_set_roads.txt', sep = ",", header = TRUE, stringsAsFactors = FALSE, fill = TRUE, quote = "\"") 
training_dist = training_values %>% select(id, NEAR_DIST)

training_dist$id = str_replace_all(training_dist$id, pattern = ",",replacement = "") # Remove commas to convert to numeric data types
training_dist$NEAR_DIST = str_replace_all(training_dist$NEAR_DIST, pattern = ",", replacement = "")

training_dist$id = as.integer(training_dist$id) # Convert to numeric data types
training_dist$NEAR_DIST = round(as.numeric(training_dist$NEAR_DIST),2)

str(training_dist)

write.csv(training_dist, '../data/cleaned_distances.csv')

# quote argument allows single quotes to be treated as normal data
# dat1 <- full_join(training_values, training_labels, by = 'id')