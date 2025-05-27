from flask import Flask, jsonify

app = Flask(__name__)

request_count = 0

@app.route('/count', methods=['GET'])
def count_requests():
    global request_count
    request_count += 1
    return jsonify({'count': request_count})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)