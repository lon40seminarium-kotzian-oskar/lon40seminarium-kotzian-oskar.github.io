#!/usr/bin/env bash
export DJANGO_SETTINGS_MODULE=elektronika.settings
export RENDER=true
export PYTHONUNBUFFERED=1

echo "START.SH: Django initialization starting" >&2

# Create data directories
mkdir -p /data/zdjęcia 2>/dev/null || true
chmod 755 /data 2>/dev/null || true
chmod 755 /data/zdjęcia 2>/dev/null || true

echo "START.SH: Running migrations" >&2
python manage.py migrate --noinput --verbosity 2

# Check if table was created
echo "START.SH: Checking database" >&2
python3 << 'DBCHECK'
import sqlite3, sys, os

db_path = '/data/db.sqlite3'
if not os.path.exists(db_path):
	print("ERROR: Database file does not exist!", file=sys.stderr)
	sys.exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
conn.close()

print(f"Tables in database: {tables}", file=sys.stderr)
if 'pokaz_elektroniki_część_elektroniczna' not in tables:
	print("ERROR: Expected table not found!", file=sys.stderr)
	sys.exit(1)
print("OK: Database tables verified", file=sys.stderr)
DBCHECK

if [ $? -ne 0 ]; then
	echo "START.SH: Database check failed, exiting" >&2
	exit 1
fi

echo "START.SH: Collecting static files" >&2
python manage.py collectstatic --noinput --verbosity 0 2>/dev/null || true

echo "START.SH: Starting Gunicorn" >&2
exec gunicorn elektronika.wsgi:application \
	--bind 0.0.0.0:${PORT:-8000} \
	--workers 1 \
	--timeout 60 \
	--access-logfile - \
	--error-logfile - \
	--log-level info
