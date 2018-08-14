library(dplyr)
library(randomForest)
library(caret)

dat <- read.csv('../data/taarifa.csv', stringsAsFactors = FALSE)

# convert categoricals to factors
dat$quantity = factor(dat$quantity)
dat$extraction_type = factor(dat$extraction_type)
dat$waterpoint_type = factor(dat$waterpoint_type)
dat$payment = factor(dat$payment)
dat$source = factor(dat$source)

dat$construction_year[dat$construction_year == 'unknown'] <- 0
dat$population[dat$population == 'unknown'] <- 0

# convert well status to integers
dat$status_group[which(dat$status_group == 'functional')] <- 0
dat$status_group[which(dat$status_group == 'functional needs repair')] <- 1
dat$status_group[which(dat$status_group == 'non functional')] <- 2

dat$status_group <- factor(dat$status_group)

#split dataset into training and testing sets using 75-25 split
set.seed(123)
training_indicies = sample(1:nrow(dat), size = floor(0.75*nrow(dat))) # By default, sample is without replacement so training indicies unique
training = dat[training_indicies,]
testing = dat[-training_indicies,]

# Random Forest.
rf_model <- randomForest(status_group ~ quantity + waterpoint_type + extraction_type + construction_year + payment + source + population, ntree = 100, data = training)
summary(rf_model)
predicted_status <- predict(rf_model, testing)
compare_status <- table(predicted_status, testing$status_group)
# display: off-diag numbers are mis-classifications
confusionMatrix(compare_status)
