/***********************************************************************
  The Tick Class
***********************************************************************/
function ScaleTick(size) {
    this.label = "" ;
    this.position = 0;
    this.size = size;
    this.start = 0;
    this.end = size;
}

ScaleTick.prototype.compareTo = function(that) {
    return (this.position - that.position);
}

ScaleTick.prototype.equals = function(that) {
    switch(typeof(that)) {
    case "string": return(that == this.label);
    case "number": return(that == this.position);
	// Add comparison for a tick
    }
    return false;
}

ScaleTick.prototype.setPosition = function() {
    // If no arguments set this as the initial
    if(arguments.length == 0 || _.isUndefined(arguments[0])) {
        this.start = 0;
        this.position = 0; 
    }
    // Else set it after the given tick
    else {
        this.start = arguments[0].end;
        this.position = arguments[0].position + 1;
    }
    
    this.end = this.start + this.size;
    return (this);
}

ScaleTick.prototype.Clone = function() {
    var copy = new ScaleTick(0);
    
    for (var attr in this) {
	copy[attr] = this[attr];
    }
    return(copy);
}


/***********************************************************************
  The Transform Class
***********************************************************************/
function VariableDiscreteScale() {
    this.ticks = [];
    this.size = 0;
    this.length = 0;
    this.Add.apply(this, arguments);
}

VariableDiscreteScale.prototype.Add = function() {
    var labels, sizes;
    if(arguments.length == 1 && 
       typeof(arguments[0]) == "object") {
        labels = _.keys(arguments[0]);
        sizes = _.toArray(arguments[0]);
    }
    else {
        sizes = _.filter(arguments, 
			 function(x) {return(typeof(x) == "number");});
        labels = _.filter(arguments, 
                         function(x) {return(typeof(x) == "string");});
    }
    
    for(var i = 0; i < sizes.length; i++) {
        var val = new ScaleTick(sizes[i]);
	
	val.setPosition(this.ticks[this.length-1]);
	val.label = labels[i] || val.position.toString();
	
        if(this.ticks.length > 0 && 
	   _.some(this.ticks, function(x) {return(x.label == val.label);}))
            throw "Label Already Exists";
	
        this.ticks.push(val); 
        this.length++;
        this.size += sizes[i];        
    }
    return this;
}

VariableDiscreteScale.prototype.Delete = function() {
    var itemsToDelete;
    
    // Accept an array or multiple arguments
    if(arguments.length == 1 && 
       _.isArray(arguments[0])) {
        itemsToDelete = arguments[0];
    }
    else {
	itemsToDelete = arguments;
    }
    
    
    for(var i = 0; i < itemsToDelete.length; i++) {
	this.ticks = _.filter(this.ticks, function(x) {
	    return(!x.equals(itemsToDelete[i]));})
    };
    
    this.Recalculate();

    return(this);
}

VariableDiscreteScale.prototype.Insert = function(p, s, l){
    this.Add(s, l);
    this.ticks[this.length-1].position = p + 0.001;
    return(this.Sort());
}

VariableDiscreteScale.prototype.toString = function() {
    var output = "";
    this.ticks.forEach(function(x) {
	return(output += "| " + x.start + "-"
               + x.label + "-" + x.end + " |");});
    return(output);
}

VariableDiscreteScale.prototype.Recalculate = function() {
    this.length = this.ticks.length;
    
    for(var i = 0; i < this.length; i++) 
        this.ticks[i].setPosition(this.ticks[i-1]);
    
    this.size = this.ticks[this.length-1].end; 
    
    return(this);
}


/*******************************************************************************
   Position Methods
*******************************************************************************/
VariableDiscreteScale.prototype.Sort = function(f) {
    if(!_.isFunction(f))
        f = function(a, b) {return(a.position - b.position);}
    this.ticks.sort(f);
    this.Recalculate();
    return(this);
}

VariableDiscreteScale.prototype.Swap = function(i, j) {
    if(_.isString(i) || _.isString(j))
	return(this.Swap(this.getPosition(i), this.getPosition(j)));
    
    this.ticks[i].position = j;
    this.ticks[j].position = i;
    
    this.Sort();
    this.Recalculate();
    return(this);
}

VariableDiscreteScale.prototype.Reposition = function(j) {
    if(j.length != this.length) 
        throw "argument length must equal this.length";
    
    if(_.isString(j[0]))
        j = this.getPosition(j);

    for(var i = 0; i < this.length; i++) 
        this.ticks[j[i]].position = i;
    
    this.Sort();
    this.Recalculate();
    return(this);
}


/*******************************************************************************
   Get Methods
*******************************************************************************/
VariableDiscreteScale.prototype.Coordinates = function(p) {
    return([this.Start(p), this.End(p)]);
}

VariableDiscreteScale.prototype.Start = function(p) {
    if(_.isString(p) || (_.isArray(p) && _.isString(p[0])))
	return(this.Start(this.getPosition(p)));

    if(_.isArray(p)) 
        return(_.min(p.map(this.Start, this)));
    else
	return(this.ticks[p].start);
}

VariableDiscreteScale.prototype.End = function(p) {
    if(_.isString(p) || (_.isArray(p) && _.isString(p[0])))
        return(this.End(this.getPosition(p)));

    if(_.isArray(p)) 
        return(_.max(p.map(this.End, this)));
    else
        return(this.ticks[p].end);
}

VariableDiscreteScale.prototype.Size = function(p, q) {
    if(_.isString(p) || (_.isArray(p) && _.isString(p[0])))
        return(this.Size(this.getPosition(p)));
    
    if(_.isArray(p))
	return(this.Size(_.min(p), _.max(p)));
    
    if(_.isNumber(q)) {
	var out = 0;
        for(var i = (p > q ? q : p); i <= (p < q ? q : p); i++) {
	    out += this.ticks[i].size;
	}
	return out;
    }
    else
        return(this.ticks[p].size);
}

VariableDiscreteScale.prototype.Center = function(p) {
    return this.Start(p) + Math.round(this.Size(p) / 2);
}

VariableDiscreteScale.prototype.getPosition = function(l) {
    if(_.isArray(l)) 
    	return(l.map(this.getPosition, this));
    else
	return(_.findWhere(this.ticks, {label: l}).position);
}

VariableDiscreteScale.prototype.getLabels = function() {
    return(this.ticks.map(function(x) {return x.label;}));
}

VariableDiscreteScale.prototype.Tick = function(i) {
    if(_.isString(i)) 
	i = this.getPosition(i);
    
    return(this.ticks[i]);
}






