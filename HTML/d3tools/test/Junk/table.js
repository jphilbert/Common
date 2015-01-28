tableData = [{row: "A", x: 10, y: 20}, {row: "B", x: 10/4 , y: 50}, 
{row: "C", x: 43 , y: 542}]

d3.select("table").remove();

var table = d3.select("#table").append("table")
    .style("border-collapse", "collapse")
    .style("border", "0px black solid"),
// .attr("style", "margin-left: 250px"),
thead = table.append("thead"),
tbody = table.append("tbody");

// append the header row
thead.append("tr")
    .selectAll("th")
    .data(_.keys(tableData[0]))
    .enter()
    .append("th")
    .style("font-size", "12px")
    .style("padding", "10px")
    .text(function(column) { return column; });

var rows = tbody.selectAll("tr")
    .data(tableData)	// Attach data to each row
    .enter()
    .append("tr");

var cells = rows.selectAll("td")
    .data(function(row) {
        return _.keys(tableData[0]).map(function(column) {
            return {column: column, value: row[column]};
        });
    }).enter().append("td")
    .style("border", "1px black solid")
    .style("padding", "2px")
    .text(function(d){return d.value;})

    .style("font-size", "10px");




tableData = [{row: "A", x: 10, y: 20}, {row: "B", x: 10/4 , y: 50}, 
             {row: "C", x: 0.001 , y: 123}]

rows = tbody.selectAll("tr")
    .data(tableData)

// rows.exit().transition().duration(1500).remove();


cells = rows.selectAll("td")
    .data(function(row) {
        return _.keys(tableData[0]).map(function(column) {
            return {column: column, value: row[column]};
	});
    });

cells = rows.selectAll("td")
    .data();


cells.transition().duration(1500)
    .style("color", "white")
    .transition().duration(150)
    .style("color", "black")
    .text(function(d){return d.value;});

