#############################################################################
## MISC.R
##   Simple description
##
## AUTHOR:	John P. Hilbert
## CREATED:	2011-??-??
## MODIFIED:	2012-09-10
## 
## SUMMARY:
##   Miscellaneous utility and common functions. 
##
## VERSIONS:
##   1) Added SILENT to SRC function.
## 
## REQUIRE:
##   - *nil*
##
## TO DO:
##   - Tasks
##
#############################################################################

## ##########################################################################
## Utility Function 
## ##########################################################################
src <- function(file, directory = NULL, verbose.level = 0,
                silent = FALSE, ...) {
  ## ########################################################################
  ## SRC(FILE, DIRECTORY = NULL, ...)
  ## Like SOURCE, however does a diff on object prior and post, and prints info
  ## on them. Added new functionality: src(FILE, DIRECTORY) which is equivalent
  ## to src(file.path(DIRECTORY, FILE)).
  ##
  ## Added automatic searching of ./methods/ directory.
  ##
  ## PARAMETERS:
  ##   - file
  ##   - directory = NULL       - if NULL search in current working or in
  ##                                    /methods 
  ##   - silent = FALSE         - if TRUE, no verbose
  ##   - ... - additional options to pass to SOURCE
  ##
  ## OUTPUT:
  ##   - NULL
  ##
    ## ########################################################################
  current.objects <- ls(".GlobalEnv")

  cat(paste("Loading script:", toupper(file), "\n"))
  
  if(is.null(directory)) {
    if(file.exists(file)) {
      source(file, ...)
    }
    else {
      if(file.exists(file.path("methods", file)))
        source(file.path("methods", file), ...)
      else
        stop("File " %+% file %+% " does not exist")
    }
  }
  else {
    if(file.exists(file.path(directory, file)))
      source(file.path(directory, file), ...)
    else
      stop("File " %+% file.path(directory, file) %+% " does not exist")
  }
  
  if(!silent) {
    new.objects <- ls(envir = as.environment('.GlobalEnv'))
    new.objects <- new.objects[!(new.objects %in% current.objects)]
    if(length(grep("\\+", new.objects)) != 0)
      new.objects <- new.objects[-grep("\\+", new.objects)]
    ## This is needed since *someone* created a stupid function using a special
    ##  symbol 
    
    out <- adply(new.objects, 1, object.summaries, objects.only = FALSE)
    out <- out[, -1]
    if(nrow(out) > 0) {
      cat("\n")
      print(out)
      cat("\n")
    }
  }
}

object.sizes <- function(units = "Mb", threshold = units) {
  ## ########################################################################
  ## OBJECT.SIZES(UNITS = "MB", THRESHOLD = UNITS)
  ## Lists the objects and their sizes in the environment.
  ##
  ## PARAMETERS:
  ##   - units = "Mb"
  ##   - threshold = units
  ##
  ## OUTPUT:
  ##   - out
  ##
  ## ########################################################################
  string.to.units <- function(s) {
    switch(tolower(substr(s, 1, 1)),
           k = 1024,
           m = 1024 ^ 2,
           g = 1024 ^ 3,
           1)
  }
  
  out <-
    melt(sapply(ls('.GlobalEnv', pattern = "[A-Za-z]"),
                function(x) object.size(eval(parse(text = x)))))
  out$variables <- rownames(out)
  out <- out[order(out$value, decreasing = TRUE), ]
  out <- out[out$value >= string.to.units(threshold), c(2,1)]
  out$value <- round(out$value / string.to.units(units), 1)
  rownames(out) <- seq_along(rownames(out))
  names(out) <- c("Variable", units)
  
  return(out)
}

object.summaries <- function(pattern = NULL, objects.only = TRUE) {
  ## ########################################################################
  ## OBJECT.SUMMARIES(PATTERN = NULL)
  ## Lists Object Summaries (Class, Row, Column, Size) that match pattern.
  ##
  ## PARAMETERS:
  ##   - pattern = NULL
  ##   - objects.only = TRUE - if FALSE, filter out functions
  ##
  ## OUTPUT:
  ##   - out
  ##
  ## ########################################################################
  if(is.null(pattern))
    p <- "[A-Za-z]"
  else
    p <- "^" %+% pattern %+% "$"
  
  out <- adply(ls('.GlobalEnv', pattern = p), 1, function(x)
               data.frame(Variable = x,
                          Class = class(eval.p(x)),
                          Rows = ifelse(class(eval.p(x)) == "data.frame" |
                            class(eval.p(x)) == "matrix",
                            nrow(eval.p(x)),
                            length(eval.p(x))),
                          Columns = ifelse(class(eval.p(x)) == "data.frame" |
                            class(eval.p(x)) == "matrix",
                            ncol(eval.p(x)), 1)))
  out$X1 <- NULL
  out <- merge(out, object.sizes("Mb", "b"), all.x=TRUE)

