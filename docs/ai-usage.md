# Registro de uso de IA

Qué se le pidió a Claude Code, qué se aceptó tal cual, qué se corrigió y por qué. Se escribe a
medida que se avanza, no al final.

## 2026-08-30

### Descartar `Order` como carrito en borrador

**Se pidió:** evaluar si `Cart` merece ser una tabla propia, o si alcanzaba con mostrar una `Order`
como carrito en la UI.

**Se aceptó:** el análisis y la recomendación de mantener `Cart`/`CartItem` separados. El argumento
que decidió fue que `OrderItem` congela el precio y el carrito necesita el precio vigente, así que
reusar el modelo obligaba a debilitar la constraint que sostiene la regla.

**Se cambió:** nada del análisis. Se decidió no dejar la nota en el README en ese momento. El
razonamiento terminó documentado igual al ponerse el README al día, porque es la decisión de diseño
menos obvia del proyecto.

### Generar la aplicación Rails

**Se pidió:** generar la app con un comando `rails new` propuesto por Claude, sin Hotwire.

**Se aceptó:** la estructura general del comando y el stack resultante, Rails 8.1 con PostgreSQL,
ERB y Minitest.

**Se cambió, y es la corrección más relevante del día:** el comando propuesto incluía `--skip-test`,
descrito como si saltara sólo los system tests. En realidad elimina el framework de test completo,
lo que habría dejado el proyecto sin `test/` pese a que las reglas de negocio deben ir con tests. Se
reemplazó por `--skip-system-test`.

**Se agregó sin haberlo consultado antes:** `--skip-docker`, `--skip-kamal`, `--skip-thruster`,
`--skip-solid` y `--skip-ci`. Son andamiaje de deploy, que está fuera de alcance, y Solid sumaba tres
esquemas extra con sus migraciones. Se informó el cambio al reportar el resultado.

**Contexto del entorno:** el Ruby del sistema era 2.6.10 y no había Rails instalado. Se fijó Ruby
3.4.9 con `rbenv local`, sin tocar la versión global ni las gemas de otros proyectos.

### Elegir el flujo de ramas

**Se pidió:** decidir si vale la pena una rama por paso, sabiendo que no habrá PRs.

**Se aceptó:** la recomendación de trabajar directo sobre `master`. Sin revisión, una rama por paso
sólo agrega merges y burbujas al historial, y va en contra de un historial que se lee en orden.

**Se cambió:** el primer commit se había hecho en una rama aparte, siguiendo
`docs/git-conventions.global.md`, que asume flujo de PR. Se colapsó con `merge --ff-only` para dejar
el historial lineal. De las convenciones se mantiene el formato de los mensajes de commit.

### Esquema y modelos del dominio

**Se pidió:** el modelo de datos en dos commits separados, primero las migraciones y después los
modelos con validaciones, incluyendo los subtotales calculados.

**Se aceptó:** las ocho migraciones con FKs indexadas y constraints, y los ocho modelos con sus
validaciones y totales.

**Se verificó en vez de darlo por bueno**, por ser código no trivialmente comprobable a simple vista:

- Los `CHECK` de la base rechazan cantidad cero, cantidad negativa, precio negativo y producto
  duplicado en el mismo carrito. Se probó con inserts directos contra PostgreSQL dentro de una
  transacción revertida.
- Las ocho migraciones revierten y se vuelven a aplicar sin errores.
- La validación de cantidad no entera efectivamente corta. La duda era que una columna `integer`
  castea `1.5` a `1` antes de validar. Rails valida contra el valor previo al type cast, así que
  tanto `1.5` como el texto `"1.5"` de un formulario se rechazan.

**Se agregó sin haberlo consultado antes:**

- Los tests de modelo en el mismo commit que las validaciones, en lugar de dejarlos para el paso de
  tests. Una validación sin test que la ejerza es una afirmación sin evidencia.
- Un índice único `(sub_order_id, product_id)` en `order_items`, que no estaba pedido. Un mismo
  producto dos veces en la misma suborden sería siempre un error de agrupación del checkout.
