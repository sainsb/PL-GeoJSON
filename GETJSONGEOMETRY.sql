create or replace FUNCTION getJSONgeometry(inlayer in varchar2, infield in varchar2, inid in Nvarchar2) return CLOB AS
v_clob CLOB;
foo varchar2(32000);
v_ring sde.ST_Linestring;
temppoint sde.ST_Point;
numpoints int;
v_numrings int;
v_geom sde.ST_Geometry;
v_tmp_clob CLOB;
v_vc varchar2(32000);
SQLCMD VARCHAR2(32000);
v_x number;
v_y number;

/* Found here:
http://www.talkapex.com/2009/06/how-to-quickly-append-varchar2-to-clob.html
*/
procedure app(v_clob in out nocopy clob, v_vc in out nocopy varchar2, v_app varchar2) is
begin
	v_vc := v_vc || v_app;
	exception when VALUE_ERROR then
	if v_clob is null then
	v_clob := v_vc;
	else
	dbms_lob.append(v_clob, v_vc);
	v_vc := v_app;
	end if;
end;

BEGIN
--select sde.st_transform(shape,4152) into v_geom from taxlots.taxlots where tlid=inid;
SQLCMD := 'select sde.st_transform(shape,4152) from ' || inLayer || ' WHERE ' || infield ||' = ''' || inid || '''';
EXECUTE IMMEDIATE SQLCMD into v_geom;

   -- catches all 'no data found' errors

v_vc := v_vc || '"geometry": { "type": "Polygon", "coordinates": [' || chr(10) || '[';
select sde.st_ExteriorRing(v_geom) into v_ring from dual;
select sde.st_numpoints(v_ring) into numpoints from dual;

for point in 1..(numpoints-1) Loop

	select sde.st_pointn(v_ring, point) into temppoint from dual;
	select sde.st_X(temppoint) into v_x from dual;
	select sde.st_Y(temppoint) into v_y from dual;

	foo := '[' || to_char(v_x) || ',';
	foo := foo || to_char(v_y) || '],' || chr(10);

	app(v_clob, v_vc, foo);
end loop;

select sde.st_pointn(v_ring, numpoints) into temppoint from dual;
select sde.st_X(temppoint) into v_x from dual;
select sde.st_Y(temppoint) into v_y from dual;
foo := '['|| to_char(v_x) || ',';
foo := foo || to_char(v_y) || ']';
app(v_clob, v_vc, foo);

--v_clob := v_clob || v_vc;

-- Interior rings
select sde.st_NumInteriorRing(v_geom) into v_numrings from dual;

if v_numrings > 0 then
	v_vc := '],' || chr(10) || '[';

	for ring in 1..v_numrings Loop
		select sde.st_InteriorRingN(v_geom, ring) into v_ring from dual;
		select sde.st_numpoints(v_ring) into numpoints from dual;

	  for point in 0..numpoints-1 Loop
	   
		  select sde.st_pointn(v_ring, point) into temppoint from dual;
		  select sde.st_X(temppoint) into v_x from dual;
		  select sde.st_Y(temppoint) into v_y from dual;
		  
		  foo := '[' || to_char(v_x) || ',';
		  foo := foo || to_char(v_y) || '],' || chr(10);
		  
		  app(v_clob, v_vc, foo);
	  end loop;
	  
	  select sde.st_pointn(v_ring, numpoints) into temppoint from dual;
	  select sde.st_X(temppoint) into v_x from dual;
	  select sde.st_Y(temppoint) into v_y from dual;
	  foo := '[' || to_char(v_x) || ',';
	  foo := foo || to_char(v_y) || ']';
	  
	  app(v_clob, v_vc, foo);
	  
	  if ring <> v_numrings then
	  foo := '],' || chr(10) || '[';
	  else
	  foo :=']';
	  end if;
	  
	  app(v_clob, v_vc, foo);

	End Loop;

else
	foo :=']';
	app(v_clob, v_vc, foo);
end if;
foo:=']}';

app(v_clob, v_vc, foo);
v_clob := v_clob || v_vc;

return v_clob;

END;
