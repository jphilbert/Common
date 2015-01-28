function wordwrap( str, width, brk, cut ) {
    /*************************************************************
     * Converts em to pixels
     *          str             string 
     *          width		max width (in characters) 
     *				(optional = 75)
     *		brk		seperator (optional = '\n')
     *
     * Wraps STR by inserting BRK such that the max character length 
     * per line is WIDTH
     *
     * CITE:
     * James Padolsey
     * http://james.padolsey.com/javascript/wordwrap-for-javascript
    *************************************************************/
    brk = brk || '\n';
    width = width || 75;
    cut = cut || false;
    
    if (!str) { return str; }
    
    var regex = '.{1,' +width+ '}(\\s|$)' + 
        (cut ? '|.{' +width+ '}|.+$' : '|\\S+?(\\s|$)');
    
    return str.match( RegExp(regex, 'g') ).join( brk );
}

function em2px(em, fontSize) {
    /*************************************************************
     * Converts em to pixels
     *          em               em width (text/numeric) 
     *          fontSize         base font size (optional = 16)
     *
     * Returns the numeric size in pixels.
     * If already in pixels (containing 'px' suffix), returns the 
     * numeric part.
     *************************************************************/
    fontSize = fontSize || 16;
    
    if(_.isString(fontSize)) 
        fontSize = em2px(fontSize);

    if(_.isString(em) && em.split("em").length > 1)
        return em.split("em")[0] * fontSize;
    else if(_.isString(em)) 
        em = +em.split("px")[0];
    
    return(em);
}

function px2em(px, fontSize) {
    /*************************************************************
     * Converts pixels to em
     *          px               pixel width (text/numeric) 
     *          fontSize         base font size (optional = 16)
     *
     * Returns the numeric size in em.
     * If already in em (containing 'em' suffix), returns the 
     * numeric part.
     *************************************************************/
    fontSize = fontSize || 16;

    if(_.isString(fontSize)) 
        fontSize = em2px(fontSize);
    
    if(_.isString(px) && px.split("em").length > 1)
        return +px.split("em")[0];
    else if(_.isString(px)) 
        px = +px.split("px")[0];
    
    return(px/fontSize);    
}

function wrapLongLines(bWidth, bHeight, minFontSize){
    /*************************************************************
     * Wraps a text in a d3 object
     *
     *		bWidth           width of 'text' box
     *		bHeight          height of 'text' box
     *		minFontSize      (optional) minimum font size
     *
     * USAGE:
     *  d3.selectAll("text").each(function(d) {
     *          wrapLongLines.call(this,
     *                          columnScale.Size(d.column),
     *                          rowScale.Size(d.row),   
     *                          5);})
     *************************************************************/
    var el = d3.select(this);
    var text = el.text();
    minFontSize = minFontSize || 10;
    
    // Text Size
    var tHeight = this.getBBox().height;
    var tWidth = this.getBBox().width;
    
    // if the text width is larger we need to wrap 
    // however if it appears to be already split (contains breaks), skip
    if(tWidth > bWidth && text.search('\n') < 0) {
        // Calculate the optimal number of lines
        var n = Math.sqrt((tWidth / tHeight) * (bHeight / bWidth));
        // Calculate the optimal font scaling
        var scale = tHeight / bHeight / (n + 1);
        
        // If the font is to small, recalculate
        if(Math.floor(scale * bHeight) < minFontSize) {
            scale = minFontSize / bHeight;          
            n = tHeight / bHeight / scale;
        }
        
        // Set The text
        el.text(wordwrap(text, Math.floor(text.length / n), "\n"));
    }
}

function insertLineBreaks(d, i, minFontSize) {
    /*************************************************************
     * Correctly inserts line breaks in a d3 object
     *
     * bWidth           width of 'text' box
     * bHeight          height of 'text' box
     * minFontSize      (optional) minimum font size
     *
     * USAGE:
     *  d3.selectAll("text").each(insertLineBreaks)
     *
     *                  --OR--
     *
     *  d3.selectAll("text").each(function(d, i) {
     *          insertLineBreaks.call(this, d, i, 5);})
     *
     *************************************************************/
    var el = d3.select(this);
    var lines = el.text().split('\n');
    minFontSize = minFontSize || 10;
    
    // Only do something if there are more than one line
    if(lines.length > 1) {
	
        var xCurrent = +d3.select(this).attr("x");
        var yCurrent = +d3.select(this).attr("y");    
        
        var textOffset = em2px(el.attr("dy"), el.style("font-size"));
        var textAnchor = el.attr("text-anchor");
        var bHeight = this.getBBox().height;
        var lastLength = 0;
        var currentLength = 0;
        
        var maxLines = lines.length;
        var fontSize = Math.floor(bHeight / maxLines);

        // Fix long paragraphs
        if(fontSize < minFontSize) {
            maxLines = Math.floor(bHeight / minFontSize) - 1;
            fontSize = Math.floor(bHeight / (maxLines + 1));
            // append ellipsis
            lines[maxLines-1] = lines[maxLines-1].trim() + '...';
        }
        
        // Set font size, anchor, and clear text
        el.attr("font-size", fontSize)
            .attr("text-anchor", "start")
            .text('');
        
        // Transfer the offset to the TSPANS
        textOffset += -(maxLines-1) * fontSize;
        textOffset = Math.round(textOffset);
        
        // Loop through lines
        for (var i = 0; i < maxLines; i++) {
            var tspan = el.append('tspan').text(lines[i].trim());
            
            if (i == 0)         // Shift the first line
                tspan.attr('dy', textOffset);
            else                // ... or offset the subsequent lines
                tspan.attr('dy', fontSize);
            
            // Align the text horizontally
            currentLength = tspan.node().getComputedTextLength();
            switch(textAnchor) {
            case "end":
                tspan.attr('dx', -currentLength);               
                break;
            case "start":
                tspan.attr('dx', -lastLength);
                break;
            case "middle":
                tspan.attr('dx', -Math.floor((currentLength + lastLength)/2));
                break;
            }
            lastLength = tspan.node().getComputedTextLength(); 
        }
    }
}