- `dependent: :restrict_with_error` en las asociaciones de `Supplier`, `Product` y `Store`, como
  traducción del supuesto de no permitir borrar productos.

**Decisión que quedó abierta:** `price_cents` admite cero, porque ninguna regla prohíbe un producto
gratis. Se constriñó sólo el precio negativo, que es claramente un bug.

### Seeds y catálogo

**Se pidió:** continuar con los seeds y el catálogo.

**Se aceptó:** seeds idempotentes (`find_or_create_by!`/`find_or_initialize_by` + `update!`) con 1
tienda, 2 proveedores y 3 productos por proveedor con precios y stock distintos. Catálogo de solo
lectura en `/`, agrupado por proveedor, usando `includes(:products)` para evitar N+1.

**Se agregó sin haberlo consultado antes:**

- `format_money` en `ApplicationHelper`, formateando con `divmod` entero en vez de dividir por
  100.0. Es la forma de mantener la regla "dinero en enteros, nunca floats" también en la capa de
  presentación, no sólo en el modelo.
- Tests del controller (proveedor con productos, y proveedor sin productos para no romper con
  colecciones vacías) y del helper de formateo, en el mismo commit que el código.

**Se verificó en vez de darlo por bueno:** que `db:seed` corrido dos veces seguidas no duplica
filas (mismo `Store.count`, `Supplier.count` y `Product.count` antes y después), y que la página
renderiza sin errores contra la base real (`bin/rails server` + `curl`).

### Carrito de compras

**Se pidió:** continuar con el carrito — agregar productos desde el catálogo, verlo, cambiar
cantidad y quitar items. Se acordó en plan mode antes de tocar código, dejando el checkout
explícitamente fuera de esta tarea.

**Se aceptó:** `current_store`/`current_cart` en `ApplicationController`, `CartsController#show`,
`CartItemsController` (`create`/`update`/`destroy`) con redirect clásico, y `Cart#add_product` para
sumar cantidad en vez de duplicar el item.

**Se verificó en vez de darlo por bueno, por no ser trivialmente comprobable a simple vista:**
`Cart#add_product` asigna la cantidad cruda al item, valida, y recién si `errors[:quantity]` queda
vacío arma la suma con el entero ya casteado. La duda era si sumar con `.to_i` a mano bastaba; no
alcanza, porque `"1.5".to_i` da `1` y colaría una cantidad inválida redondeada. Confirmado en
consola (`CartItem.new(quantity: "1.5").quantity` → `1`, pero `valid?` → `false`) y con tests que
cubren cantidad 0, negativa y no entera tanto en alta nueva como sumando sobre un item existente.

