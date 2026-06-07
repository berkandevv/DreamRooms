# Checklist funcional - Dream Rooms

Pruebas sobre el entorno Docker local (`./start-demo.sh`).
Los endpoints de la API cuelgan del prefijo `http://localhost:8000/api` (por ejemplo `http://localhost:8000/api/hotels`, mientras que la ruta base sin recurso devuelve 404), el panel de administración está en `http://localhost:8000` y la SPA en `:5173`.
Para cada punto se indica el método de comprobación y el resultado obtenido.

Notación: `[✓]` indica que la comprobación resultó correcta.

---

## FRONT - Cliente y publico

### Catalogo
- [✓] El listado muestra únicamente hoteles publicados. `GET /hotels` devuelve 25 registros, todos con `status=published`. Se creó un hotel en estado `draft` y se confirmó que no aparece en el listado.
- [✓] Los filtros se aplican correctamente: ciudad/comunidad, estrellas, precio mínimo/máximo y servicios.
  - Mediante la API se verificaron `stars`, `city`, `min_price/max_price`, `country` y `pets/smoking`, todos con respuesta correcta (stars=5 devuelve 5 hoteles, city=Madrid devuelve 5 y el rango 50-100 devuelve 10).
  - Los valores `max_price<min_price` y `stars=9` devuelven 422.
  - Cabe señalar que los filtros de comunidad, ciudad y servicios residen en el **frontend**. La interfaz de `/hotels` muestra "Comunidad autónoma", "Ciudad" y el filtro de servicios, pero el filtrado se ejecuta en cliente. La API no dispone de query de región ni de servicios.
- [✓] El detalle por slug carga habitaciones, servicios y reseñas publicadas. `GET /hotels/hostal-la-muralla` devuelve 3 room_types y 3 servicios. Un slug inexistente devuelve 404. La interfaz muestra la imagen, el precio (58€/noche) y las reseñas.
- [✓] La comprobación de disponibilidad por fechas funciona correctamente. `GET /room-types/{id}/availability?from=&to=` responde 200 y, sin fechas, devuelve 422. El `quote` calcula las noches y el precio de forma correcta.

### Cuenta
- [✓] Registro de cliente y de propietario. Con `account_type=customer|owner` devuelve 201 con su token y su rol correspondientes. El campo correcto es `account_type`, no `role`, y `account_type=admin` devuelve 422.
- [✓] Login: cliente y propietario reciben token. Con contraseña incorrecta devuelve 422.
- [✓] Logout. `POST /auth/logout` responde 200 y el token deja de ser válido (una llamada posterior a `me` devuelve 401).
- [✓] Cambio de contraseña con verificación de la actual. Si la contraseña actual es incorrecta devuelve 422. Si es correcta, 200. Posteriormente, la contraseña antigua deja de ser válida y la nueva permite el acceso.
- [✓] La desactivación de la cuenta impide el acceso. Sin contraseña devuelve 422, con contraseña 200, y el login posterior devuelve 422.

### Reservas
- [✓] Reservar con tarjeta simulada genera una reserva en estado `confirmed` + `paid`. Con `payment_method=card` el estado queda en confirmed, el payment_status en paid y se genera el pago simulado.
- [✓] Reservar con pago en el hotel genera una reserva en estado `pending` y no descuenta cupo (overbooking). Con `payment_method=hotel` el estado es pending y el payment_status pending. Tras una reserva con pago en hotel la disponibilidad de la noche no se decrementa, y se admiten reservas con pago en hotel aunque el cupo esté a 0. La reserva fija `cancellation_deadline_at`. No existe expiración automática de pendientes en el código actual (ver nota 4).
- [✓] El control de disponibilidad por unidades solo se aplica al pago con tarjeta. El pago en hotel admite overbooking. La estancia mínima, la fecha cerrada y la ocupación siguen bloqueando ambos métodos.
  - Si el número de adultos supera capacidad·unidades, devuelve 422 en ambos métodos.
  - Con tarjeta, el cupo insuficiente (`available_units`) y la fecha cerrada devuelven 422.
  - Con pago en hotel, el cupo insuficiente se permite (overbooking, 201). La fecha cerrada y la estancia mínima siguen devolviendo 422.
  - El seed fija `min_stay_nights=2` en fin de semana: reservar una sola noche de sábado devuelve 422 y dos noches devuelve 201.
