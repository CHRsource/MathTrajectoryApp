/*
drop database math_db;
drop user 'mathuser'@'localhost';
*/

CREATE DATABASE math_db;

CREATE USER 'mathuser'@'localhost' IDENTIFIED BY 'mathpassword';
GRANT ALL PRIVILEGES ON math_db.* to 'mathuser'@'localhost';
FLUSH PRIVILEGES;

USE math_db;

CREATE TABLE topics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,           -- Название темы
    level VARCHAR(50) NOT NULL            -- Уровень сложности (basic, intermediate, advanced)
);

CREATE TABLE topic_dependencies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    topic_id INT NOT NULL,           -- Идентификатор темы, для которой нужны предварительные темы
    prerequisite_id INT NOT NULL,    -- Идентификатор предварительной темы
    FOREIGN KEY (topic_id) REFERENCES topics(id),
    FOREIGN KEY (prerequisite_id) REFERENCES topics(id)
);

CREATE TABLE questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    topic_id INT,                          -- Ссылка на тему
    question_image VARCHAR(255),       -- Путь к изображению вопроса
    correct_answer_image VARCHAR(255), -- Путь к изображению правильного ответа
    wrong_answer_1_image VARCHAR(255), -- Путь к изображению неправильного ответа 1
    wrong_answer_2_image VARCHAR(255), -- Путь к изображению неправильного ответа 2
    wrong_answer_3_image VARCHAR(255), -- Путь к изображению неправильного ответа 3
    FOREIGN KEY (topic_id) REFERENCES topics(id)
);


CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,  -- Уникальный идентификатор пользователя
    username VARCHAR(255) NOT NULL,     -- Имя пользователя
    email VARCHAR(255) NOT NULL UNIQUE, -- Электронная почта (должна быть уникальной)
    password VARCHAR(255) NOT NULL,     -- Пароль пользователя (можно хранить в зашифрованном виде)
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Дата и время регистрации
);


CREATE TABLE test_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,               -- Идентификатор пользователя
    test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Дата и время сдачи теста
    score INT NOT NULL,                 -- Количество правильных ответов
    total_questions INT NOT NULL,       -- Общее количество вопросов в тесте
    FOREIGN KEY (user_id) REFERENCES users(id) -- Ссылка на пользователя
);

-- каждому результату (test_results.id) соответствует одна сохранённая траектория
CREATE TABLE trajectories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    test_result_id INT NOT NULL,
    trajectory JSON NOT NULL,           -- сохраняем список тем в JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (test_result_id) REFERENCES test_results(id)
);



INSERT INTO topics (name, level) VALUES 
('Арифметика', 'basic'),
('Проценты', 'basic'),
('Дроби', 'basic'),
('Степени и корни', 'intermediate'),
('Выражения', 'basic'),
('Уравнения (линейные, квадратные)', 'intermediate'),
('Системы уравнений', 'intermediate'),
('Функции и графики', 'intermediate'),
('Производные', 'advanced'),
('Исследование функций', 'advanced'),
('Геометрия (базовая)', 'basic'),
('Планиметрия', 'intermediate'),
('Стереометрия', 'intermediate'),
('Тригонометрия', 'intermediate'),
('Неравенства (линейные, квадратные, дробные)', 'intermediate'),
('Логарифмы', 'advanced'),
('Комбинаторика', 'advanced'),
('Вероятности', 'advanced'),
('Текстовые задачи', 'intermediate'),
('Задачи по геометрии', 'advanced');

INSERT INTO topic_dependencies (topic_id, prerequisite_id) VALUES
(2, 1),  -- Проценты зависит от Арифметики
(3, 1),  -- Дроби зависит от Арифметики
(4, 1),  -- Степени и корни зависит от Арифметики
(5, 2),  -- Выражения зависит от Процентов
(5, 3),  -- Выражения зависит от Дробей
(5, 4),  -- Выражения зависит от Степеней и корней
(6, 5),  -- Уравнения (линейные, квадратные) зависит от Выражений
(7, 6),  -- Системы уравнений зависит от Уравнений
(8, 6),  -- Функции и графики зависит от Уравнений
(9, 8),  -- Производные зависит от Функций и графиков
(10, 9), -- Исследование функций зависит от Производных
(11, 1), -- Геометрия (базовая) зависит от Арифметики
(12, 11), -- Планиметрия зависит от Геометрии
(13, 11), -- Стереометрия зависит от Геометрии
(14, 12), -- Тригонометрия зависит от Планиметрии
(14, 6),  -- Тригонометрия зависит от Уравнений
(15, 6),  -- Неравенства (линейные, квадратные, дробные) зависит от Уравнений
(16, 4),  -- Логарифмы зависит от Степеней и корней
(16, 6),  -- Логарифмы зависит от Уравнений
(17, 1),  -- Комбинаторика зависит от Арифметики
(18, 17), -- Вероятности зависит от Комбинаторики
(18, 8),  -- Вероятности зависит от Функций и графиков
(19, 6),  -- Текстовые задачи зависит от Уравнений
(20, 12), -- Задачи по геометрии зависит от Планиметрии
(20, 13); -- Задачи по геометрии зависит от Стереометрии


