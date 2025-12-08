function Write-Info($message) {
    Write-Host "$message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "$message" -ForegroundColor Green
}

function Write-Error($message) {
    Write-Host "$message" -ForegroundColor Red
}

Write-Host "Starting database setup with UTF-8..." -ForegroundColor Magenta

# Путь к docker на Mac
$DOCKER_PATH = "/usr/local/bin/docker"
$CONTAINER_NAME = "paydeya-db"

# Проверяем, существует ли docker
if (-not (Test-Path $DOCKER_PATH)) {
    Write-Error "Docker not found at $DOCKER_PATH"
    Write-Error "Please ensure Docker Desktop is installed and running"
    exit 1
}

# Проверяем запущен ли контейнер
Write-Info "Checking if container '$CONTAINER_NAME' is running..."
$containerResult = & $DOCKER_PATH ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}"
if (-not $containerResult) {
    Write-Error "Container '$CONTAINER_NAME' is not running"
    Write-Info "Starting container..."
    & $DOCKER_PATH run --name $CONTAINER_NAME -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:15
    Start-Sleep -Seconds 10  # Ждем запуска контейнера
}

# Проверяем базу данных
Write-Info "Checking database..."
$result = & $DOCKER_PATH exec $CONTAINER_NAME psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='paydeya';" 2>$null
if ($result.Trim() -eq "1") {
    Write-Success "Database 'paydeya' exists"
} else {
    Write-Info "Creating database 'paydeya'..."
    & $DOCKER_PATH exec $CONTAINER_NAME psql -U postgres -c "CREATE DATABASE paydeya;" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database 'paydeya' created"
    } else {
        Write-Error "Failed to create database"
        exit 1
    }
}

# Run migrations
Write-Info "Running migrations..."
@(
    "001_create_users_table.sql",
    "002_add_specializations_table.sql",
    "003_create_materials_tables.sql",
    "004_add_ratings_table.sql",
    "005_create_progress_tables.sql"
) | ForEach-Object {
    Write-Info "Executing $_"
    if (Test-Path "migrations/$_") {
        Get-Content "migrations/$_" | & $DOCKER_PATH exec -i $CONTAINER_NAME psql -U postgres -d paydeya 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Migration $_ had issues (continuing anyway...)"
        }
    } else {
        Write-Warning "Migration file $_ not found (skipping)"
    }
}

# Insert sample data
Write-Info "Inserting sample data..."
if (Test-Path "migrations/006_sample_data.sql") {
    Get-Content "migrations/006_sample_data.sql" | & $DOCKER_PATH exec -i $CONTAINER_NAME psql -U postgres -d paydeya 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Sample data inserted successfully!"
    } else {
        Write-Warning "Failed to insert sample data (continuing anyway...)"
    }
}

# Verify data
Write-Info "Verifying data..."
& $DOCKER_PATH exec -i $CONTAINER_NAME psql -U postgres -d paydeya -c "
SELECT
    'Пользователи: ' || COUNT(*) as users,
    'Материалы: ' || COUNT(*) as materials,
    'Рейтинги: ' || COUNT(*) as ratings
FROM
    (SELECT 1 FROM users) u,
    (SELECT 1 FROM materials) m,
    (SELECT 1 FROM material_ratings) r;
" 2>$null

Write-Host "Database setup completed!" -ForegroundColor Green