#############################################################################
## PLOTTING.R
##   Additional functions for plotting
##
## AUTHOR:	John P. Hilbert
## CREATED:	2012-03-09
## MODIFIED:	2012-11-07
## 
## SUMMARY:
##   Details
##
## REVISIONS:
##   1) Made changes for 0.9.2.1 ggplot2
##      Added annotate.subplot
##      Added gg.HeatMap
##
## INPUT:
##   PACKAGES / SCRIPTS:
require(ggplot2)
require(scales)
require(gridExtra)
require(RGraphics)                      # offers splitTextGrob(string)
src("Geom_Point.r", common.dir)
src("Geom_TextBox.r", common.dir)
##
## TO DO:
##   - <NONE>
##
#############################################################################

## ##########################################################################
## Options
## ##########################################################################
## Turn off legend
opts.no.legend <-
  theme(legend.position = "none")

## Top legend
opts.top.legend <-
  theme(legend.position = "top", legend.direction = "horizontal")

## Turn off all axis titles
opts.no.axis.titles <-
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank())

## Rotate x-axis text 90 degrees
opts.veritcal.text <- theme(axis.text.x =
                            element_text(angle = 90, hjust = 1, vjust = 0.25))


## ##########################################################################
## Breaks / Scales
## ##########################################################################
hi.lo.mid_breaks <- function(x){
  breaks <- signif(quantile(x, probs = c(0.1, 0.5, 0.9), na.rm = TRUE), 2)
  names(breaks) <- attr(breaks, "labels")
  breaks
}

hi.lo_breaks <- function(x){
  breaks <- signif(quantile(x, probs = c(0.2, 0.8), na.rm = TRUE), 2)
  names(breaks) <- attr(breaks, "labels")
  breaks
}

scale_x_year <- function(...) {
  scale_x_date(labels = date_format("%Y"), breaks = date_breaks("year"),
               minor_breaks = date_breaks("3 months"), ...)
}

## Set the y axis to dollars
scale_y_dollars <-
  scale_y_continuous(labels = dollar)


## ##########################################################################
## Pot Saving Wrappers
## ##########################################################################
ggsave.quick <- function(filename, landscape = TRUE,
                         height = 8.25, width = 10.75, ...) {
  ## ########################################################################
  ## GGSAVE.QUICK(FILENAME, LANDSCAPE = TRUE,
  ##    HEIGHT = 8.25, WIDTH = 10.75, ...)
  ## A quicker ggsave
  ## Basically saves plots for full page printing by overriding height and
  ## width.  Contains a new BOOL argument for landscape (default = TRUE) 
  ##
  ## PARAMETERS:
  ##   - filename
  ##   - landscape = TRUE
  ##   - height = 8.25
  ##   - width = 10.75
  ##   - ...
  ##
  ## OUTPUT:
  ##   - NULL
  ##
  ## ########################################################################
  if(landscape) 
    ggsave(filename = filename,
           height = height, width = width, ...)
  else
    ggsave(filename = filename,
           height = width, width = height, ...)
  
}

ppsave <- function(filename = default_name(plot),
                   plot,
                   device = default_device(filename),
                   path = NULL,
                   scale = 1,
                   width = par("din")[1],
                   height = par("din")[2],
                   dpi = 300,
                   keep = plot$options$keep,
                   drop = plot$options$drop, ...) {
  ## ########################################################################
  ## PPSAVE(PARAMETERS)
  ## Similar to ggsave, however the plot is assumed to be a plot printing
  ## function taking arguments (...)
  ##
  ## PARAMETERS:
  ##   - parameters
  ##
  ## OUTPUT:
  ##   - NULL
  ##
  ## EXAMPLE:
  ## this.plot <- function(a, b)
  ##   align.plots(a, b, heights = c(1.5, 0.5))
  ##
  ## ppsave(filename = "this_plot.png", this.plot, a = plot.a, b = plot.b)
  ## 
  ## ########################################################################
  if (!inherits(plot, "function")) 
    stop("plot should be a plot printing function")
  eps <- ps <- function(..., width, height)
    grDevices::postscript(...,
                          width = width,
                          height = height,
                          onefile = FALSE,
                          horizontal = FALSE,
                          paper = "special")
  tex <- function(..., width, height)
    grDevices::pictex(...,
                      width = width, height = height)
  pdf <- function(..., version = "1.4")
    grDevices::pdf(...,
                   version = version)
  svg <- function(...)
    grDevices::svg(...)
  wmf <- function(..., width, height)
    grDevices::win.metafile(...,
                            width = width, height = height)
  png <- function(..., width, height)
    grDevices::png(..., width = width,
                   height = height, res = dpi, units = "in")
  jpg <- jpeg <- function(..., width, height)
    grDevices::jpeg(...,
                    width = width,
                    height = height, res = dpi, units = "in")
  bmp <- function(..., width, height)
    grDevices::bmp(..., width = width,
                   height = height, res = dpi, units = "in")
  tiff <- function(..., width, height)
    grDevices::tiff(...,
                    width = width, height = height, res = dpi, units = "in")
  
  default_name <- function(plot) {
    paste(digest.ggplot(plot), ".pdf", sep = "")
  }
  
  default_device <- function(filename) {
    pieces <- strsplit(filename, "\\.")[[1]]
    ext <- tolower(pieces[length(pieces)])
    match.fun(ext)
  }
  
  if (missing(width) || missing(height)) {
    message("Saving ", prettyNum(width * scale, digits = 3), 
            "\" x ", prettyNum(height * scale, digits = 3), "\" image")
  }
  
  width <- width * scale
  height <- height * scale
  if (!is.null(path)) {
    filename <- file.path(path, filename)
  }
  device(file = filename, width = width, height = height)
  on.exit(capture.output(dev.off()))
  plot(...)
  invisible()
}