- [✓] Listado y detalle de las reservas propias. `GET /customer/bookings` y `/{id}` responden 200. Una reserva ajena devuelve 404.
- [✓] La cancelación dentro de plazo restaura las unidades y genera reembolso. La cancelación responde 200, la reserva queda `cancelled` y, si estaba pagada, el `payment_status` pasa a `refunded` con su pago `refunded` registrado. Comprobado con tarjeta (reembolso automático y restauración de inventario) y con pago en hotel previamente cobrado por el propietario.
- [✓] La cancelación fuera de plazo se permite, pero sin reembolso. Responde 200, la reserva queda `cancelled`, el `payment_status` se mantiene (no se crea pago `refunded`) y la interfaz avisa de que se cobrará igualmente y no se reembolsará el importe. Las habitaciones de `hostal-la-muralla` traen `free_cancellation_hours=48` en el seed: reservando con check_in para el día siguiente el plazo ya está vencido y la cancelación entra en este supuesto.
- [✓] No permite cancelar una reserva completada ni una ya cancelada. Una reserva completada devuelve 422 y una ya cancelada, también.

### Resenas
- [✓] Solo se puede reseñar una reserva completada. Sobre una reserva `confirmed` devuelve 422 y sobre una `completed` devuelve 201.
- [✓] Se admite una única reseña por reserva. La segunda reseña devuelve 422 y una reserva con reseña previa devuelve 422.
- [✓] Se admite adjuntar una sola foto, de carácter opcional. Un multipart con `image` devuelve 201 y la `image_url` resulta accesible (200). Con 2 imágenes, o con un fichero que no sea imagen, devuelve 422.
- [✓] La reseña creada queda pendiente y no se publica automáticamente. Se genera con `status=pending`.

### Favoritos
- [✓] Añadir y eliminar favorito. `POST` y `DELETE /customer/hotels/{id}/favorite` responden 2xx.
- [✓] El listado de favoritos es coherente: el hotel aparece tras añadirlo y desaparece tras eliminarlo.

## FRONT - Panel propietario
- [✓] Crear hotel y crear tipo de habitación. `POST /owner/hotels` y `/owner/hotels/{id}/room-types` devuelven 201. La vista `/owner` lista los hoteles con su estado, reservas y precio.
- [✓] Asignar servicios al hotel y a la habitación. Los `service_ids` respetan el scope (hotel/both para el hotel, room_type/both para la habitación) y quedan asignados.
- [✓] La subida de foto reemplaza la anterior, sin acumularlas. Tras dos subidas permanece una única imagen. Dos imágenes simultáneas devuelven 422 y un fichero .txt devuelve 422.
- [✓] Actualizar la disponibilidad en bloque y cerrar una fecha concreta. La operación bulk responde 200 y, al cerrar la fecha, el estado queda en `closed`.
- [✓] Editar hotel y editar habitación. El `PUT` del hotel (stars) y de la habitación (base_price) responden 200.
- [✓] Consultar las reservas de sus hoteles y filtrarlas. `GET /owner/bookings` con los filtros `status` y `payment_status` funciona correctamente.
- [✓] Cambiar el estado de una reserva respetando las transiciones válidas. La secuencia pending→confirmed→completed es correcta. Las transiciones pending→completed y completed→pending devuelven 422.
- [✓] Registrar un pago manual completo, únicamente para pago en hotel. Con el importe exacto el estado pasa a paid. Un importe parcial devuelve 422, un doble pago devuelve 422 y sobre una reserva `card` devuelve 422.
- [✓] No puede consultar ni gestionar hoteles ni reservas de otro propietario. owner2 sobre recursos de owner1 devuelve 404, tanto al ver/editar el hotel como al ver/cambiar la reserva.

---

## BACK - API

### Auth
- [✓] El register crea cliente/propietario con token. Devuelve 201 con el rol y el token correctos.
- [✓] El login concede token únicamente a un usuario activo cliente/propietario. Los usuarios activos reciben token. Uno desactivado devuelve 422.
- [✓] El login rechaza al administrador. `admin@dreamrooms.com` devuelve 403 con el mensaje "Admin users cannot authenticate through the API".
- [✓] me, logout, cambio de contraseña y desactivación de cuenta funcionan correctamente (detallado en la sección Cuenta).

### Publico
- [✓] Hoteles con sus filtros, únicamente los publicados (ver Catalogo).
- [✓] Detalle por slug. Uno inexistente devuelve 404.
- [✓] Reseñas: `GET /hotels/{slug}/reviews` devuelve únicamente las `published`.
- [✓] Disponibilidad y quote correctos.

### Cliente
- [✓] Crear, listar, consultar y cancelar reserva.
- [✓] Crear reseña, que queda pendiente y admite image.
- [✓] Favoritos.

### Propietario
- [✓] Hoteles, habitaciones y disponibilidad (CRUD y bulk).
- [✓] Reservas: estado y pago manual.
- [✓] No accede a recursos de otro propietario (404).

