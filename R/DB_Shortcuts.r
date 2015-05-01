dbConn.LocalPostgres <- function() {
    drv <- dbDriver("PostgreSQL")
    dbConnect(drv, dbname = "")
}

dbConn.Redshift <- function(db = "ci100000_lens") {
    drv <- dbDriver("PostgreSQL")
    p <- pipe("cat ~/settings/Redshift/R_Settings.txt.gpg|gpg -d")
    conn.str <- readLines(p)
    close(p)
    dbConnect(drv, dbname = gsub("ci100000_lens", db, conn.str))
}
