#############################################################################
## TS_TOOLS.R
##   Methods for Time Series manipulation
##
## AUTHOR:	John P. Hilbert
## CREATED:	2012-02-28
## MODIFIED:    2012-09-04
## 
## SUMMARY:
##   Details
##
## REVISIONS:
##   1) Added new functions:
##              Split.Weeks.To.Day
##              Combine.Months
##              Combine.Weeks.By.Year [Updated version on Aggregate.Weeks...]
##              Correct.Weekends
##              Calculate.Weekday.Ratio
##
## INPUT:
##   PACKAGES / SCRIPTS:
require(TTR)
src("Day_Tools.r", common.dir, silent = TRUE)
##
##   DATA:
##   - <NONE>
##
## TO DO:
##   - Add method documentation / examples
##
#############################################################################
TS.Lag <- function(data, n, by = c("day", "month", "year"),
                   date.var = "date", omit.var = NULL) {
  ## ########################################################################
  ## TS.LAG(DATA, N, BY = C("DAY", "MONTH", "YEAR"),
  ##            DATE.VAR = "DATE", OMIT.VAR = NULL) 
  ## Lags a Time Series (a data frame with a 'date' column in this regard) N
  ##  periods of intervals set BY which may be one of 'day', 'month', or 'year'.
  ##
  ## PARAMETERS:
  ##   - data
  ##   - n
  ##   - by = c("day", "month", "year")
  ##   - date.var = "date"
  ##   - omit.var = NULL
  ##
  ## OUTPUT:
  ##   - data
  ##
  ## ########################################################################
  by <- match.arg(tolower(by), c("day", "month", "year"))
  
  other.var <- names(data)
  other.var <- !(other.var %in% c(date.var, omit.var))
  
  out <- data
  for(m in n) {
    data.lag <- data
    data.lag[, date.var] <- 
      switch(by,
             day = data.lag[, date.var] + m,
             month = Add.Month(data.lag[, date.var], m),
             year = Add.Year(data.lag[, date.var], m)) 

    names(data.lag)[other.var] <- paste("lag", m, names(data.lag)[other.var],
                                        sep = ".")
    
    out <- merge(out, data.lag, all = TRUE)
  }
  if(length(n) == 1)
    names(out) <- gsub(".1", "", names(out))

  return(out)
}

## ##########################################################################
## Filling Methods
## ##########################################################################
Add.Missing.Days <- function(data, date.var = "date", constant.var = NULL) {
  ## ########################################################################
  ## ADD.MISSING.DAYS(DATA, DATE.VAR)
  ## Add any missing days into DATA
  ##
  ## PARAMETERS:
  ##   - DATA = data.frame to be used
  ##   - DATE.VAR = name of date variable (default "date")
  ##   - CONSTANT.VAR = NULL = variables that are constant, and hence will fill
  ##    in automatically. Useful if this function is embedded in a **ply
  ##    function. 
  ##
  ## OUTPUT:
  ##   - DATA
  ##
  ## ########################################################################
  all.dates <- data.frame(x = seq(min(data[, date.var]),
                            max(data[, date.var]),
                            by = "day"))
  names(all.dates)[1] <- date.var

  data <- merge(data, all.dates, all = TRUE)

  for(i in constant.var)
    data[, i] <- data[1, i]

  return(data)
}

Fill.Loess <- function(data, date.var = "date",
                       omit.var = NULL, n.span = 30) {
  ## ########################################################################
  ## FILL.LOESS(DATA, DATE.VAR, OMIT.VAR, N.SPAN)
  ## Fill in missing days using a loess curve
  ##
  ## PARAMETERS:
  ##   - DATA = data.frame to be used
  ##   - DATE.VAR = name of date variable (default "date")
  ##   - OMIT.VAR = columns to omit from filling (assumes they are constant)
  ##   - N.SPAN = approximate number of lead / lags to use in Loess algorithm
  ##
  ## OUTPUT:
  ##   - DATA
  ##
  ## ########################################################################

  v <- names(data)[!(names(data) %in% c(omit.var, date.var))]
  predict.dates <- seq(min(data[, date.var]), max(data[, date.var]),
                       by = "day")
  predict.dates <- predict.dates[!(predict.dates %in% data[, date.var])]

  ## data <- transform(data, f = FALSE)

  data <- merge(data, data.frame(date = predict.dates), all = TRUE)

  for(i in v) {
    this.fit <- loess(as.formula(i %+% "~ as.numeric(" %+% date.var %+% ")"),
                      data,
                      span = n.span / nrow(data),
                      degree = 2)

    data[data$date %in% predict.dates, i] <-
      predict(this.fit, as.numeric(predict.dates))
  }

  data[,omit.var] <- data[1, omit.var]

  return(data)
}

