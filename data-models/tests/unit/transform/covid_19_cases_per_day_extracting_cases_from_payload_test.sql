{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_cases_per_day'
    )
}}

{% call test('covid19_cases_per_day') %}
  {% call mock_source('covid19_stg', 'covid19_stg') %}
    select CAST('2021-05-06' as date) as day, '[{"newCases": 20}]' as payload, null as country_id
  {% endcall %}

  {% call expect() %}
    select cast('2021-05-06' as Date) as day, 20 as cases
  {% endcall %}
{% endcall %}
 
