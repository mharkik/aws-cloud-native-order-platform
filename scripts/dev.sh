#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

select_java() {
  if [[ "$(uname -s)" == Darwin ]]; then
    export JAVA_HOME
    JAVA_HOME=$(/usr/libexec/java_home -v 25)
  fi
  if [[ -n "${JAVA_HOME:-}" ]]; then
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
  if ! java -version 2>&1 | head -n 1 | grep -Eq 'version "25([.\"]|$)'; then
    echo 'JDK 25 is required. Set JAVA_HOME to your JDK 25 installation.' >&2
    exit 1
  fi
}

load_env() {
  if [[ ! -f .env ]]; then
    echo 'Run ./scripts/dev.sh setup first.' >&2
    exit 1
  fi
  set -a
  source .env
  set +a
  : "${POSTGRES_PASSWORD:?Set POSTGRES_PASSWORD in .env}"
}

case "${1:-help}" in
  setup)
    select_java
    python3 - <<'PY'
import os
import secrets
from pathlib import Path
path = Path('.env')
if not path.exists():
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as file:
        file.write('POSTGRES_USER=orderplatform\nPOSTGRES_PASSWORD=' + secrets.token_hex(24) + '\nPOSTGRES_PORT=5432\n')
    print('Created ignored .env with a random local PostgreSQL password.')
else:
    print('Existing .env preserved.')
PY
    ;;
  doctor)
    select_java
    java -version
    ./mvnw --version
    git --version
    docker --version
    docker compose version
    docker info --format 'Docker server: {{.ServerVersion}}'
    ;;
  build)
    select_java
    exec ./mvnw --batch-mode verify
    ;;
  db-up)
    load_env
    exec docker compose up -d --wait postgres
    ;;
  db-down)
    exec docker compose down
    ;;
  run)
    select_java
    case "${2:-}" in
      customer-service|product-service|order-service) load_env ;;
      notification-service) ;;
      *) echo 'Specify customer-service, product-service, order-service or notification-service.' >&2; exit 1 ;;
    esac
    exec ./mvnw --batch-mode -pl "services/$2" spring-boot:run
    ;;
  smoke)
    for port in 8081 8082 8083 8084; do
      response=$(curl --fail --silent --show-error --max-time 10 "http://localhost:$port/actuator/health")
      python3 -c 'import json,sys; result=json.load(sys.stdin); assert result["status"] == "UP", result' <<< "$response"
      echo "Port $port: UP"
    done
    ;;
  *)
    echo 'Usage: ./scripts/dev.sh {setup|doctor|build|db-up|db-down|run SERVICE|smoke}'
    ;;
esac
