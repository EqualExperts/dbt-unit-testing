{% if dbt_unit_testing.version_bigger_or_equal_to("1.5.0") %}
  select * from {{ ref('model_with_version', version=2) }} where a > 2
{% endif %}

