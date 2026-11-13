import os
from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent.parent
from django.core.exceptions import ImproperlyConfigured
DEBUG = os.getenv("DEBUG", "False").lower() == "true"
SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")
if not SECRET_KEY:
    if DEBUG:
        SECRET_KEY = "dev-only-insecure-key"  # only ever used when DEBUG=True (local dev / tests)
    else:
        raise ImproperlyConfigured("DJANGO_SECRET_KEY must be set when DEBUG is False")
ALLOWED_HOSTS = [x.strip() for x in os.getenv("ALLOWED_HOSTS", "localhost,127.0.0.1,backend").split(",") if x.strip()]
INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.staticfiles", "corsheaders", "ops"]
MIDDLEWARE = ["django.middleware.security.SecurityMiddleware", "corsheaders.middleware.CorsMiddleware", "django.middleware.common.CommonMiddleware"]
ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"
DATABASES = {"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": os.getenv("DB_PATH", str(BASE_DIR / "db.sqlite3"))}}
STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
USE_TZ = True
CORS_ALLOWED_ORIGINS = [x.strip() for x in os.getenv("CORS_ALLOWED_ORIGINS", "http://localhost:5173").split(",") if x.strip()]
