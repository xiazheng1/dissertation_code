# Generalized random forest-causal_forest algorithm

library(tidyverse)
library(grf)
library(readstata13)
library(ggpubr)

rm(list=ls())

path <- "my_directory"
setwd(path)

set.seed(2023)

# Load data from Stata 
df <- read.dta13("hsls_BYF2_procd.dta", convert.factors = F) # do not create factors from Stata value labels.

# Train a causal forest

# remove observations with missing values in the outcome or treatment
df_work <- df %>% 
  filter(`nctdisad_2012_ter` != "NA" & `nevercol` != "NA")

W <- df_work$nctdisad_2012_ter
Y <- df_work$nevercol               
X <- df_work[, c("ngender", "nrace", "nbirthy", "nlang", "nexpct", "ndisab", 
                 "nptype", "nnumhm", "nses", "npage", 
                 "nschtype", "nschloc", "nschreg", "nschrp")]

# check the percentage of cases having missing values in one or more covariates
sum(!complete.cases(X)) / nrow(X) 
t.test(W ~ !complete.cases(X), data = df_work)  #check for significant difference in treatment assignment between the missing and non-missing groups

# the difference is highly significant, remove cases with missing values in the covariates
df_work <- df_work[complete.cases(X),]
W <- df_work$nctdisad_2012_ter
Y <- df_work$nevercol               
X <- df_work[, c("ngender", "nrace", "nbirthy", "nlang", "nexpct", "ndisab", 
                 "nptype", "nnumhm", "nses", "npage", 
                 "nschtype", "nschloc", "nschreg", "nschrp")]

# train separate regression forests to estimate marginal outcomes and propensity scores with all covariates
Y.forest = regression_forest(X, Y) 
Y.hat = predict(Y.forest)$predictions
W.forest = regression_forest(X, W)
W.hat = predict(W.forest)$predictions     # using oob predictions
hist(W.hat, xlab = "propensity score") # check the overlap assumption
#If there is strong overlap, the histogram will be concentrated away from 0 and 1. 
#If the data is concentrated at the extremes, the overlap assumption likely does not hold.


# train a pilot forest on all features
cf_raw <- causal_forest(X, Y, W, Y.hat = Y.hat, W.hat = W.hat, sample.weights = df_work$nsampwt)  
# can reduce the parameters for tuning, and increase tune.num.trees for more stable results
# did not enable cluster-robust estimation during training
# num.trees defaults to 2000 for each forest

# estimate causal effects for the training data using out-of-bag prediction
oob.predictions_raw = predict(cf_raw)$predictions
hist(oob.predictions_raw)     # check if the distribution of the personalized effect predictions reveals any variation

#train a second forest on features that saw a reasonable number of splits
varimp <- variable_importance(cf_raw)
varimp_index <- which(varimp > mean(varimp))
ranked.vars <- order(varimp, decreasing = TRUE)
colnames(X)[ranked.vars[1:5]]    #get the five most important vars
colnames(X)[varimp_index]

cf <- causal_forest(X[,ranked.vars[1:5]], Y, W, Y.hat = Y.hat, W.hat = W.hat, sample.weights = df_work$nsampwt, tune.parameters = "all")

oob.predictions <- predict(cf)$predictions
hist_tuned <- hist(oob.predictions)
hist_tuned

# Make a histogram of oob.predictions from tuned and untuned refined forests
cf_untuned <- causal_forest(X[,ranked.vars[1:5]], Y, W, Y.hat = Y.hat, W.hat = W.hat, sample.weights = df_work$nsampwt)

oob.predictions_untuned <- predict(cf_untuned)$predictions
hist_untuned <- hist(oob.predictions_untuned)

plot(hist_tuned, col = rgb(1, 0, 0, 1), xlim = c(-0.3, 0.3), ylim = c(0, 2500), border = F,
     xlab = substitute(paste(bold('Personalized CATEs'))), ylab = substitute((paste(bold('Count')))), main = NULL)
