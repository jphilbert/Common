d3Tools = function() {
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
    
    function cutText(obj, bWidth, bHeight, minFontSize){
	/*************************************************************
	 * Cuts a d3 text object in a pieces to fit into a box
	 *		bWidth           width of 'text' box
	 *		bHeight          height of 'text' box
	 *		minFontSize      (optional) minimum font size
	 *
	 * USAGE:
	 *  d3.selectAll("text").each(function(d) {
         *         d3Tools.cutText(this, 100, 50, 5);})
	 *************************************************************/
	var el = d3.select(obj);
	var text = el.text();
	minFontSize = minFontSize || 10;
	
	// Text Size
	var tHeight = obj.getBBox().height;
	var tWidth = obj.getBBox().width;
        
	
	// if the text width is larger we need to wrap 
	// however if it appears to be already split (contains breaks), skip
	if(tWidth > bWidth && text.search('\n') < 0) {
            // Calculate the optimal number of lines
            var n = Math.sqrt((tWidth / tHeight) * (bHeight / bWidth));
	    
            // Calculate the optimal font scaling
            var scale = tHeight / bHeight / (n + 1);
	    
            // If the font is to small, recalculate
            if(Math.floor(scale * bHeight) < minFontSize) {
	    	scale = _.max([minFontSize / bHeight, 1]);          
	    	n = (tWidth / bWidth) * scale;
            }
            
            // Set The text
            el.text(wordwrap(text, Math.floor(text.length / n), "\n"));
	}
    }
    
    function optimizeTextSize(obj, bHeight, minFontSize, longLineSuffix) {
	/**********************************************************************
	 * Optimizes multi-line text size to fit in a box.  If the minimum font
	 * size is specified and is larger, this will truncate the text and
	 * change the objects font size (this is required since INSERTLINEBREAKS
	 * will not fix the size if it ends up being a single line)
	 *
         *     bHeight		- (optional) height of box
	 *			   if omitted, uses the textBB
         *     minFontSize	- (optional) minimum font size
         *                         if omitted, uses 10
         *     longLineSuffix   - (optional) if lines need to be trimmed, 
	 *			   append this to the last line
	 *
	 *
	 * USAGE:
	 *   Typically use in conjunction with insertLineBreaks
	 *	svg.selectAll("text").each(function(d, i) {
	 *	  var h = d3Tools.optimizeTextSize(this, 50, 10, "...")
	 *	  d3Tools.insertLineBreaks(this, h);})
	 *
	 *********************************************************************/
	var el = d3.select(obj);
	var lines = el.text().split('\n');
	minFontSize = minFontSize || 10;
        var fontSize = em2px(el.attr("font-size"));
        minFontSize = _.min([minFontSize, fontSize]);
        longLineSuffix = longLineSuffix || "";
        
	
	// Only do something if there are more than one line
	if(lines.length > 1) {
            bHeight || obj.getBBox().height;
	    
            var maxLines = lines.length;
	    
	    // Shrink ONLY
            fontSize = _.min([fontSize, Math.floor(bHeight / maxLines)]);

            // Fix long paragraphs
            if(fontSize < minFontSize) {
		var maxLines = Math.floor(bHeight / minFontSize);
                fontSize = minFontSize;
		
		// append ellipsis
		lines[maxLines-1] = lines[maxLines-1].trim() + longLineSuffix;
                el.text(_.head(lines, maxLines).join("\n"));
                el.attr("font-size", fontSize);
            }
	}
	
	return fontSize;
    }
    
    function insertLineBreaks(obj, newFontSize) {
        /*************************************************************
         * Correctly inserts line breaks in a d3 object
         *	newFontSize	- (optional) new font size
	 *			  if omitted, uses the existing
         *
         * USAGE:
         *  d3.selectAll("text").each(function(d, i) {
         *          insertLineBreaks(this, 5);})
         *
         *************************************************************/
        var el = d3.select(obj);
        var lines = el.text().split('\n');
	
        // Only do something if there are more than one line
        if(lines.length > 1) {
	    
            var xCurrent = +d3.select(obj).attr("x");
            var yCurrent = +d3.select(obj).attr("y");    
	    
	    
            var textAnchor = el.attr("text-anchor") || "start"; 
            var lastLength = 0;
            var currentLength = 0;
	    
            var maxLines = lines.length;
            var fontSize = newFontSize || el.attr("font-size");
            var textOffset = em2px(el.attr("dy"), fontSize);
	    
            // Set font size, anchor, and clear text
            el.attr("font-size", fontSize)
                .attr("text-anchor", "start")
                .text('');
	    
            // Transfer the offset to the TSPANS
	    if(textOffset == fontSize) {	// Top Aligned (dy = 1em)
                textOffset = fontSize;
	    }
	    else if(textOffset) {		// Center Aligned (dy = 0.35em)
                textOffset = -textOffset / 2 - ((maxLines - 2) * fontSize)/2;
                textOffset = Math.round(textOffset);
	    }
	    else{				// Bottom Aligned (dy = null)
                textOffset = -(maxLines - 1) * fontSize;
	    }
	    
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
		    tspan.attr('dx', -Math.floor((currentLength +
						  lastLength)/2));
		    break;
		}
		lastLength = tspan.node().getComputedTextLength(); 
	    }
	}
    }

    function wrapText(obj, boxWidth, boxHeight, minFontSize, longLineSuffix) {
        cutText(obj, boxWidth, boxHeight, minFontSize);
        var h = optimizeTextSize(obj, boxHeight, minFontSize,
    					 longLineSuffix);
        insertLineBreaks(obj, h);
    }
    
    return {wordwrap: wordwrap,
	    em2px: em2px,
	    px2em: px2em,
            // cutText: cutText,
            // optimizeTextSize: optimizeTextSize,
	    // insertLineBreaks: insertLineBreaks,
            wrapText: wrapText};
}();