ppsave.quick <- function(filename, plot, landscape = TRUE,
                         height = 8.25, width = 10.75, ...) {
  ## ########################################################################
  ## PPSAVE.QUICK(FILENAME, PLOT, LANDSCAPE = TRUE,
  ##    HEIGHT = 8.25, WIDTH = 10.75, ...)
  ## Basically saves plots for full page printing by overriding height and
  ## width.  Contains a new BOOL argument for landscape (default = TRUE) 
  ##
  ## PARAMETERS:
  ##   - filename
  ##   - plot
  ##   - landscape = TRUE
  ##   - height = 8.25
  ##   - width = 10.75
  ##   - ...
  ##
  ## OUTPUT:
  ##   - NULL
  ##
  ## ########################################################################
  if(landscape) 
    ppsave(filename = filename, plot = plot,
           height = height, width = width, ...)
  else
    ppsave(filename = filename, plot = plot,
           height = width, width = height, ...)
}

plot.save <- function(filename, plot = last_plot(),
                      landscape = TRUE, path = "plots", ...) {
  ## ########################################################################
  ## PLOT.SAVE(FILENAME, PLOT = LAST_PLOT(), LANDSCAPE = TRUE,
  ##    PATH = "PLOTS", ...)
  ## Depending on the PLOT argument, invokes ggplot.quick or pplot.quick.  By
  ## default it uses the last plot yielding a ggsave.
  ##
  ## NOTE:
  ##      Added PATH = "plots", by default
  ##
  ## PARAMETERS:
  ##   - filename
  ##   - plot = last_plot()
  ##   - landscape = TRUE
  ##   - path = "plots"
  ##   - ...
  ##
  ## OUTPUT:
  ##   - NULL
  ##
  ## ########################################################################
  if(inherits(plot, "ggplot")) 
    ggsave.quick(filename, landscape = landscape, plot = plot, path = path, ...)
  else
    ppsave.quick(filename, landscape = landscape, plot = plot, path = path, ...)
}


###############################################################################
## More advanced plots
###############################################################################
gg.HeatMap <- function(data, x, y, fill, allow.reorder = FALSE,
                       vertical.text = TRUE,
                       label = function(x) trunc(x * 100),
                       low.color = "white", high.color = "red") {
  ## ########################################################################
  ## GG.HEATMAP(DATA, X, Y, FILL, VERTICAL.TEXT = TRUE,
  ##            LABEL = FUNCTION(X) TRUNC(X * 100),
  ##            LOW.COLOR = "WHITE", HIGH.COLOR = "RED")
  ## Draws a heat map using ggplot.  Unlike typical heat-map functions, this
  ## expects a data frame of x/y labels and a strength.  The ordering will be
  ## based on the ordering of the given data frame.  The strength by default is
  ## labeled by trunc(strength * 100), but can be changed by passing a different
  ## function.
  ##
  ## PARAMETERS:
  ##   - data           - data frame containing x/y labels and a fill strength
  ##   - x              
  ##   - y
  ##   - fill
  ##   - allow.reorder  - if FALSE, use ordering in data
  ##   - vertical.text  - Rotate text on X axis (TRUE)
  ##   - label          - function for labeling cells, use NA to turn off
  ##   - low.color      - low color (white)
  ##   - high.color     - high color (red)
  ##
  ## OUTPUT:
  ##   - ggplot object
  ##
  ## ########################################################################
  e <- eval(substitute(list(x = x, y = y, fill = fill)),
            data, parent.frame())
  tags <- names(e)
  data <- do.call("data.frame", e)
  
  if(!allow.reorder)
    data <- transform(data,
                      x = factor(x, levels = unique(x)),
                      y = factor(y, levels = unique(y)))
  
  p <- qplot(data = data,
             y = y,
             x = x,
             fill = fill,
             geom = "tile")
  if(class(label) == "function")
    p <- p + geom_text(aes(label = label(fill)))
  
  p <- p + theme_bw()
  
  if(vertical.text)
    p <- p + opts.veritcal.text 
  
  p <- p + theme(legend.position = "none",
                 axis.ticks = element_blank()) 
  p <- p + scale_fill_gradient(low = low.color, high = high.color)

  p <- p + labs(x = "x", y = "y")
  return(p)
}

