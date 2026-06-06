# DreamRooms

DreamRooms es una aplicación web de reservas de hoteles. Este repositorio reúne
el entorno Docker de desarrollo y referencia los proyectos de backend y
frontend como submódulos Git.

## Funcionalidades principales

- Catálogo de hoteles con filtros, habitaciones, servicios y reseñas
- Consulta de disponibilidad y cálculo del precio de una estancia
- Registro e inicio de sesión de clientes y propietarios
- Reservas, favoritos y reseñas para clientes
- Gestión de hoteles, habitaciones, disponibilidad, reservas y pagos para propietarios
- Panel web de administración
- Documentación OpenAPI de la API con Scramble y Swagger

## Tecnologías

- Laravel 13, PHP 8.3 y Laravel Sanctum
- React 19, Vite 8 y Tailwind CSS
- MySQL 8
- Nginx
- Docker Compose

## Requisitos

- Git
- Docker Desktop o Docker Engine con Docker Compose

## Instalación

Clona el repositorio incluyendo los submódulos:

```bash
git clone --recurse-submodules git@github.com:berkandevv/DreamRooms.git
cd DreamRooms
```

Si ya habías clonado el repositorio sin los submódulos:

```bash
git submodule update --init --recursive
```

## Arranque rápido

Con Docker iniciado, ejecuta:

```bash
./start-demo.sh
```

Si el sistema muestra un error de permisos al ejecutar el script, concede
permiso de ejecución una vez y vuelve a lanzarlo:

```bash
chmod +x start-demo.sh
./start-demo.sh
```

El script prepara automáticamente el entorno local:

1. Crea `backend/.env` si todavía no existe.
2. Configura la conexión del backend con MySQL dentro de Docker.
3. Detiene los contenedores anteriores del proyecto sin borrar los volúmenes.
4. Construye la imagen PHP y levanta MySQL, PHP-FPM y Nginx.
5. Instala las dependencias Composer.
6. Genera `APP_KEY` si es necesario.
7. Recrea la base de datos y carga los datos demo.
8. Levanta los servidores Vite del frontend React y del panel Laravel.

> [!WARNING]
> El script ejecuta `php artisan migrate:fresh --seed --force`. Cada ejecución
> elimina las tablas existentes y vuelve a cargar los datos demo. Úsalo solo
> para desarrollo local.

## URLs locales

| Servicio | URL |
| --- | --- |
| Frontend React | [http://localhost:5173](http://localhost:5173) |
| Backend Laravel | [http://localhost:8000](http://localhost:8000) |
| Documentación Scramble | [http://localhost:8000/docs/api](http://localhost:8000/docs/api) |
| Especificación OpenAPI | [http://localhost:8000/docs/api.json](http://localhost:8000/docs/api.json) |
| Swagger | [http://localhost:8000/docs/swagger](http://localhost:8000/docs/swagger) |

## Usuarios demo

| Rol | Email | Contraseña |
| --- | --- | --- |
| Cliente | `cliente01@dreamrooms.test` | `password` |
| Propietario | `owner01@dreamrooms.test` | `password` |
| Administrador | `admin@dreamrooms.com` | `12345678` |

El cliente y el propietario se pueden usar desde el frontend React. El
administrador accede al panel web Laravel desde
[http://localhost:8000/login](http://localhost:8000/login).

## Servicios Docker

| Servicio | Descripción |
| --- | --- |
| `database` | Base de datos MySQL de DreamRooms |
| `backend` | Backend Laravel servido con PHP-FPM |
| `nginx` | Servidor Nginx expuesto en el puerto `8000` |
| `frontend` | Servidor Vite del frontend React en el puerto `5173` |
| `backend-vite` | Servidor Vite de los assets Laravel en el puerto `5174` |

Comandos útiles:

```bash
docker compose ps
docker compose logs -f
docker compose down
```

## Submódulos

Este repositorio fija una versión concreta de cada proyecto:

| Proyecto | Directorio | Repositorio |
| --- | --- | --- |
| Backend | `backend/` | [DreamRooms-api](https://github.com/berkandevv/DreamRooms-api) |
| Frontend | `frontend/` | [DreamRooms-front](https://github.com/berkandevv/DreamRooms-front) |

Para descargar las versiones registradas por este repositorio:

```bash
git pull --recurse-submodules
git submodule update --init --recursive
```

Para actualizar las referencias después de publicar cambios en los
repositorios individuales:

```bash
git submodule update --remote backend frontend
git add backend frontend
git commit -m "chore(git): update project submodules"
```

## Documentación específica

- [Backend y API](https://github.com/berkandevv/DreamRooms-api#readme)
- [Frontend React](https://github.com/berkandevv/DreamRooms-front#readme)

## Licencia

Este proyecto se distribuye bajo la licencia MIT. Consulta [LICENSE](LICENSE).
