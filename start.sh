#!/usr/bin/env bash
set -euo pipefail

export DJANGO_SETTINGS_MODULE=elektronika.settings
export RENDER=true
export PYTHONUNBUFFERED=1

# Write startup log to persistent disk
LOGFILE="/data/startup.log"
exec 1>>"$LOGFILE" 2>&1

echo "========================================"
echo "START.SH - $(date)"
echo "========================================"
echo "RENDER=$RENDER"
echo "PWD=$(pwd)"
echo "User: $(whoami)"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p /data/zdjęcia
chmod 755 /data
chmod 755 /data/zdjęcia
ls -la /data/

# Check for stale database
echo ""
echo "Checking for stale database..."
if [ -f "/data/db.sqlite3" ]; then
	echo "Found /data/db.sqlite3, checking if valid..."
	python3 << 'EOF'
import sqlite3, os
try:
	conn = sqlite3.connect('/data/db.sqlite3')
	cursor = conn.cursor()
	cursor.execute("SELECT count(*) FROM sqlite_master WHERE type='table'")
	count = cursor.fetchone()[0]
	conn.close()
	print(f"Database has {count} tables")
	if count == 0:
		os.remove('/data/db.sqlite3')
		print("Removed empty database")
except Exception as e:
	print(f"Database error: {e}")
	os.remove('/data/db.sqlite3')
	print("Removed corrupted database")
EOF
else
	echo "No database file found (will be created)"
fi

# Run migrations
echo ""
echo "Running migrations..."
python manage.py migrate --noinput

# Check migrations created tables
echo ""
echo "Checking if migrations created tables..."
python3 << 'EOF'
import sqlite3, sys, os

if not os.path.exists('/data/db.sqlite3'):
	print("ERROR: Database file was not created!")
	sys.exit(1)

conn = sqlite3.connect('/data/db.sqlite3')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
conn.close()

print(f"Tables created: {tables}")
for t in tables:
	print(f"  - {t}")

if 'pokaz_elektroniki_część_elektroniczna' not in tables:
	print("ERROR: Required table NOT created by migrations!")
	print("Available tables:", tables)
	sys.exit(1)

print("SUCCESS: All expected tables exist!")
EOF

if [ $? -ne 0 ]; then
	echo ""
	echo "ERROR: Database verification failed!"
	exit 1
fi

# Collect static
echo ""
echo "Collecting static files..."
python manage.py collectstatic --noinput --verbosity 0

echo ""
echo "========================================"
echo "Starting Gunicorn..."
echo "========================================"

exec gunicorn elektronika.wsgi:application \
	--bind 0.0.0.0:${PORT:-8000} \
	--workers 1 \
	--timeout 60 \
	--access-logfile - \
	--error-logfile - \
	--log-level info
