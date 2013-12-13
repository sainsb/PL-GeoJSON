create or replace
FUNCTION getJSONgeometry(inlayer in varchar2, infield in varchar2, inid in Nvarchar2) return CLOB AS
v_clob CLOB;
v_polygon sde.ST_Geometry;
v_geom sde.ST_Geometry;
SQLCMD VARCHAR2(32000);
numpolys number;
v_type number;

BEGIN
--select sde.st_transform(shape,4152) into v_geom from taxlots.taxlots where tlid=inid;
SQLCMD := 'select sde.st_transform(shape,4152) from ' || inLayer || ' WHERE ' || infield ||' = ''' || inid || '''';
EXECUTE IMMEDIATE SQLCMD into v_geom;

select sde.st_entity(v_geom) into v_type from dual;

if v_type = 8 THEN -- POLYGON

  v_clob := '"geometry": { "type": "Polygon", "coordinates": [' || chr(10);
  
  select sde.st_geometryn(v_geom,0) into v_polygon from dual;
  
  v_clob := v_clob || getJSONGeometryRings(v_geom) || ']}';
  
ELSIF v_type = 264 THEN-- MULTIPOLYGON 

  select sde.st_numgeometries(v_geom) into numpolys from dual;
  v_clob :=  '"geometry": { "type": "MultiPolygon", "coordinates": [';
  
  for polygon in 1..(numpolys) Loop
    select sde.st_geometryn(v_geom, polygon) into v_polygon from dual;
    v_clob := v_clob || '[' || getJsongeometryrings(v_polygon) || ']';
    if polygon <> numpolys then
      v_clob := v_clob || ',';
    end if;
  end loop;
v_clob := v_clob || ']}';
end if;
return v_clob;
END;