INSERT INTO questions (topic_id, question_image, correct_answer_image, wrong_answer_1_image, wrong_answer_2_image, wrong_answer_3_image) VALUES
(1, 'theme1_q1.png', 'theme1_q1_correct_a.png', 'theme1_q1_wrong_a1.png', 'theme1_q1_wrong_a2.png', 'theme1_q1_wrong_a3.png'),
(1, 'theme1_q2.png', 'theme1_q2_correct_a.png', 'theme1_q2_wrong_a1.png', 'theme1_q2_wrong_a2.png', 'theme1_q2_wrong_a3.png'),

(2, 'theme2_q1.png', 'theme2_q1_correct_a.png', 'theme2_q1_wrong_a1.png', 'theme2_q1_wrong_a2.png', 'theme2_q1_wrong_a3.png'),
(2, 'theme2_q2.png', 'theme2_q2_correct_a.png', 'theme2_q2_wrong_a1.png', 'theme2_q2_wrong_a2.png', 'theme2_q2_wrong_a3.png'),

(3, 'theme3_q1.png', 'theme3_q1_correct_a.png', 'theme3_q1_wrong_a1.png', 'theme3_q1_wrong_a2.png', 'theme3_q1_wrong_a3.png'),
(3, 'theme3_q2.png', 'theme3_q2_correct_a.png', 'theme3_q2_wrong_a1.png', 'theme3_q2_wrong_a2.png', 'theme3_q2_wrong_a3.png'),

(4, 'theme4_q1.png', 'theme4_q1_correct_a.png', 'theme4_q1_wrong_a1.png', 'theme4_q1_wrong_a2.png', 'theme4_q1_wrong_a3.png'),
(4, 'theme4_q2.png', 'theme4_q2_correct_a.png', 'theme4_q2_wrong_a1.png', 'theme4_q2_wrong_a2.png', 'theme4_q2_wrong_a3.png'),

(5, 'theme5_q1.png', 'theme5_q1_correct_a.png', 'theme5_q1_wrong_a1.png', 'theme5_q1_wrong_a2.png', 'theme5_q1_wrong_a3.png'),
(5, 'theme5_q2.png', 'theme5_q2_correct_a.png', 'theme5_q2_wrong_a1.png', 'theme5_q2_wrong_a2.png', 'theme5_q2_wrong_a3.png'),

(6, 'theme6_q1.png', 'theme6_q1_correct_a.png', 'theme6_q1_wrong_a1.png', 'theme6_q1_wrong_a2.png', 'theme6_q1_wrong_a3.png'),
(6, 'theme6_q2.png', 'theme6_q2_correct_a.png', 'theme6_q2_wrong_a1.png', 'theme6_q2_wrong_a2.png', 'theme6_q2_wrong_a3.png'),

(7, 'theme7_q1.png', 'theme7_q1_correct_a.png', 'theme7_q1_wrong_a1.png', 'theme7_q1_wrong_a2.png', 'theme7_q1_wrong_a3.png'),
(7, 'theme7_q2.png', 'theme7_q2_correct_a.png', 'theme7_q2_wrong_a1.png', 'theme7_q2_wrong_a2.png', 'theme7_q2_wrong_a3.png'),

(8, 'theme8_q1.png', 'theme8_q1_correct_a.png', 'theme8_q1_wrong_a1.png', 'theme8_q1_wrong_a2.png', 'theme8_q1_wrong_a3.png'),
(8, 'theme8_q2.png', 'theme8_q2_correct_a.png', 'theme8_q2_wrong_a1.png', 'theme8_q2_wrong_a2.png', 'theme8_q2_wrong_a3.png'),

(9, 'theme9_q1.png', 'theme9_q1_correct_a.png', 'theme9_q1_wrong_a1.png', 'theme9_q1_wrong_a2.png', 'theme9_q1_wrong_a3.png'),
(9, 'theme9_q2.png', 'theme9_q2_correct_a.png', 'theme9_q2_wrong_a1.png', 'theme9_q2_wrong_a2.png', 'theme9_q2_wrong_a3.png'),

(10, 'theme10_q1.png', 'theme10_q1_correct_a.png', 'theme10_q1_wrong_a1.png', 'theme10_q1_wrong_a2.png', 'theme10_q1_wrong_a3.png'),
(10, 'theme10_q2.png', 'theme10_q2_correct_a.png', 'theme10_q2_wrong_a1.png', 'theme10_q2_wrong_a2.png', 'theme10_q2_wrong_a3.png'),

