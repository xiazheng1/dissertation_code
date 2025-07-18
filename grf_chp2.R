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
df <- read.dta13("childK5_procd.dta", convert.factors = F) # do not create factors from Stata value labels.

# Train a causal forest

# remove observations with missing values in the outcome or treatment
df_work <- df %>% 
  filter(`nctdisad_sp2_ter` != "NA" & `nsoc_sp3` != "NA")

W <- df_work$nctdisad_sp2_ter
Y <- df_work$nsoc_sp3         
X <- df_work[, c("ngender", "nbirthy", "nrace", "ndisab", "nlang", "nspedu", "nfnumhm", "nfptype", "nfpage", "nfpmarried", "nfhses", "nschtype", 
                 "nschenroll", "nschreg", "nschloc")]

# check the percentage of cases having missing values in one or more covariates
sum(!complete.cases(X)) / nrow(X) 
t.test(W ~ !complete.cases(X), data = df_work)  #check for significant difference in treatment assignment between the missing and non-missing groups
#if the difference is not significant, we keep the cases with missing values in the covariates; if significant, remove obs with missing values in the covariates

# the difference is highly significant, remove cases with missing values in the covariates
df_work <- df_work[complete.cases(X),]
W <- df_work$nctdisad_sp2_ter
Y <- df_work$nsoc_sp3            
X <- df_work[, c("ngender", "nbirthy", "nrace", "ndisab", "nlang", "nspedu", "nfnumhm", "nfptype", "nfpage", "nfpmarried", "nfhses", "nschtype", 
                 "nschenroll", "nschreg", "nschloc")]


# train separate regression forests to estimate marginal outcomes and propensity scores with all covariates
Y.forest = regression_forest(X, Y) 
Y.hat = predict(Y.forest)$predictions
W.forest = regression_forest(X, W)
W.hat = predict(W.forest)$predictions     # using oob predictions
hist(W.hat, xlab = "propensity score") # check the overlap assumption
#If there is strong overlap, the histogram will be concentrated away from 0 and 1. 
#If the data is instead concentrated at the extremes, the overlap assumption likely does not hold.


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
colnames(X)[ranked.vars[1:5]]   #get the five most important vars

cf <- causal_forest(X[,varimp_index], Y, W, Y.hat = Y.hat, W.hat = W.hat, sample.weights = df_work$nsampwt, tune.parameters = "all")

oob.predictions <- predict(cf)$predictions
hist_tuned <- hist(oob.predictions)
hist_tuned

# Make a histogram of oob.predictions from tuned and untuned refined forests
cf_untuned <- causal_forest(X[,varimp_index], Y, W, Y.hat = Y.hat, W.hat = W.hat, sample.weights = df_work$nsampwt)

oob.predictions_untuned <- predict(cf_untuned)$predictions
hist_untuned <- hist(oob.predictions_untuned)

plot(hist_tuned, col = rgb(1, 0, 0, 1), xlim = c(-0.8, 0.5), ylim = c(0, 2000), border = F, 
     xlab = substitute(paste(bold('Personalized CATEs'))), ylab = substitute(paste(bold('Count'))), main = NULL)
plot(hist_untuned, col = rgb(0, 0, 1, 0.3), xlim = c(-0.8, 0.5),  ylim = c(0, 2000), border = F, add = T,
     xlab = substitute(paste(bold('Personalized CATEs'))), ylab = substitute(paste(bold('Count'))), main = NULL)
tunedCol <- rgb(1, 0, 0, 1)
untunedCol <- rgb(0,0,1,0.3)
legend("topleft", legend = c("tuned", "untuned"), bty = "n", 
       fill = c(tunedCol,untunedCol), border = NA)

# Average Treatment Effect
average_treatment_effect(cf, target.sample = "overlap", subset = df_work$nsampwt > 0)

# Best linear projection of CATEs onto the most important variables to assess associations
df_work_pr <- cbind(df_work, oob.predictions) %>% 
  mutate(ptype = recode(nfptype, '1'=1, '2'=2, '3'=2, '4'=2)) %>% 
  mutate(lang = recode(nlang, '2'=1, '1'=2, '3'=2)) %>%
  mutate(numhm = ifelse(nfnumhm > 4, 2, 1)) %>%
  mutate(race = ifelse(nrace == 1, 1, 2))

best_linear_projection(cf, df_work_pr$numhm, subset = df_work_pr$nsampwt > 0)
best_linear_projection(cf, X$nfpage, subset = df_work$nsampwt > 0)
best_linear_projection(cf, X$nfhses, subset = df_work$nsampwt > 0)
best_linear_projection(cf, df_work_pr$race, subset = df_work_pr$nsampwt > 0)
best_linear_projection(cf, df_work_pr$ptype, subset = df_work_pr$nsampwt >0)

best_linear_projection(cf, df_work_pr$lang, subset = df_work_pr$nsampwt >0)
best_linear_projection(cf, X$nschenroll, subset = df_work$nsampwt > 0)

