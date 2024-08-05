import os
import time
import base64
import sqlite3

DB_PATH = '../../config.sqlite3'
TOKEN_TIMEOUT = 24*60*60


def get_db_cursor():
    connection = sqlite3.connect(DB_PATH)
    return connection.cursor(), connection


def create_db():
    cursor, _ = get_db_cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS configuration(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        value TEXT
    )''')
    cursor.execute('''CREATE UNIQUE INDEX IF NOT EXISTS configuration_name ON configuration(name)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS tokens(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash TEXT,
        expires INTEGER
    )''')
    cursor.execute('''CREATE INDEX IF NOT EXISTS tokens_hash ON tokens(hash)''')



def set_configuration(name, value):
    cursor, connection = get_db_cursor()
    cursor.execute('''INSERT INTO configuration(name, value)
                      VALUES(?, ?)
                      ON CONFLICT(name) DO UPDATE SET value=excluded.value''', (name, value))
    connection.commit()
    connection.close()


def get_configuration(name, default_value=None):
    cursor, connection = get_db_cursor()
    cursor.execute('''SELECT value FROM configuration WHERE name=?''', (name,))
    result = cursor.fetchone()
    connection.close()
    return result[0] if result else default_value


def get_all_configuration():
    cursor, connection = get_db_cursor()
    cursor.execute('''SELECT name, value FROM configuration''')
    result = {k: v for k, v in cursor}
    connection.close()
    return result


def add_token():
    cursor, connection = get_db_cursor()
    token = base64.urlsafe_b64encode(os.urandom(64)).decode('utf-8')
    expires = int(time.time()) + TOKEN_TIMEOUT
    cursor.execute('''INSERT INTO tokens(hash, expires) VALUES(?, ?)''', (token, expires))
    connection.commit()
    connection.close()
    return token


def is_token_valid(token):
    cursor, connection = get_db_cursor()
    current_time = int(time.time())
    cursor.execute('''DELETE FROM tokens WHERE expires < ?''', (current_time,))
    cursor.execute('''SELECT COUNT(*) FROM tokens WHERE hash=? AND expires >= ?''', (token, current_time))
    result = cursor.fetchone()[0]
    connection.commit()
    connection.close()
    return result > 0



configuration = {
        'token': 'hakieshaslo',

        'serial': '/dev/ttyACM99'
    }


if __name__ == '__main__':
    create_db()
