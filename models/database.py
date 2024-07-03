import mysql.connector

class Database:
    def __init__(self):
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

    def create_table(self):
        create_table_query = """
        CREATE TABLE IF NOT EXISTS chatbot_data (
            id INT AUTO_INCREMENT PRIMARY KEY,
            question TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
            answer TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
        ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        """
        self.cursor.execute(create_table_query)
        self.db_connection.commit()

    def insert_data(self, data):
        insert_query = "INSERT INTO chatbot_data (question, answer) VALUES (%s, %s)"
        check_query = "SELECT COUNT(*) FROM chatbot_data WHERE question = %s"
        for q, a in data:
            self.cursor.execute(check_query, (q,))
            result = self.cursor.fetchone()
            if result[0] == 0:
                self.cursor.execute(insert_query, (q, a))
        self.db_connection.commit()

    def fetch_data(self):
        self.cursor.execute("SELECT question, answer FROM chatbot_data")
        data = self.cursor.fetchall()
        return data

    def close(self):
        self.cursor.close()
        self.db_connection.close()

    def load_data_from_file(self, file_path):
        with open(file_path, encoding='utf-8') as file:
            data = []
            for line in file:
                parts = line.strip().split('~')
                if len(parts) == 2:
                    data.append(parts)
        return data

    def reset_and_load_data(self, file_path):
        data = self.load_data_from_file(file_path)
        self.insert_data(data)

# Veritabanı işlemlerini gerçekleştir
if __name__ == "__main__":
    dataset_path = "/home/enoca2/Desktop/OMUChatbot/api/model/dataset.txt"
    db = Database()
    db.create_table()
    db.reset_and_load_data(dataset_path)
    fetched_data = db.fetch_data()

    db.close()
