#!/usr/bin/env bash
set -euo pipefail

echo "Running startup tasks..."
echo "Python: $(python --version)"
echo "Working directory: $(pwd)"

# Ensure persistent storage directories exist on Render
if [ -n "$RENDER" ]; then
	echo "Creating persistent storage directories on Render"
	mkdir -p /data/zdjęcia
	chmod 755 /data
	chmod 755 /data/zdjęcia
fi

# Run migrations - MUST succeed
echo "Applying migrations..."
if ! python manage.py migrate --noinput; then
	echo "ERROR: Database migrations failed! Aborting startup."
	exit 1
fi
echo "✓ Migrations completed successfully"

# Show database tables
echo "Current DB tables:"
python - <<'PY'
from django.db import connection
try:
	connection.ensure_connection()
	tables = connection.introspection.table_names()
	print(f"Found {len(tables)} tables:", tables)
except Exception as e:
	print('ERROR: Failed to inspect DB tables:', e)
	exit(1)
PY

echo "Collecting static files..."
python manage.py collectstatic --noinput || echo "WARNING: collectstatic had issues (non-critical)"

echo "Starting Gunicorn on port ${PORT:-8000}..."
exec gunicorn elektronika.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 1
