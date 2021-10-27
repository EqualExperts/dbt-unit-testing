{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_cases_per_day'
    )
}}

{% set inputs %}
covid19_stg as (
select null as day, '' as payload, 'uk' as country_id)
{% endset %}

{% set expectations %}
select 'uk' as country_id
{% endset %}
 
{{ unit_test(inputs, expectations) }}

