select 
day,
country_id,
{% if target.type == 'postgres' %}
    SUM(COALESCE((payload::json->0->>'newCases')::int,0)) as cases
{% elif target.type == 'bigquery' %}
    SUM(COALESCE(CAST(JSON_EXTRACT(payload,'$[0].newCases')  AS INT),0)) as cases
{% else %}
    {{ exceptions.raise_compiler_error(target.type ~" not supported in this project") }}
{% endif %}
from {{ dbt_unit_testing.source('dbt_unit_testing','covid19_stg') }} group by day, country_id