# pull official base image
FROM python:alpine3.20


# Set working directory
WORKDIR /home/app
RUN mkdir /home/app/staticfiles
RUN mkdir /home/app/mediafiles

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install Python dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# Copy project files
COPY . /home/app

# Copy entrypoint script
COPY ./entrypoint.sh /home/app/entrypoint.sh

# Give execute permissions to entrypoint script
RUN chmod +x /home/app/entrypoint.sh

# Expose the Django application port
EXPOSE 8000

# Define entrypoint script and default arguments
CMD ["/home/app/entrypoint.sh"]
