from flask import Flask, jsonify
import redis
import os
import logging

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)