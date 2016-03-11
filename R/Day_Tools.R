#############################################################################
## DAY_TOOLS.R
##   Methods for manipulating dates
##
## AUTHOR:	John P. Hilbert
## CREATED:	2011-01-03
## MODIFIED:	2012-02-28
## 
## SUMMARY:
##   Details
##
## OUTPUT:
##   - <NONE>
##
## REQUIRE:
##   PACKAGES / SCRIPTS:
        require(chron)
        require(zoo)
##
##   DATA:
##   - <NONE>
##
## TO DO:
##   - <NONE>
##
#############################################################################


Add.Leap.Year <- function(data, date.var = "date") {
  ## ########################################################################
  ## ADJUST.LEAP.YEAR(DATA)
  ## Adds Feb 29th back in for leap years.  The values will be copies of Feb
  ##  28th.  NOTE: this function does not need to be embedded in DDPLY
  ##
  ## PARAMETERS:
  ##   - DATA
  ##   - DATE.VAR = "date" = date variable
  ##
  ## OUTPUT:
  ##   - data
  ##
  ## ########################################################################

  leap.years <- month.day.year(range(data[, date.var]))$year
  leap.years <- seq(leap.years[1], leap.years[2])

  leap.years <- leap.years[leap.year(leap.years)]

  leap.years <- mdy.Date(2, 28, leap.years)

  leap.years <- leap.years[(leap.years >= min(data[, date.var]) &
                            leap.years <= max(data[, date.var]))]

  leap.years <- subset(data, date %in% leap.years)
  leap.years[, date.var] <- leap.years[, date.var] + 1

  data <- rbind(data, leap.years)
  data <- data[order(data[, date.var]), ]

  return(data)
}

Drop.Leap.Year <- function(data, date.var = "date")
  data[!(month.day.year(data[, date.var])$month == 2 &
         month.day.year(data[, date.var])$day == 29), ] 

Add.Year <- function(date, n) {
  ## ########################################################################
  ## ADD.YEAR(DATE, N)
  ## Adds exactly N years to DATE
  ##
  ## PARAMETERS:
  ##   - date
  ##   - n
  ##
  ## OUTPUT:
  ##   - date
  ##
  ## ########################################################################
  date <- month.day.year(date)
  date <- mdy.Date(date$month, date$day, date$year + n)
  return(date)
}

Add.Month <- function(date, n) {
  ## ########################################################################
  ## ADD.MONTH(DATE, N)
  ## Adds exactly N months to DATE
  ##
  ## PARAMETERS:
  ##   - date
  ##   - n
  ##
  ## OUTPUT:
  ##   - date
  ##
  ## ########################################################################
  date <- month.day.year(date)
  date$month <- date$month + n
  date <- mdy.Date((date$month - 1) %% 12 + 1,
                   date$day,
                   date$year + (date$month - 1) %/% 12)
  return(date)
}

Week <- function(date, relative.date = mdy.Date(1, 1,
                         month.day.year(date)$year),
                 remove.leap.year = TRUE) {
  ## ########################################################################
  ## WEEK(DATE, RELATIVE.DATE, REMOVE.LEAP.YEAR)
  ## Calculates the week of DATE relative to RELATIVE.DATE.  By default,
  ##  RELATIVE.DATE is the first of the year.  Additionally, this function can
  ##  remove leap day to allow the weeks to match year to year.
  ##
  ## PARAMETERS:
  ##   - DATE
  ##   - RELATIVE.DATE = XXXX-01-01 = relative day to calculate weeks from
  ##   - REMOVE.LEAP.YEAR = TRUE = ignore February 29th completely in
  ##    calculations  
  ##
  ## OUTPUT:
  ##   - DATE = week number relative to RELATIVE.DATE.  Note: these are not
  ##    unique by default if DATE spans multiple years.
  ##
  ## ########################################################################
  date <- as.numeric(date - relative.date - 
                     (remove.leap.year &
                      leap.year(month.day.year(date)$year) &
                      date >= mdy.Date(2, 29,
                        month.day.year(date)$year))) %/% 7
  
  return(date)
}

