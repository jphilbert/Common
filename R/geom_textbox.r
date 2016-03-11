#############################################################################
## GEOM_TEXTBOX.R
##   Creates a text box geometry for ggplot2  
##
## AUTHOR:	John P. Hilbert
## CREATED:	2013-04-26
## MODIFIED:	2013-04-26
## 
## SUMMARY:
##   Similar to GEOM_TEXT, this script produces GEOM_TEXTBOX which has added
##   variables BG.FILL, BG.COLOR, BG.ALPHA for the text background.  This has
##   been altered from http://pastebin.com/DuNYy2gT.
##
## REVISIONS:
##   1) <NONE>
##
## TO DO:
##   - the options of the box are currently static (not an aesthetic)
##   - there layers are not in the correct order in that the boxes are plotted
##     first then the text.  this creates odd overlaps
##
## INPUT:
##   PACKAGES / SCRIPTS:
require(ggplot2)
require(proto)
##
## OUTPUT:
##   FUNCTIONS:
##   - btextGrob
##   - geom_textbox
## 
## EXAMPLES:
## qplot(wt, mpg, data = mtcars, label = rownames(mtcars), size = wt) +
##   geom_textbox(color = "black",
##                bg.fill = "white",
##                bg.alpha = 0.5,
##                bg.color = "purple")
##
#############################################################################


btextGrob <- function(label, x = unit(0.5, "npc"), y = unit(0.5, "npc"),
                      just = "center", hjust = NULL, vjust = NULL, rot = 0,
                      check.overlap = FALSE, default.units = "npc",
                      name = NULL, gp = gpar(), vp = NULL, f = 1.5,
                      fill = NA, alpha = 0.3, color = NA) {
  if (!is.unit(x))
    x <- unit(x, default.units)
  if (!is.unit(y))
    y <- unit(y, default.units)
  grob(label = label, x = x, y = y, just = just, hjust = hjust,
       vjust = vjust, rot = rot, check.overlap = check.overlap,
       name = name, gp = gp, vp = vp, cl = "text")
  tg <- textGrob(label = label, x = x, y = y, just = just, hjust = hjust,
                 vjust = vjust, rot = rot, check.overlap = check.overlap)
  w <- unit(rep(1, length(label)), "strwidth", as.list(label))
  h <- unit(rep(1, length(label)), "strheight", as.list(label))
  rg <- rectGrob(x=x, y=y, width=f*w, height=f*h,
                 gp = gpar(fill=fill, alpha=alpha, col=color))
  gTree(children=gList(rg, tg), vp=vp, gp=gp, name=name)
}


GeomTextBox <- proto(ggplot2:::GeomText, {
  objname <- "textbox"

  draw <- function(., data, scales, coordinates, ...,
                   parse = FALSE, na.rm = FALSE,
                   bg.fill = "white", bg.color = NA, bg.alpha = 0.3) {
    data <- remove_missing(data, na.rm, c("x", "y", "label"),
                           name = "geom_textbox")

    lab <- data$label
    if (parse) {
      lab <- parse(text = lab)
    }

    with(coord_transform(coordinates, data, scales),
         btextGrob(lab, x, y, default.units="native",
                   hjust=hjust, vjust=vjust, rot=angle,
                   gp = gpar(col = alpha(colour, alpha),
                     fontsize = size * .pt,
                     fontfamily = family, fontface = fontface,
                     lineheight = lineheight),
                   fill = bg.fill,
                   color = bg.color,
                   alpha = bg.alpha)
         )
  }
  
})

geom_textbox <- function(mapping = NULL, data = NULL, stat = "identity",
                         position = "identity", parse = FALSE,
                         ...) {
  GeomTextBox$new(mapping = mapping, data = data, stat = stat,
                  position = position, parse = parse,
                  ...)
}

environment(GeomTextBox) <- environment(ggplot2:::GeomText)
