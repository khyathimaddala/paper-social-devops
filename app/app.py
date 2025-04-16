from flask import Flask
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    filename='/home/ec2-user/app/app.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

@app.route('/')
def home():
    logging.info('Request received for homepage')
    return "Welcome to Paper.Social!"

if __name__ == "__main__":
    logging.info('Application started')
    app.run(host='0.0.0.0', port=5000)
