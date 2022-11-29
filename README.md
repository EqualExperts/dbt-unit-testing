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
  - [Available Macros](#available-macros)
  - [Test Examples](#test-examples)
  - [Different ways to build mock values](#different-ways-to-build-mock-values)
  - [Mocking](#mocking)
    - [Database dependencies in detail](#database-dependencies-in-detail)
    - [Requirement](#requirement)
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
    revision: v0.2.6
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
    select  ...
  {% endcall %}

{% endcall %}
```

The first line is boilerplate we can't avoid:

```jinja
{{ config(tags=['unit-test']) }}
```

We leverage the command dbt test to run the unit tests; then, we need a way to isolate the unit tests. The rest of the lines are the test itself, the mocks (test setup) and expectations.

## Available Macros

- **dbt_unit_testing.test** Macro used to define a test.
- **dbt_unit_testing.mock-ref** Macro used to mock a model/snapshot/seed.
- **dbt_unit_testing.mock-source** Macro used to mock a source.
- **dbt_unit_testing.expect** Macro used to define the test expectations.

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
    order_id | customer_id | order_date 
    1        | 1           | null
    2        | 1           | null
  {% endcall %}
  
  {% call dbt_unit_testing.mock_ref ('stg_payments', {"input_format": "csv"}) %}
    order_id | amount
    1        | 10
    2        | 10
  {% endcall %}

  {% call dbt_unit_testing.expect({"input_format": "csv"}) %}
    customer_id | customer_lifetime_value
    1           | 20
  {% endcall %}
{% endcall %}

{% endcall %}
```

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

### Requirement

To be able to mock the models and sources in tests, in your dbt models you **must** use the macros  **dbt_unit_testing.ref** and **dbt_unit_testing.source**, for example:

```sql

    select * from {{ dbt_unit_testing.ref('stg_customers') }}

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

If you need to use the original dbt *ref* macro for some reason (in *dbt_utils.star* macro, for instance), you can use *builtins.ref*, like this:

```jinja
select {{ dbt_utils.star(builtins.ref('some_model')) }}
from {{ ref('some_model') }}
```

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
