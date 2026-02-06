#!/usr/bin/env bash
set -euo pipefail

echo "Running startup tasks..."
echo "Python: $(python --version)"
echo "Working directory: $(pwd)"

# Run migrations (allow failures transiently)
echo "Applying migrations"
if python manage.py migrate --noinput; then
	echo "migrate succeeded"
else
	echo "migrate failed with exit code $?"
fi

echo "Current DB tables:" 
python - <<'PY'
from django.db import connection
try:
	connection.ensure_connection()
	print(connection.introspection.table_names())
except Exception as e:
	print('Failed to inspect DB tables:', e)
PY

echo "Collecting static files"
python manage.py collectstatic --noinput || echo "collectstatic failed"

echo "Starting Gunicorn"
exec gunicorn elektronika.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 1
