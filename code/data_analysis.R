library(ggplot2)
library(dplyr)

# Working Directory: taarifa/folder (such as report or code or data)
dat <- read.csv('../data/taarifa.csv', stringsAsFactors = FALSE)

prop_non_functional = round(nrow(dat %>% filter(status_group == 'non functional'))/nrow(dat)*100,2)

# Finds the proportion of wells by a given category label
find_prop <- function(label, data = dat){
  total = data %>% group_by_(label) %>% summarise(total_number = n())
  counts = data %>% group_by_(label, 'status_group') %>% summarise(number_of_wells = n())
  counts = full_join(counts, total, by = label) %>% mutate(prop = round(number_of_wells/total_number*100, 2))
  return(counts)
}
find_prop('extraction_type')

# Store proportions in a list
discrete_categories = c('quantity','extraction_type', 'waterpoint_type', 'payment','source_type','quality_group','management_group') # Name of columns with discrete variables
dat_proportions = numeric()
for(col in discrete_categories){
  dat_proportions = c(dat_proportions, list(find_prop(col)))
}
names(dat_proportions) <- discrete_categories
dat_proportions

ggplot(data = dat_proportions$quantity) +
  geom_col(aes(x = quantity, y = prop, fill = status_group)) +
  labs(x = 'Water Quantity', fill = 'Status', y = 'Percentage of Waterpoints') +
  ggtitle('Status of Waterpoints by Water Quantity') +
  geom_hline(aes(yintercept = prop_non_functional), size = 1, linetype = 'dashed') +
  scale_fill_manual(values = c('#00BA38','#619CFF','#F8766D')) # default ggplot2 colours in green-blue-red

dat_year = dat %>% filter(construction_year != 0 & construction_year != 'unknown') %>% filter(construction_year != 'unknown')
dat_population = dat %>% filter(population != 0) %>% filter(population != 'unknown')

nrow(dat %>% filter(waterpoint_type == 'unknown'))/nrow(dat)
nrow(dat_year)/nrow(dat)
nrow(dat_population)/nrow(dat)
