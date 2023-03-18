## Unit testing jaffle_shop

This project illustrates the usage of dbt-unit-testing in dbt's fictional ecommerce store.

### What's in this repo?
This repo contains the original [jaffle_shop](https://github.com/dbt-labs/jaffle_shop) project structure plus [unit tests](./tests/unit/).

The project is composed by seeds to simulate data from three entities Customers, Orders and Payments, with the following entity-relationship diagram:

![Jaffle Shop ERD](./etc/jaffle_shop_erd.png)

Using the described seeds, there's a [staging layer](./models/staging/) composed by one model per each seed, and the final model is a [customers model](./models/customers.sql) with the following calculated fields: first_order, most_recent_order and number_of_orders.


(Orders model was removed from the original jaffle_shop for simplicity)
### Unit tests
To illustrate how you can do unit testing using the dbt-unit-testing framework, there is a test suite that you can inspect. We've created 3 different files that corresponds to the same test suite, but with different mocking strategies. If you're not familiar with mocking strategies please check the (../README.md).

- [Tests using full mocking strategy](./tests/unit/tests_using_full_mocking_strategy_and_sql_input.sql)
- [Tests using simplified mocking strategy](./tests/unit/tests_using_simplified_mocking_strategy_and_sql_input.sql)
- [Tests using pure mocking strategy](./tests/unit/tests_using_pure_mocking_strategy_and_sql_input.sql) 
  
Inside each test file there are exatly **the same tests** so you can compare the pure strategy (simplest) with more helpfull strategies Full/Simplified. 

Note: when using Full/Simplified mocking strategies, they're relying in documentation of seeds and models, not in database dependencies.

### Run the sample project in your machine
If you want to run the tests on your machine and play with the examples:

1. You need to have docker.
2. Clone this repository.
3. Use make to run
```
make
```
