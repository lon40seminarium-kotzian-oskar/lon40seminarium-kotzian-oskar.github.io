#!/usr/bin/env python
"""
Render startup script - creates database and runs migrations
"""
import os
import sys
import traceback

print("\n" + "="*70, flush=True)
print("STARTUP.PY - Django Initialization", flush=True)
print("="*70, flush=True)

try:
    # 1. Create persistent storage FIRST
    print("Step 1: Creating persistent storage...", flush=True)
    os.makedirs('/data/zdjęcia', exist_ok=True)
    print("  ✓ /data/zdjęcia created", flush=True)

    # 2. Setup environment
    print("\nStep 2: Setting up Django...", flush=True)
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'elektronika.settings')
    os.environ['RENDER'] = 'true'

    import django
    django.setup()
    print("  ✓ Django initialized", flush=True)

    # 3. Run migrations
    print("\nStep 3: Running migrations...", flush=True)
    from django.core.management import call_command
    call_command('migrate', '--noinput', verbosity=2)
    print("  ✓ Migrations completed", flush=True)

    # 4. Verify database
    print("\nStep 4: Verifying database...", flush=True)
    import sqlite3

    if not os.path.exists('/data/db.sqlite3'):
        raise Exception("Database file not created at /data/db.sqlite3")

    conn = sqlite3.connect('/data/db.sqlite3')
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in cursor.fetchall()]
    conn.close()

    print(f"  Found {len(tables)} tables:", flush=True)
    for t in tables:
        print(f"    - {t}", flush=True)

    if 'pokaz_elektroniki_część_elektroniczna' not in tables:
        raise Exception(f"Required table not found! Tables: {tables}")

    print("  ✓ Database verification passed", flush=True)

    # 5. Collect static
    print("\nStep 5: Collecting static files...", flush=True)
    try:
        call_command('collectstatic', '--noinput', verbosity=0)
        print("  ✓ Static files collected", flush=True)
    except Exception as e:
        print(f"  ⚠ collectstatic failed (non-critical): {e}", flush=True)

    print("\n" + "="*70, flush=True)
    print("✓ STARTUP COMPLETED SUCCESSFULLY", flush=True)
    print("="*70 + "\n", flush=True)
    sys.exit(0)

except Exception as e:
    print("\n" + "="*70, flush=True)
    print("✗ STARTUP FAILED", flush=True)
    print("="*70, flush=True)
    print(f"\nError: {e}", flush=True)
    print("\nTraceback:", flush=True)
    traceback.print_exc()
    print("="*70 + "\n", flush=True)
    sys.exit(1)
