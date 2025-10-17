#!/usr/bin/env bash
set -euo pipefail

# Use provided paths (space-separated) or default to '.'
if [ "$#" -eq 0 ]; then
  TARGETS=(".")
else
  TARGETS=()
  for d in "$@"; do
    d="${d#@}"              # allow '@dir' style
    TARGETS+=("$d")
  done
fi

echo "=== Scan targets ==="
printf '%s\n' "${TARGETS[@]}"

echo
echo "=== Heuristics: Candidate Fields (PII, auth, finance) ==="
rg -n --no-heading -S \
  -e '\b(email|e-mail|phone|msisdn|full[_-]?name|first[_-]?name|last[_-]?name|dob|birth[_-]?date|nid|ktp|id_no|npwp|passport|address|street|city|province|postal|zip|lat|lng|location|imei|device[_-]?id|ip[_-]?address|card[_-]?number|pan|cvv|exp(ir|iry)|account[_-]?number|iban|swift|tax|salary|gender|religion|biometric|health)\b' \
  "${TARGETS[@]}" || true

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

# --- Spring Boot / JPA / Hibernate entities ---
rg -n --no-heading -S \
  -e '@Entity\b|@Table\b|@Column\b|@Id\b|@Join(Column|Table)\b|@GeneratedValue\b|extends\s+JpaRepository|CrudRepository|JpaSpecificationExecutor' \
  -g '*.java' "${TARGETS[@]}" || true

# --- Mongoose (MongoDB) schema definitions ---
rg -n --no-heading -S -g '!node_modules' \
  -e '\b(mongoose\.model|Mongoose\.model|mongoose\.Schema|new\s+Schema\(|Schema\()\b' \
  -g '*.js' -g '*.ts' "${TARGETS[@]}" || true

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
