{{ config (materialized = 'incremental' ) }}

select c1 from {{ dbt_unit_testing.ref('model_for_incremental') }}

{% if is_incremental() %}
  where c1 > (select max(c1) from {{ this }})
{% endif %}
