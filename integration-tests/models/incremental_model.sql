{{ config (materialized = 'incremental' ) }}

select c from {{ dbt_unit_testing.ref('model_for_incremental') }}

{% if is_incremental() %}
  where c > (select max(c) from {{ this }})
{% endif %}
