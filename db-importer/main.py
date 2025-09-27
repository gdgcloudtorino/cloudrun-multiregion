import os
import psycopg2

def import_data():
    try:
        conn = psycopg2.connect(
            host=os.environ.get('DB_HOST'),
            database=os.environ.get('DB_NAME'),
            user=os.environ.get('DB_USER'),
            password=os.environ.get('DB_PASS')
        )
        cur = conn.cursor()

        with open('games.sql', 'r') as f:
            cur.execute(f.read())
        
        conn.commit()
        cur.close()
        conn.close()
        print("Data imported successfully.")

    except Exception as e:
        print(f"Error importing data: {e}")

if __name__ == "__main__":
    import_data()