HeatMap.Reorder <- function(data, x, y, value, append.only = FALSE) {
  ## ########################################################################
  ## HEATMAP.REORDER(DATA, X, Y, VALUE, APPEND.ONLY = FALSE)
  ## Reorders factors for heat-map using hierarchal clustering.  The clustering
  ## is done on each variable in turn and then reordered. Reordering is
  ## optional, however the ordering is appended to the data.frame
  ##
  ## PARAMETERS:
  ##   - data           - data.frame containing x, y, and value
  ##   - x              
  ##   - y
  ##   - value          - value to use for distance
  ##   - append.only    - if TRUE, reordering is not done
  ##
  ## OUTPUT:
  ##   - data           - original data with additional variables "order." +
  ##                      x/y.  x/y may be reordered (default)
  ##
  ## ########################################################################
  
  x.string <- as.character(substitute(x))
  y.string <- as.character(substitute(y))
  value.string <- as.character(substitute(value))
  
  get.ordering <- function(data, x, y, value) {
    f <- formula(paste(x, "~", y))
    ordering <- dcast(data, f, value = value, fill = max(data[, value]) * 100)
    row.names(ordering) <- ordering[, 1]
    ordering[, 1] <- NULL
    
    hc <- hclust(dist(ordering))
    
    ordering <- data.frame(label = hc$labels[hc$order],
                           order = seq_along(hc$order))
    names(ordering) <- c(x, "order." %+% x)
    ordering
  }
  
  data <- merge(data, get.ordering(data, x.string, y.string, value.string))
  data <- merge(data, get.ordering(data, y.string, x.string, value.string))
  
  if(!append.only) {
    data[, x.string] <- reorder(data[, x.string], data[, "order." %+% x.string])
    data[, y.string] <- reorder(data[, y.string], data[, "order." %+% y.string])
  }
  
  data
}


## ##########################################################################
## Plot Range / Coordinate Translation
## ##########################################################################
get.Plot.Range <- function(plot) {
  ## ########################################################################
  ## GET.PLOT.RANGE(PLOT)
  ## Gets the range (X/Y) of PLOT
  ##
  ## PARAMETERS:
  ##   - plot           - Plot to use
  ##   
  ## OUTPUT:
  ##   - data frame of length 2
  ##
  ## ########################################################################
  plot.info <- ggplot_build(plot)
  data.frame(x = plot.info$panel$ranges[[1]]$x.range,
             y = plot.info$panel$ranges[[1]]$y.range)
}

get.Plot.Size <- function(plot) {
  ## ########################################################################
  ## GET.PLOT.SIZE(PLOT)
  ## Gets the size (X/Y) of PLOT
  ##
  ## PARAMETERS:
  ##   - plot           - Plot to use
  ##   
  ## OUTPUT:
  ##   - data frame of length 2
  ##
  ## ########################################################################
  plot.rng <-get.Plot.Range(plot)
  data.frame(x = diff(plot.rng$x),
             y = diff(plot.rng$y))
}

Plot.Position.Convert <- function(plot, coord) {
  ## ########################################################################
  ## PLOT.POSITION.CONVERT(PLOT, COORD)
  ## Translates normalized coordinates to the coordinates of PLOT
  ##
  ## PARAMETERS:
  ##   - plot           - Plot to use
  ##   - coord          - normalized (0-1) coordinates where 0,0 is lower left
  ##
  ## OUTPUT:
  ##   - vector of size 2
  ##
  ## ########################################################################
  r <- get.Plot.Range(plot)
  s <- data.frame(x = diff(r$x),
                  y = diff(r$y))
  coord[1] <- r$x[1] + s$x * coord[1]
  coord[2] <- r$y[1] + s$y * coord[2]
  coord
}
