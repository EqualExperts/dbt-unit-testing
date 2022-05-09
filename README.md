# DBT Unit Testing

[![Dbt Unit Testing](https://github.com/EqualExperts/dbt-unit-testing/actions/workflows/main.yml/badge.svg)](https://github.com/EqualExperts/dbt-unit-testing/actions/workflows/main.yml)

This [dbt](https://github.com/dbt-labs/dbt) package contains macros to support unit testing that can be (re)used across dbt projects.

## Why do we need unit tests in dbt?

One of the software engineering practices that we follow is TDD. We strongly believe that it helps us create better code and achieve a good level of confidence in its correctness. So, why not use this in our dbt projects?

### Dbt is code

A dbt project, like a “regular” software project, consists of several files of SQL code. And we want to be sure that the logic of this code is correct before it jumps to production.

We think that using TDD can also help us to write better SQL code. Using TDD, we write the test, make it pass with the simplest SQL code we can think of, and then refactor it, knowing we have a test to assure it still works. It would be awesome if we could do this on our dbt projects!

### But wait, dbt already has tests

That’s right, but dbt tests were mainly designed for data tests. They are used to check the correctness of the data produced by the models. We want to write unit tests on our SQL code. We want to be sure that the logic of the code is correct.

### A word on unit tests

The line between unit and integration tests is sometimes a bit blurred. This is also true with these tests in dbt.

We can think of a dbt model as a function, where the inputs are other models, and the output is the result of its SQL. A unit test in dbt would be a test where we provide fake inputs to a model, and then we check the results against some expectations.

However, a model in dbt can belong to a long chain of models, each transforming the data in its own rules. We could test a model by providing fake inputs to the first models in that chain and asserting the results on the final model. We would be checking all the intermediate transformations along the way. This, on the other end, could be called an integration test.

These integration tests are harder to write because we have to think of how the data is transformed throughout all those models until it reaches the model we want to test. However, they provide an extra level of confidence. As usual, we need to keep a good balance between these two types of tests.

As we will see, using this definition, our framework will allow us to create both unit and integration tests.

### What do you want to achieve?

We want to write dbt tests using TDD and receive fast feedback on the results. Running one or more dbt models each time we change them, as we were doing on the previous approach, was not the best way to do it, and we wanted to remove this step.
The goal is to write the test, write the model, and then run the test (with “dbt test”).

### Main features

- Use fake inputs on any model or source
- Define fake inputs with sql or csv format within the test
- Run tests without the need to run dbt and install the models into a database.
- Focus the test on what’s important
- Provide fast and valuable feedback
- Write more than one test on a dbt test file

### Available Macros

- **dbt_unit_testing.test** Macro used to defined a test.
- **dbt_unit_testing.mock-ref** Macro used to mock a model.
- **dbt_unit_testing.mock-source** Macro used to mock a source.
- **dbt_unit_testing.expect** Macro used to defined the test expectations.
- **dbt_unit_testing.ref** Macro used to override dbt ref in dbt models.
- **dbt_unit_testing.source** Macro used to override dbt source in dbt models.

### Skeleton of a test

```jinja
{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test ('[Model to Test]','[Test Name]') %}
  {% call dbt_unit_testing.mock_ref ('[Model to Mock]') %}
     select ...
  {% endcall %}

  {% call dbt_unit_testing.mock_source('[Ref to Mock]') %}
    select ...
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select  ...
  {% endcall %}

{% endcall %}
```

Note the configuration lines at the begining of the test:

```jinja
{{
    config(
        tags=['unit-test']
    )
}}
```

This is required for these tests to work.

### Example of a test

```jinja
{{ config(tags=['unit-test']) }}

{% call dbt_unit_testing.test('covid19_cases_per_day') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing_staging', 'covid19_stg') %}
    select CAST('2021-05-05' as date) as day, '[{}]' as payload
    union all
    select CAST('2021-05-06' as date) as day, '[{"newCases": 20}]' as payload
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select cast('2021-05-05' as Date) as day, 0 as cases
    union all
    select cast('2021-05-06' as Date) as day, 20 as cases
  {% endcall %}
{% endcall %}
```

### Different ways to build mock values

Instead of using standard sql to define your input values, you can use a more tabular way, like this:

```jinja
{% call dbt_unit_testing.test('covid19_cases_per_day') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing_staging', 'covid19_stg', {"input_format": "csv"}) %}
    day::Date, payload
    '2021-05-05', '[{}]'
    '2021-05-06', '[{"newCases": 20}]'
  {% endcall %}

  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}
    day::Date, cases
    '2021-05-05', 0
    '2021-05-06', 20
  {% endcall %}
{% endcall %}
```

All the unit testing related macros (**`mock_ref`**, **`mock_source`**, **`expect`**) accept an `options` parameter, that can be used to specify the following:

- `input_format`: "sql" or "csv" (default = "sql")
- `column_separator` (default = ",")
- `type_separator` (default = "::")
- `line_separator` (default = "\n")

(the last three options are used only for `csv` format)

These defaults can be also be changed project wise, in the vars section of your `dbt_project.yml`:

```yaml
vars:
  unit_tests_config:
    input_format: "csv"
    column_separator: "|"
    line_separator: "\n"
    type_separator: "::"
```

With the above configuration you could write your tests like this:

```jinja
{% call dbt_unit_testing.test('covid19_cases_per_day') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing_staging', 'covid19_stg') %}
    day::Date    | payload
    '2021-05-05' | '[{}]'
    '2021-05-06' | '[{"newCases": 20}]'
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    day::Date    | cases
    '2021-05-05' |  0
    '2021-05-06' |  20
  {% endcall %}
{% endcall %}
```

#### Mock sources and models

To be able to mock the models and sources in tests, in your dbt models you should use the macros  **dbt_unit_testing.ref** and **dbt_unit_testing.source**, for example:

```sql
select day,
country_name,
cases
from {{ dbt_unit_testing.ref('covid19_cases_per_day') }}
     JOIN {{ dbt_unit_testing.source('dbt_unit_testing','covid19_country_stg') }}
     USING (country_id)

```

Alternatively, if you prefer to keep using the standard `ref` macro in the models, you can add these macros to your project:

```jinja
{% macro ref(model_name) %}
   {{ return(dbt_unit_testing.ref(model_name)) }}
{% endmacro %}

{% macro source(source, model_name) %}
   {{ return(dbt_unit_testing.source(source, model_name)) }}
{% endmacro %}
```

Also, the sources columns must be available. If sources are not present in the database,  you have to declare them in your sources file. Example:

```yaml
sources:
  - name: dbt_unit_testing
    tables:
      - name: covid19_stg
        columns:
          - name: day
          - name: country_id
          - name: payload
      - name: covid19_country_stg
        columns:
          - name: country_id
          - name: country_name
```

You may need to specify the columns data type also, like this:

```yaml
sources:
  - name: dbt_unit_testing
    tables:
      - name: covid19_stg
        columns:
          - name: day
            data_type: integer
          ...
```

### Mocking strategy

In some environments (particularly BigQuery), you may find that you need to reduce query complexity. There are three levels of complexity that you can specify when running tests, in decreasing order of complexity:

- *`Full`*
- *`Simplified`*
- *`Database`*

The *`Full`* strategy provides the best developer experience by mocking all the models with the SQL that's on each model's file. There is no need to materialize the models in the database to run the tests. It can also infer the types of all the columns that are not used in a mocked model, preventing some type mismatches when running the tests.

The *`Simplified`* strategy builds less complex test queries but it doesn't infer the types of the columns as the `Full` strategy does. This means that sometimes you need to declare the type of a column in the mocking sql, even if you don't need that column in the test.

The *`Database`* strategy generates the most simple queries because it uses the models in the database. This requires that all the models used by the model being tested must be previously materialized in the database (the only exception being the model being tested, which will always use the SQL from its file).
Another downside of this strategy is that you can only mock the immediate parents of the model being tested. If you have a model hierarchy like A->B->C, for instance, you have to mock model B to test model A, you cannot mock model C (the other strategies allow this).
Furthermore, you need to ensure that the models in the database contain no rows, otherwise, the tests could be affected by them.

You can specify the mocking strategy in the dbt_project.yml file, like this:

```yaml
vars:
  unit_tests_config:
    mocking_strategy: Full
```

You can also specify a different mocking strategy for a specific model in the test, like this:

```jinja
{% call dbt_unit_testing.test('some_model') %}

  {% call dbt_unit_testing.mock_ref('some_model_to_be_mocked', {"mocking_strategy": "SIMPLIFIED"} ) %}
    select 1 as t
  {% endcall %}

  ...

{% endcall %}
```

All the mocked models in the other tests will use the mocking strategy declared in dbt_project.yml file (or `FULL`, if none is specified), but this particular model in this test will use the `SIMPLIFIED` strategy. This can be useful if you want to use the power of the `FULL` strategy in all models except for the ones that increase the complexity of the final SQL.

Note: Strategy names are case insensitive

### Convenience features

- You can define multiple tests in the same file using `UNION ALL` [here](integration-tests/tests/unit/transform/covid_19_cases_per_day_test.sql).
- When mocking a ref or a model you just need to define the columns that you will test.

#### Test Feedback

Good test feedback is what allows us to be productive when developing unit tests and developing our models.
The test macro provides visual feedback when a test fails showing what went wrong by comparing the lines of the expectations with the actuals.

##### Example

```yaml
MODEL: covid19_stats
TEST:  Test country name join
| diff | count |        day | cases | country_name   |
| ---- | ----- | ---------- | ----- | -------------- |
| -    |     1 | 2021-06-06 |    10 | United Kingdom |
| +    |     1 | 2021-05-05 |    10 | United Kingdom |
```

The first line was not on the model but the second line was.

## Known Limitations

- It's not possible to have a *model* with the same name as a *source* or a *seed*.

## Compatibility

[x] dbt > 0.20

[x] BigQuery

[x] Snowflake

[x] Postgres

[ ] Redshift

## Installation Instructions

Add the following to packages.yml

```yaml
packages:
  - git: "https://github.com/EqualExperts/dbt-unit-testing"
    revision: v0.1.0
```

[read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## License

This project is [licensed](./LICENSE) under the [MIT License](https://mit-license.org/).
