{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_stats'
    )
}}

{% set inputs %}
covid19_cases_per_day as (
select cast('2021-05-05' as Date) as day, 10 as cases, 'uk' as country_id
),
covid19_country_stg as (
select 'uk' as country_id, 'United Kingdom' as country_name
)
{% endset %}

{% set expectations %}
select  cast('2021-05-05' as Date) as day, 10 as cases,  'United Kingdom' as country_name    
{% endset %}
 
{{ unit_test(inputs, expectations) }}

