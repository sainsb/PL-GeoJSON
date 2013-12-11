create or replace FUNCTION getGeoJSON(inlayer in varchar2, infield in varchar2, inid in varchar2, return_properties in number) return CLOB AS
v_clob CLOB;
v_geom CLOB;
v_props CLOB;
BEGIN

v_clob :='{ "type": "FeatureCollection", "features": [ { "type": "Feature",';

if return_properties =1 THEN

select getJSONProperties(inlayer, infield, inid) into v_props from dual;

if v_props is null THEN
raise NO_DATA_FOUND;
end if;

v_clob := v_clob || v_props || ', ';
else
v_clob := v_clob || '"properties" : {"' || infield || '" : "' || inid || '"}, ';
end if;

select getJSONGeometry(inlayer, infield, inid) into v_geom from dual;

if v_geom is null THEN
raise NO_DATA_FOUND;
end if;

v_clob := v_clob || v_geom || '}]}';

return v_clob;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
   return '{ "type": "FeatureCollection", "features": []}';
END;