Fill.SMA <- function(data, date.var = "date", omit.var = NULL, n.span = 30,
                     na.fill.function = Fill.Linear) {
  ## ########################################################################
  ## FILL.SMA(DATA, DATE.VAR = "DATE", OMIT.VAR = NULL, N.SPAN = 30)
  ## Fill in missing day using a SMA.
  ##
  ## PARAMETERS:
  ##   - data
  ##   - date.var = "date"
  ##   - omit.var = NULL
  ##   - n.span = 30
  ##   - na.fill.function = Fill.Linear = function to fill NA's with
  ##
  ## OUTPUT:
  ##   - data
  ##
  ## ########################################################################
  v <- names(data)[!(names(data) %in% c(omit.var, date.var))]

  predict.dates <- seq(min(data[, date.var]), max(data[, date.var]),
                       by = "day")
  predict.dates <- !(predict.dates %in% data[, date.var])

  data <- na.fill.function(data, date.var, omit.var)

  for(i in v) {   
    data[, i] <- ifelse(predict.dates,
                        SMA(data[, i], n.span),
                        data[, i])
  }

  data[,omit.var] <- data[1, omit.var]

  return(data)
}

Fill.Last <- function(data, date.var = "date", omit.var = NULL) {
  ## ########################################################################
  ## FILL.LAST(DATA, DATE.VAR = "DATE", OMIT.VAR = NULL)
  ## Fill in missing days using last non-NA.  This function will buffer the head
  ##  and tail of the series (unlike other functions)
  ##
  ## PARAMETERS:
  ##   - data
  ##   - date.var = "date"
  ##   - omit.var = NULL
  ##
  ## OUTPUT:
  ##   - data
  ##
  ## ########################################################################
  v <- names(data)[!(names(data) %in% c(omit.var, date.var))]

  data <- data[order(data[, date.var]), ]

  for(i in v) {
    org.data <- na.omit(data[, c(date.var, i)])
    f <- approxfun(org.data[, date.var], org.data[, i], method="const",
                   yleft = head(org.data[, i], 1),
                   yright = tail(org.data[, i], 1))
    data[, i] <- f(data[, date.var])
  }

  return(data)
}

Fill.Linear <- function(data, date.var = "date", omit.var = NULL) {
  ## ########################################################################
  ## FILL.LINEAR(DATA, DATE.VAR = "DATE", OMIT.VAR = NULL)
  ## Fill in missing days using a linear approximation of non-NA
  ##
  ## PARAMETERS:
  ##   - data
  ##   - date.var = "date"
  ##   - omit.var = NULL
  ##
  ## OUTPUT:
  ##   - data
  ##
  ## ########################################################################
  v <- names(data)[!(names(data) %in% c(omit.var, date.var))]

  for(i in v) {
    org.data <- na.omit(data[, c(date.var, i)])
    f <- approxfun(org.data[, date.var], org.data[, i])
    data[, i] <- f(data[, date.var])
  }

  return(data)
}

## ##########################################################################
## Split / Combine Methods
## ##########################################################################

## !!! OUTDATED !!!
Aggregate.Weeks.By.Year <- function(data, 
                                    date.var = "date",
                                    other.aggregate.var = NULL) {
  ## ########################################################################
  ## AGGREGATE.WEEKS.BY.YEAR(DATA, START.OF.YEAR = "2001-01-01",
  ##            DATE.VAR = "DATE", OTHER.AGGREGATE.VAR = NULL)  
  ## Aggregates DATA into weeks starting from month / day given by START.OF.YEAR
  ##  for each year in DATA.  The aggregation is done by summing each variable,
  ##  however an added variable (DATA.POINTS) is given to facilitate
  ##  transforming to a mean.  Aggregation can be further split by
  ##  OTHER.AGGREGATE.VAR, if needed. 
  ##
  ## PARAMETERS:
  ##   - data
  ##   - start.of.year = "2001-01-01"
  ##   - date.var = "date"
  ##   - other.aggregate.var = NULL
  ##
  ## OUTPUT:
  ##   - data
  ##
  ## ########################################################################
  data$data.points <- 1
  valid.names <- setdiff(union(names(data), "data.points"),
                         union(date.var, other.aggregate.var))
  
  data$year <- month.day.year(data[, date.var])$year
  data$week <- Week(data[, date.var])

  data <- ddply(data,
                union(other.aggregate.var, c("year", "week")),
                function(x) data.frame(XXXdate = min(x[, date.var]),
                                       colwise(sum, valid.names)(x)))
  
  names(data) <- gsub("XXXdate", date.var, names(data))
  
  data <- data[, c(date.var, other.aggregate.var, valid.names)]

  return(data)
}

