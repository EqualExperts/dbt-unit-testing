### Run tests locally
You need to change the ci/profiles.yml postgres:

```yml
   postgres:
      type: postgres
      host: <strike>localhost</strike>postgres
      user: postgres
      pass: postgres
      port: 5432
      schema: dbt_unit_testing
      dbname: postgres
      threads: 1
```

```bash
make TARGET=postgres
```