  if(objects.only)
    out <- subset(out, Class != "function")
  else
    out[out$Class == "function", c("Rows", "Columns")] <- NA
  
  out[order(out$Class), ]
  
  return(out)
}

function.summaries <- function(pattern = NULL) {
  ## ########################################################################
  ## FUNCTION.SUMMARIES(PATTERN = NULL)
  ## Lists Function Summaries (Class, Row, Column, Size) that match pattern.
  ##
  ## PARAMETERS:
  ##   - pattern = NULL
  ##
  ## OUTPUT:
  ##   - out
  ##
  ## ########################################################################  
  out <- subset(object.summaries(pattern, objects.only=FALSE),
                Class == "function")
  
  return(out$Variable)
}

eval.p <- function(a.string.to.evaluate) {
  ## ########################################################################
  ## EVAL.P(X)
  ## Parse and evaluates string x.
  ##
  ## PARAMETERS:
  ##   - x
  ##
  ## OUTPUT:
  ##   - eval(parse(text = x))
  ## 
  ## NOTE: the variable name must be something a user would never use. DO NOT
  ##  CHANGE 
  ##
  ## EXAMPLES:
  ##      x <- 5
  ##      eval.p("x")
  ##      [1] 5
  ## 
  ## ########################################################################
  return(eval(parse(text = a.string.to.evaluate)))
}

## ##########################################################################
## Misc Data Functions
## ##########################################################################
## Adds strings together
"%+%" <- function(a,b) paste(a,b,sep="")

between <- function(x, range, exclusive = FALSE) {
  ## ########################################################################
  ## BETWEEN(X, RANGE, EXCLUSIVE = FALSE)
  ## Evaluates x >= a & x <= b.  If EXCLUSIVE == TRUE, evaluates x > a & x < b
  ##
  ## PARAMETERS:
  ##   - x - numeric (length = 1)
  ##   - range - numeric (length = 2)
  ##   - exclusive = FALSE 
  ##
  ## OUTPUT:
  ##   - out
  ## 
  ## EXAMPLE:
  ##     between(1.5, c(1, 2))
  ##      [1] TRUE
  ##     between(1, c(1, 2))
  ##      [1] TRUE
  ##     between(1, c(1, 2), TRUE)
  ##      [1] FALSE
  ## 
  ## ########################################################################
  if(exclusive)
    return(x > min(range) & x < max(range))
  else
    return(x >= min(range) & x <= max(range))
  
  return(NULL)
}

toProper <- function(string, old.sep = " ", new.sep = " ") {
  ## ########################################################################
  ## TOPROPER(STRING, OLD.SEP = " ", NEW.SEP = " ")
  ## Capitalizes first letter of each word in a string.  Optional NEW.SEP and
  ##  OLD.SEP allow overriding and replacement of the word separator.
  ##
  ## PARAMETERS:
  ##   - string - string to parse
  ##   - old.sep = " " - old word separator (replace from) 
  ##   - new.sep = " " - new word separator (replace to)
  ##
  ## OUTPUT:
  ##   - string
  ##
  ## EXAMPLE:
  ##   toProper("jack.and.jill", ".", "-")
  ##   [1] "Jack-And-Jill"
  ## ########################################################################
  
  ## Unwrap list or vector of strings
  sapply(tolower(string), function(x){
    ## Split string into words (by old seperator)
    v <- unlist(strsplit(x, split = old.sep, fixed = TRUE))
    u <- sapply(v, function(x){
      substring(x, 1, 1) <- toupper(substring(x, 1, 1))
      return(x)
    }, USE.NAMES = FALSE)
    ## paste the string back together (by new seperator)
    return(paste(u, collapse = new.sep))
  }, USE.NAMES = FALSE)
}

drop.names <- function(data, ...) {
    ## ########################################################################
    ## DROP.NAMES(PARAMETERS)
    ## Drops variables from data.frame DF.  (...) can be a multiple strings or a
    ## vector of strings. 
    ##
    ## PARAMETERS:
    ##   - data - a data.frame
    ##   - ... - list of column names to drop
    ##
    ## OUTPUT:
    ##   - data
    ## 
    ## EXAMPLE:
    ##      temp <- data.frame(w = 0, x = 1, y = 2, z = 3)
    ##      temp
    ##      ## w x y z
    ##      ## 0 1 2 3
    ##      drop.names(temp, "x", "y")
    ##      ## w z
    ##      ## 0 3
    ##
    ## ########################################################################
    data[, names(data)[!names(data) %in% c(...)]]
}