Quarters <- function(date, Q1.start = c(1, 1)) {
  ## ########################################################################
  ## QUARTERS(DATE, Q1.START = C(1, 1))
  ## Converts DATE into quarters of format YYYY-Q#.  By default, Q1 starts on
  ##  January 1st. 
  ##
  ## PARAMETERS:
  ##   - date
  ##   - Q1.start = c(1, 1) = MONTH, DAY of start of Q1 
  ##
  ## OUTPUT:
  ##   - date
  ##
  ## TODO:
  ## Allow passing DATE as Q1.START 
  ## ########################################################################
  if(length(Q1.start) != 2 ||
     !between(Q1.start[1], c(1, 12), exclusive = FALSE) ||
     !between(Q1.start[2], c(1, 30), exclusive = FALSE))
    stop("Q1.Start must be length 2 ",
         "with Q1.start[1] in (1, 12) and Q1.start[2] in (1, 30)")
  
  Q1.start <- Q1.start - c(1, 1)
  date <- Add.Month(date - Q1.start[2], -Q1.start[1])
  
  date <- paste(years(date),
                quarters(date),
                sep = "-")
  
  return(date)
}

Quarters.To.Date <- function(quarters, quarter.delimiter = "-Q",
                             Q1.start = c(1, 1)) {
  ## ########################################################################
  ## QUARTERS.TO.DATE(QUARTERS, QUARTER.DELIMITER = "-Q", Q1.START = C(1, 1))
  ## Converts quarterly vector of format YYYY-Q# into DATE.  The format is
  ##  customizable via QUARTER.DELIMITER to anything of the form YYYY%#.
  ##  By default, Q1 starts on January 1st. 
  ##
  ## PARAMETERS:
  ##   - quarters
  ##   - quarter.delimiter = "-Q"
  ##   - Q1.start = c(1, 1) = MONTH, DAY of start of Q1
  ##
  ## OUTPUT:
  ##   - quarters
  ##
  ## ########################################################################
  if(length(Q1.start) != 2 ||
     !between(Q1.start[1], c(1, 12), exclusive = FALSE) ||
     !between(Q1.start[2], c(1, 30), exclusive = FALSE))
    stop("Q1.Start must be length 2 ",
         "with Q1.start[1] = (1, 12) and Q1.start[2] = (1, 30)")

  quarters <- strsplit(quarters, quarter.delimiter)
  quarters <- sapply(quarters,
                     function(x) {
                       x <- as.numeric(x)          
                       mdy.Date(((x[2]-1) * 3) + Q1.start[1],
                                Q1.start[2],
                                x[1])})
  quarters <- as.Date(quarters)
  
  return(quarters)
}

Day.Of.Week <- function(date, ..., literal = FALSE) {
  ##==========================================================================##
  ## Day.Of.Week:
  ##  Calculates the days of the week.  This encapsulates chron::day.of.week,
  ##  thus has similar functionality.  It also allows Date object to be to be
  ##  passed and supports either numeric or literal return.
  ##
  ## Parameter:
  ##	date:	
  ##		date object
  ##			---- or ----
  ##	month, day, year:
  ##		numeric month, day, and year of date
  ##	literal = FALSE:	
  ##		toggles literal string or numeric return
  ##
  ## Returns:
  ##	Day of week, either literal string (see literal parameter) or numeric.
  ##	(1 = SUNDAY)
  ##==========================================================================##
  if (inherits(date, "Date")){
    x <- month.day.year(date)
    out <- day.of.week(x$month, x$day, x$year)		
  }
  else {
    out <- day.of.week(date, ...)
  }
  
  if (literal) {
    out <- c("Sunday",
             "Monday",
             "Tuesday",
             "Wednesday",
             "Thursday",
             "Friday",
             "Saturday")[out + 1]
  }
  return(out)			
}

#### The following use package: ZOO
First.Of.Month <- function(date) as.Date(as.yearmon(date))
Last.Of.Month <- function(date) as.Date(as.yearmon(date), frac = 1)
Days.In.Month <- function(date) {
  x <- as.yearmon(date)
  return(as.numeric(as.Date(x, frac = 1) - as.Date(x)) + 1)
}

