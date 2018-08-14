library(nnet)
library(caret)

dat <- read.csv('../data/taarifa.csv', stringsAsFactors = FALSE)

# convert categoricals to factors
dat$quantity = factor(dat$quantity)
dat$extraction_type = factor(dat$extraction_type)
dat$waterpoint_type = factor(dat$waterpoint_type)
dat$payment = factor(dat$payment)
dat$source = factor(dat$source)

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

# multinomial logistic regression model
mlr1 = multinom(status_group ~ quantity + extraction_type + waterpoint_type + construction_year + payment + source + population, 
                data = dat, maxit = 200)
# confusion matrix - training subset
cm1 <- table(predict(mlr1, dat), dat$status_group)
# display: off-diag numbers are mis-classifications
cm1

# calculate percentage of accurate classifications
sum(diag(cm1))/sum(cm1)
mlr1$AIC

# Check variable importance
importance <- varImp(mlr1)
importance <- importance[order(importance$Overall,decreasing = TRUE), ,drop = FALSE]
print(importance)

# Cross-validation
trctrl <- trainControl(method = "repeatedcv", number = 5, repeats = 2)
set.seed(333)

mlr_fit <- train(status_group ~ quantity + extraction_type + waterpoint_type + construction_year + gps_height + payment + source + population,
                 data = training, method = "multinom", maxit = 200, trControl=trctrl, preProcess = c("center", "scale"),tuneLength = 10, na.action=na.exclude)
mlr_fit

# get predictions
test_pred <- predict(mlr_fit, newdata = testing)
# check confusion matrix
confusionMatrix(test_pred, testing$status_group )