{% snapshot sample_snapshot %}

{{
  config(
    target_schema = 'snapshots',
    unique_key = 'existing_source_a',
    strategy = 'check',
    check_cols = ['existing_source_b']
    )
}}
select * from {{dbt_unit_testing.source('dbt_unit_testing','sample_source_without_columns_declared')}} where existing_source_a > 0
{% endsnapshot %}