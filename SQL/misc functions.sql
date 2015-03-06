create or replace function parse_string (str varchar2, delimiter varchar2,
	   occurrence number)
    /* ------------------------------------------------------------
	PARSE_STRING(string, delimiter, occurrence)

	Returns the substring of STRING between the OCCURRENCE and OCCURRENCE+1 of
	DELIMITER. If OCCURRENCE < 1, returns the substring before the first
	occurrence. If OCCURRENCE is greater than the number of occurrences of
	DELIMITER, it will return the full string.

	EXAMPLE:
	  PARSE_STRING('1_2_3_4', '_', 0) = '1'
	  PARSE_STRING('1_2_3_4', '_', 1) = '2'
	  PARSE_STRING('1_2_3_4', '_', 3) = '4'
	  PARSE_STRING('1_2_3_4', '_', 4) = '1_2_3_4'
	  PARSE_STRING('1_2_3_4', '+', 5) = '1_2_3_4'

	------------------------------------------------------------ */
    return varchar2
    is
    v_pos1 number;
    v_pos2 number;
   
    begin

    IF occurrence < 1 THEN
    v_pos1 := 1;
    v_pos2 := INSTR (str, delimiter, 1, 1);
    ELSE
    v_pos1 := INSTR (str, delimiter, 1, occurrence) + 1;
    v_pos2 := INSTR (str, delimiter, 1, occurrence + 1);
    END IF;



    IF v_pos2 = 0 THEN
    v_pos2 := length(str) + 1;
    END IF;

    IF v_pos1 = 0 THEN
    v_pos2 := 1;
    END IF;

    return SUBSTR (str, v_pos1, v_pos2 - v_pos1);
    end parse_string;
    /
