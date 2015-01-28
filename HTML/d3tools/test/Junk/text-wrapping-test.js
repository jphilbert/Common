// Test Data
// This data has line breaks already
var data4 = [{row: "0", column: "0", text: "10", fill: "red"},
             {row: "1", column: "0", 
              text: "The quick brown fox\n jumped over the lazy\n dog. \n and then the fox died.", 
              fill: "blue"},
             {row: "0", column: "1", 
text: "The quick brown fox\n jumped over the lazy\n dog.", fill: "orange"},
             {row: "1", column: "1", text: "4", fill: "white"}];

// This data has does not
var data5 = [{row: "0", column: "0", text: "10", fill: "red"},
             {row: "1", column: "0", 
              text: "The quick brown fox jumped over the lazy dog and then the fox died, but the dog lived happily ever after so they say, YO YO YO YO YO YO YO YO YO YO YO YO YO YO YO YO YO YO YO YO", 
              fill: "blue"},
             {row: "0", column: "1", 
              text: "The quick brown fox jumped over the lazy dog and then the fox died.",
	      fill: "orange"},
             {row: "1", column: "1", text: "4", fill: "white"}];


function UpdateTable(svg, data, x) {
    // Bind
    var text = svg.selectAll("text")
        .data(data, 
	      function(d) {return (d.row + "-" + d.column + "-" + d.text); });
    var rect = svg.selectAll("rect")
        .data(data,
	      function(d) {return (d.row + "-" + d.column); });
    
    // Enter
    rect.enter().append("rect")
        .attr("x", function(d) {return columnScale.Start(d.column) - 20;})
        .attr("y", function(d) {return rowScale.Start(d.row);})
        .attr("width", function(d) {return columnScale.Size(d.column) - 2;})
        .attr("height", function(d) {return rowScale.Size(d.row) - 2;})
        .style("fill", function(d) {return d.fill;})
        .style("fill-opacity", 1e-6)
    
    text.enter().append("text")
        .attr("x", function(d) {return columnScale.Center(d.column) - 20;})
        .attr("y", function(d) {return rowScale.Center(d.row);})
        .attr("font-size", function(d) {return rowScale.Size(d.row);})
        .attr("dy", "0.3em")
        .attr("text-anchor", "middle")
        .text(function(d) {return d.text})
        .each(function(d, i) {
	    wrapLongLines.call(this,
			       columnScale.Size(d.column),
			       rowScale.Size(d.row),
			       x);})
            .each(function(d, i) {insertLineBreaks.call(this, d, i, x);})
		
		// Update
		rect.transition().duration(1000)
        .attr("x", function(d) {return columnScale.Start(d.column);})
        .attr("y", function(d) {return rowScale.Start(d.row);})
        .attr("width", function(d) {return columnScale.Size(d.column) - 2;})
        .attr("height", function(d) {return rowScale.Size(d.row) - 2;})
        .style("fill", function(d) {return d.fill;})
        .style("fill-opacity", 0.5);
    
    text.transition().duration(1000)
    // .style("fill-opacity", 1e-6)
    // .transition().duration(500)
        .attr("x", function(d) {return columnScale.Center(d.column);})
        .attr("y", function(d) {return rowScale.Center(d.row);})
    // .attr("dy", -2)
    // .attr("font-size", function(d) {return rowScale.Size(d.row);})
    // .attr("dy", ".35em")
        .style("fill-opacity", 1)
    // .attr("text-anchor", "end");
    // .text(function(d) {return d.text});
    
    
    
    // Exit
    rect.exit().transition().duration(1000)
        .style("fill-opacity", 1e-6)
        .attr("x", function(d) {return columnScale.Start(d.column) + 20;})
        .remove();
    
    text.exit().transition().duration(1000)
        .style("fill-opacity", 1e-6)
        .attr("x", function(d) {return columnScale.End(d.column) + 20;})
	.remove();
    
    // return(w)
}

var svg = createSVG("#table", 
                    {top: 0, right: 0, bottom: 0, left: 0}, 
                    [400, 400]);

var columnScale = new ArbitraryDiscreteScale(200, 150);
var rowScaleInitial = new ArbitraryDiscreteScale(20, 40, 30);