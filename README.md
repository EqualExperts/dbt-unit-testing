[![Dbt Unit Testing](https://github.com/EqualExperts/dbt-unit-testing/actions/workflows/main.yml/badge.svg)](https://github.com/EqualExperts/dbt-unit-testing/actions/workflows/main.yml)

<!-- omit in toc -->
# DBT Unit Testing

Dbt Unit Testing is a dbt package that provides support for unit testing in [dbt](https://github.com/dbt-labs/dbt).

You can test models independently by mocking their dependencies (models, sources, snapshots, seeds).

- [Installation](#installation)
- [More About Dbt Unit Testing](#more-about-dbt-unit-testing)
  - [Purpose](#purpose)
  - [SQL First](#sql-first)
  - [How](#how)
  - [Main Features](#main-features)
- [Documentation](#documentation)
  - [Anatomy of a test](#anatomy-of-a-test)
  - [Running Tests](#running-tests)
  - [Available Macros](#available-macros)
  - [Test Examples](#test-examples)
  - [Different ways to build mock values](#different-ways-to-build-mock-values)
  - [Mocking](#mocking)
    - [Database dependencies in detail](#database-dependencies-in-detail)
    - [Important Requirement](#important-requirement)
  - [Incremental Models](#incremental-models)
  - [Column Transformations](#column-transformations)
    - [How to use](#how-to-use)
    - [Use Case 1: Rounding Column Values](#use-case-1-rounding-column-values)
    - [Use Case 2: Converting Structs to JSON Strings in BigQuery](#use-case-2-converting-structs-to-json-strings-in-bigquery)
  - [Available Options](#available-options)
  - [Test Feedback](#test-feedback)
    - [Example](#example)
- [Known Limitations](#known-limitations)
- [Compatibility](#compatibility)
- [License](#license)

# Installation

Add the following to packages.yml

```yaml
packages:
  - git: "https://github.com/EqualExperts/dbt-unit-testing"
    revision: v0.4.12
```

[read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

**Warning**: We recommend you to upgrade from 0.1.3. However 0.2.0 introduces breaking changes by removing the mocking strategies (you need to update and use the new options, see [Available Options](#available-options) and release notes).

# More About Dbt Unit Testing

## Purpose

Neither the data tests nor the schema tests are suitable to test the models' logic because the intention is to test the data flowing through the models. However, after coding a couple of models, we found the need to have unit tests for models to test the model logic with mocked data. Also, the expected behaviour of unit tests consists of:

- Ability to mock dependencies
- Ability to run each test independently
- Fast feedback loop
- Good Test Feedback

## SQL First

We believe using SQL for the tests is the best approach we can take, with some help from Jinja macros. It could be debatable, but we think using SQL requires less knowledge and a friendlier learning curve.

## How

We have a set of Jinja macros that allow you to define your mocks and the test scenario. With your test definition, we generate a big SQL query representing the test and run the query against a dev environment. The tests can run in two different ways:

- without any dependencies of artifacts (models, sources, snapshots). You don't need models or sources on the dev environment for testing; it just uses the SQL Engine. However, you must mock all the dependencies and all the columns in tests.
- with dependencies of artifact definition (defined models, sources or snapshots). It means that we can use your model definition to make your test simpler. For instance, if you have a model with 20 columns to mock and just want to mock one, we can grab the missing columns from your model/source definition and save you the work. You also need to have them refreshed to run the tests.

Both strategies have pros and cons. We think you should use the tests without any dependencies till you think it's unusable and hard to maintain.

## Main Features

- Use mocked inputs on any model, source or snapshot
- Define mock inputs with SQL or, if you prefer, in a tabular format within the test
- Run tests without the need to run dbt and install the models into a database.
- Focus the test on what's important
- Provide fast and valuable feedback
- Write more than one test on a dbt test file

# Documentation

## Anatomy of a test

The test is composed of a test setup (mocks) and expectations:

```jinja
{{ config(tags=['unit-test']) }}

{% call dbt_unit_testing.test ('[Model to Test]','[Test Name]') %}
  {% call dbt_unit_testing.mock_ref ('[model name]') %}
     select ...
  {% endcall %}

  {% call dbt_unit_testing.mock_source('[source name]') %}
    select ...
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select ...
  {% endcall %}

{% endcall %}
```

The first line is boilerplate we can't avoid:

```jinja
{{ config(tags=['unit-test']) }}
```

We leverage the command dbt test to run the unit tests; then, we need a way to isolate the unit tests. The rest of the lines are the test itself, the mocks (test setup) and expectations.

### Creating multiple tests in the same file

When creating multiple tests in the same test file, you need to make sure they are all separated by an `UNION ALL` statement: 

```Jinja
{{ config(tags=['unit-test']) }}

{% call dbt_unit_testing.test ('[Model to Test]','[Test Name]') %}
  {% call dbt_unit_testing.mock_ref ('[model name]') %}
     select ...
  {% endcall %}

  {% call dbt_unit_testing.mock_source('[source name]') %}
    select ...
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select  ...
  {% endcall %}

{% endcall %}

UNION ALL

{% call dbt_unit_testing.test ('[Model to Test]','[Another Test]') %}
  {% call dbt_unit_testing.mock_ref ('[model name]') %}
     select ...
  {% endcall %}

  {% call dbt_unit_testing.mock_source('[source name]') %}
    select ...
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select  ...
  {% endcall %}

{% endcall %}
```

### Expectations

The expectations are the results you expect from the model. The framework compares the expectations with the actuals and shows the differences in the test report.

```jinja
{% call dbt_unit_testing.expect() %}
  select ...
{% endcall %}
```

You can use the macro `expect_no_rows` to test if the model returns no rows:

```jinja
{% call dbt_unit_testing.expect_no_rows() %}
{% endcall %}
```

## Running tests

The framework leverages the dbt test command to run the tests. You can run all the tests in your project with the following command:

```bash
dbt test
```

If you want to run just the unit tests, you can use the following command:

```bash
dbt test --select tag:unit-test
```

## Available Macros

| macro name                      | description                                     |
|---------------------------------|-------------------------------------------------|
| dbt_unit_testing.test           | Defines a Test                                  |
| dbt_unit_testing.mock_ref       | Mocks a **model** / **snapshot** / **seed**     |
| dbt_unit_testing.mock_source    | Mocks a **source**                              |
| dbt_unit_testing.expect         | Defines the Test expectations                   |
| dbt_unit_testing.expect_no_rows | Used to test if the model returns no rows       |

## Test Examples

We've created an illustrative test suite for the [jaffle-shop](/jaffle-shop/). Let's pick one test to illustrate what we've been talking about:

```jinja
{{ config(tags=['unit-test']) }}

{% call dbt_unit_testing.test('customers', 'should sum order values to calculate customer_lifetime_value') %}
  
  {% call dbt_unit_testing.mock_ref ('stg_customers') %}
    select 1 as customer_id, '' as first_name, '' as last_name
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_orders') %}
    select 1001 as order_id, 1 as customer_id, null as order_date
    UNION ALL
    select 1002 as order_id, 1 as customer_id, null as order_date
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_payments') %}
    select 1001 as order_id, 10 as amount
    UNION ALL
    select 1002 as order_id, 10 as amount
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 1 as customer_id, 20 as customer_lifetime_value
  {% endcall %}
{% endcall %}

```

Looking at the first macro:

```jinja
{% call dbt_unit_testing.test('customers', 'should sum order values to calculate customer_lifetime_value') %}
```

You can see that the test is about the 'customers' model, and the test description means that it tests the calculation of the customer_lifetime_value. The model customers has three dependencies:

- 'stg_customers'
- 'stg_orders'
- 'stg_payments'

Then the test setup consists of 3 mocks.

```jinja

  {% call dbt_unit_testing.mock_ref ('stg_customers') %}
    select 1 as customer_id, '' as first_name, '' as last_name
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_orders') %}
    select 1001 as order_id, 1 as customer_id, null as order_date
    UNION ALL
    select 1002 as order_id, 1 as customer_id, null as order_date
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_payments') %}
    select 1001 as order_id, 10 as amount
    UNION ALL
    select 1002 as order_id, 10 as amount
  {% endcall %}

```

It creates a scenario with a single user with two orders and two payments that we use to ensure the
calculation is correct with the following expectation:

```jinja

  {% call dbt_unit_testing.expect() %}
    select 1 as customer_id, 20 as customer_lifetime_value
  {% endcall %}

```

And that's the test decomposed by the main parts. In detail, you can look at our test examples [here](/jaffle-shop/tests/unit/tests.sql).

## Different ways to build mock values

Instead of using standard SQL to define your input values, you can use a tabular format like this:

```jinja
{% call dbt_unit_testing.test('customers', 'should sum order values to calculate customer_lifetime_value') %}
  
  {% call dbt_unit_testing.mock_ref ('stg_customers', {"input_format": "csv"}) %}
    customer_id, first_name, last_name
    1,'',''
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_orders', {"input_format": "csv"}) %}
    order_id,customer_id,order_date
    1001,1,null
    1002,1,null
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_payments', {"input_format": "csv"}) %}
    order_id,amount
    1001,10
    1002,10
  {% endcall %}

  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}
    customer_id,customer_lifetime_value
    1,20
  {% endcall %}
{% endcall %}

```

All the unit testing macros (**`mock_ref`**, **`mock_source`**, **`expect`**) accept an `options` parameter :

- `input_format`: "sql" or "csv" (default = "sql")
- `column_separator` (default = ",")
- `type_separator` (default = "::")
- `line_separator` (default = "\n")

(the last three options are used only for `csv` format)

These defaults can also be changed project-wise, in the vars section of your `dbt_project.yml`:

```yaml
vars:
  unit_tests_config:
    input_format: "csv"
    column_separator: "|"
    line_separator: "\n"
    type_separator: "::"
```

With the above configuration, you could write your tests like this:

```jinja
{% call dbt_unit_testing.test('customers', 'should sum order values to calculate customer_lifetime_value') %}
  
  {% call dbt_unit_testing.mock_ref ('stg_customers', {"input_format": "csv"}) %}
    customer_id | first_name | last_name
    1           | ''         | ''
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_orders', {"input_format": "csv"}) %}
    order_id | customer_id | order_date::date
    1        | 1           | null
    2        | 1           | null
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_payments', {"input_format": "csv"}) %}
    order_id | amount::int
    1        | 10
    2        | 10
  {% endcall %}

  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}
    customer_id | customer_lifetime_value
    1           | 20
  {% endcall %}
{% endcall %}

```

Notice that you can specify the type of a column by adding the type name after the column name, separated by "::".

The name of the type is the same as the name of the type in the database (e.g. `int`, `float`, `date`, `timestamp`, etc).

## Mocking

Mocks can be completely independent of the dev/test environment if you set up all the required dependencies (it's explained here [How](#how).

Let's take a look into another [jaffle-shop](/jaffle-shop/) example, an almost dumb test, but it illustrates well:

```jinja
{% call dbt_unit_testing.test('customers', 'should show customer_id without orders') %}
  {% call dbt_unit_testing.mock_ref ('stg_customers') %}
    select 1 as customer_id, '' as first_name, '' as last_name
  {% endcall %}

  {% call dbt_unit_testing.mock_ref ('stg_orders') %}
    select null::numeric as customer_id, null::numeric as order_id, null as order_date  
    where false
  {% endcall %}

  {% call dbt_unit_testing.mock_ref ('stg_payments') %}
     select null::numeric as order_id, null::numeric as amount 
     where false
  {% endcall %}
  
  {% call dbt_unit_testing.expect() %}
    select 1 as customer_id
  {% endcall %}
{% endcall %}

```

It tests the customer_id that comes from the stg_customers, but the setup contains other details that enable the test to run without any dependencies on existing models/sources.

As mentioned, there's a possibility to improve the test setup.
You can use the option **'include_missing_columns'** in the mocks:

```jinja
{% set options = {"include_missing_columns": true} %}

{% call dbt_unit_testing.test('customers', 'should show customer_id without orders') %}
  
  {% call dbt_unit_testing.mock_ref ('stg_customers', options) %}
    select 1 as customer_id
  {% endcall %}

  {% call dbt_unit_testing.expect() %}
    select 1 as customer_id
  {% endcall %}
{% endcall %}
```

 Much simpler to read and maintain, but there's a cost! You need the **sources** defined and updated in your test/dev env.

 **'include_missing_columns'** inspects your models and sources to calculate what columns are missing in each mock. When a mock is missing, the framework infers the mock from the models and sources, if they exist.

 Each approach has pros and cons, so it's up to you to decide if you want to depend on the underlying table definitions.

### Database dependencies in detail

The framework infers the missing columns and missing mocks by building the SQL of the underlying models recursively, down to the sources.
This SQL can be a pretty complex query; sometimes, it's non-performant or even a blocker.

You can use the option **'use-database-models'** to avoid the recursive inspection and use the model defined in the database. Be aware that this makes a new dependency on the underlying model definition, and it needs to be updated each time you run a test.

### Important Requirement

To be able to mock the models and sources in tests, in your dbt models you can use the macros  **dbt_unit_testing.ref** and **dbt_unit_testing.source**, for example:

```sql

    select * from {{ dbt_unit_testing.ref('stg_customers') }}

```

Alternatively, if you prefer to keep using the standard `ref` and `source` macros in the models, you can override them by adding these lines to your project:

```jinja
{% macro ref() %}
   {{ return(dbt_unit_testing.ref(*varargs, **kwargs)) }}
{% endmacro %}

{% macro source() %}
   {{ return(dbt_unit_testing.source(*varargs, **kwargs)) }}
{% endmacro %}
```

If you need to use the original dbt *ref* macro for some reason (in *dbt_utils.star* macro, for instance), you can use *builtins.ref*, like this:

```jinja
select {{ dbt_utils.star(builtins.ref('some_model')) }}
from {{ ref('some_model') }}
```

## Model versions

You can specify a model version on the `dbt_unit_testing.ref` macro, the same way you do on the dbt ref macro:

```jinja
{% call dbt_unit_testing.ref('some_model', version=3) %}
```

or

```jinja
{% call dbt_unit_testing.ref('some_model', v=3) %}
```

if you are overriding the ref and source macros in your project, please use the new way of doing it ([here](#requirement)). This is necessary for the version parameter to work:

```jinja
{% macro ref() %}
   {{ return(dbt_unit_testing.ref(*varargs, **kwargs)) }}
{% endmacro %}

{% macro source() %}
   {{ return(dbt_unit_testing.source(*varargs, **kwargs)) }}
{% endmacro %}
```

### Testing Model versions

You can test a specific model version by specifying the `version` parameter on the `dbt_unit_testing.test` macro:

```jinja
{% call dbt_unit_testing.test('some_model', 'should return 1', version=3) %}
  {% call dbt_unit_testing.expect() %}
    select 1
  {% endcall %}
{% endcall %}
```

If `version` is not specified, the test will run against the latest version of the model.

It is also possible to mock a specific model version, again by specifying the `version` parameter on the `dbt_unit_testing.mock_ref` macro:

```jinja
{% call dbt_unit_testing.mock_ref('some_model', version=3) %}
  select 1
{% endcall %}
```

If `version` is not specified, the latest version of the model will be mocked.

## Incremental models

You can write unit tests for incremental models. To enable this functionality, you should add the following code to your project:

```jinja
{% macro is_incremental() %}
  {{ return (dbt_unit_testing.is_incremental()) }}
{% endmacro %}
```

Here's an example of how you can test a model using this approach.

Consider the following model:

```jinja
{{ config (materialized = 'incremental' ) }}

select c from {{ dbt_unit_testing.ref('some_model') }}

{% if is_incremental() %}
  where c > (select max(c) from {{ this }})
{% endif %}
```

When writing a test for this model, it will simulate the model running in `full-refresh` mode, without the `is_incremental` section:

```jinja
{% call dbt_unit_testing.test('incremental_model', 'full refresh test') %}
  {% call dbt_unit_testing.mock_ref ('model_for_incremental') %}
    select 10 as c
    UNION ALL
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('incremental_model') %}
    select 15 as c
    UNION ALL
    select 25 as c
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 10 as c
    UNION ALL
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
{% endcall %}
```

As you can observe, the existing rows for the incremental_model were deleted, and the model performed a `full-refresh` operation, which is reflected in the expectations.

To test the `is_incremental` section of your model, you must include the option {"run_as_incremental": "True"} in your test. Here's an example using the above model:

```jinja
{% call dbt_unit_testing.test('incremental_model', 'incremental test', options={"run_as_incremental": "True"}) %}
  {% call dbt_unit_testing.mock_ref ('some_model') %}
    select 10 as c
    UNION ALL
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
  {% call dbt_unit_testing.mock_ref ('incremental_model') %}
    select 10 as c
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 20 as c
    UNION ALL
    select 30 as c
  {% endcall %}
{% endcall %}
```

Note that in this case, we are also mocking the model being tested (`incremental_model`) to ensure the incremental logic functions correctly. It is necessary to mock the model itself when writing a test for the `is_incremental` part of the model.

*Note: As previously mentioned, these type of tests are meant to test the `is_incremental` part of the model. Testing different increments strategies (such as `merge`, `delete+insert` or `insert_overwrite`) is not supported.*

## Column Transformations

This functionality allows for the application of transformations to columns before the execution of unit tests.

Column transformations enable the alteration of column data, catering to the need for data standardization, conversion, or formatting prior to testing. This addition aims to support more sophisticated testing requirements and ensure data integrity within the testing process.

### How to use

To leverage the column transformations feature in `dbt-unit-testing`, you need to define a JSON structure specifying the desired transformations for each column. This structure is integrated into the unit test options. Below is an example of how to format this JSON structure:

```Json
{
  "col_name_1": "round(col_name_1, 4)",
  "col_name_2": "to_json_string(col_name_2)"
}
```

You can assign this JSON into a variable and pass it into the unit test options. Below is an example of how to do this:

```Jinja
{% set column_transformations = {
  "col_name_1": "round(col_name_1, 4)",
  "col_name_2": "to_json_string(col_name_2)"
} %}

{% call dbt_unit_testing.test('some_model_name', options={"column_transformations": column_transformations}) %}

...
```

In this example, `col_name_1` is rounded to four decimal places, and `col_name_2` is converted to a JSON string. These transformations are applied before the execution of the unit test.

In addition to specifying column transformations at the individual test level, `dbt-unit-testing` also allows for a more generalized approach. You can define column transformations globally in the dbt_project.yml file. This approach allows for the application of column transformations to all unit tests in the project.

Here is an example of how to set up column transformations in the dbt_project.yml file:

```yaml
vars:
  unit_tests_config:
    column_transformations:
      some_model_name:
        col_name_1: round(col_name_1, 4)
        # ... additional transformations for 'some_model_name'
      another_model_name:
        # ... transformations for 'another_model_name'
```

In this configuration, transformations such as `round(col_name_1, 4)` are applied to `col_name_1` in the context of `some_model_name`.

You can also use the special token `##column##` in your column transformations. This token will be replaced by the column name in the test query, properly quoted for the current database adapter:


```yaml
vars:
  unit_tests_config:
    column_transformations:
      some_model_name:
        col_name_1: "round(##column##, 2)"
        # ... additional transformations
```

In this example, `round(##column##)` will be evaluated such that `##column##` is replaced with the properly quoted name of `col_name_1`. This ensures that the column name is correctly formatted for the database adapter in use.

### Use Case 1: Rounding Column Values

In many scenarios, especially when dealing with floating-point numbers, precision issues can arise, leading to inconsistencies in data testing. For example, calculations or aggregations may result in floating-point numbers with excessive decimal places, making direct comparisons challenging. To address this, `dbt-unit-testing` can round these values to a specified number of decimal places, ensuring consistency and precision in tests.

Consider a model, `financial_model`, which contains a column `avg_revenue` representing the average of the revenue values from another table. Due to calculations, `avg_revenue` might have an extensive number of decimal places. For testing purposes, you might want to round these values to a fixed number of decimal places.

```SQL
SELECT
    id,
    AVG(revenue) as avg_revenue
FROM
    raw_financial_data
```

You can ensure that `avg_revenue` is rounded to five decimal places when testing `financial_model`, and your expectations are also rounded to five decimal places. This ensures that the test is precise and consistent.

```Jinja
{% set column_transformations = {
  "avg_revenue": "round(##column##, 5)"
} %}

{% call dbt_unit_testing.test('financial_model', options={"column_transformations": column_transformations}) %}
  {% call dbt_unit_testing.mock_ref ('raw_financial_data') %}
    select 5.0 as revenue
    UNION ALL
    select 2.0 as revenue
    UNION ALL
    select 3.0 as revenue
  {% endcall %}
  {% call dbt_unit_testing.expect() %}
    select 3.33333 as avg_revenue
  {% endcall %}
{% endcall %}
```

### Use Case 2: Converting Structs to JSON Strings in BigQuery

In BigQuery, certain data types like structs and arrays pose a challenge for `dbt-unit-testing`, because it needs to use the EXCEPT clause. BigQuery does not support these operations directly on structs or arrays. A practical solution is to convert these complex data types into JSON strings, allowing for standard SQL operations to be applied in tests. This can be achieved using column transformations.

Let's consider a model, `user_activity_model`, which includes a struct column `activity_details` in BigQuery. To facilitate testing involving grouping or comparison, we transform `activity_details` into a JSON string.

```SQL
SELECT
    user_id,
    activity_details -- struct column
FROM
    raw_user_activity
```

```Jinja
{% set column_transformations = {
  "activity_details": "to_json_string(##column##)"
} %}

{% call dbt_unit_testing.test('user_activity_model', options={"column_transformations": column_transformations}) %}
  -- Test cases and assertions here
{% endcall %}
```

In this example, the `activity_details` column, which is a struct, is transformed into a JSON string using `to_json_string(##column##)` before the execution of the unit test. This transformation facilitates operations like grouping and EXCEPT in BigQuery by converting the struct into a more manageable string format.

## Available Options

| option                      | description                     | default              | scope*              |
|-----------------------------|---------------------------------|--------------------|--------------------|
| **include_missing_columns** | Use the definition of the model to grab the columns not specified in a mock. The columns will be added automatically with *null* values (this option will increase the number of roundtrips to the database when running the test).                          | false | project/test/mock       |
| **use_database_models**     | Use the models in the database instead of the model SQL. <br> This option is used to simplify the final test query if needed                                      | false | project/test/mock       |
| **input_format**            | **sql**: use *SELECT* statements to define the mock values. <br> <br> *SELECT 10::int as c1, 20 as c2 <br> UNION ALL <br>  SELECT 30::int as c1, 40 as c2* <br> <br> **csv**: Use tabular form to specify mock values. <br> <br> c1::int \| c2 <br> 10 \| 20 <br> 30 \| 40                            | sql | project/test       |
| **column_separator**        | Defines the column separator for csv format                     | , | project/test       |
| **line_separator**          | Defines the line separator for csv format                       | \\n | project/test       |
| **type_separator**          | Defines the type separator for csv format                       | :: | project/test       |
| **use_qualified_sources**   | Use qualified names (source_name + table_name) for sources when building the CTEs for the test query. It allows you to have source models with the same name in different sources/schema.                         | false | project            |
| **disable_cache**        | Disable cache                             | false| project            |
| **diff_column**        | The name of the `diff` column in the test report        | diff| project/test            |
| **count_column**        | The name of the `count` column in the test report        | count| project/test            |
| **run_as_incremental**      | Runs the model in `incremental` mode (it has no effect if the model is not incremental)     | false| project/test            |
| **column_transformations**      | A JSON structure specifying the desired transformations for each column. See [Column Transformations](#column-transformations) for more details.     | {}| project/test            |
| last_spaces_replace_char | Replace the spaces at the end of the values with another character. See [Test Feedback](#test-feedback) for more details. | (space) | project/test |

Notes:

- **scope** is the place where the option can be defined:
  - if the scope is project you can define the option as a global setting in the project.yml
  - if the scope is test you can define/override the option at the test level
  - if the scope is mock you can define/override the option at the mock level
- **Qualified sources** You must use an alias when referencing sources if you use this option.

## Test Feedback

Good test feedback is what allows us to be productive when developing unit tests and developing our models.
The test macro provides visual feedback when a test fails, showing what went wrong by comparing the lines of the expectations with the actuals.
To make the feedback even more readable, you can provide `output_sort_field` in parameters specifying the field to sort by:  

```jinja
{% call dbt_unit_testing.test('some_model', 'smoke test', {"output_sort_field": "business_id"}) %}

  ...
  
{% endcall %}
```

The result will be displayed the way to compare two adjacent lines conveniently.  

### Example

```yaml
MODEL: customers
TEST:  should sum order values to calculate customer_lifetime_value
Rows mismatch:
| diff | count | customer_id | customer_lifetime_value |
| ---- | ----- | ----------- | ----------------------- |
| +    |     1 |           1 |                      20 |
| -    |     1 |           1 |                      30 |
```

The first line was not on the model, but the second line was.

### Spaces at the end of the diff values

It can be hard to spot the difference when the values have spaces at the end. To avoid this, you can use the option `last_spaces_replace_char` to replace the spaces at the end of the values with another character:

```yaml
vars:
  unit_tests_config:
    last_spaces_replace_char: "."
```

This will replace the spaces at the end of the values with a dot. The result will be displayed like this:

```yaml
MODEL: customers
TEST:  should sum order values to calculate customer_lifetime_value
Rows mismatch:
| diff | count | some_column |
| ---- | ----- | ----------- |
| +    |     1 | John        |
| -    |     1 | John..      |
```

# Known Limitations

- You can not have a *model* with the same name as a *source* or a *seed* (unless you set the *use_qualified_sources* option to *true*).

- With our current approach, there's an extra step that you need to take if you want to use the builtins *ref* or *source* macros in your models (in *dbt_utils.star*, for instance). Otherwise, you'll get an error like this one:

```jinja
Compilation Error in test some_model_test (tests/unit/some_model_test.sql)
    dbt was unable to infer all dependencies for the model "some_model_test".
    This typically happens when ref() is placed within a conditional block.
    
    To fix this, add the following hint to the top of the model "some_model_test":
    
    -- depends_on: {{ ref('some_model') }}
````

In this situation, you need to add this line to the top of your **test** (**not the model!**):

```jinja
-- depends_on: {{ ref('some_model') }}
{{
    config(
        tags=['unit-test']
    )
}}

{% call dbt_unit_testing.test('model_being_tested', 'sample test') %}

... ... ... ... ... 

```



# Compatibility

[x] dbt > 0.20

[x] BigQuery

[x] Snowflake

[x] Postgres

[ ] Redshift

# License

This project is [licensed](./LICENSE) under the [MIT License](https://mit-license.org/).
