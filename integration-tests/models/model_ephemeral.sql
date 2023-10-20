{{ config (materialized = 'incremental' ) }}

select 1 as a, 'b' as b