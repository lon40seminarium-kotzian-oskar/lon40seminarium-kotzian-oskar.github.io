#!/usr/bin/env python
import os
import sys
import sqlite3

# Create persistent storage BEFORE anything else
os.makedirs('/data/zdjęcia', exist_ok=True)

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'elektronika.settings')
os.environ['RENDER'] = 'true'

import django
django.setup()

from django.core.management import call_command

print("\n" + "="*60, file=sys.stderr)
print("STARTUP.PY - Python startup script", file=sys.stderr)
print("="*60, file=sys.stderr)
print(f"RENDER={os.environ.get('RENDER')}", file=sys.stderr)
print(f"User: {os.getlogin() if hasattr(os, 'getlogin') else 'unknown'}", file=sys.stderr)
print(f"CWD: {os.getcwd()}", file=sys.stderr)
print("="*60 + "\n", file=sys.stderr)

# Run migrations
print("Running Django migrations...", file=sys.stderr)
try:
    call_command('migrate', '--noinput', verbosity=2)
    print("Migrations completed successfully\n", file=sys.stderr)
except Exception as e:
    print(f"ERROR: Migrations failed: {e}\n", file=sys.stderr)
    sys.exit(1)

# Verify database
print("Verifying database tables...", file=sys.stderr)
try:
    db_path = '/data/db.sqlite3'
    if not os.path.exists(db_path):
        print(f"ERROR: Database not created at {db_path}", file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in cursor.fetchall()]
    conn.close()

    print(f"Found {len(tables)} tables:", file=sys.stderr)
    for t in tables:
        print(f"  - {t}", file=sys.stderr)

    if 'pokaz_elektroniki_część_elektroniczna' not in tables:
        print("\nERROR: Expected table not found!", file=sys.stderr)
        sys.exit(1)

    print("\nSUCCESS: Database verified!\n", file=sys.stderr)
except Exception as e:
    print(f"ERROR: {e}\n", file=sys.stderr)
    sys.exit(1)

# Collect static
print("Collecting static files...", file=sys.stderr)
try:
    call_command('collectstatic', '--noinput', verbosity=0)
    print("Static files collected\n", file=sys.stderr)
except Exception as e:
    print(f"WARNING: collectstatic failed: {e} (non-critical)\n", file=sys.stderr)

print("="*60, file=sys.stderr)
print("Startup complete - ready to start Gunicorn", file=sys.stderr)
print("="*60 + "\n", file=sys.stderr)
