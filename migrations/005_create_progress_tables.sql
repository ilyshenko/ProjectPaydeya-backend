-- Удаляем старую таблицу если существует
DROP TABLE IF EXISTS material_completions;
DROP TABLE IF EXISTS favorite_materials;

-- Создаем таблицу рейтингов с правильными foreign keys
CREATE TABLE IF NOT EXISTS material_ratings (
    id SERIAL PRIMARY KEY,
    material_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Внешние ключи
    FOREIGN KEY (material_id) REFERENCES materials(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    -- Уникальность: пользователь может оценить материал только один раз
    UNIQUE(material_id, user_id)
);

-- Таблица для избранных материалов
CREATE TABLE IF NOT EXISTS favorite_materials (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    material_id INTEGER NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, material_id)
);

-- Таблица для завершенных материалов
CREATE TABLE IF NOT EXISTS material_completions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    material_id INTEGER NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
    time_spent INTEGER NOT NULL, -- время в секундах
    grade DECIMAL(3,2) CHECK (grade >= 1 AND grade <= 5),
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, material_id)
);

-- Индексы для оптимизации прогресса
CREATE INDEX IF NOT EXISTS idx_favorite_materials_user_id ON favorite_materials(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_materials_material_id ON favorite_materials(material_id);
CREATE INDEX IF NOT EXISTS idx_material_completions_user_id ON material_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_material_completions_material_id ON material_completions(material_id);
CREATE INDEX IF NOT EXISTS idx_material_ratings_material_id ON material_ratings(material_id);
CREATE INDEX IF NOT EXISTS idx_material_ratings_user_id ON material_ratings(user_id);