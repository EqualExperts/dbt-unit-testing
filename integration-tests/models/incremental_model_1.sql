{{ config (materialized = 'incremental' ) }}

select c1, '"postgres"."dbt_unit_testing_dbt_test__audit"."incremental_model"' as c2
from {{ dbt_unit_testing.ref('model_for_incremental') }}

{% if is_incremental() %}
  where c1 > (select max(c1) from {{ this }})
{% endif %}
