#!/bin/bash
dbt test --data --exclude tag:unit-test
