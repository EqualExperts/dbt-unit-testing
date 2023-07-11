{{ config (materialized = 'incremental' ) }}

select c1 from {{ dbt_unit_testing.ref('incremental_model_1') }}
left join {{ dbt_unit_testing.ref('incremental_model_2') }} using (c1)

{% if is_incremental() %}
  where c1 > (select max(c1) from {{ this }})
{% endif %}