plot(hist_untuned, col = rgb(0, 0, 1, 0.3), xlim = c(-0.3, 0.3),  ylim = c(0, 2500), border = F, add = T,
     xlab = substitute((paste(bold('Personalized CATEs')))), ylab = substitute((paste(bold('Count')))), main = NULL)
tunedCol <- rgb(1, 0, 0, 1)
untunedCol <- rgb(0,0,1,0.3)
legend("topleft", legend = c("tuned", "untuned"), bty = "n", 
       fill = c(tunedCol,untunedCol), border = NA)

# Average Treatment Effect
average_treatment_effect(cf, target.sample = "overlap", subset = df_work$nsampwt > 0)

# Best linear projection of CATEs onto the most important variables to assess associations
best_linear_projection(cf, X$nexpct, subset = df_work$nsampwt > 0)
best_linear_projection(cf, X$nses, subset = df_work$nsampwt > 0)
best_linear_projection(cf, X$npage, subset = df_work$nsampwt > 0)
best_linear_projection(cf, X$nschreg, subset = df_work$nsampwt > 0)
best_linear_projection(cf, X$ndisab, subset = df_work$nsampwt > 0)

# Make histograms of CATEs by important variables
df_work_pr <- cbind(df_work, oob.predictions) %>% 
  mutate(nexpct = recode(nexpct, '1'=1, '2'=1, '3'=1, '4'=1, '5'=2, '6'=2, '7'=3,'8'=3,'9'=3,'10'=3))

ggplot_expct <- ggplot(data = df_work_pr) +
  geom_histogram(aes(oob.predictions, fill = as.factor(nexpct)), binwidth = 0.01, position = "dodge") +
  labs(title = expression(paste(bold("Distribution of CATEs by Expected Level of Education"))), x = expression(paste(bold("Personalized CATEs"))), y = expression(paste(bold("Count"))), fill = "Expected Level of Education") +
  scale_fill_brewer(palette = "RdYlBu") +
  scale_fill_discrete(labels = c("1 less than bachelor's", "2 bachelor's", "3 graduate degree")) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "grey"),
        panel.grid.minor.y = element_line(color = "grey"),
        panel.background = element_rect(fill = NA),
        axis.line = element_line(color = "grey")
  )
ggplot_expct

# Make scatterplots of CATEs by important variables
ggplot_ses_expct <- ggplot(data = df_work_pr, aes(nses, oob.predictions, color = as.factor(nexpct))) +
  geom_point() + geom_smooth(method = "loess", se = FALSE, show.legend = FALSE) +
  labs(title = expression(paste(bold("Association Between CATEs and Household SES by Expected Level of Education"))),
       x = expression(paste(bold("Household SES Scale"))),
       y = expression(paste(bold("Personalized CATEs"))),
       color = "Expected Level of Education") +
  scale_color_brewer(palette = "RdYlBu") +
  scale_color_discrete(labels = c("1 less than bachelor's", "2 bachelor's", "3 graduate degree")) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "grey"),
        panel.grid.minor.y = element_line(color = "grey"),
        panel.background = element_rect(fill = NA),
        axis.line = element_line(color = "grey")
  )
ggplot_ses_expct

ggplot_page_expct <- ggplot(data = df_work_pr, aes(npage, oob.predictions, color = as.factor(nexpct))) +
  geom_point() + geom_smooth(method = "loess", se = FALSE, show.legend = FALSE) +
  labs(title = expression(paste(bold("Association between CATEs and Parents' Age by Expected Level of Education"))),
       x = expression(paste(bold("Parents' Age"))),
       y = expression(paste(bold("Personalized CATEs"))),
       color = "Expected Level of Education") +
  scale_color_brewer(palette = "RdYlBu") +
  scale_color_discrete(labels = c("1 less than bachelor's", "2 bachelor's", "3 graduate degree")) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "grey"),
        panel.grid.minor.y = element_line(color = "grey"),
        panel.background = element_rect(fill = NA),
        axis.line = element_line(color = "grey")
  )
ggplot_page_expct


