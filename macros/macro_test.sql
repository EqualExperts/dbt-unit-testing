-- Macros for unit testing macros.
--
-- The macros in this file are intended for testing macros instead of models.
--
-- Inspiration for assert_* macros was taken from: 
-- https://github.com/yu-iskw/dbt-unittest
-- but instead of raising exceptions on failure, the tests print failure
-- messages and feel much like the model tests that are written
-- with dbt_unit_testing.test()

-- macro_test runs a unit test.
--
-- Use with a {% call macro_test... %} test body {% endcall %} from .sql files
-- in the tests directory.
-- 
-- If the test body returns anything other than white space, it will
-- be considered a failure, and the content will be printed.
--
-- Tests written this way are executed with the dbt test command.
{% macro macro_test(description='unspecified', options={}) -%}
    {# If caller returns anything, it's considered a failure #}
    {%- if execute -%}
    
        {# Set up mocks specified in options. #}
        {% set mocks = [] %}
        {% for pkg, macro_name, mock_fn in options.get('mocks', []) %}
            {% do mocks.append(
                dbt_unit_testing.mock_macro(pkg, macro_name, mock_fn=mock_fn)) %}
        {% endfor %}

        {# Run the test. #}
        {%- set res = caller()|trim -%}
        {%- if res -%}
            {{ dbt_unit_testing.println('{RED}TEST:  {YELLOW}' ~ description) }}
            {{ dbt_unit_testing.println('{RED}ERROR: {YELLOW}' ~ res) }}
            select 1 as fail
        {%- else -%}
            {# Test passed. Return a query that returns zero rows #}
            select 1 from (select 1) as t where false
        {%- endif -%}
        
        {# Restore mocks. #}
        {% for m in mocks %}
            {% do m.restore() %}
        {% endfor %}
    {%- endif -%}
{%- endmacro %}


-- An alternative way to write tests. Each test is given a helper object t
-- with methods for creating mocks that can be tracked and cleaned up
-- automatically at the end of each test.
{% macro macro_test_with_t(description='unspecified', options={}) -%}
    {# If caller returns anything, it's considered a failure #}
    {%- if execute -%}
        {# Run the test. It may call t.mock() to set up mocks. #}
        {% set t = dbt_unit_testing._new_t(description, options) %}
        {%- set res = caller(t)|trim -%}
        {%- if res -%}
            {{ dbt_unit_testing.println('{RED}TEST:  {YELLOW}' ~ description) }}
            {{ dbt_unit_testing.println('{RED}ERROR: {YELLOW}' ~ res) }}
            select 1 as fail
        {%- else -%}
            {# Test passed. Return a query that returns zero rows #}
            select 1 from (select 1) as t where false
        {%- endif -%}
        
        {# Restore mocks. #}
        {% for m in t.mocks %}
            {% do m.restore() %}
        {% endfor %}
    {%- endif -%}
{%- endmacro %}

{% macro _new_t(description, options) %}
    {% set t = {
        'description': description,
        'options': options,
        'assert_true': dbt_unit_testing.assert_true,
        'assert_equal': dbt_unit_testing.assert_equal,
        'mocks': [],
    } %}

    {% call(pkg, name, mock_fn=None, return_value=None) dbt_unit_testing.make_func(t, 'mock') %}
        {% if caller and not mock_fn %}
            {% set mock_fn = caller %}
        {% endif %}
        {% set m = dbt_unit_testing.mock_macro(
            pkg, name, mock_fn=mock_fn, return_value=return_value) %}
        {% do t.mocks.append(m) %}
        {# TODO: return m when https://github.com/dbt-labs/dbt-core/issues/7144 is fixed. #}
        {# {{ return(m) }} #}
    {% endcall %}

    {{ return(t) }}
{% endmacro %}

-- Returns an error message if b is not true.
{% macro assert_true(b, description='') -%}
    {%- if b is not true -%}
        {{ b }} is not true{{ ': %s' % description if description else '' }}
    {%- endif -%}
{%- endmacro %}

-- Returns an error message if the values are not equal.
{% macro assert_equal(actual, expected, description='') -%}
    {%- if actual != expected -%}
        Values are not equal
        actual:   {{ actual }} 
        expected: {{ expected }}
        {{ description }}
    {%- endif -%}
{%- endmacro %}

-- Mocks the implementation of a macro and returns a mock object.
{% macro mock_macro(package, macro_name, mock_fn=None, return_value=None) %}
  {% set m = {
    'package': package,
    'macro_name': macro_name,
    'return_value': return_value,
    'original_fn': package[macro_name],
    'mock_fn': mock_fn,
    'calls': [],
  } %}

  {% call dbt_unit_testing.make_func(m, 'restore') %}
    {% do m.package.update({m.macro_name: m.original_fn}) %}
  {% endcall %}

  {# If mock_fn is given, use it, otherwise, create a mock_fn 
   # that returns return_value. #}
  {% if not mock_fn %}
    {%- call dbt_unit_testing.make_func(m, 'mock_fn') -%}
      {%- set c = {
        'args': varargs,
        'kwargs': kwargs,
      } -%}
      {%- do m.calls.append(c) -%}
    {# TODO: Why can I return here unaffected by 
     # https://github.com/dbt-labs/dbt-core/issues/7144 ?
     #}
      {{ return(m.return_value) }}
    {%- endcall -%}
  {% endif %}

  {% do package.update({macro_name: m.mock_fn}) %}
  
  {{ return(m) }}
{% endmacro %}

{% macro make_func(o, name) %}
  {% do o.update({name: caller}) %}
{% endmacro %}

{% macro mock_example(s) %}
    {{ return(dbt_unit_testing.sanitize(s)) }}
{% endmacro %}
