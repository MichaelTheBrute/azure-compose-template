from flask import Flask, jsonify
import redis
import os
import logging
import psycopg2
from urllib.parse import urlparse

app = Flask(__name__)

# Set up logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

def is_running_in_azure():
    """More reliable method to detect Azure Container Apps environment"""
    # Method 1: Check for environment variables that exist in Container Apps
    azure_env_indicators = [
        'CONTAINER_APP_NAME',       # Set in Container Apps
        'WEBSITES_CONTAINER_START_TIME',  # Set in Container Apps
        'CONTAINER_APP_REVISION'    # Container Apps revision identifier
    ]
    
    for var in azure_env_indicators:
        if os.getenv(var):
            logger.info(f"Azure detected via environment variable: {var}={os.getenv(var)}")
            return True
    
    # Method 2: Check network configuration specific to Container Apps
    try:
        # Container Apps typically has this localhost address bound
        with open('/proc/net/tcp', 'r') as f:
            tcp_content = f.read()
            if '0100007F:0035' in tcp_content:  # 127.0.0.1:53 in hex
                logger.info("Azure detected via network configuration")
                return True
    except Exception:
        pass
    
    # Method 3: Check for Azure-specific filesystems or mounts
    try:
        with open('/proc/mounts', 'r') as f:
            mounts = f.read()
            if 'overlay' in mounts and 'containerd' in mounts:
                logger.info("Azure Container Apps detected via filesystem mounts")
                return True
    except Exception:
        pass
    
    logger.info("Not running in Azure based on all detection methods")
    return False

def get_redis_host():
    """Get Redis host based on environment"""
    if is_running_in_azure():
        # In Azure, use simple hostname without port or environment name
        redis_host = "redis"
        logger.info(f"Running in Azure environment, using Redis host: {redis_host}")
    else:
        # For local development
        redis_host = "redis"
        logger.info(f"Running in local environment, using Redis host: {redis_host}")
    
    return redis_host

# Get Redis host and create client
redis_host = get_redis_host()
try:
    redis_client = redis.StrictRedis(host=redis_host, port=6379, decode_responses=True)
    logger.info(f"Connected to Redis at {redis_host}:6379")
except Exception as e:
    logger.error(f"Failed to connect to Redis at {redis_host}:6379: {str(e)}")
    redis_client = None

def get_db_connection():
    """Get PostgreSQL database connection"""
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        db_user = os.getenv('DB_USER')
        db_pass = os.getenv('DB_PASS')
        db_host = os.getenv('DB_HOST')
        db_name = os.getenv('DB_NAME', 'postgres')
        if db_user and db_pass and db_host:
            database_url = f"postgresql://{db_user}:{db_pass}@{db_host}:5432/{db_name}"
            logger.info("DATABASE_URL constructed from individual DB_* environment variables")
        else:
            logger.warning("DATABASE_URL and/or DB_* environment variables not set")
            return None

    try:
        conn = psycopg2.connect(database_url)
        logger.info("Connected to PostgreSQL database")
        return conn
    except Exception as e:
        logger.error(f"Failed to connect to PostgreSQL: {str(e)}")
        return None

@app.route('/count', methods=['GET'])
def count_requests():
    # Increment the counter in Redis
    if redis_client:
        try:
            count = redis_client.incr('request_count')
            logger.info(f"Incremented count to {count}")
            return jsonify({'count': count})
        except Exception as e:
            logger.error(f"Error incrementing count in Redis: {str(e)}")
            return jsonify({'count': 999, 'error': str(e)})
    else:
        # Fallback if Redis is not connected
        return jsonify({'count': 333, 'note': 'Redis not connected'})

@app.route('/app-name', methods=['GET'])
def get_app_name():
    """Get app name from the metadata table"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'app_name': 'Default App', 'source': 'fallback'})
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT appname FROM metadata LIMIT 1;")
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result and result[0]:
            return jsonify({'app_name': result[0], 'source': 'database'})
        else:
            return jsonify({'app_name': 'Studio Logic App', 'source': 'default'})
            
    except Exception as e:
        logger.error(f"Failed to get app name: {str(e)}")
        return jsonify({'app_name': 'Offline App', 'source': 'error', 'error': str(e)})

@app.route('/redis-test', methods=['GET'])
def test_redis():
    """Test endpoint to verify Redis connection"""
    result = {
        'redis_host': redis_host,
        'connected': False,
        'error': None
    }
    
    try:
        if redis_client:
            # Try a simple ping
            response = redis_client.ping()
            result['connected'] = response
            result['ping_response'] = response
            
            # Try to set and get a value
            redis_client.set('test_key', 'test_value')
            test_value = redis_client.get('test_key')
            result['test_value'] = test_value
    except Exception as e:
        result['error'] = str(e)
    
    return jsonify(result)

@app.route('/db-test', methods=['GET'])
def test_database():
    """Test endpoint to verify PostgreSQL connection"""
    result = {
        'database_url_set': bool(os.getenv('DATABASE_URL')),
        'connected': False,
        'error': None
    }
    
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute('SELECT version();')
            version = cursor.fetchone()
            result['connected'] = True
            result['postgres_version'] = version[0] if version else 'Unknown'
            cursor.close()
            conn.close()
    except Exception as e:
        result['error'] = str(e)
    
    return jsonify(result)

if __name__ == '__main__':
    # Only enable debug mode in local development, never in Azure
    is_azure = is_running_in_azure()
    debug_mode = not is_azure and os.getenv('FLASK_DEBUG', '0') == '1'
    
    if debug_mode:
        logger.info("🔧 Debug mode enabled for local development")
    else:
        logger.info("🔒 Debug mode disabled for production/Azure deployment")
    
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)
