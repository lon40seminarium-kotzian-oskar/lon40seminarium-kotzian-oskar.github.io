#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo "START: Django app initialization"
echo "======================================"
echo "RENDER=${RENDER:-NOT_SET}"
echo "PWD=$(pwd)"
echo "Python: $(python --version)"

# Create directories
echo "Setting up persistent storage..."
mkdir -p /data/zdjęcia 2>/dev/null || true
chmod 755 /data 2>/dev/null || true
chmod 755 /data/zdjęcia 2>/dev/null || true

# Show database status
echo ""
echo "Checking database..."
if [ -f "/data/db.sqlite3" ]; then
	echo "Found existing /data/db.sqlite3"
	ls -lh /data/db.sqlite3
else
	echo "No database file yet (will be created)"
fi

# Clean stale database
if [ -f "/data/db.sqlite3" ]; then
	python3 << 'DBCHECK'
import os, sqlite3
try:
	conn = sqlite3.connect('/data/db.sqlite3')
	cursor = conn.cursor()
	cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
	tables = [row[0] for row in cursor.fetchall()]
	conn.close()
	print(f"Current tables: {tables}")
	if not tables or 'pokaz_elektroniki_część_elektroniczna' not in tables:
		print("Missing required table - removing stale db")
		os.remove('/data/db.sqlite3')
except:
	print("Database corrupt - removing")
	os.remove('/data/db.sqlite3')
DBCHECK
fi

# RUN MIGRATIONS
echo ""
echo "======================================"
echo "Running migrations..."
echo "======================================"
python manage.py migrate --noinput
if [ $? -ne 0 ]; then
	echo "ERROR: Migrations failed!"
	exit 1
fi

# Verify tables
echo ""
echo "======================================"
echo "Verifying tables..."
echo "======================================"
python3 << 'VERIFY'
import sys, sqlite3
conn = sqlite3.connect('/data/db.sqlite3')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
conn.close()
print(f"Tables in database: {tables}")
if 'pokaz_elektroniki_część_elektroniczna' not in tables:
	print("ERROR: Expected table not created!")
	sys.exit(1)
print("OK: All tables present")
VERIFY

# Collect static
echo ""
echo "Collecting static files..."
python manage.py collectstatic --noinput 2>&1 | tail -3

# Start server
echo ""
echo "======================================"
echo "Starting Gunicorn server..."
echo "======================================"
exec gunicorn elektronika.wsgi:application \
	--bind 0.0.0.0:${PORT:-8000} \
	--workers 1 \
	--timeout 60 \
	--access-logfile - \
	--error-logfile -
