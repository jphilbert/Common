#############################################################################
## MULTI-PLOT.R
##   Functions for Multi Plots
##
## AUTHOR:	John P. Hilbert
## CREATED:	2013-04-25
## MODIFIED:	2013-05-03
## 
## SUMMARY:
##   Multi-Plots (plots within plots) are relatively simple with these
##   functions. The main procedure is as follows:
##      1) Prepare the data
##              - a subplot data frame which includes all the data for each
##                individual subplot.  For example, if one wishes to plot 10 pie
##                charts, the data frame should have an 10 plot index label and
##                a label and size for each slice for each plot.  Optionally,
##                one may add custom colors.
##              - a super plot data frame containing Cartesian coordinates and
##                size of each plot.  The scale of the coordinates are dependent
##                on the underlying main plot however the size is can be
##                normalized.  Additionally the same index for the subplots must
##                be included to map between the two.
##      2) Create an initial layer such as a blank ggplot() or existing qplot()
##      3) Create the subplots (CREATE.SUB.PLOTS)
##      4) Add the subplots to the initial plot (ADD.SUB.PLOTS)
## 
##   If a common legend for the subplots are needed and custom colors are added
##   (default colors have not been verified match) then:
##      5) Create a legend plot (PLOT.LEGEND.FILL)
##      6) Annotate this to the previous plot
## 
## REVISIONS:
##   1) Fixed issue in Add.Sub.Plots where a subplot was expected (due to it
##      being in the main dataset) but not previously created
##   2) Fixed vertical justification on legend title
##   3) Added rectangular (size.x != size.y) to ADD.SUB.PLOTS and subsequently
##      annotation_subplot.
## **4) Added BAR.CHART
##
## TO DO:
##   - Create dodge and stacked bar charts
##   - Create bullseye charts
##
## INPUT:
##   PACKAGES / SCRIPTS:
## require(ggmap)                          # For theme_nothing()
##
#############################################################################

theme_nothing <-
    theme(axis.text =          element_blank(),
          axis.title =         element_blank(),
          panel.background =   element_blank(),
          panel.grid.major =   element_blank(),
          panel.grid.minor =   element_blank(),     
          axis.ticks.length =  unit(0, "cm"),
          axis.ticks.margin =  unit(0.01, "cm"),
          panel.margin =       unit(0, "lines"),
          plot.margin =        unit(c(0, 0, -.5, -.5), "lines"),
          plot.background =    element_blank(),
          legend.position =    "none",
          complete = TRUE)

## ##########################################################################
## Subplot Function
## ##########################################################################
annotation_subplot <- function(plot, x, y, size = 1) {
  ## ########################################################################
  ## ANNOTATION_SUBPLOT(PLOT, X, Y, SIZE)
  ## Creates a subplot annotation to be added to an existing plot.  See
  ## annotation_custom.
  ##
  ## NOTE: This (probably) fixes the multiple annotation problem
  ##
  ## PARAMETERS:
  ##   - plot           - typical a qplot or gplot
  ##   - x / y          - either a vector of length 2 defining the corners of
  ##                      the bounding box of the subplot or a scalar number
  ##                      defining the center
  ##   - size           - if the center is given, defines the diameter or x, y
  ##                      extent (if vector)
  ##
  ## OUTPUT:
  ##   - ggplot object
  ##
  ## ########################################################################
  if(length(x) == 2 & length(y == 2)) {
    xmin <- x[1]
    xmax <- x[2] 
    ymin <- y[1] 
    ymax <- y[2] 
  }
  else if(length(size) > 1) {
    xmin <- x[1] - size[1]/2
    xmax <- x[1] + size[1]/2
    ymin <- y[1] - size[2]/2
    ymax <- y[1] + size[2]/2
  }
  else {
    xmin <- x[1] - size/2
    xmax <- x[1] + size/2
    ymin <- y[1] - size/2
    ymax <- y[1] + size/2
  }
  g <- ggplotGrob(plot)
  g$name <- paste(g$name, sample.int(10^9, 1))
  annotation_custom(g, xmin, xmax, ymin, ymax)
}

