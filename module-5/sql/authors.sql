-- Таблица авторов для занятия 5.1.
-- База course, пользователь student, контейнер pg18-course.
-- Повторный запуск очищает таблицу и снова вставляет три строки.

DROP TABLE IF EXISTS authors;

CREATE TABLE authors (
    author_id integer PRIMARY KEY,
    name text NOT NULL
);

INSERT INTO authors (author_id, name) VALUES
    (1, 'Иванова'),
    (2, 'Петров'),
    (3, 'Смирнова');