(11, 'theme11_q1.png', 'theme11_q1_correct_a.png', 'theme11_q1_wrong_a1.png', 'theme11_q1_wrong_a2.png', 'theme11_q1_wrong_a3.png'),
(11, 'theme11_q2.png', 'theme11_q2_correct_a.png', 'theme11_q2_wrong_a1.png', 'theme11_q2_wrong_a2.png', 'theme11_q2_wrong_a3.png'),

(12, 'theme12_q1.png', 'theme12_q1_correct_a.png', 'theme12_q1_wrong_a1.png', 'theme12_q1_wrong_a2.png', 'theme12_q1_wrong_a3.png'),
(12, 'theme12_q2.png', 'theme12_q2_correct_a.png', 'theme12_q2_wrong_a1.png', 'theme12_q2_wrong_a2.png', 'theme12_q2_wrong_a3.png'),

(13, 'theme13_q1.png', 'theme13_q1_correct_a.png', 'theme13_q1_wrong_a1.png', 'theme13_q1_wrong_a2.png', 'theme13_q1_wrong_a3.png'),
(13, 'theme13_q2.png', 'theme13_q2_correct_a.png', 'theme13_q2_wrong_a1.png', 'theme13_q2_wrong_a2.png', 'theme13_q2_wrong_a3.png'),

(14, 'theme14_q1.png', 'theme14_q1_correct_a.png', 'theme14_q1_wrong_a1.png', 'theme14_q1_wrong_a2.png', 'theme14_q1_wrong_a3.png'),
(14, 'theme14_q2.png', 'theme14_q2_correct_a.png', 'theme14_q2_wrong_a1.png', 'theme14_q2_wrong_a2.png', 'theme14_q2_wrong_a3.png'),

(15, 'theme15_q1.png', 'theme15_q1_correct_a.png', 'theme15_q1_wrong_a1.png', 'theme15_q1_wrong_a2.png', 'theme15_q1_wrong_a3.png'),
(15, 'theme15_q2.png', 'theme15_q2_correct_a.png', 'theme15_q2_wrong_a1.png', 'theme15_q2_wrong_a2.png', 'theme15_q2_wrong_a3.png'),

(16, 'theme16_q1.png', 'theme16_q1_correct_a.png', 'theme16_q1_wrong_a1.png', 'theme16_q1_wrong_a2.png', 'theme16_q1_wrong_a3.png'),
(16, 'theme16_q2.png', 'theme16_q2_correct_a.png', 'theme16_q2_wrong_a1.png', 'theme16_q2_wrong_a2.png', 'theme16_q2_wrong_a3.png'),

(17, 'theme17_q1.png', 'theme17_q1_correct_a.png', 'theme17_q1_wrong_a1.png', 'theme17_q1_wrong_a2.png', 'theme17_q1_wrong_a3.png'),
(17, 'theme17_q2.png', 'theme17_q2_correct_a.png', 'theme17_q2_wrong_a1.png', 'theme17_q2_wrong_a2.png', 'theme17_q2_wrong_a3.png'),

(18, 'theme18_q1.png', 'theme18_q1_correct_a.png', 'theme18_q1_wrong_a1.png', 'theme18_q1_wrong_a2.png', 'theme18_q1_wrong_a3.png'),
(18, 'theme18_q2.png', 'theme18_q2_correct_a.png', 'theme18_q2_wrong_a1.png', 'theme18_q2_wrong_a2.png', 'theme18_q2_wrong_a3.png'),

(19, 'theme19_q1.png', 'theme19_q1_correct_a.png', 'theme19_q1_wrong_a1.png', 'theme19_q1_wrong_a2.png', 'theme19_q1_wrong_a3.png'),
(19, 'theme19_q2.png', 'theme19_q2_correct_a.png', 'theme19_q2_wrong_a1.png', 'theme19_q2_wrong_a2.png', 'theme19_q2_wrong_a3.png'),

(20, 'theme20_q1.png', 'theme20_q1_correct_a.png', 'theme20_q1_wrong_a1.png', 'theme20_q1_wrong_a2.png', 'theme20_q1_wrong_a3.png'),
(20, 'theme20_q2.png', 'theme20_q2_correct_a.png', 'theme20_q2_wrong_a1.png', 'theme20_q2_wrong_a2.png', 'theme20_q2_wrong_a3.png');




SELECT 
    t1.name AS topic_name, 
    t2.name AS prerequisite_name
FROM 
    topic_dependencies td
JOIN 
    topics t1 ON td.topic_id = t1.id
JOIN 
    topics t2 ON td.prerequisite_id = t2.id;
    
/*delete from users where id = 2;
alter table users auto_increment = 2;*/

/*delete from test_results where user_id = 2;
alter table test_results auto_increment = 2;
update test_results set id = 1 where id = 22;*/



