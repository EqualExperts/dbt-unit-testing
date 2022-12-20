# Run tests locally

To run the integration tests on your local machine using postgres, you can do the following:

- Change the ci/profiles.yml

```diff
   postgres:
      type: postgres
-     host: localhost
+     host: postgres
      user: postgres
      pass: postgres
      port: 5432
      schema: dbt_unit_testing
      dbname: postgres
      threads: 1
```

- Run the following command inside the integration_tests folder

```bash
make TARGET=postgres
```

- The metrics tests uses dbt version `1.3.1` and copies the folder `tests/fixtures/metrics` to `models/`. The reason is that
other versions of dbt will break if those models are present. At the end of the testing the folder is removed again.
