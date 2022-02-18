select '{{dbt_unit_testing.build_model_complete_sql("covid19_cases_per_day").replace("'", "''").strip()}}'  as model
{{dbt_unit_testing.sql_except()}}
select 'select * from (select
day,
country_id,SUM(COALESCE((payload::json->0->>''newCases'')::int,0)) as cases
from "postgres"."dbt_unit_testing"."covid19_stg" group by day, country_id) as tmp' as model

