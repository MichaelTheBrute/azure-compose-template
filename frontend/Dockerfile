FROM python:3.9-slim

WORKDIR /app

# Copy requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code and templates
COPY src/ .
COPY templates/ ./templates/

# Expose Flask's new port
EXPOSE 8080

# Run the Flask app
CMD ["python", "app.py"]