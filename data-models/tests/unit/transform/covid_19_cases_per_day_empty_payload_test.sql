{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_cases_per_day'
    )
}}

{% set inputs %}
covid19_stg as (
select CAST('2021-05-05' as date) as day, '[{}]' as payload, null as country_id)
{% endset %}

{% set expectations %}
select cast('2021-05-05' as Date) as day, 0 as cases
{% endset %}
 
{{ unit_test(inputs, expectations) }}

