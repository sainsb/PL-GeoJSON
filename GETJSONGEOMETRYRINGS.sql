create or replace
FUNCTION getJSONGeometryRings(in_POLYGON in sde.ST_Geometry) return clob as
v_clob CLOB;
v_vc varchar2(32000);
v_ring sde.ST_Linestring;
numpoints int;
v_numinteriorrings int;
temppoint sde.ST_Point;
v_x number;
v_y number;

procedure app(v_clob in out nocopy clob, v_vc in out nocopy varchar2, v_app varchar2) is
begin
	v_vc := v_vc || v_app;
	exception when VALUE_ERROR then
	dbms_lob.append(v_clob, v_vc);
	v_vc := v_app;
end;

function point2Char(in_point sde.ST_Point) return varchar2 as
begin
  select sde.st_X(in_point), sde.ST_Y(in_point) into v_x, v_y from dual;
  return '[' || to_char(v_x,'fm9999999.999999') || ',' || to_char(v_y,'fm9999999.999999') || ']' || chr(10);
end;

Begin 

/* Exterior ring first */
select sde.st_ExteriorRing(in_Polygon) into v_ring from dual;
select sde.st_numpoints(v_ring) into numpoints from dual;
--dbms_output.put_line(numpoints);
v_clob := '[' || CHR(10);

for point in 1..(numpoints-1) Loop
	select sde.st_pointn(v_ring, point) into temppoint from dual;
	app(v_clob, v_vc, point2char(temppoint) || ',');
end loop;

/* Final point and closing bracket */
select sde.st_pointn(v_ring, numpoints) into temppoint from dual;
app(v_clob, v_vc, point2char(temppoint) || ']');

-- Interior rings
select sde.st_NumInteriorRing(in_polygon) into v_numinteriorrings from dual;

if v_numinteriorrings > 0 then
	app(v_clob, v_vc, ',' || chr(10) );

	for ring in 1..v_numinteriorrings Loop --ring 0 is the exterior ring so we start with 1
          app(v_clob, v_vc, '[' );
          select sde.st_InteriorRingN(in_polygon, ring) into v_ring from dual;
          select sde.st_numpoints(v_ring) into numpoints from dual;

	  for point in 1..(numpoints-1) Loop
            select sde.st_pointn(v_ring, point) into temppoint from dual;
            app(v_clob, v_vc, point2char(temppoint) || ',');
	  end loop;
          
	  dbms_output.put_line('Ring ' || ring || ', number of rings: ' || v_numinteriorrings);
          
          /* Final point and closing bracket */
	  select sde.st_pointn(v_ring, numpoints) into temppoint from dual;
	  app(v_clob, v_vc, point2char(temppoint) || ']');
          
	  --v_clob := v_clob || v_vc;
          if ring <> v_numinteriorrings then
            app(v_clob, v_vc, ',');
          end if;
	End Loop;
end if;
-- Anything left over 
v_clob := v_clob || v_vc;
return v_clob;
end;
