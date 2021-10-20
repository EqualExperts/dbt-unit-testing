{{ config(dataset='staging')}}
select 
day,
country_id,
SUM(COALESCE(CAST(JSON_EXTRACT(payload,'$[0].newCases')  AS INT64),0)) as cases
from {{ source('covid19_raw','covid19_raw') }} group by day, country_id