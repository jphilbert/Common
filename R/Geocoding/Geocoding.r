## require(ggmap)                          # No Longer Required
require(RJSONIO)

###############################################################################
## Google
###############################################################################
## https://developers.google.com/maps/documentation/geocoding/

## loop

## mutli addresses

## Parser
geocode.parse.Google <- function(results) {
    if(results$status != 'OK') {
        warning(paste(results$status,
                      results$error_message, sep = '\n\t'))
        return(NULL)
    }
        
    ## print(messages)
    ## TODO: Parse Messages

    ## Flatten Result (single)
    flatten.result <- function(r) {
        ## Parse the Geometry
        gcdf <- with(r$geometry, {
            data.frame(lon = if.null(location['lng']),
                       lat = if.null(location['lat']), 
                       loctype = if.null(location_type)
                       ## vp.NE.lat = if.null(viewport$northeast$lat), 
                       ## vp.SW.lat = if.null(viewport$southwest$lat), 
                       ## vp.NE.lon = if.null(viewport$northeast$lng), 
                       ## vp.SW.lon = if.null(viewport$southwest$lng)
                       )
        })

        ## Additional Info
        gcdf$type <- if.null(r$types[1])
        gcdf$partial <- if.null(r$partial_match, FALSE)
        ## gcdf$address <- if.null(r$formatted_address)

        ## Parse the Address
        addr <- t(ldply(r$address_components, function(l) {
            if(length(l$types) < 1)     # Sometimes this is empty and throws and
                                        # error
                return(NULL)            
            as.data.frame(l, stringsAsFactors = FALSE)[1, ]
        }))
        addr <- as.data.frame(addr, stringsAsFactors = FALSE)
        names(addr) <- addr["types", ]

        ## NOTE: drop = F retains single column data.frames
        addr <- addr[c("long_name", "short_name"), , drop = F]

        original.names <- c("locality", "administrative_area_level_2",
                           "administrative_area_level_1", "country",
                           "postal_code", "street_number", "route",
                            "point_of_interest", "establishment")
        
        missing.columns <- setdiff(original.names, names(addr))
        addr[, missing.columns] <- NA
        addr <- addr[, original.names]

        names(addr) <- c("city", "county", "state",
                         "country", "postal_code", "street_number", "route",
                         "point_of_interest", "establishment")
        addr$state_short <- addr["short_name", "state"]
        addr$country <- addr["short_name", "country"]
        addr$street <- paste(addr$street_number, addr$route)
        addr <- addr["long_name", c("point_of_interest", "establishment",
                                    "street", "city", "county", "state",
                                    "state_short", "country", "postal_code")]

        row.names(addr) <- NULL
        gcdf <- cbind(gcdf, addr)
        return(gcdf)
    }
    return(ldply(results$results, flatten.result))
}

## Single
geocode.Google.single <- function(location, api = NULL) {
    if(is.factor(location))
        location <- as.character(location)
    
    location <- gsub(' ', '+', location)
    
    call.url <- 'http://maps.googleapis.com/maps/api/geocode/json?'
    call.url <- paste(call.url, '&address=', location, sep = '')
    call.url <-  URLencode(call.url)
    if(!is.null(api))
        call.url <- paste(call.url, '&key=', api, sep = '')

    connect <- url(call.url)
    out <- readLines(connect, warn = FALSE)
    close(connect)

    out <- fromJSON(paste(out, collapse = ''))   
    out <- geocode.parse.Google(out)
    out
}

## Reverse
reverse.geocode.Google.single <- function(lat, lon, api = NULL) {
    call.url <- 'http://maps.googleapis.com/maps/api/geocode/json?'
    call.url <- paste(call.url, '&latlng=', lat, ',', lon, sep = '')
    call.url <-  URLencode(call.url)
    if(!is.null(api))
        call.url <- paste(call.url, '&key=', api, sep = '')

    connect <- url(call.url)
    out <- readLines(connect, warn = FALSE)
    close(connect)

    out <- fromJSON(paste(out, collapse = ''))   
    out <- geocode.parse.Google(out)
    out
}