### Reglas de seguridad
- [✓] Ignora el `user_id` y el `owner_user_id` enviados por el cliente. Una reserva con `user_id` inyectado queda asociada al token, y un hotel con `owner_user_id` inyectado pertenece al propietario del token.
- [✓] El administrador no accede por API a las rutas privadas de cliente/propietario. No obtiene token. Sin token devuelve 401 y con token inválido, 401.
- [✓] Roles cruzados: un cliente contra `/owner` devuelve 403 y un propietario contra `/customer`, también.

---

## BACK - Panel admin web

### Acceso
- [✓] La raíz redirige al login (302 a `/login`).
- [✓] Al login solo accede el administrador. Propietario y cliente regresan a `/login`. El administrador accede a `/dashboard`.
- [✓] Las rutas de auto-registro y recuperación de contraseña no existen: `/register`, `/forgot-password` y `/reset-password` devuelven 404.
- [✓] La sesión no persiste al cerrar el navegador (`session.expire_on_close=true`).

### Gestion
- [✓] Users: permite editar, pero no gestionar a otros administradores ni autodesactivarse.
  - La edición de un cliente se guarda correctamente (el nombre se actualiza en BD).
  - La edición de un usuario administrador devuelve 403 (`ensureManageable`). Los roles asignables son únicamente owner/customer.
  - La autodesactivación está bloqueada: el administrador no es gestionable desde el panel de users y existe además un guard sobre el propio status.
- [✓] Hotels, room types y availability admiten edición. Las páginas cargan (200) y el modelo es el mismo que ya se validó con propietario.
- [✓] Bookings: consultar, cambiar estado y registrar pago. Un pago manual deja la reserva en `paid` y el cambio confirmed→completed la deja en `completed` (verificado en BD).
- [✓] Reviews: moderar de pending a published u hidden y visualizar la foto. El flujo completo es correcto y el formulario muestra la imagen.
- [✓] Services: crear y editar. El servicio creado queda registrado y se comprueba en la BD.
- [✓] Perfil: editar datos y contraseña, sin posibilidad de eliminar la cuenta. La actualización es correcta y no existe ruta de borrado (`DELETE /profile` devuelve 405).

---

## Integracion front <-> back
- [✓] El cliente publica un comentario y este aparece como pending en el administrador. La reseña se genera como `pending` y se visualiza en su pantalla de edición del panel.
- [✓] El administrador publica la reseña y esta aparece en la página pública del hotel. Tras la publicación, `GET /hotels/hostal-la-muralla/reviews` ya la incluye.
- [✓] El administrador oculta la reseña (hidden) y desaparece del público. Tras ocultarla, deja de aparecer tanto en el endpoint público como en el detalle de la interfaz.
- [✓] El propietario sube una foto nueva y permanece únicamente esa. Tras dos subidas queda una sola imagen.
- [✓] Reserva con pago en hotel, se registra el pago y queda en paid. Verificado tanto desde propietario como desde administrador.
- [✓] Una edición de usuario en el administrador se refleja en la SPA. Al cambiar el nombre de un cliente desde el panel, el nuevo nombre aparece en la navegación de la SPA.

---

## Notas y hallazgos (no son bugs)

1. En el registro, el parámetro es `account_type` (`customer`/`owner`), no `role`. El envío de `role` se ignora (resulta customer). `account_type=admin` devuelve 422.
2. Los filtros de catálogo por API se limitan a `city/country/stars/price/pets/smoking`. "Comunidad" y "servicios" se filtran en cliente, dentro de la SPA.
3. El seed incluye datos para probar el plazo de cancelación y la estancia mínima sin configuración previa: las habitaciones de `hostal-la-muralla` traen `free_cancellation_hours=48` y la disponibilidad fija `min_stay_nights=2` en fin de semana. El resto de habitaciones mantiene `free_cancellation_hours=NULL`, en cuyo caso toda cancelación se considera dentro de plazo (con reembolso).
4. No existe expiración automática de reservas pendientes. La tabla `bookings` no tiene columna `expires_at` ni hay comando programado ni scheduler que las cancele. Una reserva con pago en hotel permanece en `pending` hasta que el propietario o el administrador la confirme, complete o cancele, o el cliente la cancele. En la creación solo se fija `cancellation_deadline_at`, derivado del `free_cancellation_hours` del tipo de habitación.
5. Las comprobaciones que crean datos (hoteles, reservas, servicios, reseñas) se revierten volviendo a ejecutar `./start-demo.sh`, que recarga el seed con `migrate:fresh --seed`.
