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
AUC_ROC_wilcox <- function(labels, scores) {
  1-wilcox.test(scores ~ labels)$statistic / sum(labels) / sum(!labels)
}

AUC_ROC_prob <- function(labels, scores, N=1e6) {
  pos <- sample(scores[labels], N, replace=TRUE)
  neg <- sample(scores[!labels], N, replace=TRUE)
  (sum(pos > neg) + sum(pos == neg)/2) / N # give partial credit for ties
}

## USE:
## nmPred %>%
##   group_by(model, segment) %>%
##   summarize(auc = AUC_ROC_prob(target == 1, pred, N = 1e6)) %>%
##   arrange(segment, model)

## These are modification of code from PRROC package
AUC_ROC_integral <- function(sensitivity, specificity) {
  if (sensitivity[1] > sensitivity[length(sensitivity)]) {
    sensitivity <- rev(sensitivity)
    specificity <- rev(specificity)
  }
  specificity <- c(1, specificity) - c(specificity, 0)
  sensitivity <- (c(sensitivity, 1) + c(0, sensitivity))/2
  sum(specificity * sensitivity)
}

AUC_PR_integral <- function(tp, fp) {
  if (tp[1] > tp[length(tp)]) {
    tp <- rev(tp)
    fp <- rev(fp)
  }
  total_t <- max(tp)
  tp0 <- lag(tp, default = 0)
  fp0 <- lag(fp, default = 0)

  h <- (fp - fp0) / (tp - tp0)
  a <- 1 + h
  b <- (fp0 - h * tp0) / total_t
  h[tp == tp0] <- 1
  a[tp == tp0] <- 1
  b[tp == tp0] <- 0
  
  v <- ((tp-tp0)/total_t - b/a *
          (log(a * tp/total_t + b) - log(a * tp0/total_t + b) )) / a
  v2 <- (tp - tp0) / total_t / a
  v[b == 0] <- v2[b == 0]
  sum(v)
}

## Davis and Goadrich
AUC_PR_dg <- function(tp, fp) {
  if (tp[1] > tp[length(tp)]) {
    tp <- rev(tp)
    fp <- rev(fp)
  }

  total_t <- max(tp)
  
  data <-
    data.frame(tp = tp[-1], fp = fp[-1]) %>%
    mutate(
      tp0 = lag(tp, default = 0),
      fp0 = lag(fp, default = 0),
      idx = tp - tp0 > 1 & tp/(tp + fp) != tp0/(tp0 + fp0),
      idx = !is.na(idx) & idx) %>%
    select(tp0, tp, fp0, fp, idx)

  auc.dg <- data %>%
    mutate(
      auc.dg = (tp - tp0) / total_t *
        (tp0 / (tp0 + fp0) + tp / (tp + fp)) / 2,
      is.nan = is.nan(auc.dg),
      auc.dg = ifelse(is.nan(auc.dg),
      (tp - tp0) / total_t * (tp/(tp + fp)),
      auc.dg),
      is.nan = is.nan(auc.dg)) %>%
    filter(!idx) %>%
    pull(auc.dg)
  auc.dg <- sum(auc.dg)

  ## Add correction if needed
  data <- data %>%
    filter(idx) %>%
    mutate(r = row_number())    
  if (nrow(data) > 0) {
    data <- data %>%
      crossing(gap = seq(0, max(data$tp-data$tp0))) %>%
      filter(gap <= tp-tp0) %>%
      mutate(h2 = (fp-fp0)/(tp-tp0),
             correction = (tp0 + gap) / (tp0 + gap + fp0 + h2 * gap)) %>%
      group_by(r) %>%
      summarize(correction = sum((correction + lag(correction)) /
                                   2 / total_t, na.rm = T)) %>%
      pull(correction)

    auc.dg <- auc.dg + sum(data)
  }

  return(auc.dg)
}

## USE:
## nmPred %>%
##   group_by(model, segment) %>%
##   ConfusionMatrix(target, pred) %>%
##   PerformanceMeasures() %>%
##   summarize(aucroc = AUC_ROC_integral(sens, spec),
##             aucpr = AUC_PR_integral(tp, fp),
##             aucprdg = AUC_PR_dg(tp, fp)) 



###############################################################################
## Performance Measures At All Thresholds
###############################################################################
ConfusionMatrix <- function(data, target, prediction, add_lower_bound = T) {
  target <- enquo(target)
  prediction <- enquo(prediction)
  groups <- group_vars(data)
  data <- data %>%
    mutate(t = !! target == 1) %>%
    group_by(t, prediction = !! prediction, add = T) %>%
    count %>%
    spread(t, n, fill = 0) %>%
    rename('false' = 'FALSE', 'true' = 'TRUE') %>%
    group_by_at(groups)

  ## Since the first record has non-zero TRUE/FALSE (i.e. not the true lower
  ## bounds) this block adds that row which is needed for correct AUC
  ## calculations 
  if(add_lower_bound) {
    data <- data %>%
      do(bind_rows(mutate(.,
                          prediction = prediction -
                            diff(range(prediction))*1E-3,
                          false = 0, true = 0) %>% head(1),
                   .))
  }

  data
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


###############################################################################
## Plots
###############################################################################
Plot_ROC <- function(data,
                     sensitivity = !!sym("sens"),
                     specificity = !!sym("spec")) {
  sensitivity <- enquo(sensitivity)
  specificity <- enquo(specificity)
  if(length(group_vars(data)) < 1)
    plot <- data %>%
      ggplot(aes(y = !!sensitivity, x = 1-!!specificity)) 
  else
    plot <- data %>%
      unite('grp', group_vars(data), sep = ' - ') %>%
      ggplot(aes(y = !!sensitivity, x = 1-!!specificity, color = grp)) +
      scale_color_hue(group_vars(data) %>% str_c(collapse = ' - '))

  plot +
    geom_line() +
    geom_abline(linetype = 2) +
    scale_x_continuous("1-Specificity", limits = c(0, 1), label = percent) +
    scale_y_continuous("Sensitivity", limits = c(0, 1), label = percent) +
    coord_equal() +
    theme_bw()
}


Plot_Lift <- function(data,
                     lift = !!sym("lift"),
                     freq = !!sym("p_predicted")) {
  lift <- enquo(lift)
  freq <- enquo(freq)
  if(length(group_vars(data)) < 1)
    plot <- data %>%
      ggplot(aes(y = !!lift, x = !!freq)) 
  else
    plot <- data %>%
      unite('grp', group_vars(data), sep = ' - ') %>%
      ggplot(aes(y = !!lift, x = !!freq, color = grp)) +
      scale_color_hue(group_vars(data) %>% str_c(collapse = ' - '))

  plot +
    geom_line() +
    geom_hline(yintercept = 1, size = 1) +
    scale_x_continuous("Percent Predicted",
                       limits = c(0, NA), label = percent) +
    scale_y_continuous("Lift", limits = c(1, NA)) +
    theme_bw()
}
