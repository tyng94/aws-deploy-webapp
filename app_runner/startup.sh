#!/bin/bash
python manage.py collectstatic && gunicorn --workers 2 app_runner.wsgi