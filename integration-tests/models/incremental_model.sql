{{ config (materialized = 'incremental' ) }}

select c from {{ dbt_unit_testing.ref('model_for_incremental') }}

{% if dbt_unit_testing.is_incremental() %}
  where c > (select max(c) from {{ dbt_unit_testing.this() }})
{% endif %}