Trade.Days.In.Month <- function(date, day = 1:5, ratio = FALSE) {
  ##==========================================================================##
  ## Trade.Days.Days.In.Month:
  ## 	Counts occurances of particular day in month. By default it counts
  ##	Monday - Friday.
  ##
  ## Parameter:
  ##	date:
  ##		date object(s) specifying month and year
  ##	day = 1:5:
  ##		day(s) to count (0 = Sunday ... 6 = Saturday)
  ##	ratio = FALSE:
  ##		if TRUE returns the percentage of days in month
  ##
  ## Returns:
  ##	number (or ratio) of particular days in month.  If day is a vector, the 
  ##	total sum will be given.  If a date is a vector, a vector will be 
  ##	returned.
  ##==========================================================================##
  sapply(date, function(x){
    total.Days <- Days.In.Month(x)
    extra.Days <- Day.Of.Week(First.Of.Month(x)) +
      (1:(total.Days - 28)) - 1
    extra.Days <- extra.Days %% 7
    extra <- day %in% extra.Days
    if(ratio) 
      return(sum(4 + extra) / total.Days)
    else
      return(sum(4 + extra))
  })
}

mdy.Date <- function(month,day,year){
  ##==========================================================================##
  ## mdy.Date:
  ## 	Converts Month, Day, Year to Date
  ##
  ## Parameter:
  ##	month, day, year:
  ##		scalars or equal length vectors
  ##
  ## Returns:
  ##	Date object specified by parameters
  ##==========================================================================##
  ##	fixedMonth <- month %% 12
  ##	fixedMonth[fixedMonth < 1] <- 12
  ##	fixedYear <- year + ((month - 1) %/% 12)
  ##	dateString <- paste(fixedMonth,day,fixedYear)
  ##	return(as.Date(dateString, "%m %d %Y"))
  return(as.Date(julian(month, day, year)))
}

Nth.Of.Day <- function(year, month, day.of.week, n = 1) {
  ##==========================================================================##
  ## Nth.Of.Day:
  ## 	Returns the date of the Nth dayOfWeek in month / year.
  ##
  ## Parameter:
  ##	year:
  ##		year in question
  ##	month:
  ##		month in question
  ##	day.of.week:
  ##		day of week to find (0 = Sunday)
  ##	n:
  ##		n-th occurance
  ##
  ## Returns:
  ##	Date object specified by parameters
  ##==========================================================================##
  day <- day.of.week - Day.Of.Week(month, 1, year)
  day <- day + (n-(0 <= day))*7 + 1
  return(mdy.Date(month, day, year))
}

Last.Of.Day <- function(year, month, day.of.week) {
  ##==========================================================================##
  ## Last.Of.Day:
  ## 	Returns the date of last dayOfWeek in month / year.
  ##
  ## Parameter:
  ##	year:
  ##		year in question
  ##	month:
  ##		month in question
  ##	day.of.week:
  ##		day of week to find (0 = Sunday)
  ##
  ## Returns:
  ##	Date object specified by parameters
  ##==========================================================================##
  lastDayOfMonth <- Days.In.Month(year + (month - 1)/12)
  day <- Day.Of.Week(month, lastDayOfMonth, year) - day.of.week
  day <- lastDayOfMonth - day - 7 * (day < 0)
  return(mdy.Date(month, day, year))
  
}


###############################################################################
##	Federal Holidays
###############################################################################
holiday.names <- toProper(
                          c(
                            "new years day",
                            "martin luther king day",
                            "presidents day",
                            "memorial day",
                            "independence day",
                            "labor day",
                            "columbus day",
                            "veterans day",
                            "thanksgiving",
                            "christmas eve",
                            "christmas day",
                            "new years eve",
                            "easter",
                            "good friday",
                            "ash wednesday"))

