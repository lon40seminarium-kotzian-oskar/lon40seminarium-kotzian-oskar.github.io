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

# Check if database file exists and is potentially stale
if [ -n "$RENDER" ] && [ -f "/data/db.sqlite3" ]; then
	echo "Checking if existing database is valid..."
	python - <<'PY'
import os
import sqlite3

db_path = '/data/db.sqlite3'
try:
	conn = sqlite3.connect(db_path)
	cursor = conn.cursor()
	cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='pokaz_elektroniki_część_elektroniczna'")
	exists = cursor.fetchone()
	conn.close()

	if not exists:
		print("Database exists but tables missing - removing stale database")
		os.remove(db_path)
		print("Removed stale database, will recreate it")
except Exception as e:
	print(f"Database check error: {e}, removing stale database")
	try:
		os.remove(db_path)
		print("Removed potentially corrupted database")
	except:
		pass
PY
fi

# Run migrations - MUST succeed
echo "Applying migrations..."
python manage.py migrate --noinput || {
	echo "ERROR: Database migrations failed!"
	exit 1
}
echo "Migrations applied"

# Verify tables were actually created
echo ""
echo "Verifying database tables..."
python - <<'PY'
from django.db import connection
import sys

try:
	connection.ensure_connection()
	tables = connection.introspection.table_names()
	print(f"Found {len(tables)} tables")

	# Check if our app table exists
	required_table = 'pokaz_elektroniki_część_elektroniczna'
	if required_table in tables:
		print(f"✓ {required_table} table exists")
	else:
		print(f"ERROR: {required_table} table NOT found!")
		print(f"Available tables: {tables}")
		sys.exit(1)

except Exception as e:
	print(f'ERROR: Failed to inspect DB tables: {e}')
	sys.exit(1)
PY

echo ""
echo "Collecting static files..."
python manage.py collectstatic --noinput || echo "WARNING: collectstatic had issues (non-critical)"

echo ""
echo "Starting Gunicorn on port ${PORT:-8000}..."
exec gunicorn elektronika.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 1
