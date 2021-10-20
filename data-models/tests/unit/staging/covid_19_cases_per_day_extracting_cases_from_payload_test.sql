{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_cases_per_day'
    )
}}

{% set inputs %}
covid19_raw as (
select CAST('2021-05-06' as date) as day, '[{"newCases": 20}]' as payload, null as country_id)
{% endset %}

{% set expectations %}
select cast('2021-05-06' as Date) as day, 20 as cases
{% endset %}
 
{{ unit_test(inputs, expectations) }}