Holiday <- function(year, holiday = holiday.names, with.names = TRUE){
  Holiday.Easter <- function(year){
    ## The algorithm is due to J.-M. Oudin (1940) and is reprinted in the 
    ## 	'Explanatory Supplement to the Astronomical Almanac', ed. P. K. 
    ## 	Seidelmann (1992). See Chapter 12, "Calendars", by L. E. Doggett.
    
    C <- year %/% 100
    N <- year - 19 * (year %/% 19)
    K <- (C - 17) %/% 25
    I <- C - C %/% 4 - (C - K) %/% 3 + 19 * N + 15
    I <- I - 30 * (I %/% 30)
    I <- I - (I %/% 28) * (1 - (I %/% 28) * (29 %/% (I + 1)) * ((21 - N) %/% 11))
    J <- year + year %/% 4 + I + 2 - C + C %/% 4
    J <- J - 7 * (J %/% 7)
    L <- I - J
    month <- 3 + (L + 40) %/% 44
    day <- L + 28 - 31 * (month %/% 4)
    return(mdy.Date(month, day, year))
  }
  
  out <- NULL
  for (x in holiday) {
    out <- c(out,
             switch(tolower(x),
                                        # 1st of January
                    "new years day" = 
                    mdy.Date(1, 1, year), 
                                        # 3rd Monday of January
                    "martin luther king day" = 
                    Nth.Of.Day(year, 1, 1, 3), 
                                        # 3rd Monday of February
                    "presidents day" = 
                    Nth.Of.Day(year, 2, 1, 3), 
                                        # Last Monday of May
                    "memorial day" =
                    Last.Of.Day(year, 5, 1), 
                                        # 4th of July
                    "independence day" =
                    mdy.Date(7, 4,year),
                                        # 1st Monday in September
                    "labor day" = 
                    Nth.Of.Day(year, 9, 1, 1),
                                        # 2nd Monday in October
                    "columbus day" = 
                    Nth.Of.Day(year, 10, 1, 2),
                                        # 11th of November
                    "veterans day" = 
                    mdy.Date(11, 11, year),				
                                        # 4th Thursday of November
                    "thanksgiving" = 
                    Nth.Of.Day(year, 11, 4, 4),
                                        # 24th of December
                    "christmas eve" = 
                    mdy.Date(12, 24, year),
                                        # 25th of December
                    "christmas day" = 
                    mdy.Date(12, 25, year),
                                        # 31st of December
                    "new years eve" = 
                    mdy.Date(12, 31, year),
                                        # Magic
                    "easter" = 
                    Holiday.Easter(year),
                                        # 2 days prior to Easter
                    "good friday" = 
                    Holiday.Easter(year) - 2,			
                                        # 40 days prior to Easter
                    "ash wednesday"	= 
                    Holiday.Easter(year) - 39,
                                        # Dummy
                    NULL
                    )
             )
  }
  if(!is.null(out)) {
    if(with.names)
      return(data.frame(name = rep(toProper(holiday),
                          rep(length(year), length(holiday))),
                        date = as.Date(out)))
    else
      return(as.Date(out))
  }
}

Holidays.Per.Month <- function(year, holiday = holiday.names, 
                               vacation = c("christmas", "thanksgiving"), weekday.only = FALSE,
                               ratio = FALSE) {
  ##==========================================================================##
  ## Holidays.Per.Month:
  ## 	Counts Holidays per month
  ##
  ## Parameter:
  ##	year, weekday.only = FALSE:	year(s) to count
  ##
  ## Returns:
  ##	array of month and holidays
  ##==========================================================================##
  
  h <- c(Holiday(year, holiday), Vacation(year, vacation))
  
#### removes weekends if requested
  if (weekday.only) h <- h[!is.weekend(h)]
  
#### counts
  out <- as.data.frame(table(First.Of.Month(h)))
  names(out) <- c("date", "holidays")
  
  out$date <- as.Date(out$date)
  
#### divide out days in month if requested 
  if (ratio) out <- transform(out, holidays = holidays / Days.In.Month(date))
  return(out)
}

Vacation <- function(year, holiday = c("christmas", "thanksgiving"),
                     with.names = TRUE){
  out <- NULL
  for (x in holiday) {
    out <- c(out,
             switch(tolower(x),
                    ## 1st of January
                    "christmas" = 
                    Holiday(year, "christmas day",
                            with.names = FALSE) + rep(1:5, length(year)),
                    ## 3rd Monday of January
                    "thanksgiving" = 
                    Holiday(year, "thanksgiving",
                            with.names = FALSE) + 1,
                    ## Dummy
                    NULL
                    )
             )
  }
  ## if(is.null(out))
  ##   return(NULL)
  ## else
  if(!is.null(out)) {
    if(with.names)
      return(data.frame(name = "Vacation",
                        date = as.Date(out)))
    else
      return(as.Date(out))
  }
}

Monthly.Indicators <- function(date, formula = months, ...) {
  ##==========================================================================##
  ## Monthly.Indicators:
  ## 	Creates a data.frame of length(date) x 12 of indicators
  ##
  ## Parameter:
  ##	date:		date list to use
  ##	formula:	either months or quarters
  ##	...:		additional parameters to pass to formula
  ##
  ## Returns:
  ##	month indicators
  ##==========================================================================##
  x <- data.frame(date, v = formula(date, ...), indicator = 1)
  return(cast(x, formula = date~v, fill = 0))	
}


