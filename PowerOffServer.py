from flask import Flask
import os
import subprocess

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello World!'

@app.route('/shutdown', methods=['GET'])
def poweroff():
    # os.system('sudo shutdown -h now')
    subprocess.run(["sudo", "/sbin/shutdown", "-h", "now"])
    # os.system('shutdown -h now')
    print('Powering off...')
    return 'Powering off...'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)