Split.Weeks.To.Days <- function(data,
                                date.var = "date",
                                other.aggregate.var = NULL,
                                buffer.week = 7) {
  valid.names <- setdiff(names(data),
                         union(date.var, other.aggregate.var))

  subfunction <- function(x) {
    date.range <- range(x$date)

    x[, valid.names] <- x[, valid.names] / 7

    x <- transform(x, date = date + 3)    # Center the data in the week
    x <- Add.Missing.Days(x, constant.var = "fss")
    ## buffer the week
    if(buffer.week > 0){
      x <- rbind(transform(subset(x, date < min(date) + buffer.week),
                           date = date - buffer.week),
                 x,
                 transform(subset(x, date > max(date) - buffer.week),
                           date = date + buffer.week))
      date.range <- date.range + c(-1, 1) * buffer.week
    }
    x <- Fill.Linear(x, date.var, omit.var = other.aggregate.var)

    x <- subset(x, date >= date.range[1] & date <= date.range[2])
    return(x)
  }

  if(is.null(other.aggregate.var))
    data <- subfunction(data)
  else
    data <- ddply(data, other.aggregate.var, subfunction)
  return(data)
}

Combine.Months <- function(data,
                           date.var = "date",
                           other.aggregate.var = NULL,
                           remove.incomplete = TRUE) {
  data$data.points <- 1
  valid.names <- setdiff(names(data),
                         union(date.var, other.aggregate.var))

  data[, date.var] <- Last.Of.Month(data[, date.var])

  data <- ddply(data,
                union(other.aggregate.var, date.var),
                function(x) colwise(sum, valid.names)(x))

  data <- data[, c(date.var, other.aggregate.var, valid.names)]

  if(remove.incomplete){
    data <- subset(data, data.points == Days.In.Month(date))
    data$data.points <- NULL
  }

  return(data) 
}

Combine.Weeks.By.Year <- function(data, 
                                  date.var = "date",
                                  other.aggregate.var = NULL,
                                  remove.incomplete = TRUE,
                                  ...) {
  data$data.points <- 1
  valid.names <- setdiff(union(names(data), "data.points"),
                         union(date.var, other.aggregate.var))

  data$year <- month.day.year(data[, date.var])$year
  data$week <- Week(data[, date.var], ...)

  data <- ddply(data,
                union(other.aggregate.var, c("year", "week")),
                function(x) data.frame(XXXdate = min(x[, date.var]),
                                       colwise(sum, valid.names)(x)))
  
  names(data) <- gsub("XXXdate", date.var, names(data))

  data <- data[, c(date.var, other.aggregate.var, valid.names)]

  if(remove.incomplete){
    data <- subset(data, data.points == 7)
    data$data.points <- NULL
  }

  return(data)
}

## ##########################################################################
## Weekend Corrections
## ##########################################################################
Correct.Weekends <- function(x, weekday.correction,
                             date.var = "date",
                             ignore.var = NULL) {
  if(class(weekday.correction) == "data.frame") {
    agg.var <- names(weekday.correction)[1]
    x <- ddply(x, agg.var, function(z) {
      Correct.Weekends(z,
                       weekday.correction[weekday.correction[ ,agg.var] == 
                                          z[1, agg.var], 2],
                       date.var,
                       union(ignore.var, agg.var))
    })
  }
  else {
    valid.names <- setdiff(names(x),
                           union(date.var, ignore.var))
    x[!is.weekend(x[, date.var]), valid.names] <-
      x[!is.weekend(x[, date.var]), valid.names] * weekday.correction

    weekday.correction <- (7 - 5 * weekday.correction) / 2

    x[is.weekend(x[, date.var]), valid.names] <-
      x[is.weekend(x[, date.var]), valid.names] * weekday.correction
  }
  x
}

Calculate.Weekday.Ratio <- function(x, var, date.var = "date",
                                    other.aggregate.var = NULL, ...) {
  if(is.null(other.aggregate.var)){
    out <- mean(x[!is.weekend(x[, date.var]), var], ...) /
      mean(x[, var], na.rm = TRUE)
  }
  else {
    out <- ddply(x, other.aggregate.var,
                 Calculate.Weekday.Ratio, var, date.var, ...)
    names(out)[2] <- var
  }
  out
}
