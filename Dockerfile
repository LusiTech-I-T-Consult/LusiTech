# Dockerfile

# 1. Base image
FROM python:3.10-slim

# 3. Set working directory
WORKDIR /app

# 4. Install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# 5. Copy project
COPY . /app/

# 6. Collect static files (optional, for production)
# RUN python manage.py collectstatic --noinput

# 7. Run Django server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
