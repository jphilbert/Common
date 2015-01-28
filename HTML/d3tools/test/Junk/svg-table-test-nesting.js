var data1 = {
    data: [{row: "0", column: "0", text: "X", fill: "red"},
           {row: "1", column: "0", text: "O", fill: "blue"},
           {row: "2", column: "0", text: "X", fill: "red"},
           {row: "1", column: "2", text: "O", fill: "blue"}],
    columnScale: new ArbitraryDiscreteScale(40, 40, 40),
    rowScale: new ArbitraryDiscreteScale(40, 40, 40)};

var data2 = {
    data: [{row: "2", column: "2", text: "X", fill: "red"},
           {row: "1", column: "2", text: "O", fill: "blue"},
           {row: "2", column: "1", text: "X", fill: "red"},
           {row: "1", column: "0", text: "O", fill: "blue"}],
    columnScale: new ArbitraryDiscreteScale(40, 40, 40),
    rowScale: new ArbitraryDiscreteScale(40, 40, 40)};

var data3 = {
    data: [{row: "2", column: "0", text: "X", fill: "red"},
           {row: "1", column: "0", text: "O", fill: "blue"},
           {row: "2", column: "1", text: "X", fill: "red"},
           {row: "2", column: "2", text: "O", fill: "blue"}],
    columnScale: new ArbitraryDiscreteScale(40, 40, 40),
    rowScale: new ArbitraryDiscreteScale(40, 40, 40)};

var dataMain = {
    data: [{row: "0", column: "2", subTable: data1},
           {row: "1", column: "0", subTable: data2},
           {row: "2", column: "1", subTable: data3}],
    columnScale: new ArbitraryDiscreteScale(
	 data1.columnScale.size, 
         data2.columnScale.size,
         data3.columnScale.size),
     rowScale: new ArbitraryDiscreteScale(
         data1.rowScale.size, 
         data2.rowScale.size,
         data3.rowScale.size)}; 

data1.style = function(obj, objType, time) {
    time = time || "enter";    
    var thisObj;
    var off = 0;
    
    var parent = this;
    
    console.log(objType);
    console.log(parent.xOff);
    
    switch(time) {
    case "enter":
        off = -20;
        thisObj = obj.enter().append(objType)
            .style("fill-opacity", 1e-6);
        time = "update";
        break;
    case "exit":
        off = 20;
        thisObj = obj.exit().transition().duration(1000)
            .style("fill-opacity", 1e-6);
        time = "complete";
        break;
    default:
        thisObj = obj.transition().duration(1000)
            .style("fill-opacity", 1);
        time = "exit";
    }
    
    if(objType == "rect") {
        thisObj.attr("x", function(d) {
            return parent.columnScale.Start(d.column) + parent.xOff + off;})
            .attr("y", function(d) {
                return parent.rowScale.Start(d.row) + parent.yOff;})
            .attr("width", function(d) {
                return parent.columnScale.Size(d.column);})
            .attr("height", function(d) {
                return parent.rowScale.Size(d.row);})
            .style("fill", function(d) {
                return d.fill;})
    }
    else {
        thisObj.attr("x", function(d) {
            return parent.columnScale.Center(d.column) + 
                parent.xOff + off;})
            .attr("y", function(d) {
                return parent.rowScale.Center(d.row) + parent.yOff;})
            .attr("font-size", function(d) {
                return parent.rowScale.Size(d.row) * 3 / 4;})
            .attr("dy", ".35em")
            .attr("text-anchor", "middle")
            .text(function(d) {return d.text;})
    }
    
    if(time == "complete") 
        return(thisObj);
    else
        return(parent.style(obj, objType, time));
}    

data3.style = data2.style = data1.style;

function UpdateTable(svg, thisData, id) {
    function UpdateSingle(svg, table, id) {
        if(_.filter(table.data, function(x) {return(x.text);}).length == 0)
	    return null;
	
	console.log(table);
	
        // Bind
        var text = id ? svg.selectAll(id) : svg
        text = text.selectAll("text")
            .data(table.data, function(d) {
		return (d.row + "-" + 
			d.column + "-" + d.text); 
	    });
	
        var rect = id ? svg.selectAll(id) : svg
        rect = rect.selectAll("rect")
            .data(table.data, function(d) {
		return (d.row + "-" + d.column); 
	    });
	
        table.style(rect, "rect");
        table.style(text, "text");
    }
    
    function UpdateNest(svg, table, id) {
        if( _.filter(table.data, function(x) {return(x.subTable);}).length == 0)
            return null;
	
	console.log(table);

	var thisGroup = id ? svg.selectAll(id) : svg 
	id = id || "";
	
	thisGroup = svg.selectAll("g")
            .data(table.data, 
		  function(d) {
		      return ("r" + d.row + "-" + "c" + d.column); 
		  });
	
	thisGroup.enter()
	    .append("g")
            .attr("id", function(d, i) {
		return ("r" + d.row + "-" + "c" + d.column); 
	    });
	
        table.data.forEach(function(x) {
            x.subTable.xOff = thisData.columnScale.Start(x.column) + 
		(table.xOff || 0);
            x.subTable.yOff = thisData.rowScale.Start(x.row) + 
                (table.yOff || 0);
            UpdateTable(svg, 
			x.subTable,
                        "#r" + x.row + "-" + "c" + x.column);
	}); 
	
	thisGroup.exit().remove();
    }
    
    UpdateNest(svg, thisData, id);
    UpdateSingle(svg, thisData, id);
}
