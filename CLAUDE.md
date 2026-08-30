# CLAUDE.md

Contexto y reglas de trabajo para este repositorio.

## Qué es este proyecto

Mini marketplace B2B. Una tienda compra productos de varios proveedores; al confirmar la compra se
crea una orden con una **suborden por proveedor**.

Restricciones que mandan sobre cualquier otra consideración:

- **MVP primero.** Nada de diseño visual sofisticado ni abstracciones especulativas.
- **No agregar complejidad por requisitos futuros que no están en el alcance.**
- **Nada de metaprogramación, DSLs caseros, gems que escondan comportamiento ni patrones opacos.**
  Todo el código tiene que poder explicarse en voz alta sin abrir la documentación de una gema.
- Si algo no cabe en el alcance, se documenta como pendiente en el README.

## Stack

- Ruby on Rails (última estable), app monolítica, **no** API-only.
- PostgreSQL.
- **Vistas nativas de Rails (ERB)**. Sin Vue, sin React, sin SPA.
- Hotwire solo si simplifica algo concreto (p. ej. actualizar el carrito sin recargar). Si no
  aporta, se prefiere el formulario clásico con redirect.
- ViewComponent: **opcional y bajo demanda**. Introducir un componente solo cuando haya
  duplicación real de markup en 3 o más lugares (candidato natural: la tarjeta de producto y el
  bloque de "grupo por proveedor"). No armar una librería de componentes por adelantado.
- CSS: lo mínimo. Un archivo propio o utilidades simples. Legible > bonito.
- Tests: **Minitest** (el default de Rails, menos setup que RSpec). Fixtures para datos base.

## Dominio

Modelos previstos:

- `Store` — la tienda compradora. Una sola, creada en seeds.
- `Supplier` — proveedor. `name`.
- `Product` — `belongs_to :supplier`, `name`, `price_cents`, `stock`.
- `Cart` / `CartItem` — carrito persistido en DB, `belongs_to :store`. La sesión guarda el `cart_id`.
- `Order` — `belongs_to :store`, `has_many :sub_orders`.
- `SubOrder` — `belongs_to :order`, `belongs_to :supplier`, `has_many :order_items`.
- `OrderItem` — `belongs_to :sub_order`, `belongs_to :product`, `quantity`, `unit_price_cents`.

Reglas de negocio (van con validaciones **y** tests):

1. Un producto pertenece a un único proveedor.
2. Las cantidades son enteros **estrictamente mayores que cero**.
3. Al confirmar la compra se crea exactamente una suborden por proveedor involucrado.
4. `OrderItem` **congela** `unit_price_cents` al momento de la compra. Si después cambia el precio
   del producto, la orden histórica no se altera. Nunca calcular totales leyendo `product.price`.
5. Cada suborden expone su subtotal; la orden expone su total general.
6. La creación de la orden es **atómica**: ante cualquier error no quedan órdenes ni subórdenes
   parciales. Todo dentro de una transacción, con `raise` para forzar rollback.
7. Ante un error, la UI muestra un mensaje comprensible (flash o errores en el formulario), nunca
   un stack trace ni un 500.

## Decisiones ya tomadas (no re-litigar)

- **Dinero en enteros** (`*_cents`), nunca floats. Un helper de formateo en la vista.
- **Carrito persistido en DB**, no en sesión. Tradeoff: una tabla más y limpieza pendiente de
  carritos abandonados, a cambio de validaciones de ActiveRecord y tests mucho más simples.
- **Subtotales y total calculados**, no denormalizados en columnas. Se derivan de los items
  (que ya tienen el precio congelado). Si aparece un problema de N+1 se resuelve con `includes`,
  no con contadores en caché.
- **Sin autenticación.** Un `current_store` en `ApplicationController` que devuelve la única tienda
  de los seeds. Aislado en un solo método para que se vea que es un punto de extensión conocido.
- **Lógica de checkout en un service object** (`app/services/orders/create_order.rb` o similar),
  no en el controller ni repartida en callbacks. El controller solo orquesta y decide qué renderizar.
- **Stock:** se valida disponibilidad al confirmar la compra y se descuenta dentro de la misma
  transacción. Sin reservas, sin locking optimista, sin manejo de concurrencia — eso se documenta
  como limitación conocida en el README.

## Casos borde a cubrir

Cubrir estos (y tener test para al menos los marcados con ★):

- ★ Orden con productos de 2+ proveedores → una suborden por proveedor, con los items correctos.
- ★ Cambio de precio del producto después de la compra → la orden mantiene el precio histórico.
- ★ Fallo a mitad del checkout → no queda ninguna orden ni suborden en la base.
- ★ Cantidad 0, negativa o no entera → rechazada con mensaje.
- Carrito vacío → no se puede confirmar la compra.
- Stock insuficiente al confirmar → error comprensible, carrito intacto.
- Agregar dos veces el mismo producto → suma cantidades, no crea un item duplicado.
- Producto eliminado o despublicado mientras está en el carrito (decidir y documentar; lo más
  simple es no permitir borrar productos y anotarlo como supuesto).

Fuera de alcance explícito: auth, roles, pagos, impuestos, envíos, integraciones, imágenes, panel
de admin, emails, deploy.

## Convenciones de código

- Rails idiomático y aburrido. Controllers delgados, modelos con validaciones, servicios para
  flujos con varios pasos.
- Nombres de dominio en inglés en el código (`SubOrder`, `supplier`); textos de UI en español.
- Validaciones tanto en el modelo como constraints en la base cuando importan (`NOT NULL`, FKs,
  `CHECK (quantity > 0)`).
- Nada de `rescue` genérico que se trague errores. Rescatar excepciones específicas.
- Sin comentarios que expliquen lo obvio. Comentar solo el *por qué* de una decisión no evidente.
- Migraciones con índices en las FKs.

## Comandos

```bash
bin/setup                      # instala dependencias y prepara la base
bin/rails db:prepare db:seed   # crea/migra y carga datos iniciales
bin/rails server               # levanta la app
bin/rails test                 # corre los tests
bin/rubocop                    # lint
```

Los seeds deben incluir, como mínimo: 1 tienda, 2 proveedores, 3 productos por proveedor, con
precios y stock distintos. `db:seed` tiene que ser idempotente.

## Flujo de trabajo

- **Commits pequeños y atómicos** que dejen ver la evolución de la solución: primero el modelo de
  datos, después el catálogo, el carrito, el checkout, los tests. Un commit por paso lógico, con
  mensaje descriptivo en imperativo.
- Correr `bin/rails test` antes de cada commit.
- Cuando una decisión tenga un tradeoff relevante, anotarla en el README apenas se toma, no al final.
- Si una tarea se está volviendo grande, cortarla y proponer el corte antes de escribir código.
- Registrar en `docs/ai-usage.md` a medida que se avanza: fecha, qué se pidió, qué se aceptó, qué se
  cambió y por qué.
- Si generás algo que no es trivialmente verificable (una query, una transacción, una validación con
  casos raros), decilo explícitamente para revisarlo en vez de darlo por bueno.
