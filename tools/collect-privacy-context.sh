#!/usr/bin/env bash
set -euo pipefail

# Default values
MODEL_DEFS=()
COVERAGE_DIRS=()

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --model-defs)
      shift
      while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
        MODEL_DEFS+=("$1")
        shift
      done
      ;;
    --coverage-dirs)
      shift
      while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
        COVERAGE_DIRS+=("$1")
        shift
      done
      ;;
    *)
      echo "Unknown parameter passed: $1"
      exit 1
      ;;
  esac
done

# If no arguments are provided, scan the entire repository
if [ ${#MODEL_DEFS[@]} -eq 0 ] && [ ${#COVERAGE_DIRS[@]} -eq 0 ]; then
  TARGETS=(".")
else
  TARGETS=("${COVERAGE_DIRS[@]}")
fi

echo "=== Scan targets ==="
if [ ${#MODEL_DEFS[@]} -gt 0 ]; then
  echo "Model definitions: ${MODEL_DEFS[*]}"
fi
if [ ${#COVERAGE_DIRS[@]} -gt 0 ]; then
  echo "Coverage directories: ${COVERAGE_DIRS[*]}"
fi
if [ ${#TARGETS[@]} -eq 1 ] && [ "${TARGETS[0]}" == "." ]; then
    echo "Scanning entire repository."
fi


echo
echo "=== Heuristics: Candidate Fields (PII, auth, finance) ==="
if [ ${#MODEL_DEFS[@]} -gt 0 ]; then
  PII_TERMS=$(rg -o -w -e '(email|e-mail|phone|msisdn|full[_-]?name|first[_-]?name|last[_-]?name|dob|birth[_-]?date|nid|ktp|id_no|npwp|passport|address|street|city|province|postal|zip|lat|lng|location|imei|device[_-]?id|ip[_-]?address|card[_-]?number|pan|cvv|exp(ir|iry)|account[_-]?number|iban|swift|tax|salary|gender|religion|biometric|health)' "${MODEL_DEFS[@]}" | sort -u)
  for pii in $PII_TERMS; do
    echo "Scanning for usage of '$pii' in coverage directories..."
    rg -n --no-heading -S -e "$pii" "${COVERAGE_DIRS[@]}" || true
  done
else
  rg -n --no-heading -S \
    -e '\b(email|e-mail|phone|msisdn|full[_-]?name|first[_-]?name|last[_-]?name|dob|birth[_-]?date|nid|ktp|id_no|npwp|passport|address|street|city|province|postal|zip|lat|lng|location|imei|device[_-]?id|ip[_-]?address|card[_-]?number|pan|cvv|exp(ir|iry)|account[_-]?number|iban|swift|tax|salary|gender|religion|biometric|health)\b' \
    "${TARGETS[@]}" || true
fi


echo
echo "=== Heuristics: Auth/Session/JWT ==="
rg -n --no-heading -S -e '\b(jwt|session|refresh[_-]?token|access[_-]?token|oauth|oidc|sso)\b' "${TARGETS[@]}" || true

echo
echo "=== Heuristics: ORM Models & Migrations (table/column hints) ==="

# --- SQL / Flyway / Liquibase migration files ---
rg -n --no-heading -S -g '!node_modules' \
  -e '\b(CREATE\s+TABLE|ALTER\s+TABLE|ADD\s+COLUMN|DROP\s+COLUMN|PRIMARY\s+KEY|FOREIGN\s+KEY|CONSTRAINT|INDEX|REFERENCES)\b' \
  -g '*.sql' "${TARGETS[@]}" || true

rg -n --no-heading -S -g '!node_modules' \
  -e '\b(flyway|V[0-9]+__.*\.sql|Repeatable\s+migration)\b' \
  -g '*.sql' "${TARGETS[@]}" || true

# --- Sequelize (Node.js) model definitions and migrations ---
rg -n --no-heading -S -g '!node_modules' \
  -e '\b(sequelize\.define|Sequelize\.define|sequelize\.init|DataTypes\.|Sequelize\.DataTypes\.|Model\.init)\b' \
  -g '*.js' -g '*.ts' "${TARGETS[@]}" || true

rg -n --no-heading -S -g '!node_modules' \
  -e '\b(queryInterface\.createTable|queryInterface\.addColumn|queryInterface\.removeColumn|queryInterface\.changeColumn)\b' \
  -g '*.js' -g '*.ts' "${TARGETS[@]}" || true

# --- Prisma schema ---
rg -l 'datasource db' -g '*.prisma' "${TARGETS[@]}" | while read -r schema_file; do
  ./tools/process-prisma-schema.sh "$schema_file"
done || true

# --- Spring Boot / JPA / Hibernate entities ---
rg -l '@Entity' -g '*.java' "${TARGETS[@]}" | while read -r java_file; do
  ./tools/process-jpa-entity.sh "$java_file"
done || true

# --- Mongoose (MongoDB) schema definitions ---
rg -l 'mongoose\.model' -g '*.js' -g '*.ts' "${TARGETS[@]}" | while read -r model_file; do
  ./tools/process-mongoose-model.sh "$model_file"
done || true

echo
echo "=== Heuristics: External Integrations (SDKs/Webhooks/APIs) ==="
rg -n --no-heading -S \
  -e '\baws|gcs|s3|firebase|mixpanel|amplitude|segment|facebook|google(ads|analytics)|mailchimp|mandrill|mailgun|sendgrid|twilio|whatsapp|telegram|slack|sentry|datadog|newrelic|shopify|zendesk|hubspot\b' \
  "${TARGETS[@]}" | rg -v '@Value' || true
rg -n --no-heading -S -e '\bhttps?://[A-Za-z0-9\.\-_/]+(api|webhook)[A-Za-z0-9\.\-_/]*' "${TARGETS[@]}" || true

echo
echo "=== Heuristics: HTTP Endpoints (for processing/transfers) ==="
rg -n --no-heading -S -g '!node_modules' \
  -e '\b(router|routes|route|@Get|@Post|@Put|@Delete|@Patch|@RequestMapping|RestController|Controller|app\.get|app\.post|app\.put|app\.delete|app\.patch|router\.get|router\.post|router\.put|router\.delete|router\.patch)\b' \
  -g '*.js' -g '*.ts' -g '*.java' "${TARGETS[@]}" || true
