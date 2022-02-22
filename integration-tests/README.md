### Run tests locally
To run the integration tests on your local machine using postgres, you can do the following:

#### Change the ci/profiles.yml

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

#### Run the following command inside the integration_tests folder

```bash
make TARGET=postgres
```
