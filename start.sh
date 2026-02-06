#!/usr/bin/env bash
set -euo pipefail

echo "Running startup tasks..."
echo "Python: $(python --version)"
echo "Working directory: $(pwd)"

# Run migrations (allow failures transiently)
echo "Applying migrations"
python manage.py migrate --noinput || (echo "migrate failed"; exit 1)

echo "Collecting static files"
python manage.py collectstatic --noinput || echo "collectstatic failed"

echo "Starting Gunicorn"
exec gunicorn elektronika.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 1
