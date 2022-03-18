{{ config(materialized='ephemeral') }}

-- A dummy model that makes it easy to pass through
-- a mocked result.
SELECT * FROM {{ dbt_unit_testing.ref('mock') }}
