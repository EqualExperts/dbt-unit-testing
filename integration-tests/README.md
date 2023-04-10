# Run tests locally

To run the integration tests on your local machine using postgres, you can do the following:

Run the following command inside the `integration-tests` folder:

```bash
make TARGET=postgres
```

- The metrics tests uses dbt version `1.3.1` and copies the folder `tests/fixtures/metrics` to `models/`. The reason is that
other versions of dbt will break if those models are present. At the end of the testing the folder is removed again.
