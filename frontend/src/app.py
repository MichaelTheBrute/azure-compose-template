import os
from flask import Flask, render_template
import requests

app = Flask(__name__)

# Use Dapr's service invocation API for backend communication
BACKEND_URL = os.environ.get('BACKEND_URL', 'http://localhost:3500/v1.0/invoke/backend/method')

@app.route('/')
def index():
    try:
        response = requests.get(f'{BACKEND_URL}/count')
        response.raise_for_status()
        count = response.json().get('count', 0)
    except requests.RequestException:
        count = 'Error fetching count'
    return render_template('index.html', count=count)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)