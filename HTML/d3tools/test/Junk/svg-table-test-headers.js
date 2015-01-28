var dataField = [{row: "0", column: "0", text: "R0 C0", fill: "red"},
		 {row: "1", column: "0", text: "R1 C0", fill: "blue"},
		 {row: "0", column: "1", text: "R0 C1", fill: "orange"},
		 {row: "1", column: "1", text: "R1 C1", fill: "white"},
		 {row: "2", column: "0", text: "R2 C0", fill: "pink"},
		 {row: "2", column: "1", text: "R2 C1", fill: "pink"}];

var dataField2 = [{row: "0", column: "0", text:"$1.23", fill: "red"},
		 {row: "1", column: "0", text: "$1.23" 	, fill: "blue"},
		 {row: "0", column: "1", text: "$1.23" 	, fill: "orange"},
		 {row: "1", column: "1", text: "$1.23" 	, fill: "white"},
		 {row: "2", column: "0", text: "$1.23" 	, fill: "pink"},
		 {row: "2", column: "1", text: "$1.23" 	, fill: "pink"}];

var dataLeft = [{row: "0", column: "0", text: "Line 1"},
                {row: "1", column: "0", text: "Line 2"},
                {row: "2", column: "0", text: "Line 3"}];

var dataTop = [{row:"top", column: ["0", "1"], text: "Title"},
               {row:"bottom", column: "0", text: "Column 1"},
               {row:"bottom", column: "1", text: "Column 2"}];


var columnScale = new ArbitraryDiscreteScale(200, 200);
var rowScale = new ArbitraryDiscreteScale(40, 40, 40);

var topRowScale = new ArbitraryDiscreteScale(60, 40, 'top', 'bottom');
var leftColumnScale = new ArbitraryDiscreteScale(100);




function UpdateTable(svg, data, rowScale, columnScale, xOff, yOff, id) {
    xOff = xOff || 0;
    yOff = yOff || 0;
    
    // Bind
    var text = svg.selectAll(id) 
    text = text.selectAll("text")
        .data(data, 
              function(d) {return (d.row + "-" + d.column + "-" + d.text); });
    
    var rect = svg.selectAll(id)
    rect = rect.selectAll("rect")
        .data(data, 
              function(d) {return (d.row + "-" + d.column + "-" + d.text); });
    
    // Enter
    rect.enter().append("rect")
        .attr("x", function(d) {
	    return columnScale.Start(d.column) - 20 + xOff;})
        .attr("y", function(d) {
	    return rowScale.Start(d.row) + yOff;})
        .attr("width", function(d) {return columnScale.Size(d.column) - 2;})
        .attr("height", function(d) {return rowScale.Size(d.row) - 2;})
        .style("fill", function(d) {return d.fill;})
        .style("fill-opacity", 1e-6);
    
    text.enter().append("text")
        .attr("x", function(d) {
	    return columnScale.Center(d.column) - 10 - 20 + xOff;})
        .attr("y", function(d) {
	    return rowScale.Center(d.row) + yOff;})
        .attr("font-size", function(d) {return rowScale.Size(d.row) * 3 / 4;})
        .attr("dy", ".35em")
        .attr("text-anchor", "middle")
        .text(function(d) {return d.text})
        .style("fill-opacity", 1e-6);
    
    // Update
    rect.transition().duration(1000)
        .attr("x", function(d) {
            return columnScale.Start(d.column) - 20 + xOff;})
        .attr("y", function(d) {
            return rowScale.Start(d.row) + yOff;})
        .attr("width", function(d) {return columnScale.Size(d.column) - 2;})
        .attr("height", function(d) {return rowScale.Size(d.row) - 2;})
    // .style("fill", function(d) {return d.fill;})
        .style("fill-opacity", 0.5);
    
    text.transition().duration(1000)
    // .style("fill-opacity", 1e-6)
    // .transition().duration(500)
        .attr("x", function(d) {
            return columnScale.Center(d.column) - 10 + xOff;})
        .attr("y", function(d) {
            return rowScale.Center(d.row) + yOff;})
    // .attr("font-size", function(d) {return rowScale.Size(d.row);})
        .style("fill-opacity", 1)
        .text(function(d) {return d.text});
    
    // Exit
    rect.exit().transition().duration(1000)
        .style("fill-opacity", 1e-6)
	.attr("x", function(d) {return columnScale.Start(d.column) + 
				20 + xOff;})
        .remove();
    
    text.exit().transition().duration(1000)
        .style("fill-opacity", 1e-6)
	.attr("x", function(d) {return columnScale.Center(d.column) + 
				20 + xOff;})
	.remove();
}

function UpdateAll(d) {
    UpdateTable(svg, dataTop, topRowScale, columnScale,
		leftColumnScale.sizeContinous, 0,
		"#table-top");
    UpdateTable(svg, dataLeft, rowScale, leftColumnScale, 
                0, topRowScale.sizeContinous,
		"#table-left");
    UpdateTable(svg, d, rowScale, columnScale,
		leftColumnScale.sizeContinous, topRowScale.sizeContinous,
		"#table-field");
    
    svg.selectAll("#table-left text").on("click", function() {
	var l = [0, 1, 2];
        var s1 = l[Math.floor(Math.random() * 3)]
        var s2 = _.without(l, s1)[Math.floor(Math.random() * 2)]
        rowScale.Swap(s1, s2);
	UpdateAll(d);
    });

    svg.selectAll("#table-top text").on("click", function() {
        columnScale.Swap(0, 1);
        UpdateAll(d);
    });
    
    svg.selectAll("#table-field text").on("click", function() {
        UpdateAll(d == dataField2 ? dataField : dataField2);
    });
    
}
