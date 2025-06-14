import functools
import random
import io
import matplotlib
matplotlib.use('Agg')

from app import app
from matplotlib import pyplot as plt
from matplotlib.dates import DateFormatter
from flask import render_template, request, redirect, url_for, session, flash, abort, send_file
from werkzeug.security import generate_password_hash, check_password_hash
from app.models import get_topic_name_by_id, get_question_by_topic, get_topics_graph, save_test_result, save_trajectory, \
    get_user_history, get_score_history
from app.models import get_user_by_username, create_user, get_user_by_email
from app.expert_system import get_next_test_and_trajectory, MIN_CORRECT


def get_knowledge():
    return session.setdefault('knowledge', {})

def set_knowledge(k):
    session['knowledge'] = k

def set_score(k):
    session['last_score'] = k

def get_score():
    return session.get('last_score', 0)

def get_q_counter():
    return session.get('q_counter', 0)

def inc_q_counter():
    session['q_counter'] = session.get('q_counter', 0) + 1
    return session['q_counter']

def get_current_questions():
    """Возвращает список вопросов для текущего раунда из сессии."""
    return session.get('current_questions', [])

def set_current_questions(questions):
    """Сохраняет сформированный раунд вопросов в сессии."""
    session['current_questions'] = questions

def clear_current_questions():
    session.pop('current_questions', None)


def reset_progress():
    session['knowledge'] = {}
    session['q_counter'] = 0
    session['last_score'] = 0
    clear_current_questions()

@app.route('/reset')
def reset():
    reset_progress()
    return redirect(url_for('test'))

@app.route('/')
def index():
    reset_progress()
    return render_template("index.html")

@app.route('/test', methods=['GET', 'POST'])
def test():
    knowledge = get_knowledge()

    if request.method == 'POST':
        for key, value in request.form.items():
            topic_id, question_id = key.split('_')
            topic_id = int(topic_id)
            topic_name = get_topic_name_by_id(topic_id)
            if not topic_name:
                continue

            # вместо булевого хранить счётчик correct
            current = knowledge.get(topic_name, 0)
            if value == 'correct':
                current += 1
                set_score(get_score() + 1)
            knowledge[topic_name] = current

        # после подсчёта — отмечаем темы «известными»
        for topic, count in list(knowledge.items()):
            if count >= MIN_CORRECT:
                # перекладываем из счётчика в булево знание
                knowledge[topic] = True

        set_knowledge(knowledge)
        clear_current_questions()
        return redirect(url_for('test'))

    # === GET ===
    test_questions = get_current_questions()
    if not test_questions:
        knowledge = get_knowledge()
        topics_graph = get_topics_graph()
        data = get_next_test_and_trajectory(knowledge, topics_graph)

        # если тем нет — сразу на results
        if not data['next_test_topics']:
            user_id = session.get('user_id')
            if user_id:
                test_result_id = save_test_result(user_id, get_score(), get_q_counter())
                save_trajectory(test_result_id, data)

            return redirect(url_for('results'))

        test_questions = []
        for topic in data['next_test_topics']:
            topic_questions = get_question_by_topic(topic)
            for q in topic_questions:
                # Создаём список ответов с метками
                answers = [
                    ('correct', q['correct_answer_image']),
                    ('wrong', q['wrong_answer_1_image']),
                    ('wrong', q['wrong_answer_2_image']),
                    ('wrong', q['wrong_answer_3_image']),
                ]
                random.shuffle(answers)
                q['shuffled_answers'] = answers
                q['question_number'] = inc_q_counter()
                test_questions.append(q)

        set_current_questions(test_questions)

        for q in test_questions:
            print("Q:", q['question_image'], q['shuffled_answers'])

    return render_template("test.html", questions=test_questions)

@app.route('/results')
def results():
    # достаём из сессии
    score = get_score()
    total = get_q_counter()

    topics_graph = get_topics_graph()
    knowledge = get_knowledge()
    data = get_next_test_and_trajectory(knowledge, topics_graph)
    return render_template("results.html", data=data, score=score, total=total)


def login_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return view(**kwargs)
    return wrapped_view

@app.route('/history')
@login_required
def history():
    user_id = session['user_id']
    history = get_user_history(user_id)
    return render_template('history.html', history=history)

@app.route('/score_plot.png')
@login_required
def score_plot():
    user_id = session['user_id']
    dates, scores = get_score_history(user_id)

    if not dates:
        abort(404)

    plt.figure(figsize=(10, 5))

    # Отрисовка линий с точками
    plt.plot(dates, scores, marker='o', linestyle='-', color='blue')

    # Форматирование оси X
    plt.xlabel('Дата и время')
    plt.ylabel('Баллы')
    plt.title('Динамика баллов пользователя')

    # Отображение дат с годом и минутами
    date_format = DateFormatter('%d.%m.%Y %H:%M')
    plt.gca().xaxis.set_major_formatter(date_format)

    plt.gcf().autofmt_xdate()  # Поворот дат для читаемости

    buf = io.BytesIO()
    plt.savefig(buf, format='png', bbox_inches='tight')
    buf.seek(0)
    plt.close()
    return send_file(buf, mimetype='image/png')


@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username'].strip()
        email    = request.form['email'].strip()
        password = request.form['password'].strip()

        if not username or not email or not password:
            flash('Все поля обязательны к заполнению', 'error')
        elif get_user_by_username(username):
            flash('Пользователь с таким именем уже существует', 'error')
        elif get_user_by_email(email):
            flash('Пользователь с таким адресом электронной почты уже существует', 'error')
        elif len(password) < 6:
            flash('Пароль должен содержать минимум 6 символов.', 'error')
        elif password.isdigit():
            flash('Пароль не должен состоять только из цифр.', 'error')
        elif password.isalpha():
            flash('Пароль не должен состоять только из букв.', 'error')
        else:
            pw_hash = generate_password_hash(password)
            create_user(username, email, pw_hash)
            flash('Регистрация прошла успешно, войдите в систему.', 'success')
            return redirect(url_for('login'))
        return render_template('register.html', username=username, email=email)
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = get_user_by_username(username)

        if not user or not check_password_hash(user['password'], password):
            flash('Неправильное имя пользователя или пароль', 'error')
        else:
            session.clear()
            session['user_id'] = user['id']
            flash('Вы вошли в систему', 'success')
            return redirect(url_for('index'))

    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    session.clear()
    flash('Вы вышли из системы', 'info')
    return redirect(url_for('index'))

