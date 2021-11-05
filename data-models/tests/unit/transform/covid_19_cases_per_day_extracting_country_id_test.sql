{{
    config(
        tags=['unit-test'],
        model_under_test='covid19_cases_per_day'
    )
}}

{% call test('covid19_cases_per_day') %}
  {% call mock_source('covid19_stg', 'covid19_stg') %}
    select null as day, '' as payload, 'uk' as country_id
  {% endcall %}

  {% call expect() %}
    select 'uk' as country_id
  {% endcall %}
{% endcall %}
 

