# DBT Unit Testing

[![Dbt Unit Testing](https://github.com/EqualExperts/dbt-unit-test-demo/actions/workflows/integration_tests.yml/badge.svg)](https://github.com/EqualExperts/dbt-unit-test-demo/actions/workflows/integration_tests.yml)

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

However, a model in dbt can belong to a long chain of models (see image below), each transforming the data in its own rules. We could test a model by providing fake inputs to the first models in that chain and asserting the results on the final model. We would be checking all the intermediate transformations along the way. This, on the other end, could be called an integration test.

These integration tests are harder to write because we have to think of how the data is transformed throughout all those models until it reaches the model we want to test. However, they provide an extra level of confidence. As usual, we need to keep a good balance between these two types of tests.

As we will see, using this definition, our framework will allow us to create both unit and integration tests.

### What do you want to achieve?

We came up with a list of requirements that we would like to fulfill when writing tests in dbt:

Use fake inputs on any model
Focus the test on what’s important
Provide fast and valuable feedback
Write more than one test on a dbt test file
We want to write dbt tests using TDD and receive fast feedback on the results. Running one or more dbt models each time we change them, as we were doing on the previous approach, was not the best way to do it, and we wanted to remove this step.

The goal is to write the test, write the model, and then run the test (with “dbt test”).

### Main features

- Use fake inputs on any model or ref
- Define fake inputs with sql
- Focus the test on what’s important
- Provide fast and valuable feedback
- Write more than one test on a dbt test file

### Available Macros

- **dbt_unit_testing.test** Macro used to defined a test.
- **dbt_unit_testing.mock-ref** Macro used to mock a model.
- **dbt_unit_testing.mock-source** Macro used to mock a source.
- **dbt_unit_testing.expect** Macro used to defined the test expectations.

### Skeleton of a test

```jinja
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

### Example of a test

```jinja
{% call dbt_unit_testing.test('covid19_cases_per_day', 'empty payload') %}
  {% call dbt_unit_testing.mock_source('dbt_unit_testing_staging', 'covid19_stg') %}
    select CAST('2021-05-05' as date) as day, '[{}]' as payload
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select cast('2021-05-05' as Date) as day, 0 as cases
  {% endcall %}
{% endcall %}
```

### Convenience features

- You can define multiple tests in the same file using UNION [here](https://github.com/EqualExperts/dbt-unit-testing/blob/master/integration-tests/tests/unit/transform/covid_19_cases_per_day.sql).
- When mocking a ref or a model you just need to define the columns that you will test.

#### Test Feedback

Good test feedback is what allow us to be productive when developing unit tests and developing our models.
The test macro provides visual feedback when a test fails showing what went wrong comparing the lines of the expectations with the actuals.

##### Example

```yaml
MODEL: covid19_stats
TEST:  Test country name join
| | diff | count |        day | cases | country_name   |
| | ---- | ----- | ---------- | ----- | -------------- |
| | -    |     1 | 2021-06-06 |    10 | United Kingdom |
| | +    |     1 | 2021-05-05 |    10 | United Kingdom |
```

The first line was not on the model but the second line was.

## Compatibility

[x] dbt > 0.20

[x] BigQuery

[ ] Snowflake

[ ] Postgres

[ ] Redshift

## Installation Instructions

Add the following to packages.yml

```yaml
packages:
  - git: "https://github.com/EqualExperts/dbt-unit-testing"
    revision: master
```

[read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
