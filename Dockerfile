FROM python:3.12-slim

# Install required packages including Nginx and Supervisor
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Collect static files
ENV STATIC_ROOT=/app/staticfiles
RUN python manage.py migrate
RUN python manage.py collectstatic --noinput

# Configure Nginx and SSL
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/

# Create SSL directory and copy certificates
RUN mkdir -p /etc/nginx/ssl
COPY amarkagojpatro.pem /etc/nginx/ssl/
COPY amarkagojpatro.key /etc/nginx/ssl/
RUN chmod 600 /etc/nginx/ssl/amarkagojpatro.key

# Set up Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create required directories
RUN mkdir -p /var/log/supervisor

# Expose ports
EXPOSE 80 443

# Start Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]