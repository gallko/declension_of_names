-- DROP FUNCTION skl_fam(text, type_sex, type_case, type_name);

CREATE FUNCTION skl_fam(IN strName text, IN chSex type_sex DEFAULT 'муж', IN strPadezh type_case DEFAULT 'dat', in tp_nm type_name DEFAULT 'фамилия') RETURNS text AS
$BODY$
DECLARE
    strSql text;
    strResult text;
    end_case text;
    end_num integer;
BEGIN
    execute 'SELECT t_exception_name.' || strPadezh || ' FROM t_exception_name WHERE name_exc=$1 AND sex=$2;'
        using strName, chSex
        INTO strResult;
    IF strResult is null then 
        execute 'SELECT (' || strPadezh || ').end_sur, ('|| strPadezh ||').num FROM t_end_name WHERE $1 ~* mask_end AND sex = $2 AND tp_name = $3;'
            using strName, chSex, tp_nm
            INTO end_case, end_num;
            strResult := substring(strName, 1, char_length(strName) - end_num) || end_case;
    end if;
    RETURN strResult;
END;
$BODY$
LANGUAGE plpgsql VOLATILE NOT LEAKPROOF;
ALTER FUNCTION public.skl_fam(in text, in type_sex, in type_case, IN type_name)
  OWNER TO rus;
COMMENT ON FUNCTION public.skl_fam(in text, in type_sex, in type_case, in type_name)
  IS 'склонение фамилии';
