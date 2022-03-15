{{ config(materialized='ephemeral') }}

-- A dummy model intended to be mocked.
SELECT 1 as please_mock_me
