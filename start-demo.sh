#!/usr/bin/env sh
# Prepara y levanta el entorno de desarrollo local con Docker:
# configura el .env del backend, arranca los contenedores y carga datos demo.
set -eu

# Raíz del proyecto (directorio del script) para resolver rutas absolutas
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENV_FILE="$ROOT_DIR/backend/.env"
ENV_EXAMPLE="$ROOT_DIR/backend/.env.example"

cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker no esta instalado o no esta disponible en PATH." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker no esta iniciado. Abre Docker Desktop y vuelve a ejecutar este script." >&2
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

# Fija una variable en el .env: la sustituye si ya existe, la añade si no
set_env() {
    key=$1
    value=$2

    if grep -q "^${key}=" "$ENV_FILE"; then
        sed "s|^${key}=.*|${key}=${value}|" "$ENV_FILE" > "$ENV_FILE.tmp"
        mv "$ENV_FILE.tmp" "$ENV_FILE"
    else
        printf '\n%s=%s\n' "$key" "$value" >> "$ENV_FILE"
    fi
}

set_env APP_URL http://localhost:8000
set_env APP_NAME DreamRooms
# Conexión a MySQL dentro de Docker (host "database", no localhost)
set_env DB_CONNECTION mysql
set_env DB_HOST database
set_env DB_PORT 3306
set_env DB_DATABASE dreamrooms
set_env DB_USERNAME dreamrooms
set_env DB_PASSWORD dreamrooms

echo "Deteniendo contenedores anteriores..."
docker compose down --remove-orphans

echo "Construyendo PHP y levantando MySQL..."
docker compose up -d --build database backend nginx

# Instala las dependencias de Composer solo en el primer arranque
if [ ! -f "$ROOT_DIR/backend/vendor/autoload.php" ]; then
    echo "Instalando dependencias PHP..."
    docker compose exec -T backend composer install --no-interaction
fi

# Genera la clave de cifrado de Laravel si el .env aún no la tiene
if ! grep -q '^APP_KEY=base64:' "$ENV_FILE"; then
    echo "Generando APP_KEY..."
    docker compose exec -T backend php artisan key:generate --force
fi

echo "Preparando almacenamiento y reconstruyendo la base de datos demo..."
docker compose exec -T backend php artisan config:clear
docker compose exec -T backend php artisan storage:link --force
# NOTA: migrate:fresh borra todas las tablas y recarga los datos demo
docker compose exec -T backend php artisan migrate:fresh --seed --force

echo "Levantando los servidores Vite..."
docker compose up -d frontend backend-vite

echo
echo "DreamRooms esta levantado:"
echo "  Frontend: http://localhost:5173"
echo "  Backend:  http://localhost:8000"
echo "  Swagger:  http://localhost:8000/docs/swagger"
echo "  Scramble: http://localhost:8000/docs/api"