Pie.Chart <- function(d, slice.label, slice.size, slice.colors = NULL,
                      slice.line.width = 0.5,
                      slice.line.color = "black") {
  ## ########################################################################
  ## PIE.CHART(D, SLICE.LABEL, SLICE.SIZE, SLICE.COLORS,
  ##            SLICE.LINE.WIDTH = 0.1, SLICE.LINE.COLOR = "BLACK" )
  ## Manually (aggregation must be already done) plots a plain pie chart.
  ##
  ## PARAMETERS:
  ##   - d                      - data 
  ##   - slice.label            - name of slice
  ##   - slice.size             - size of slice
  ##   - slice.colors           - color of slice (optional)
  ##   - slice.line.width       - width of slice outline
  ##   - slice.line.color       - color of slice outline
  ##
  ## OUTPUT:
  ##   - ggplot
  ##
  ## ########################################################################
  plot <- ggplot(d, aes(x = "a"))
  plot <- plot +
    geom_bar(aes_string(y = slice.size,
                        fill = slice.label),
             color = slice.line.color,
             width = 1,
             size = slice.line.width)
  plot <- plot +
    coord_polar("y")
  if(!is.null(slice.colors)) {
    plot <- plot +
      scale_fill_manual(breaks = slice.colors[, slice.label],
                        values = slice.colors$color)}
  plot <- plot + theme_nothing()
  plot
}

Bar.Chart <- function(d, bar.height, bar.label, bar.colors = NULL,
                      bar.width = 0.95, bar.line.color = "black",
                      bar.line.size = 1,
                      bar.height.limit = c(0, 1),
                      bg.color = "black",
                      bg.alpha = 1,
                      bg.border.color = "black",
                      bg.border.size = 2,
                      flip = FALSE) {
  ## ########################################################################
  ## BAR.CHART(D, BAR.HEIGHT, BAR.LABEL, BAR.COLORS, BAR.WIDTH)
  ## Manually (aggregation must be already done) plots a plain bar chart.
  ##
  ## PARAMETERS:
  ##   - d                      - data 
  ##   - bar.height             - variable name for bar height
  ##   - bar.label              - variable name for bar label
  ##   - bar.colors             - color of bars (optional)
  ##   - bar.width              - width of bar [0,1]
  ##   - bar.height.limit       - range of the height axis (should be
  ##                              consistent across all plots)
  ##   - bar.line.color         - 
  ##   - bar.line.size          - 
  ##   - bg.color               -
  ##   - bg.alpha               -
  ##   - bg.border.color        -
  ##   - bg.border.size         -
  ##   - flip                   - Flip the coordinates (FALSE)
  ##
  ## OUTPUT:
  ##   - ggplot
  ##
  ## ########################################################################
  plot <- ggplot(d)
  plot <- plot +
    geom_bar(aes_string(y = bar.height,
                        x = bar.label,
                        fill = bar.label),
             color = bar.line.color,
             width = bar.width,
             size = bar.line.size)
  
  if(!is.null(bar.colors)) 
    plot <- plot + scale_fill_manual(breaks = bar.colors[, bar.label],
                                     values = bar.colors$color)
    
  if(!is.null(bar.height.limit)) 
    plot <- plot + ylim(bar.height.limit)
  
  plot <- plot + theme_nothing()
  
  plot <- plot +
    theme(rect = element_rect(
            color = "black",
            fill = "black", size = 2,
            linetype = 0),
          panel.background = element_rect(fill = alpha(bg.color, bg.alpha)),
          panel.border = element_rect(
            color = bg.border.color, fill = NA,
            size = bg.border.size, linetype = 1))
  
  if(flip)
    plot <- plot + coord_flip
  
  plot
}

Create.Sub.Plots <- function(sub.plot.data, index,
                             plot.function = Pie.Chart, ...) {
  ## ########################################################################
  ## CREATE.SUB.PLOTS(SUB.PLOT.DATA, INDEX, PLOT.FUNCTION = PIE.CHART, ...)
  ## Creates a list of GGPLOT2 objects.
  ##
  ## PARAMETERS:
  ##   - sub.plot.data          - data to feed to PLOT.FUNCTION.  Must contain
  ##                              INDEX column
  ##   - index                  - string = name of index column
  ##   - plot.function          - function to create plots (default = Pie.Chart)
  ##   - ...                    - additional parameters for PLOT.FUNCTION
  ##
  ## OUTPUT:
  ##   - List of Plots indexed by INDEX
  ##
  ## ########################################################################
  dlply(sub.plot.data, index, plot.function, ...)
}

Add.Sub.Plots <- function(main.plot, sub.plots, index, x, y,
                          size.x = 0.1, size.y = size.x) {
  ## ########################################################################
  ## ADD.SUB.PLOTS(MAIN.PLOT, SUB.PLOTS, INDEX, X, Y, SIZE)
  ## Adds subplots to a main plot in correct location / size 
  ##
  ## PARAMETERS:
  ##   - main.plot      - Main plot to overlay subplots to
  ##   - sub.plots      - list of subplots
  ##   - index          - vector indexing sub.plots and subsequent variables 
  ##   - x              - x coordinates of subplots
  ##   - y              - y coordinates of subplots
  ##   - size.x         - size each of subplots (supports scalar value)
  ##   - size.y         - size each of subplots (supports scalar value)
  ##                      (optional, if neglected defaults size.x)
  ##
  ## OUTPUT:
  ##   - ggplot object
  ##
  ## ########################################################################
  if(length(size.x) == 1)
    size.x <- rep(size.x, length(index))
  if(length(size.y) == 1)
    size.y <- rep(size.y, length(index))
  
  if(length(x) != length(y) | length(y) != length(index) |
     length(y) != length(size.x))
    stop("Length of index, X, Y, or size do not match")

  plot.size <- max(get.Plot.Size(main.plot)[1, ])
  
  for(i in na.omit(match(names(sub.plots), index))) {
    main.plot <- main.plot +
      annotation_subplot(sub.plots[[as.character(index[i])]],
                         x[i],
                         y[i],
                         c(size.x[i], size.y[i]) * plot.size)
  }
  
  return(main.plot)
}


