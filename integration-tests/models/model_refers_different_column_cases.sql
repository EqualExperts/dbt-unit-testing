select
  "UPPER_CASE_COLUMN",
  "Mixed Case Column",
  "lowercasecolumn",
  UPPER_CASE_COLUMN,
  MixedCaseColumn,
  lower_case_column
from {{ dbt_unit_testing.ref('model_with_different_column_cases') }}