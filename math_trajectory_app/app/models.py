import json

from app import mysql

def get_topic_name_by_id(topic_id):
    cur = mysql.connection.cursor()
    cur.execute("SELECT name FROM topics WHERE id = %s", (topic_id,))
    result = cur.fetchone()
    cur.close()
    return result['name'] if result else None


def get_all_questions():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM questions")
    questions = cur.fetchall()
    cur.close()
    return questions

def get_question_by_topic(topic):
    cur = mysql.connection.cursor()
    cur.execute("SELECT id FROM topics WHERE name = %s", (topic,))
    result = cur.fetchone()

    if result:
        topic_id = result["id"]
        # Теперь выполняем запрос на выборку вопросов по topic_id
        cur.execute("SELECT * FROM questions WHERE topic_id = %s", (topic_id,))
        questions = cur.fetchall()
        cur.close()
        return questions
    else:
        cur.close()
        return []


def get_topics_graph():
    """
    Возвращает граф тем в формате:
    {
      "Название темы": {
          "level": "basic"|"intermediate"|"advanced",
          "prerequisites": ["Предварительная тема 1", ...]
      },
      ...
    }
    """
    cur = mysql.connection.cursor()
    # 1) получаем все темы
    cur.execute("SELECT id, name, level FROM topics")
    topics = cur.fetchall()  # список dict с keys 'id','name','level'

    # постройка карты id -> (name, level)
    id_to_name = {}
    name_to_level = {}
    for row in topics:
        tid = row['id']
        name = row['name']
        id_to_name[tid] = name
        name_to_level[name] = row['level']

    # 2) получаем зависимости
    cur.execute("SELECT topic_id, prerequisite_id FROM topic_dependencies")
    deps = cur.fetchall()  # список dict с keys 'topic_id','prerequisite_id'
    cur.close()

    # сгруппировать для каждой темы список prereq IDs
    prereq_map = {}
    for row in deps:
        tid = row['topic_id']
        pid = row['prerequisite_id']
        prereq_map.setdefault(tid, []).append(pid)

    # 3) собираем итоговую структуру
    topics_graph = {}
    for tid, name in id_to_name.items():
        # для темы с данным tid вытаскиваем список имен prerequisites
        prereq_ids = prereq_map.get(tid, [])
        prereq_names = [id_to_name[p] for p in prereq_ids]
        topics_graph[name] = {
            "level": name_to_level[name],
            "prerequisites": prereq_names
        }

    return topics_graph


def get_user_by_username(username):
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM users WHERE username = %s", (username,))
    user = cur.fetchone()
    cur.close()
    return user

def get_user_by_email(email):
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cur.fetchone()
    cur.close()
    return user

def create_user(username, email, password_hash):
    cur = mysql.connection.cursor()
    cur.execute(
        "INSERT INTO users (username, email, password) VALUES (%s, %s, %s)",
        (username, email, password_hash)
    )
    mysql.connection.commit()
    cur.close()


def save_test_result(user_id, score, total):
    cur = mysql.connection.cursor()
    cur.execute(
        "INSERT INTO test_results (user_id, score, total_questions) VALUES (%s, %s, %s)",
        (user_id, score, total)
    )
    mysql.connection.commit()
    last_id = cur.lastrowid
    cur.close()
    return last_id

def save_trajectory(test_result_id, trajectory_list):
    """
    test_result_id: id вставленной записи в test_results
    trajectory_list: питоновский список строк (названий тем)
    """
    cur = mysql.connection.cursor()
    # превратим питоновский список в JSON-строку
    traj_json = json.dumps(trajectory_list, ensure_ascii=False)
    cur.execute(
        "INSERT INTO trajectories (test_result_id, trajectory) VALUES (%s, %s)",
        (test_result_id, traj_json)
    )
    mysql.connection.commit()
    cur.close()


def get_user_history(user_id):
    """
    Возвращает список записей вида:
      {
        test_date: datetime,
        score: int,
        total_questions: int,
        trajectory: list[str]
      }
    Отсортировано по дате (свежие сверху).
    """
    cur = mysql.connection.cursor()
    # джойним test_results и trajectories
    cur.execute("""
        SELECT
          tr.test_date,
          tr.score,
          tr.total_questions,
          tj.trajectory
        FROM test_results tr
        LEFT JOIN trajectories tj
          ON tj.test_result_id = tr.id
        WHERE tr.user_id = %s
        ORDER BY tr.test_date DESC
    """, (user_id,))
    rows = cur.fetchall()
    cur.close()

    history = []
    for row in rows:
        raw = row.get('trajectory') or '{}'
        try:
            traj = json.loads(raw)
        except json.JSONDecodeError:
            traj = {}
        history.append({
            'test_date':        row['test_date'],
            'score':            row['score'],
            'total':            row['total_questions'],
            'can_study_now':       traj.get('can_study_now', []),
            'study_later_with_prereqs': traj.get('study_later_with_prereqs', []),
        })
    return history


def get_score_history(user_id):
    """
    Возвращает две параллельные списки:
    - dates  — список datetime
    - scores — список int
    """
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT test_date, score
        FROM test_results
        WHERE user_id = %s
        ORDER BY test_date
    """, (user_id,))
    rows = cur.fetchall()
    cur.close()

    dates  = [row['test_date'] for row in rows]
    scores = [row['score']    for row in rows]
    return dates, scores

