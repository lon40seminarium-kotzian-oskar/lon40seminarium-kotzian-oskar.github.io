#!/bin/bash
set -e

echo "========================================" >&2
echo "STARTUP SCRIPT STARTING" >&2
echo "========================================" >&2

# Run Python startup
python startup.py

echo "========================================" >&2
echo "STARTUP SCRIPT COMPLETE, STARTING GUNICORN" >&2
echo "========================================" >&2

# Start Gunicorn
exec gunicorn elektronika.wsgi:application \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers 1 \
    --timeout 60 \
    --access-logfile - \
    --error-logfile -
