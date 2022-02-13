{{ config(materialized='table',dataset='staging')}}
with values as (
select 
'' as country_id,
'' country_name
)
select * from values where country_name = 'test'