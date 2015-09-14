###############################################################################
##  File: init.R
##  Date: NA
##  Author: John P. Hilbert
## 
##  Comments:
## 	Run by Rprofile.site on startup
##
###############################################################################

## .libPaths("~/.R/packages")
options(repos =c(CASE = "http://cran.case.edu/",
            CMU = "http://lib.stat.cmu.edu/R/CRAN/"),
        stringsAsFactors = FALSE)

.Prompt <- "R> "
options(prompt = .Prompt)

## Load common packages here
## require(RODBC, warn.conflicts = FALSE)
require(RPostgreSQL, warn.conflicts = FALSE)
require(plyr, warn.conflicts = FALSE)
require(reshape2, warn.conflicts = FALSE)
require(ggplot2, warn.conflicts = FALSE)
require(dplyr, warn.conflicts = FALSE)

## Common directories
dir.common <- "~/common/r"


## List the directories
cat("directory variables are:\n",
    "\t dir.common = ", dir.common, '\n'
    ## "\t dir.science = ", dir.science, '\n'
    )

## List the files in the user directory
print(data.frame(files = list.files(dir.common)))

src <- function(...) {
  current.objects <- ls('.GlobalEnv')
  source(...)
  new.objects <- ls('.GlobalEnv')
  
  new.objects <- new.objects[!(new.objects %in% current.objects)]
  new.objects <- new.objects[-grep("\\+", new.objects)]
  ## This is needed since *someone* created a stupid function using a special
  ##  symbol 
  
  out <- adply(new.objects, 1, object.summaries, objects.only = FALSE)
  out <- out[, -1]
  cat("\n")
  print(out)
  cat("\n")
}

source(file.path(dir.common, "Misc.r"))

