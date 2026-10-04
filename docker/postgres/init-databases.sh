#!/usr/bin/env bash
set -euo pipefail

for database in customer_db product_db order_db; do
  psql --set ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    --command "CREATE DATABASE $database;"
done