# Estimate RATE again to see if values of an important variable capture any effect heterogeneity 
#use the trained forest on the full data since we are computing the RATE based on a covariate
rate.ptype <- rank_average_treatment_effect(cf, df_work_pr$ptype, subset = !is.na(df_work_pr$ptype))
rate.ptype
plot(rate.ptype, ylab = "Difference in treatment effects", main = "TOC: By Decreasing Parent Type")

rate.page <- rank_average_treatment_effect(cf, X$nfpage, subset = !is.na(X$nfpage))
rate.page
plot(rate.page, ylab = "Difference in treatment effects", main = "TOC: By Decreasing Primary Caregiver Age")

rate.lang <- rank_average_treatment_effect(cf, df_work_pr$lang, subset = !is.na(df_work_pr$lang))
rate.lang
plot(rate.lang, ylab = "Difference in treatment effects", main = "TOC: By Decreasing Language Categories")

rate.hses <- rank_average_treatment_effect(cf, X$nfhses, subset = !is.na(X$nfhses))
rate.hses
plot(rate.hses, ylab = "Difference in treatment effects", main = "TOC: By Decreasing Household SES")

# Make histograms of CATEs by important variables
ggplot_ptype <- ggplot(data = df_work_pr) +
  geom_histogram(aes(oob.predictions, fill = as.factor(ptype)), binwidth = 0.01, position = "dodge") +
  labs(title = expression(paste(bold("a. Distribution of CATEs by Parent Type"))), x = expression(paste(bold("Personalized CATEs"))), y = expression(paste(bold("Count"))), fill = "Parent Type") +
  scale_fill_brewer(palette = "RdYlBu") +
  scale_fill_discrete(labels = c("1 two bio/adop parents", "2 missing at least one bio/adop parent")) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "grey"),
        panel.grid.minor.y = element_line(color = "grey"),
        panel.background = element_rect(fill = NA),
        axis.line = element_line(color = "grey")
  )
ggplot_ptype

ggplot_lang <- ggplot(data = df_work_pr) +
  geom_histogram(aes(oob.predictions, fill = as.factor(lang)), binwidth = 0.01, position = "dodge") +
  labs(title = expression(paste(bold("a. Distribution of CATEs by Language at Home"))), x = expression(paste(bold("Personalized CATEs"))), y = expression(paste(bold("Count"))), fill = "Language") +
  scale_fill_brewer(palette = "RdYlBu") +
  scale_fill_discrete(labels = c("1 speak only english at home", "2 speak other languages at home")) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "grey"),
        panel.grid.minor.y = element_line(color = "grey"),
        panel.background = element_rect(fill = NA),
        axis.line = element_line(color = "grey")
  )
ggplot_lang

# Make scatterplots of CATEs by important variables

ggplot_page_ptype <- ggplot(data = df_work_pr, aes(nfpage, oob.predictions, color = as.factor(ptype))) +
  geom_point() + geom_smooth(method = "loess", se = FALSE, show.legend = FALSE) +
  labs(title = expression(paste(bold("b. Association between CATEs and Primary Caregiver Age by Parent Type"))),
       x = expression(paste(bold("Primary Caregiver Age"))),
       y = expression(paste(bold("Personalized CATEs"))),
       color = "Parent Type") +
  scale_color_brewer(palette = "RdYlBu") +
  scale_color_discrete(labels = c("1 two bio/adop parents", "2 missing at least one bio/adop parent")) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "grey"),
        panel.grid.minor.y = element_line(color = "grey"),
        panel.background = element_rect(fill = NA),
        axis.line = element_line(color = "grey")
  )
ggplot_page_ptype

ggplot_hses_lang <- ggplot(data = df_work_pr, aes(nfhses, oob.predictions, color = as.factor(lang))) +
  geom_point() + geom_smooth(method = "loess", se = FALSE, show.legend = FALSE) +
  labs(title = expression(paste(bold("b. Association Between CATEs and Household SES by Language at Home"))),
       x = expression(paste(bold("Household SES Scale"))),
       y = expression(paste(bold("Personalized CATEs"))),
       color = "Language") +
  scale_color_brewer(palette = "RdYlBu") +
  scale_color_discrete(labels = c("1 speak only english at home", "2 speak other languages at home")) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "grey"),
        panel.grid.minor.y = element_line(color = "grey"),
        panel.background = element_rect(fill = NA),
        axis.line = element_line(color = "grey")
  )
ggplot_hses_lang

# Combine histograms and scatterplots by key variables

ggarrange(ggplot_ptype, ggplot_page_ptype, 
          ncol = 1, 
          nrow = 2, common.legend = FALSE, legend = "bottom") 

ggarrange(ggplot_lang, ggplot_hses_lang, 
          ncol = 1, 
          nrow = 2, common.legend = TRUE, legend = "bottom") 

