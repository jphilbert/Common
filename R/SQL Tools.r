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
                           db = "EDW", uid, pwd) {
    ## ########################################################################
    ## SQLGRANT.QUICK(TABLE.NAME, USER = "PUBLIC", DB = "EDW")
    ## Grants SELECT access to TABLE.NAME for USER.
    ##
    ## PARAMETERS:
    ##   - table.names            - Table to grant SELECT access
    ##   - users                  - Users allow access
    ##   - db = "EDW", uid = "HILBERTJP", pwd = "J120741h!"          - DB connection
    ##
    ## OUTPUT:
    ##   - NULL
    ##
    ## ########################################################################
    table.names <- toupper(table.names)
    users <- toupper(users)
    oracle <- odbcConnect(db, uid, pwd)
    data <- sqlQuery(oracle,
                     paste("GRANT SELECT ON", 
                           rep(table.names, rep(length(users),
                                               length(table.names))),
                           "TO",
                           rep(users, length(table.names)),
                           collapse = "; ") %+% ";")
    close(oracle)
}

sqlComment <- function(table.names, comment = " ",
                       db = "EDW", uid, pwd) {
    ## ########################################################################
    ## SQLCOMMENT(TABLE.NAME, COMMENT = " ", DB = "EDW")
    ## Comments on a TABLE.NAME
    ##
    ## PARAMETERS:
    ##   - table.names            - Table(s) to comment on
    ##   - comment                - Comment (will be repeated for multiple
    ##                              tables)
    ##   - db = "EDW", uid = "HILBERTJP", pwd = "J120741h!"          - DB connection
    ##
    ## OUTPUT:
    ##   - NULL
    ##
    ## ########################################################################
    table.names <- toupper(table.names)
    oracle <- odbcConnect(db, uid, pwd)
    cmd <- paste("COMMENT ON TABLE ", 
                 table.names,
                 " TO '",
                 rep(comment, length(table.names)),
                 sep = "",
                 collapse = "'; ") %+% "';"
    data <- sqlQuery(oracle, cmd)
    close(oracle)
}

sqlDrop.Quick <- function(table.name, schema = NULL,
                          db = "EDW", uid, pwd) {
    ## ########################################################################
    ## SQLDROP.QUICK(TABLE.NAME, DB = "EDW")
    ## Similar to sqlDrop, however automatically opens and closes the
    ## connection.
    ##
    ## PARAMETERS:
    ##   - table.name             - Table to drop
    ##   - schema                 - schema of table
    ##   - db = "EDW", uid = "HILBERTJP", pwd = "J120741h!"          - db connection
    ##
    ## OUTPUT:
    ##   - NULL
    ##
    ## ########################################################################
    oracle <- odbcConnect(db, uid, pwd)
    if(!is.null(schema))
        table.name <- paste(schema, table.name, sep = ".")
    table.name <- toupper(table.name)
    sqlDrop(oracle, table.name)
    close(oracle)
}

sqlFetch.Quick <- function(table.name, schema = NULL,
                           db = "EDW", uid, pwd) {
    if(!is.null(schema))
        table.name <- paste(schema, table.name, sep = ".")
    table.name <- toupper(table.name)
    oracle <- odbcConnect("EDW")
    data <- sqlFetch(oracle, table.name)
    close(oracle)
    names(data) <- gsub("_", ".", tolower(names(data)))
    return(data)
}

sqlSave.Quick <- function(data, table.name,
                          schema = NULL, db = "EDW",
                          uid, pwd,
                          varTypes = NULL, ...) {
    if(!is.null(schema))
        table.name <- paste(schema, table.name, sep = ".")
    table.name <- toupper(table.name)
    oracle <- odbcConnect(db, uid, pwd)
    ## sqlDrop(oracle, table.name)

    ## Correct String Length
    dbms.name <- odbcGetInfo(oracle)["DBMS_Name"]
    names(data) <- gsub("[/.]", "_", toupper(names(data)))
    if(!is.null(varTypes))
        names(varTypes) <- gsub("[/.]", "_", toupper(names(varTypes)))

    add.varTypes <- names(data)[!(names(data) %in% names(varTypes))]
    varTypes <- c(varTypes,
                  sqlCharacterLength(dbms.name, data, add.varTypes))

    sqlSave(oracle, data, tablename = table.name,
            rownames = FALSE, safer = FALSE, varTypes = varTypes, ...)
    
    close(oracle)
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
