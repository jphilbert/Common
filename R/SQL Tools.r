#############################################################################
## SQL Tools.R
##   Wrappers for common SQL functions.
##
## AUTHOR:	John P. Hilbert
## CREATED:    2012-11-13
## MODIFIED:   2015-01-28
## 
## SUMMARY:
##   Currently this file wraps and adds simplicity to sqlSave, sqlFetch, sqlDrop
##
## REVISIONS:
##   1) added sqlGrant.Quick (a wrapper for SQL GRANT)
##   2) added SCHEMA parameter to functions
##   3) sqlGrant.Quick supports multiple table names and users
##   4) added sqlCharacterLength function to calculate the max size of strings
##      incorporated this into sqlSave.Quick
##   5) added sqlComment function to comment on tables
##
##   2015-07-22
##      Major changes for Redshift and PostgreSQL.
##      Changes toupper to tolower for tables, schemas, and variables.
##      Added DATE and BOOL when saving.
##
## TO DO:
##   - Add documentation
##
## INPUT:
##   PACKAGES / SCRIPTS:
##   - RODBC
##
##   DATA:
##   - <NONE>
##
## OUTPUT:
##   DATA:
##   - <NONE>
##
##   PLOTS:
##   - <NONE>
##
#############################################################################
require(RODBC)

sqlGrant.Quick <- function(table.names, users,
                           db = "local", ...) {
    ## ########################################################################
    ## SQLGRANT.QUICK(TABLE.NAME, USER = "PUBLIC", DB = "local")
    ## Grants SELECT access to TABLE.NAME for USER.
    ##
    ## PARAMETERS:
    ##   - table.names            - Table to grant SELECT access
    ##   - users                  - Users allow access
    ##   - db = "local"          - DB connection
    ##
    ## OUTPUT:
    ##   - NULL
    ##
    ## ########################################################################
    table.names <- tolower(table.names)
    users <- tolower(users)
    dbConn <- odbcConnect(db, ...)
    data <- sqlQuery(dbConn,
                     paste("GRANT SELECT ON", 
                           rep(table.names, rep(length(users),
                                               length(table.names))),
                           "TO",
                           rep(users, length(table.names)),
                           collapse = "; ") %+% ";")
    close(dbConn)
}

sqlComment <- function(table.names, comment = " ",
                       db = "local", ...) {
    ## ########################################################################
    ## SQLCOMMENT(TABLE.NAME, COMMENT = " ", DB = "local")
    ## Comments on a TABLE.NAME
    ##
    ## PARAMETERS:
    ##   - table.names            - Table(s) to comment on
    ##   - comment                - Comment (will be repeated for multiple
    ##                              tables)
    ##   - db = "local"          - DB connection
    ##
    ## OUTPUT:
    ##   - NULL
    ##
    ## ########################################################################
    table.names <- tolower(table.names)
    dbConn <- odbcConnect(db, ...)
    cmd <- paste("COMMENT ON TABLE ", 
                 table.names,
                 " TO '",
                 rep(comment, length(table.names)),
                 sep = "",
                 collapse = "'; ") %+% "';"
    data <- sqlQuery(dbConn, cmd)
    close(dbConn)
}

sqlDrop.Quick <- function(table.name, schema = NULL,
                          db = "local", ...) {
    ## ########################################################################
    ## SQLDROP.QUICK(TABLE.NAME, DB = "local")
    ## Similar to sqlDrop, however automatically opens and closes the
    ## connection.
    ##
    ## PARAMETERS:
    ##   - table.name             - Table to drop
    ##   - schema                 - schema of table
    ##   - db = "local"          - db connection
    ##
    ## OUTPUT:
    ##   - NULL
    ##
    ## ########################################################################
    dbConn <- odbcConnect(db, ...)
    if(!is.null(schema))
        table.name <- paste(schema, table.name, sep = ".")
    table.name <- tolower(table.name)
    sqlDrop(dbConn, table.name)
    close(dbConn)
}

sqlFetch.Quick <- function(table.name, schema = NULL,
                           db = "local", ...) {
    if(!is.null(schema))
        table.name <- paste(schema, table.name, sep = ".")
    table.name <- tolower(table.name)
    dbConn <- odbcConnect(db, ...)
    data <- sqlFetch(dbConn, table.name)
    close(dbConn)
    names(data) <- gsub("_", ".", tolower(names(data)))
    return(data)
}

sqlSave.Quick <- function(data, table.name,
                          schema = NULL, db = "local",
                          varTypes = NULL, ...) {
    if(!is.null(schema))
        table.name <- paste(schema, table.name, sep = ".")
    table.name <- tolower(table.name)
    dbConn <- odbcConnect(db, ...)
    ## sqlDrop(dbConn, table.name)

    dbms.name <- odbcGetInfo(dbConn)["DBMS_Name"]
  
    ## Dates / Logical
    varT <- sapply(data[, setdiff(names(data), names(varTypes))],
                   class)
    varT <- varT[varT %in% c('Date', 'logical')]
    varT <- gsub('logical', getSqlTypeInfo( dbms.name)$logical, varT)
    varTypes <- c(varTypes, varT)
    
    ## Correct String Length
    add.varTypes <- names(data)[!(names(data) %in% names(varTypes))]
    varTypes <- c(varTypes,
                  sqlCharacterLength(dbms.name, data, add.varTypes))
   
    names(data) <- gsub("[/.]", "_", tolower(names(data)))
    if(!is.null(varTypes))
        names(varTypes) <- gsub("[/.]", "_", tolower(names(varTypes)))

    sqlSave(dbConn, data, tablename = table.name,
            rownames = FALSE, safer = FALSE, varTypes = varTypes, ...)
    
    close(dbConn)
}

sqlCharacterLength <- function(dbName, data, var = names(data)) {
    if(length(var) == 0) return(NULL)
    data <- data[, var]

    charType <- strsplit(getSqlTypeInfo(dbName)$character, '\\(')[[1]][1]

    ## Special case if there is only one variable
    if(length(var) == 1) {
        if(is.factor(data) | is.character(data)) {
            out <- paste(charType, "(",
                         max(nchar(as.character(data))), ")", 
                         sep = "")
            names(out) <- var
            return(out)
        }
        return(NULL)
    }
    
    ## Convert factors to strings
    i <- sapply(data, is.factor)
    data[i] <- lapply(data[i], as.character)
    
    ## Find all character variables
    n <- sapply(data, is.character)
    n <- n[n]
    if(length(n) == 0) return(NULL) 

    ## Loop
    if(length(n) == 1) {
        out <- paste(charType, "(",
                     max(nchar(data[, names(n)])), ")", 
                     sep = "")
        names(out) <- names(n)
    }
    else {
        out <- sapply(data[, names(n)],
               function(x) paste(charType, "(",
                                 max(nchar(x)), ")", 
                                 sep = ""))
    }
    out
}



tryCatch(setSqlTypeInfo("Oracle",
                        list(double="NUMBER", integer="NUMBER",
                             character="VARCHAR2(255)",
                             logical="VARCHAR2(5)")),
         error = function(x){print("updated ORACLE types")})


tryCatch(setSqlTypeInfo("PostgreSQL",
                        list(double="float8", integer="int4",
                             character="varchar(255)",
                             logical="bool")),
         error = function(x){print("updated PostgreSQL types")})


tryCatch(setSqlTypeInfo("Redshift",
                        getSqlTypeInfo('PostgreSQL')),
         error = function(x){print("updated Redshift types")})
