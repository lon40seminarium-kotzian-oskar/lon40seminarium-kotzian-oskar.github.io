#!/usr/bin/env bash
set -euo pipefail

echo "===== Starting Django application ====="
echo "RENDER env var: ${RENDER:-NOT_SET}"
echo "Python: $(python --version)"
echo "Working directory: $(pwd)"

# Ensure persistent storage directories exist on Render
if [ -n "${RENDER:-}" ]; then
	echo "Creating persistent storage directories..."
	mkdir -p /data/zdjęcia
	chmod 755 /data 2>/dev/null || true
	chmod 755 /data/zdjęcia 2>/dev/null || true
	ls -la /data/ || echo "Warning: Could not list /data"
fi

# Check and clean stale database
if [ -n "${RENDER:-}" ] && [ -f "/data/db.sqlite3" ]; then
	echo "Checking database integrity..."
	python << 'PYEND'
import os, sqlite3
db_path = '/data/db.sqlite3'
try:
	conn = sqlite3.connect(db_path)
	cursor = conn.cursor()
	cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
	tables = [row[0] for row in cursor.fetchall()]
	conn.close()
	print(f"Found {len(tables)} existing tables: {tables}")
	if 'pokaz_elektroniki_część_elektroniczna' not in tables:
		print("Database missing required table - removing...")
		os.remove(db_path)
except Exception as e:
	print(f"Database error: {e} - removing...")
	try:
		os.remove(db_path)
	except:
		pass
PYEND
fi

# Run migrations
echo "Running Django migrations..."
python manage.py migrate --noinput || {
	echo "ERROR: Migrations failed!"
	exit 1
}

# Verify database
echo "Verifying database..."
python << 'PYEND'
import sys
from django.db import connection
from django.apps import apps

try:
	connection.ensure_connection()
	cursor = connection.cursor()
	cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
	tables = [row[0] for row in cursor.fetchall()]
	print(f"Tables found: {tables}")

	if 'pokaz_elektroniki_część_elektroniczna' not in tables:
		print("ERROR: Required table not found!")
		sys.exit(1)
	print("✓ Database verified OK")
except Exception as e:
	print(f"ERROR: Database verification failed: {e}")
	sys.exit(1)
PYEND

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput 2>&1 | grep -v "^Copying" || true

echo ""
echo "===== Starting Gunicorn ====="
exec gunicorn elektronika.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 1 --timeout 60
