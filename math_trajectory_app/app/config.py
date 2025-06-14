import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your_secret_key'
    MYSQL_HOST = 'localhost'
    MYSQL_USER = 'mathuser'
    MYSQL_PASSWORD = 'mathpassword'
    MYSQL_DB = 'math_db'
    MYSQL_CURSORCLASS = 'DictCursor'
