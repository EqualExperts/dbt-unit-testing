{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_cases_per_day'
    )
}}

{% call test('covid19_cases_per_day') %}
  {% call mock_source('covid19_stg', 'covid19_stg') %}
    select CAST('2021-05-05' as date) as day, '[{}]' as payload, null as country_id
  {% endcall %}

  {% call expect() %}
    select cast('2021-05-05' as Date) as day, 0 as cases
  {% endcall %}
{% endcall %}
 
