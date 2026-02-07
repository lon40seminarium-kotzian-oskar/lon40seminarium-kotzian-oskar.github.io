#!/usr/bin/env bash
set -euo pipefail

export DJANGO_SETTINGS_MODULE=elektronika.settings
export RENDER=true
export PYTHONUNBUFFERED=1

echo "======================================"
echo "Django Startup"
echo "======================================"
echo "RENDER=$RENDER"
echo "DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE"
echo "PWD=$(pwd)"

# Ensure /data exists
mkdir -p /data/zdjęcia 2>/dev/null || true
chmod 755 /data 2>/dev/null || true
chmod 755 /data/zdjęcia 2>/dev/null || true

echo "Database location:"
python3 -c "from pathlib import Path; import os; print('/data/db.sqlite3' if os.environ.get('RENDER') else 'local')"

# Show existing database
echo ""
if [ -f "/data/db.sqlite3" ]; then
	echo "Existing database: YES"
	ls -lh /data/db.sqlite3
	echo ""
	echo "Tables in existing database:"
	python3 << 'EOF'
import sqlite3
try:
	conn = sqlite3.connect('/data/db.sqlite3')
	cursor = conn.cursor()
	cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
	tables = [row[0] for row in cursor.fetchall()]
	for t in tables:
		print(f"  - {t}")
	conn.close()
except Exception as e:
	print(f"  Error checking tables: {e}")
EOF
else
	echo "Existing database: NO (will be created)"
fi

# Remove stale database if tables are missing
echo ""
echo "Checking database integrity..."
python3 << 'EOF'
import os, sqlite3
if os.path.exists('/data/db.sqlite3'):
	try:
		conn = sqlite3.connect('/data/db.sqlite3')
		cursor = conn.cursor()
		cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
		tables = [row[0] for row in cursor.fetchall()]
		conn.close()
		if 'pokaz_elektroniki_część_elektroniczna' not in tables:
			print("Missing expected table - removing stale database")
			os.remove('/data/db.sqlite3')
		else:
			print("Database OK - expected table found")
	except Exception as e:
		print(f"Database corrupt: {e} - removing")
		try:
			os.remove('/data/db.sqlite3')
		except:
			pass
else:
	print("No database yet (will be created)")
EOF

# Run migrations with verbose output
echo ""
echo "======================================"
echo "Running Django Migrations"
echo "======================================"
python manage.py migrate --noinput --verbosity 2

# Check database again
echo ""
echo "======================================"
echo "Database After Migrations"
echo "======================================"
python3 << 'EOF'
import sqlite3, sys
try:
	if not __import__('os').path.exists('/data/db.sqlite3'):
		print("ERROR: Database file was not created!")
		sys.exit(1)

	conn = sqlite3.connect('/data/db.sqlite3')
	cursor = conn.cursor()
	cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
	tables = [row[0] for row in cursor.fetchall()]
	conn.close()

	print(f"Total tables: {len(tables)}")
	for t in tables:
		print(f"  - {t}")

	if 'pokaz_elektroniki_część_elektroniczna' not in tables:
		print("\nERROR: Required table not in database!")
		sys.exit(1)
	else:
		print("\nSUCCESS: Required table found!")
except Exception as e:
	print(f"ERROR: {e}")
	sys.exit(1)
EOF

# Collect static
echo ""
echo "======================================"
echo "Collecting Static Files"
echo "======================================"
python manage.py collectstatic --noinput --verbosity 0

# Start Gunicorn
echo ""
echo "======================================"
echo "Starting Gunicorn"
echo "======================================"
exec gunicorn elektronika.wsgi:application \
	--bind 0.0.0.0:${PORT:-8000} \
	--workers 1 \
	--timeout 60 \
	--access-logfile - \
	--error-logfile - \
	--log-level info
