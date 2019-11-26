################################################################################# Coefficients / Odds for Logistic Regressions
###############################################################################
ModelCoef <- function(x) {
  summary(x)$coefficients %>%
             data.frame() %>%
             rownames_to_column("variable") %>%
             ## filter(Pr...z.. < 0.1, variable != '(Intercept)') %>%
             mutate(odds = exp(Estimate),
                    p = case_when(Pr...z.. > 0.05 ~ '.  ',
                                  Pr...z.. > 0.01 ~ '*  ',
                                  Pr...z.. > 0.001 ~ '** ',
                                  Pr...z.. >= 0 ~ '***')) %>%
             select(variable, odds, coef = Estimate, p) %>%
             arrange(variable)
}

###############################################################################
## AUC
###############################################################################
## via https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test#Area-under-curve_(AUC)_statistic_for_ROC_curves
AUCwilcox <- function(labels, scores) {
  1-wilcox.test(scores ~ labels)$statistic / sum(labels) / sum(!labels)
}

AUCprob <- function(labels, scores, N=1e6) {
  pos <- sample(scores[labels], N, replace=TRUE)
  neg <- sample(scores[!labels], N, replace=TRUE)
  (sum(pos > neg) + sum(pos == neg)/2) / N # give partial credit for ties
}

## USE:
## nmPred %>%
##   group_by(model, segment) %>%
##   summarize(auc = AUCprob(target == 1, pred, N = 1e6)) %>%
##   arrange(segment, model)


###############################################################################
## Performance Measures At All Thresholds
###############################################################################
ConfusionMatrix <- function(data, target, prediction) {
  target <- enquo(target)
  prediction <- enquo(prediction)
  groups <- group_vars(data)
  data %>%
    mutate(t = !! target == 1) %>%
    group_by(t, prediction = !! prediction, add = T) %>%
    count %>%
    spread(t, n, fill = 0) %>%
    rename('false' = 'FALSE', 'true' = 'TRUE') %>%
    group_by_at(groups)
}

PerformanceMeasures <-
  function(data, prediction_var = !!sym("prediction"),
           positive_condition_var = !!sym("true"),
           negative_condition_var = !!sym("false"),
           reverse = F) {
    prediction_var <- enquo(prediction_var)
    if(reverse) {
      positive <- enquo(negative_condition_var)
      negative <- enquo(positive_condition_var)
    }
    else {
      positive <- enquo(positive_condition_var)
      negative <- enquo(negative_condition_var)
    }
    data %>%
      rename(.t = !! positive,
             .f = !! negative) %>%
      arrange((0.5-reverse) * !! prediction_var) %>%
      mutate(
        N = sum(.t + .f),
        tn = cumsum(.f),               # FF - TN
        fn = cumsum(.t),               # FT - FN
        fp = sum(.f) - tn,             # TF - FP
        tp = sum(.t) - fn,             # TT - TP
        ## Sensitivity, Recall, Hit Rate, or True Positive Rate (TPR)
        sens = tp / (tp + fn),
        ## Specificity, Selectivity or True Negative Rate (TNR)
        spec = tn / (tn + fp),         
        ## Precision or Positive Predictive Value (PPV)
        prec = tp / (tp + fp),
        ## Prevalence
        prev = (tp + fn) / N,
        ## Accuracy
        acc = (tp + tn) / N,
        ## Diagnostic odds ratio (DOR)
        dor = tp * tn / fp / fn,
        ## Youden's J statistic, Informedness or Bookmaker Informedness (BM)
        j = sens + spec - 1,
        ## F1 score
        f1 = 2*tp / (2*tp + fp + fn),
        ## Matthews correlation coefficient (MCC)
        S = (tp + fn) / N,
        P = (tp + fp) / N,
        mcc = (tp/N - S*P) / sqrt(S*P*(1-S)*(1-P)),
        ## Predicted Cumulative Count (from high to low)
        n_predicted = (tp + fp),
        ## Predicted Cumulative Percent
        p_predicted = n_predicted / N,      
        ## Lift = Recall / Freq = Precision / Prevalence  
        lift = prec / prev) %>%
      select(-.f, -.t, -S, -P, -N)
  }

## USE:
## pf <- nmPred %>%
##   group_by(model, segment) %>%
##   ConfusionMatrix(target, pred) %>%
##   PerformanceMeasures()
