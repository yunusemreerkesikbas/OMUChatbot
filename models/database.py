import bcrypt
import mysql.connector
from mysql.connector import Error
from pydantic import BaseModel

class User(BaseModel):
    email: str
    password: str

class Database:
    def __init__(self):
        try:
            self.db_connection = mysql.connector.connect(
                host="localhost",
                port=3307,  # Docker Compose dosyasındaki portu buraya yazın
                user="chatbot_user",
                password="chatbot_db_1234",
                database="chatbot_db",
                charset='utf8mb4',
                collation='utf8mb4_unicode_ci'
            )
            self.cursor = self.db_connection.cursor()
        except Error as e:
            print(f"Error connecting to MySQL: {e}")
            self.db_connection = None
            self.cursor = None

    def create_table(self):
        if self.cursor is None:
            print("Cursor is not connected")
            return
        try:
            create_table_query = """
            CREATE TABLE IF NOT EXISTS chatbot_data (
                id INT AUTO_INCREMENT PRIMARY KEY,
                question TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
                answer TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
            ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
            """
            self.cursor.execute(create_table_query)
            self.db_connection.commit()
        except Error as e:
            print(f"Error creating table: {e}")

    def insert_data(self, data):
        if self.cursor is None:
            print("Cursor is not connected")
            return
        try:
            insert_query = "INSERT INTO chatbot_data (question, answer) VALUES (%s, %s)"
            check_query = "SELECT COUNT(*) FROM chatbot_data WHERE question = %s AND answer = %s"
            for q, a in data:
                self.cursor.execute(check_query, (q, a))
                result = self.cursor.fetchone()
                if result[0] == 0:
                    self.cursor.execute(insert_query, (q, a))
            self.db_connection.commit()
        except Error as e:
            print(f"Error inserting data: {e}")

    def fetch_data(self):
        if self.cursor is None:
            print("Cursor is not connected")
            return []
        try:
            self.cursor.execute("SELECT question, answer FROM chatbot_data")
            data = self.cursor.fetchall()
            return data
        except Error as e:
            print(f"Error fetching data: {e}")
            return []

    def create_user_table(self):
        if self.cursor is None:
            print("Cursor is not connected")
            return
        try:
            create_table_query = """
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                role VARCHAR(50) DEFAULT 'user'
            ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
            """
            self.cursor.execute(create_table_query)
            self.db_connection.commit()
        except Error as e:
            print(f"Error creating user table: {e}")

    def insert_user(self, email, password):
        if self.cursor is None:
            print("Cursor is not connected")
            return
        try:
            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            insert_query = "INSERT INTO users (email, password) VALUES (%s, %s)"
            self.cursor.execute(insert_query, (email, hashed_password))
            self.db_connection.commit()
        except mysql.connector.IntegrityError:
            raise Exception("Email already exists")
        except Error as e:
            print(f"Error inserting user: {e}")

    def get_user(self, email):
        if self.cursor is None:
            print("Cursor is not connected")
            return None
        try:
            self.cursor.execute("SELECT email, password FROM users WHERE email = %s", (email,))
            result = self.cursor.fetchone()
            if result:
                return {"email": result[0], "password": result[1]}
            return None
        except Error as e:
            print(f"Error getting user: {e}")
            return None

    def check_user(self, email, password):
        if self.cursor is None:
            print("Cursor is not connected")
            return False
        try:
            self.cursor.execute("SELECT email, password FROM users WHERE email = %s", (email,))
            result = self.cursor.fetchone()
            if result:
                stored_password = result[1].encode('utf-8')
                return bcrypt.checkpw(password.encode('utf-8'), stored_password)
            return False
        except Error as e:
            print(f"Error checking user: {e}")
            return False

    def close(self):
        if self.cursor is not None:
            self.cursor.close()
        if self.db_connection is not None:
            self.db_connection.close()

    def load_data_from_file(self, file_path):
        try:
            with open(file_path, encoding='utf-8') as file:
                data = []
                for line in file:
                    parts = line.strip().split('~')
                    if len(parts) == 2:
                        data.append(parts)
            return data
        except Exception as e:
            print(f"Error loading data from file: {e}")
            return []

    def reset_and_load_data(self, file_path):
        data = self.load_data_from_file(file_path)
        self.insert_data(data)

    def insert_admin_user(self, email, password):
        if self.cursor is None:
            print("Cursor is not connected")
            return
        try:
            self.cursor.execute("SELECT COUNT(*) FROM users WHERE email = %s", (email,))
            result = self.cursor.fetchone()
            if result[0] > 0:
                print("Admin user already exists.")
                return

            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            self.cursor.execute("INSERT INTO users (email, password, role) VALUES (%s, %s, 'admin')", (email, hashed_password))
            self.db_connection.commit()
        except mysql.connector.IntegrityError:
            raise Exception("Email already exists")
        except Error as e:
            print(f"Error inserting admin user: {e}")

# Veritabanı işlemlerini gerçekleştir
if __name__ == "__main__":
    dataset_path = "/home/enoca2/Desktop/OMUChatbot/api/model/dataset.txt"
    db = Database()
    db.create_table()
    db.reset_and_load_data(dataset_path)
    fetched_data = db.fetch_data()
    db.create_user_table()
    db.insert_admin_user("admin@example.com", "admin_password")
    db.close()
