drop table t_sex;
drop table t_end_name;
drop table t_exception_name;
drop FUNCTION skl_name(text, type_sex, type_case, type_name);

drop type type_sex;
drop type type_name;
drop TYPE case_ending;
drop TYPE type_case;

create type type_sex as enum ('муж', 'жен');
create type type_name as enum ('surname', 'name', 'patronymic');
create type type_case as enum ('gen', 'dat');

create type case_ending as (    -- тип окончаний
    end_sur text,           -- окончание
    num integer             -- количество замены
);

create table t_sex (            -- вспомогательная таблица пола
    sex type_sex primary key,
    full_str text
);
insert into t_sex values('муж', 'мужской');
insert into t_sex values('жен', 'женский');

-- Ф А М И Л И И  И М Е Н А  О Т Ч Е С Т В А --
create table t_end_name (   -- таблица склонений фамилий(имен, отчеств)
    mask_end text NOT null,               -- маска окончания
    sex type_sex not null,                -- пол
    tp_name type_name not null,           -- тип имени (фамилия, имя, отчество)
    gen case_ending not null default '("", 0)',  -- родительный (кого)
    dat case_ending not null default '("", 0)',  -- дательный (кому)
  constraint t_end_name_pkey Primary key(mask_end, sex, tp_name)
);
--мужские фамилии
    insert into t_end_name values('[аяоиыуэею]$|зе$|их$|ых$', 'муж', 'surname');
    insert into t_end_name values('[^чнк][^ыоу][ьй]$', 'муж', 'surname', '("я", 1)','("ю", 1)');
    insert into t_end_name values('[^уеыаоэяиюёл]ец$', 'муж', 'surname', '("ца", 2)','("цу", 2)');
    insert into t_end_name values('[л]ец$', 'муж', 'surname', '("ьца", 2)','("ьцу", 2)');
    insert into t_end_name values('[уеыаоэяиюё]ец$', 'муж', 'surname', '("ца", 1)','("цу", 1)');
    insert into t_end_name values('[^уеыаоэяиюё][^уеыаоэяиюё]ец$', 'муж', 'surname', '("а", 1)','("у", 1)');
    insert into t_end_name values('ый$|[^чрл]ий$|ой$', 'муж', 'surname', '("ого", 2)','("ому", 2)');
    insert into t_end_name values('^(.{1,2})ий$|ой$', 'муж', 'surname', '("я", 1)','("ю", 1)');
    insert into t_end_name values('чий$', 'муж', 'surname', '("ого", 2)','("ему", 2)');
    insert into t_end_name values('уй$', 'муж', 'surname', '("уя", 2)','("ую", 2)');
    insert into t_end_name values('[вдзкнпрстчш]$', 'муж', 'surname', '("а", 0)','("у", 0)');
-- женские фамилии
    insert into t_end_name values('[^е][оеэиыуюбвгджзклмнпрстфхцчшщьй]$', 'жен', 'surname', '("", 0)','("", 0)');
    insert into t_end_name values('[я]$', 'жен', 'surname', '("у", 2)','("ой", 2)');
    insert into t_end_name values('[^хлбднр]а$', 'жен', 'surname', '("у", 1)','("ой", 1)');
    insert into t_end_name values('[хлбднр]а$|ее$', 'жен', 'surname', '("у", 1)','("е", 1)');
--мужские имена
    insert into t_end_name values('[йь]$', 'муж', 'name', '("я", 1)','("ю", 1)');
    insert into t_end_name values('[а]$', 'муж', 'name', '("у", 1)','("е", 1)');
    insert into t_end_name values('[я]$', 'муж', 'name', '("ю", 1)','("е", 1)');
    insert into t_end_name values('[о]$', 'муж', 'name');
    insert into t_end_name values('[^лояайь]$', 'муж', 'name', '("а", 0)','("у", 0)');
    insert into t_end_name values('[л]$', 'муж', 'name', '("ла", 2)','("лу", 2)');
--женские имена
    insert into t_end_name values('[^и][ая]$', 'жен', 'name', '("у", 1)','("е", 1)');
    insert into t_end_name values('[и][ая]$', 'жен', 'name', '("ю", 1)','("е", 1)');
    insert into t_end_name values('[ь]$', 'жен', 'name', '("ию", 1)','("ие", 1)');
--отчества
    insert into t_end_name values('[ы]$', 'муж', 'patronymic');
    insert into t_end_name values('[ы]$', 'жен', 'patronymic');
    insert into t_end_name values('[^ы]$', 'муж', 'patronymic', '("а", 0)','("у", 0)');
    insert into t_end_name values('[^ы]$', 'жен', 'patronymic', '("у", 0)','("е", 0)');

create table t_exception_name (    -- таблица исключений
    name_exc text NOT null,               -- имя
    sex type_sex not null,                -- пол
    gen text not null,                    -- родительный (кого)
    dat text not null,                    -- дательный (кому)
  constraint t_exception_name_pkey Primary key(name_exc, sex)
);

CREATE FUNCTION skl_name(IN strName text, IN chSex type_sex DEFAULT 'муж', IN strPadezh type_case DEFAULT 'dat', in tp_nm type_name DEFAULT 'surname') RETURNS text AS
$BODY$
DECLARE
    --strSql text;
    strResult text;
    end_case text;
    end_num integer;
BEGIN
    EXECUTE 'SELECT t_exception_name.' || strPadezh || ' FROM t_exception_name WHERE name_exc=$1 AND sex=$2;'
        USING strName, chSex
        INTO strResult;
    IF strResult IS NULL THEN
        execute 'SELECT (' || strPadezh || ').end_sur, ('|| strPadezh ||').num FROM t_end_name WHERE $1 ~* mask_end AND sex = $2 AND tp_name = $3;'
            using strName, chSex, tp_nm
            INTO end_case, end_num;
            strResult := substring(strName, 1, char_length(strName) - end_num) || end_case;
    END IF;
    RETURN strResult;
END;
$BODY$
LANGUAGE plpgsql VOLATILE NOT LEAKPROOF;
ALTER FUNCTION public.skl_name(in text, in type_sex, in type_case, IN type_name)
  OWNER TO rus;
COMMENT ON FUNCTION public.skl_name(in text, in type_sex, in type_case, in type_name)
  IS 'склонение фамилий, имен, отчеств';
