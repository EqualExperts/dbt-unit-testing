#!/bin/bash
dbt test --data --models tag:unit-test --profiles-dir resources
