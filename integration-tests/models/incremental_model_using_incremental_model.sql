{{ config (materialized = 'incremental' ) }}

select d from {{ dbt_unit_testing.ref('incremental_model') }}

{% if is_incremental() %}
  where d > (select max(d) from {{ this }})
{% endif %}