## ##########################################################################
## Legend Functions
## ##########################################################################
annotation_legend <- function(main.plot, legend.plot, x, y) {
  ## ########################################################################
  ## ANNOTATION_LEGEND(MAIN.PLOT, LEGEND.PLOT, X, Y)
  ## Adds a legend from one plot to another
  ##
  ## PARAMETERS:
  ##   - main.plot      - ggplot where the legend will be added
  ##   - legend.plot    - ggplot with a legend
  ##   - x              - location of legend (normalized 0-1)
  ##   - y
  ##
  ## OUTPUT:
  ##   - ggplot
  ##
  ## ########################################################################
  legend.plot <- get.Legend(legend.plot)
  legend.loc <- Plot.Position.Convert(main.plot,
                                      c(x, y) * 2 - c(1, 1))
  legend.plot$name <- paste(legend.plot$name, sample.int(10^9, 1))
  annotation_custom(legend.plot,
                    xmin = legend.loc[1],
                    ymin = legend.loc[2])
}

get.Legend <- function(plot) {
  ## ########################################################################
  ## GET.LEGEND(PLOT)
  ## Gets the legend grobs of a plot.  Each scale has its own grob.  If the user
  ## does not split them further, all scales will be subsequently plotted.
  ##
  ## PARAMETERS:
  ##   - plot           - a ggplot object
  ##
  ## OUTPUT:
  ##   - grob
  ##
  ## ########################################################################
  tmp <- ggplot_gtable(ggplot_build(plot)) 
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]] 
  return(legend)
}

Plot.Legend.Fill <- function(label, color, title = NULL,
                             title.size = 20,
                             text.size = 14,
                             key.size = 0.035,
                             bg.color = "black",
                             text.color = "white") {
  ## ########################################################################
  ## PLOT.LEGEND.FILL(LABEL, COLOR, TITLE = NULL, TITLE.SIZE = 20,
  ##    TEXT.SIZE = 14, KEY.SIZE = 0.035, BG.COLOR = "BLACK",
  ##    TEXT.COLOR = "WHITE")
  ## Creates a Fill legend for adding to multi-plots.  Only the main options are
  ## included in this function, however one may add / override options using +
  ## THEME()
  ##
  ## PARAMETERS:
  ##   - label          - fill labels
  ##   - color          - fill colors
  ##   - title          - legend title
  ##   - title.size     - title size
  ##   - text.size      - label size
  ##   - key.size       - fill blob size
  ##   - bg.color       - background color (black)
  ##   - text.color     - text color (white)
  ##
  ## OUTPUT:
  ##   - ggplot
  ##
  ## ########################################################################
  this.plot <- qplot(x = seq_along(label),
                     fill = factor(label, levels = label),
                     geom = "bar",
                     binwidth = 1)
  this.plot <- this.plot +
    scale_fill_manual(values = color)
  this.plot <- this.plot +
    guides(fill = guide_legend(title = title,
             title.vjust = 5))
  this.plot <- this.plot + 
    theme(legend.position =     c(.5, .5),
          legend.background =   element_rect(color = bg.color,
            fill = bg.color, size = 10),
          legend.key =          element_rect(colour = bg.color, size = 3),
          legend.title =        element_text(size = title.size,
            color = text.color),
          legend.text =         element_text(size = text.size,
            color = text.color),
          legend.key.size =     unit(key.size, "npc"),
          panel.border =        element_rect(linetype = "dashed",
              colour = "white", size = 0),
          axis.text =          element_blank(),
          axis.title =         element_blank(),
          panel.background =   element_blank(),
          panel.grid.major =   element_blank(),
          panel.grid.minor =   element_blank(),     
          axis.ticks.length =  unit(0, "cm"),
          axis.ticks.margin =  unit(0.01, "cm"),
          panel.margin =       unit(0, "lines"),
          plot.margin =        unit(c(0, 0, -.5, -.5), "lines"),
          plot.background =    element_blank())
  this.plot
}