###############################################################################
## MapQuest
## 
## http://developer.mapquest.com/web/products/open/geocoding-service
## DELETE: Fmjtd%7Cluu82l68nd%2Cb2%3Do5-94rgh-f
###############################################################################

## Parser
geocode.parse.MapQuest <- function(results) {
    status_code <- results$info$statuscode
    if(status_code != 0) {
        warning(paste(status_code,
                      results$info$messages, sep = '\n\t'))
        return(NULL)
    }
    
    ## TODO: Parse Messages

    ## Flatten the list
    out <-
        ldply(results$results,
              function(y) {
                  out <- data.frame()
                  if(length(y$locations) != 0)
                      out <- ldply(y$locations,
                                   function(z) {
                                       as.data.frame(t(unlist(z)),
                                                     stringsAsFactors = F)})
                  out$provided.location <- y$providedLocation
                  out
              })

    ## print(out)

    ## Maps the variables to more readable names
    ##    - Move this out for speed?
    ##    - Omits country among other variables
    var.names <- c(
        ## provided.location =   "query",              
        latLng.lat =          "lat",                
        latLng.lng =          "lon",                
        street =              "street",             
        adminArea5 =          "city",               
        adminArea3 =          "state",              
        postalCode =          "postal.code",        
        geocodeQuality =      "geocode.quality",    
        geocodeQualityCode =  "geocode.quality.code")

    names(out) <- var.names[names(out)]
    out <- out[, var.names]

    ## Final clean up
    out$lat <- as.numeric(out$lat)
    out$lon <- as.numeric(out$lon)
    out[out == ''] <- NA
    out
}


## Single Geocode
## -- Location
geocode.MapQuest.single <- function(location, api) {
    if(is.factor(location))
        location <- as.character(location)
    
    call.url <- 'http://open.mapquestapi.com/geocoding/v1/address?'
    call.url <- paste(call.url, '&thumbMaps=false',
                      '&inFormat=kvp',
                      '&outFormat=json', sep = '')
    call.url <- paste(call.url, '&location=', location, sep = '')
    call.url <-  URLencode(call.url)
    call.url <- paste(call.url, '&key=', api, sep = '')

    connect <- url(call.url)
    out <- readLines(connect, warn = FALSE)
    close(connect)

    out <- fromJSON(out)
    geocode.parse.MapQuest(out)
}

## -- 5-Box
## street=1090 N Charlotte St&city=Lancaster&state=PA&postalCode=17603

## Reverse
reverse.geocode.MapQuest.single <- function(lat, lon, api) {
    call.url <- 'http://open.mapquestapi.com/geocoding/v1/reverse?'
    call.url <- paste(call.url, '&thumbMaps=false',
                      '&inFormat=kvp',
                      '&outFormat=json', sep = '')
    call.url <- paste(call.url, '&location=', lat, ',', lon, sep = '')
    call.url <-  URLencode(call.url)
    call.url <- paste(call.url, '&key=', api, sep = '')

    connect <- url(call.url)
    out <- readLines(connect, warn = FALSE)
    close(connect)

    out <- fromJSON(out)
    geocode.parse.MapQuest(out)
}

## Batch Geocode
geocode.MapQuest.batch <- function(location, api) {
    if(length(location) > 100)
        stop("Batches must be less than 100 locations")

    if(is.factor(location))
        location <- as.character(location)
    

    location <- paste('&location=', location, sep = '', collapse = '')
    
    call.url <- 'http://open.mapquestapi.com/geocoding/v1/batch?'
    call.url <- paste(call.url, '&thumbMaps=false',
                      '&inFormat=kvp',
                      '&outFormat=json', sep = '')
    call.url <- paste(call.url, location, sep = '')
    call.url <-  URLencode(call.url)
    call.url <- paste(call.url, '&key=', api, sep = '')
    
    connect <- url(call.url)
    out <- readLines(connect, warn = FALSE)
    close(connect)

    out <- fromJSON(out)
    geocode.parse.MapQuest(out)
}


###############################################################################
## US Census
## http://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.pdf
###############################################################################

