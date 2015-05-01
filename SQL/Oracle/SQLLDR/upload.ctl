-- See Also: http://www.csee.umbc.edu/portal/help/oracle8/server.815/a67792/ch05.htm

-- Options
OPTIONS (SKIP=1, DIRECT=TRUE)

load data
	-- List of Files (spaces are allowable)
	infile 'FILE_RELATIVE_TO_HERE'
	-- APPEND -- if desired
	 into table TABLE_XXX
	 fields terminated by "," optionally enclosed by '"'
 	-- List of DESTINATION columns 
	 (COLUMN_XXX,
	 COLUMN_YYY)
