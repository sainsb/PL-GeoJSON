create or replace FUNCTION getJSONProperties(inlayer in varchar2, infield in varchar2, inid in varchar2) return VARCHAR2 AS

vchar_sql varchar2(32767);
v_out VARCHAR2(32000);
v_owner VARCHAR2(50);
v_table VARCHAR2(50);
begin

vchar_sql := 'select ''"properties" : {'' || ';

if instr(inlayer, '.') > 0 THEN
  v_owner := substr(inlayer,1,instr(inlayer,'.')-1);
  v_table := substr(inlayer,instr(inlayer,'.')+1, length(inlayer));
else
  v_owner := sys_context('userenv','current_schema');
  v_table := inlayer;
end if;

    for rec in (
        select column_name, data_type
        from all_tab_columns
        where table_name = UPPER(v_Table)
            and owner = UPPER(v_Owner)
        ) loop

       if rec.data_type= 'VARCHAR2' or rec.data_type= 'NVARCHAR2' THEN
          vchar_sql := vchar_sql 
            || '''"'
            || rec.column_name || '" : "'' || '
            || 'nvl(rec.' || rec.column_name || ', '''') || ''", '' || ';
        ELSIF rec.data_type = 'DATE' THEN
          vchar_sql := vchar_sql 
            || '''"'
            || rec.column_name || '" : "'' || '
            || 'nvl(to_char(rec.' || rec.column_name || '), '''') || ''", '' || ';
        ELSIF rec.data_type <> 'ST_GEOMETRY' and rec.data_type <> 'DATE' THEN
            vchar_sql := vchar_sql 
            || '''"'
            || rec.column_name || '" : '' || '
            || 'nvl(rec.' || rec.column_name || ', 0) || '' , '' || ';
        end if; 

    end loop;

  vchar_sql := Substr(vchar_sql, 0, Length(vchar_sql) - 7) || '''';
  vchar_sql := vchar_sql || ' || ''}'' from (select * from ' || inlayer || ' where '
  || infield || ' = ''' || inid || ''') rec';
    
  dbms_output.put_line(vchar_sql);
  
 execute immediate vchar_sql into v_out ;
 return v_out;

end;