## Parser
geocode.parse.Census <- function(results) {
    ## TODO: Parse Messages
    results <- results$result$addressMatches

    if(length(results) < 1) {
        ## warning('No Results \n\t')
        return(NULL)
    }

    out <- ldply(results, function(x) {
        as.data.frame(t(unlist(x)),
                      stringsAsFactors = F)})
    

    ## Maps the variables to more readable names
    ##    - Move this out for speed?
    ##    - Omits country among other variables
    var.names <- c(
        ## various items are DROPPED and may need to be added
        coordinates.x =          "lon",                
        coordinates.y =          "lat",                
        addressComponents.fromAddress = "street.num.1",             
        addressComponents.toAddress =   "street.num.2",             
        addressComponents.streetName =  "street.name",
        addressComponents.city =        "city",
        addressComponents.state =       "state",
        addressComponents.zip =         "postal.code",
        tigerLine.tigerLineId =         'tigerLineID')

    names(out) <- var.names[names(out)]
    out <- out[, var.names]

    ## Final clean up
    out$lat <- as.numeric(out$lat)
    out$lon <- as.numeric(out$lon)
    out[out == ''] <- NA
    out
}

## Single Geocode
## -- Location
geocode.Census.single <- function(location, api) {
    if(is.factor(location))
        location <- as.character(location)

    callType <- 'locations'
    ## callType <- 'geographies'
    
    call.url <- 'http://geocoding.geo.census.gov/geocoder/'
    call.url <- paste(call.url,
                      callType, '/',
                      'onelineaddress?',
                      ## '&benchmark=Public_AR_Census2010',
                      '&benchmark=Public_AR_Current',
                      '&format=json',
                      '&vintage=Census2010_Census2010', sep = '')
    call.url <- paste(call.url, '&address=', location, sep = '')
    call.url <- URLencode(call.url)

    connect <- url(call.url)
    out <- readLines(connect, warn = FALSE)
    close(connect)

    out <- fromJSON(out)
    geocode.parse.Census(out)
}

## -- 5-Box
## street=1090 N Charlotte St&city=Lancaster&state=PA&postalCode=17603

## Reverse

## Geographies

###############################################################################
## General Functions
###############################################################################
geocode.multi <- function(addresses, key = NULL, messaging = 25,
                          geocode.function = geocode.Google.single, ...) {
    if(is.vector(addresses)) {
        n <- length(addresses)
        if(!is.null(key) && length(key) != n)
            stop("KEY is not the same length as ADDRESSES")
    }
    else
        stop("Only vectors are currently supported")
    ## n <- nrow(addresses)

    out <- NULL
    i <- 0
    repeat {
        i <- i + 1
        if(i > n) break
        
        this.record <- addresses[i]

        err <- tryCatch(
            this.geo <- geocode.function(this.record, ...),
            error = function(cond) {
                message("\n Error at record " %+% i %+% " !!!\n")
                message(cond)
                return(NULL)
            })

        if(messaging > 0 && i %% messaging == 0)
            cat("\n -- Processed " %+% i %+% " records --\n")
       
        if(is.null(err)) 
            next   
                
        ## if(is.null(this.geo)) {
        ##     cat("\n !!! Stopped at record " %+% i %+% " !!!\n")
        ##     break   
        ## }

        if(is.null(this.geo)) {
            ## cat("\n !!! No Results at record " %+% i %+% " !!!\n")
            next   
        }

        if(!is.null(key))
            this.geo$key <- key[i]
        else
            this.geo$key <- i
        out <- rbind(out, this.geo)
    }
    return(out)
}



###############################################################################
## Scratch
###############################################################################

## geocode.MapQuest.single("1524 Merrick Ave., Pittsburgh, PA",
##                         "Fmjtd%7Cluu82l68nd%2Cb2%3Do5-94rghf")

## geocode.MapQuest.batch(c("1524 Merrick Ave., Pittsburgh, PA",
##                          "UPMC, Pittsburgh"),
##                        "Fmjtd%7Cluu82l68nd%2Cb2%3Do5-94rghf")

## geocode.Census.single("1520 Merrick Ave. Pittsburgh, PA")

## geocode.parse.Census(x)


## geocode.multi(c("1524 Merrick Ave., Pittsburgh, PA",
##                 "275 Brookside Blvd., Hinckley, OH"),
##               geocode.function = geocode.Census.single)
