with model_w_seed as (
  select * from {{ dbt_unit_testing.ref('covid19_stats_using_seed') }}
)

select * from model_w_seed