Trim.Head <-
    function(x, off = 1) if(off != 0) tail(x, -off) else x

Trim.Tail <-
    function(x, off = 1) if(off != 0) head(x, -off) else x

Shift.Down <- function(x, offset = 1, fill = NA, ignore.var = NULL) {
    ## ########################################################################
    ## SHIFT.DOWN(X, OFFSET = 1, FILL = NA, IGNORE.VAR = NULL)
    ## Shifts a data.frame (array) down (right)
    ##
    ## PARAMETERS:
    ##   - x - data.frame or array to shift.
    ##   - offset = 1 - number of elements to shift by
    ##   - fill = NA - back fill value
    ##   - ignore.var = NULL - columns to ignore in shifting
    ##
    ## OUTPUT:
    ##   - x
    ##
    ## ########################################################################
    if(class(x) == "data.frame") {
        if(!is.null(ignore.var)) {
            x[, setdiff(names(x), ignore.var)] <-
                Shift.Down(x[, setdiff(names(x), ignore.var)], offset, fill)
        }
        else {
            x <- rbind(matrix(fill, offset, length(x),
                              dimnames = list(NULL, names(x))),
                       Trim.Tail(x, offset))
        }
    }
    else {
        x <- c(rep(fill, offset), Trim.Tail(x, offset))
    }

    return(x)
}

Shift.Up <- function(x, offset = 1, fill = NA, ignore.var = NULL) {
    ## ########################################################################
    ## SHIFT.UP(X, OFFSET = 1, FILL = NA, IGNORE.VAR = NULL)
    ## Shifts a data.frame (array) up (left)
    ##
    ## PARAMETERS:
    ##   - x - data.frame or array to shift.
    ##   - offset = 1 - number of elements to shift by
    ##   - fill = NA - back fill value
    ##   - ignore.var = NULL - columns to ignore in shifting
    ##
    ## OUTPUT:
    ##   - x
    ##
    ## ########################################################################
    if(class(x) == "data.frame") {
        if(!is.null(ignore.var)) {
            x[, setdiff(names(x), ignore.var)] <-
                Shift.Up(x[, setdiff(names(x), ignore.var)], offset, fill)
        }
        else {
            x <- rbind(Trim.Head(x, offset),
                       matrix(fill, offset, length(x),
                              dimnames = list(NULL, names(x))))
        }
    }
    else {
        x <- c(Trim.Head(x, offset), rep(fill, offset))
    }

    return(x)
}

Subset.Split <- function(data, logic) {
    ## ########################################################################
    ## SUBSET.SPLIT(DATA, LOGIC)
    ## Splits DATA into two subsets named TRUE and FALSE based on LOGIC
    ##
    ## PARAMETERS:
    ##   - data
    ##   - logical
    ##
    ## OUTPUT:
    ##   - list(true, false)
    ##
    ## ########################################################################
    list(true = data[logic, ], false = data[!logic, ])
}


Word.Wrap <- function(x,len) {
    sapply(x, function(x) 
           paste(strwrap(x, width=len), collapse="\n"), USE.NAMES = FALSE)
}

iif <- function (...) {
    ## ##########################################################
    ## Multi - If Else Function
    ##
    ## Repeatedly applies if-else to multiple tests
    ## iifelse(t1, y1, ...) =
    ##    ifelse(t1, y1, ifelse(t2, y2, ifelse(...)))
    ## 
    ## ##########################################################
    args <- list(...)
    nArgs <- length(args)
    if(nArgs %% 2 != 1 | nArgs < 3) {
        warning("\nInvalid number of Arguments
Must be at an odd number and at least 3")
        return(NULL)
    }
    
    no <- args[[nArgs]]
    for(i in seq(nArgs-2, 1, by = -2)) {
        test <- args[[i]]
        yes <- args[[i+1]]
        if (is.atomic(test)) {
            if (typeof(test) != "logical") 
                storage.mode(test) <- "logical"
            if (length(test) == 1 && is.null(attributes(test))) {
                if (is.na(test)) 
                    return(NA)
                else if (test) {
                    if (length(yes) == 1 && is.null(attributes(yes))) 
                        return(yes)
                }
                     else if (length(no) == 1 && is.null(attributes(no))) 
                              return(no)
            }
        }
        else test <- if (isS4(test)) 
                         as(test, "logical")
                     else as.logical(test)
        ans <- test
        ok <- !(nas <- is.na(test))
        if (any(test[ok])) 
            ans[test & ok] <-
                rep(yes, length.out = length(ans))[test & ok]
        if (any(!test[ok])) 
            ans[!test & ok] <-
                rep(no, length.out = length(ans))[!test & ok]
        ans[nas] <- NA
        no <- ans
    }
    ans
}
