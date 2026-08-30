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