**Se encontró probando en el navegador (no en los tests), y se corrigió sin haberlo consultado
antes:** el mensaje de error al rechazar una cantidad inválida salía en inglés ("Quantity must be
an integer"), porque Rails usa `:en` por defecto y el proyecto nunca había tocado I18n — el resto de
la UI está en español porque los textos están escritos directo en las vistas, no vía `t()`. Se fijó
`config.i18n.default_locale = :es` y se agregó `config/locales/es.yml` con las traducciones que hoy
se disparan. Es una traducción acotada a lo que se muestra ahora, no una capa de I18n completa para
el resto del dominio.

### Completar mensajes de validación en español

**Se pidió:** traducir las validaciones de todos los modelos, sin dejar ningún mensaje en inglés.

**Se aceptó:** completar `config/locales/es.yml` con las claves que faltaban (`blank`,
`not_a_number`, `greater_than_or_equal_to`, `required` — esta última la usa Rails para el mensaje
"must exist" de todo `belongs_to` obligatorio) y con las traducciones de atributos de los 8 modelos
(`Nombre`, `Precio`, `Stock`, `Proveedor`, `Tienda`, `Cantidad`, etc.), para que el mensaje completo
lea natural en vez de mostrar el nombre de columna en inglés.

**Se verificó en vez de darlo por bueno:** se instanció cada modelo inválido por `rails runner`
(incluyendo precio/stock negativo y cantidad decimal) para confirmar que ya no aparece
"Translation missing" en ningún caso, y se corrió `bin/rails test` (45/45 verdes, sin tocar tests).

### Validación nativa del navegador bloqueaba el mensaje en español

**Se pidió:** corregir que al ingresar una cantidad decimal en el carrito aparezca un mensaje del
navegador en inglés ("Please enter a valid value...") en vez del mensaje en español.

**Se encontró y se corrigió:** el `<html>` no tenía `lang`, y los `number_field` de cantidad usaban
`step: 1` (o el default implícito de `<input type="number">`, que también es `1`). El navegador
bloqueaba el submit antes de llegar a Rails, así que la validación en español del modelo nunca se
ejecutaba. Se agregó `lang="es"` al layout y se cambió `step: 1`/`min: 1` por `step: "any"` en
`products/index.html.erb` y `carts/show.html.erb`, delegando la validación de cantidad al modelo
(que ya la tenía cubierta y en español) en vez de duplicarla en el navegador.

**Se verificó en vez de darlo por bueno:** con un script de Playwright contra el servidor real
(`bin/rails server`), llenando el campo cantidad con `1.5` y enviando el formulario, se confirmó que
ya no aparece el tooltip nativo y que la página muestra el flash "Cantidad debe ser un número
entero". Se corrió `bin/rails test` (45/45 verdes) antes de dar el cambio por bueno.

### Validar que la cantidad del carrito no supere el stock

**Se pidió:** agregar en `CartItem` una validación que rechace una cantidad mayor al stock del
producto.

**Se aceptó:** una segunda `validates :quantity, numericality: { less_than_or_equal_to: ... }`
usando un lambda (`->(item) { item.product&.stock }`) porque el tope depende de cada registro, no es
un número fijo, y `if: -> { product.present? }` para no duplicar el error "must exist" cuando falta
el producto. Se agregó la traducción específica en
`es.yml` (`activerecord.errors.models.cart_item.attributes.quantity.less_than_or_equal_to`) en vez
de una clave genérica, porque "menor o igual que" sin contexto no deja claro que el límite es el
stock.

**No se tocó** `Cart#add_product` ni el service de checkout: esta validación solo cubre el alta o
edición directa de un `CartItem` (p. ej. `CartItemsController#update`); sumar cantidades sobre un
item existente ya pasa por `item.valid?` en `add_product`, así que el chequeo aplica igual ahí sin
cambios adicionales. La validación de stock en el momento de confirmar la compra (regla ya definida
en el service de checkout) sigue siendo la que previene condiciones de carrera; esta es solo
feedback temprano en el carrito.

**Se verificó:** se agregaron dos tests (`rechaza una cantidad superior al stock del producto`,
`permite una cantidad igual al stock del producto`) y corrió `bin/rails test` (47/47 verdes) y
`bin/rubocop` (52 archivos, sin observaciones) antes de dar el cambio por bueno.

### Reservar stock al tocar el carrito, no al confirmar la compra

**Se pidió:** que agregar un `CartItem` (o aumentar su cantidad) descuente esa cantidad de
`product.stock`, y que reducirla o quitar el item la devuelva.

**Se marcó el conflicto antes de tocar código:** CLAUDE.md documentaba lo contrario como decisión
tomada ("se valida y descuenta al confirmar la compra, sin reservas") en la sección "no
re-litigar". Se preguntó explícitamente si avanzar igual, actualizando esa decisión, o mantenerla.

**Se aceptó:** avanzar con la reserva en el carrito y actualizar CLAUDE.md/README para reflejar el
cambio de decisión. También se confirmó que el único disparador de "devolver stock" es una acción
directa sobre `CartItem` (reducir cantidad o destruirlo) — cancelación de orden y limpieza de
carritos abandonados quedan fuera de alcance porque esos flujos no existen todavía.

**Se implementó:** toda la lógica en `app/models/cart_item.rb` vía `after_save`/`after_destroy`
(no en el controller ni en `Cart#add_product`), porque el disparador es el ciclo de vida de la fila
`CartItem` sin importar el punto de entrada, y así es imposible olvidarlo en un futuro flujo que
también guarde o destruya un item. El tope de la validación pasó de `product.stock` a
`available_stock` (`product.stock + quantity_in_database`), para que un item no se cuente a sí
mismo como excedente al editarse.

**Se verificó en vez de darlo por bueno**, por ser una transacción implícita con varios call
sites:

- Se trazó a mano que `Cart#add_product` sigue funcionando sin tocarlo: su paso intermedio
  (`item.quantity = delta; item.valid?`) no rompe el tope porque `available_stock` lee
  `quantity_in_database`, no `item.quantity` en memoria.
- Se ajustó `test/fixtures/products.yml` (`teclado.stock` de 10 a 8) para que quede consistente con
  las 2 unidades que el fixture `teclado_en_carrito` ya "reserva" sin pasar por callbacks, y se
  revisó que ningún test existente pidiera más de ese stock disponible dentro de un mismo flujo.
- Se agregaron tests de reserva/devolución en `cart_item_test.rb`, `cart_test.rb`,
  `cart_items_controller_test.rb` y uno en `product_test.rb` confirmando que actualizar el stock
  directo (fuera del carrito) sigue funcionando sin interferencia. `bin/rails test` (62/62 verdes)
  y `bin/rubocop` (52 archivos, sin observaciones) antes de dar el cambio por bueno.

### Checkout: confirmar el carrito y generar la orden

**Se pidió:** que al presionar "Confirmar" en el carrito se cree una `Order` con una `SubOrder`
por proveedor, y que se muestre el desglose de la orden final.

**Se aceptó:** `Orders::CreateOrder` (service object, como indica CLAUDE.md) agrupando
`cart_items` por `product.supplier`, con `raise`/transacción para atomicidad en vez de un objeto
`Result` — CLAUDE.md pide explícitamente `raise` para forzar el rollback, y un `Result` sería una
abstracción de más para un único call site. `OrdersController#create`/`#show` y la vista de
desglose reusando el helper `format_money` ya existente.

**Se verificó en vez de darlo por bueno**, por ser una transacción con varios call sites y un
punto de la regla de negocio fácil de romper sin darse cuenta:

- Que `cart.cart_items.delete_all` (en vez de `destroy_all`) efectivamente vacía el carrito sin
  disparar `CartItem#release_stock` — test que confirma `product.stock` sin cambios después de
  confirmar la compra, que es justo el escenario que un `destroy_all` rompería en silencio.
- El caso de fallo a mitad de checkout resultó más difícil de lo esperado: las `CHECK` constraints
  de la base hacen imposible construir un `CartItem` o `Product` inválido incluso bypasseando las
  validaciones de ActiveRecord (`update_column` con cantidad 0 falla contra el constraint antes de
  llegar al service). Se optó por parchear temporalmente `Product#price_cents` en el test para
  forzar un `RecordInvalid` real a mitad de la transacción, restaurando el método original en un
  `ensure`.

**Se agregó sin haberlo consultado antes:** los tests del botón "Confirmar" en
`carts_controller_test.rb` (aparece solo con carrito no vacío) y el test de 404 en
`orders_controller_test.rb` para una orden inexistente, cubriendo el scoping por `current_store`.

**Se corrió `bin/rails test` (73/73 verdes) y `bin/rubocop` antes de cada commit.**

### Persistir `total_cents`/`subtotal_cents` en vez de calcularlos

**Se pidió:** guardar en base el total de la `Order` y el subtotal de cada `SubOrder`, ante la duda
de si las órdenes históricas perdían esa información.

**Se aclaró antes de tocar código:** no la perdían — `Order#total_cents`/`SubOrder#subtotal_cents`
ya sumaban `OrderItem#unit_price_cents`, que queda congelado. El dato correcto siempre estuvo
disponible, solo que no vivía en una columna. El cambio revierte una decisión ya documentada en el
README ("totales calculados, no denormalizados"), así que se reescribió esa sección explicando el
motivo del cambio en vez de dejar el README contradiciendo el código.

**Se aceptó:** columnas `orders.total_cents` y `sub_orders.subtotal_cents` (mismo nombre que los
métodos que reemplazan, para no tocar vistas ni tests existentes), `NOT NULL` + `CHECK (>= 0)` igual
que el resto de columnas de dinero, y el cálculo movido a `Orders::CreateOrder`.

**Se corrigió sin haberlo consultado antes:** la primera versión del service calculaba el total
leyendo `cart_item.subtotal_cents` (precio en vivo del producto) antes de crear los `order_items`.
Rompía el test que fuerza `Product#price_cents` a devolver `nil` a mitad de checkout: la resta
`quantity * nil` explota con `TypeError` en vez del `ActiveRecord::RecordInvalid` esperado al
validar `unit_price_cents`. Se movió el cálculo a después de crear cada `order_item`, leyendo
`order_item.subtotal_cents` (precio ya congelado) y actualizando `SubOrder`/`Order` con `update!`
al final de cada grupo — más alineado además con la regla de nunca calcular totales desde
`product.price_cents`.

**Se verificó en vez de darlo por bueno:** la migración escribe con backfill explícito
(`add_column` nullable → recorrer filas existentes → `change_column_null` → `add_check_constraint`)
en vez de agregar la columna `NOT NULL` directo, para no asumir que las tablas están vacías en
cualquier entorno donde se corra. Se corrió `bin/rails db:migrate` contra la base de dev (vacía, sin
filas que backfillear) y `bin/rails test` (74/74 verdes) y `bin/rubocop` (7 archivos tocados, sin
observaciones) antes de dar el cambio por bueno.

### Agrupar el carrito por proveedor antes de confirmar la orden

**Se pidió:** extender `carts/show.html.erb` para mostrar una tabla y subtotales por cada
proveedor, agrupando los productos antes de generar la orden.

**Se aceptó:** agrupar `current_cart.cart_items` por `product.supplier` en
`CartsController#show` (mismo criterio que ya usa `Orders::CreateOrder` para armar las
subórdenes) y renderizar una tabla por proveedor con su subtotal, más el total general al final.
No se creó un service ni un helper nuevo: es una agrupación de solo lectura para la vista, sin
reglas de negocio propias.

**Se agregó sin haberlo consultado antes:** el test
`"agrupa los items por proveedor y muestra el subtotal de cada uno"` en
`carts_controller_test.rb`, porque el test existente usaba dos proveedores distintos pero solo
verificaba el total general, sin cubrir el agrupamiento ni los subtotales por proveedor.

**Se corrió `bin/rails test` (78/78 verdes) y `bin/rubocop` antes de commitear.**

### Listado de órdenes

**Se pidió:** una vista `index` para `Order`, accesible desde la nav bar, con la información
mínima ya persistida en la base.

**Se aceptó:** `OrdersController#index` con `current_store.orders.order(created_at: :desc)` y una
tabla con id, fecha y `total_cents` por orden, sin tocar subórdenes ni items — las tres columnas ya
viven directo en `orders`, así que no hace falta `includes` ni ningún join para evitar N+1. Link
"Órdenes" agregado a la nav bar del layout, al lado de Catálogo y Carrito.

**Se decidió sin haberlo consultado antes:** usar `strftime` en vez de `l(order.created_at, ...)`
para la fecha. El proyecto no tiene formatos de fecha/hora traducidos en `es.yml` ni el gem
`rails-i18n`, así que `l` hubiera dependido de un formato que no existe en el locale activo.

**Se corrió `bin/rails test` (79/79 verdes) antes de commitear.**

### Corrección de tres imprecisiones del README

**Se pidió:** revisar si la "Consecuencia" de la sección "El carrito es su propio modelo, no una
orden en borrador" refleja la implementación real de `Cart` y `CartItem`, y corregir el README.

**Se verificó contra el código antes de responder:** la afirmación central era correcta
(`CartItem#unit_price_cents` delega en `product.price_cents`, `OrderItem#unit_price_cents` es
columna congelada). Lo que no cerraba eran tres puntos alrededor.

**Se aceptó:**

1. "está comentada en ambos modelos" era más literal de lo que el código sostiene: en `CartItem` el
   comentario está sobre `unit_price_cents`, pero en `OrderItem` está sobre `subtotal_cents` (por
   qué no sumar leyendo `product.price_cents`). Se precisó dónde vive cada uno en vez de cambiar el
   código para que la frase fuera cierta.
2. La Consecuencia quedó incompleta después de la decisión de reservar stock al tocar el carrito:
   `CartItem` también tiene efectos sobre `product.stock` vía callbacks que `OrderItem` no tiene.
   Se sumó un párrafo, con remite a la sección que ya explica los callbacks en vez de repetirla.
3. El supuesto "el carrito siempre refleja el precio **y el stock** vigentes del catálogo, no un
   valor reservado" contradecía directamente al supuesto siguiente ("el stock se reserva al tocar el
   carrito"). Era un resto anterior a esa decisión: el cuerpo del supuesto solo justificaba el
   precio. Se acotó a precio, con remite explícito al supuesto del stock.

**No se tocó código.** Se corrió `bin/rails test` y `bin/rubocop` igual antes de commitear, por la
regla del repo.

### Columna `minimum_purchase_cents` en `suppliers` (2026-08-31)

**Se pidió:** crear una columna `minimo_compra` en la tabla `suppliers` y generar la migración.

**Se preguntó antes de escribir código,** porque tres cosas cambiaban materialmente el trabajo:

1. Si "mínimo de compra" era un monto o una cantidad de unidades. El usuario confirmó que es un
   **monto**, así que va como entero en centavos, coherente con `price_cents` / `total_cents` /
   `subtotal_cents`.
2. Si la columna debía aplicarse ya en el checkout o solo persistirse. El usuario eligió **solo la
   columna**, para no mezclar el cambio de esquema con un cambio de comportamiento en
   `Orders::CreateOrder`.
3. El nombre: CLAUDE.md pide nombres de dominio en inglés, y `minimo_compra` hubiera quedado como
   la única columna en español del esquema. El usuario aceptó **`minimum_purchase_cents`**.

**Se aceptó:** migración con `null: false, default: 0` (0 = "sin mínimo", evita backfill y evita un
`NULL` que haya que chequear en cada lectura) más `CHECK (minimum_purchase_cents >= 0)`, siguiendo
el patrón de `products_price_cents_non_negative`. Validación `numericality` en el modelo,
`test/models/supplier_test.rb` nuevo, fixtures con dos valores distintos y seeds con un mínimo
distinto por proveedor.

**Se cambió respecto de lo obvio:** `db/seeds.rb` usaba `Supplier.find_or_create_by!(name:)` a
secas. Con un atributo nuevo eso deja de ser idempotente en el sentido útil — una segunda corrida
no actualizaría el mínimo si cambia en el archivo. Se reestructuró `CATALOG` a
`nombre => { minimum_purchase_cents:, products: }` y se agregó un `update!` explícito, igual a lo
que ya se hacía con los productos.

**Verificación:** `bin/rails test` (84/84 verdes), `bin/rubocop` sin ofensas, `bin/rails db:seed`
corrido dos veces (5 proveedores / 15 productos, sin duplicados) y el `CHECK` probado con
`bin/rails runner` + `update_column(-1)`, que falla con `PG::CheckViolation` como corresponde.

**Pendiente anotado en el README:** la columna se persiste pero ningún flujo la aplica; hacer
cumplir el mínimo en el checkout quedó en "Próximos pasos".
