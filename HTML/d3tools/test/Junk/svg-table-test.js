function createSVG(id, margin, size) {
    d3.select(id).selectAll("svg").remove();
    
    var c = {};

    var svg = d3.select(id).append("svg")
        .attr("width", size[0])
        .attr("height", size[1])
        .append("g")
        .attr("transform", 
              "translate(" + 
              margin.left + "," + 
              margin.top + ")");
    
    c.id = id;
    
    c.width = size[0] - margin.left - margin.right;
    c.height = size[1] - margin.top - margin.bottom; 
    c.margin = margin;
    
    svg.custom = c;
    
    return svg;
}

var data1 = [{row: "0", column: "0", text: "R0 C0", fill: "red"},
             {row: "1", column: "0", text: "R1 C0", fill: "blue"},
             {row: "0", column: "1", text: "R0 C1", fill: "white"},
             {row: "1", column: "1", text: "R1 C1", fill: "grey"}];

var data2 = [{row: "0", column: "0", text: "1", fill: "red"},   
             {row: "1", column: "0", text: "2", fill: "blue"},  
             {row: "0", column: "1", text: "R0 C1", fill: "white"}, 
             {row: "1", column: "1", text: "4", fill: "grey"}]; 

var data4 = [{row: "0", column: "0", text: "10", fill: "red"},
             {row: "1", column: "0", text: "2", fill: "blue"},
             {row: "0", column: "1", text: "30", fill: "orange"},
             {row: "1", column: "1", text: "4", fill: "white"}];

var data3 = [{row: "0", column: "0", text: "R0 C0", fill: "red"},
             {row: "1", column: "0", text: "R1 C0", fill: "blue"},
             {row: "0", column: "1", text: "R0 C1", fill: "orange"},
             {row: "1", column: "1", text: "R1 C1", fill: "white"},
             {row: "2", column: "0", text: "R2 C0", fill: "pink"},
             {row: "2", column: "1", text: "R2 C1", fill: "pink"}];

var columnScale = new ArbitraryDiscreteScale(200, 150);
var rowScaleInitial = new ArbitraryDiscreteScale(20, 40, 30);
var rowScaleSwap = new ArbitraryDiscreteScale(20, 40, 30);
var rowScaleShrink = new ArbitraryDiscreteScale(20, 20, 30);

rowScaleSwap.Swap(0, 1);

var rowScale = rowScaleSwap;

var svg = createSVG("#table", 
                    {top: 0, right: 0, bottom: 0, left: 0}, 
                    [400, 400]);



UpdateTable = function(svg, data, x) {
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
        .style("fill-opacity", 1e-6);
    
    text.enter().append("text")
	.attr("x", function(d) {return columnScale.End(d.column) - 10 - 20;})
        .attr("y", function(d) {return rowScale.Center(d.row);})
        .attr("font-size", function(d) {return rowScale.Size(d.row);})
        .attr("dy", ".35em")
        .attr("text-anchor", "end")
        .text(function(d) {return d.text})
        .style("fill-opacity", 1e-6);
    
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
        .attr("x", function(d) {return columnScale.End(d.column) - 10;})
        .attr("y", function(d) {return rowScale.Center(d.row);})
        .attr("font-size", function(d) {return rowScale.Size(d.row);})
        .attr("dy", ".35em")
        .style("fill-opacity", 1)
        .attr("text-anchor", "end")
    	.text(function(d) {return d.text});
    
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

