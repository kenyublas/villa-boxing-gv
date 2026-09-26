# Villa Boxing GV — Actualización v2 / v3

## v3 — Dashboard rediseñado + keep-alive de Supabase

### Activar el keep-alive (una sola vez)
1. Supabase > SQL Editor: corre `supabase/keepalive.sql`. La última consulta debe devolver `{"ok": true}`.
2. Haz commit y push de `.github/workflows/supabase-keepalive.yml`.
3. En GitHub > repo > **Actions** > "Supabase keep-alive" > **Run workflow** para probarlo. Debe salir en verde con `HTTP 200`.
4. Desde ese momento hace ping todos los días a las 8:17 a.m. Si falla, GitHub te manda un correo.

Notas:
- En repos sin commits por 60 días, GitHub desactiva los crons y te avisa por correo. Se reactiva con un clic en Actions.
- La solución definitiva es el plan Pro de Supabase (el proyecto nunca se pausa) o migrarlo a tu VPS.

### Dashboard v3
- Tres pestañas (Alumnos · Pagos · Resumen). En celular pasan a una barra inferior con botón flotante "+".
- En celular, tarjetas por alumno en lugar de la tabla de 10 columnas.
- Íconos SVG en lugar de emojis, y los mismos colores de estado en todo el Dashboard.
- Los KPIs y los chips de estado filtran la lista con un toque.
- "Requieren atención" viene plegado: muestra un resumen y se abre para ver el detalle.
- Carga con skeleton, toasts abajo que no tapan contenido y modales como hoja inferior en celular.
- Confirmaciones propias (sin `confirm()` del navegador), incluido el aviso de DNI repetido.
- Resumen: distribución por turno, modalidad, género y edad, más el ranking de fidelidad.


## Pasos para activarlo (en este orden)

1. **Supabase > SQL Editor**: pega y corre `supabase/setup.sql` completo.
   - Activa RLS en `alumnos`, crea `admins` y `pagos` y migra un pago por cada alumno existente.
   - Asume que `alumnos.id` es `uuid` y `fecha_vence`/`fecha_inicio` son `date`. Si alguna es `text`/`int`, avisa antes de correrlo.
2. **Supabase > Authentication > Users > Add user**: crea el correo y la contraseña del admin (marca *Auto Confirm User*).
3. En el SQL Editor corre el bloque **5)** del script (descoméntalo y pon el correo) para registrarlo en `admins`.
4. **Authentication > Sign In / Providers**: desactiva *Allow new users to sign up*.
5. En `index.html` revisa `DIRECCION_MAPA` (se agregó "Huánuco" por defecto; corrígelo si no es la ciudad).
6. Borra de la carpeta los archivos viejos (ya no se usan):
   - todos los `.png` / `.jpg` de la raíz (ahora viven en `img/` como WebP)
   - `PC2_CSSCascada.docx` (quedaba público en el sitio)
7. `git add -A && git commit -m "v2: auth real, pagos, WebP, fixes" && git push`

> Hasta hacer el paso 3 nadie podrá entrar al Dashboard (es lo esperado).

## Qué cambió

### Seguridad
- Login con **Supabase Auth** (correo y contraseña). Se eliminó `villaboxing / admin2026` del código.
- El Dashboard verifica la sesión y que el usuario esté en `admins`; si no, redirige.
- RLS: sin sesión de admin, la anon key ya no puede leer, editar ni borrar alumnos ni pagos.
- Escape de HTML en todos los datos (antes se podía inyectar HTML por el nombre del alumno).
- `noindex` en el Dashboard.

### Dashboard
- **Tabla `pagos`**: "Ingresos del mes" suma pagos reales (inscripciones, matrículas y renovaciones). Antes las renovaciones no sumaban.
- Sección **Pagos registrados** por mes: totales por concepto y por método (Efectivo, Yape, Plin, Transferencia) y opción de anular un pago.
- **Renovar** abre un modal con monto, método y fecha. Si el alumno está vencido, el nuevo periodo arranca desde hoy.
- Nuevo alumno: método de pago y matrícula S/ 50 opcional (se registran como pagos).
- **Recordatorios**: botón 📲 Recordar en la alerta. Marca "✓ recordatorio enviado" y se resetea al renovar.
- Bienvenida por WhatsApp con confirmación, para que el navegador no bloquee el pop-up.
- Editar ya no pisa el vencimiento de alumnos renovados (el vencimiento es editable).
- Fechas en hora de Perú: antes, después de las 7pm la fecha por defecto era la de mañana.
- La barra de progreso muestra el periodo actual, no el tiempo desde la inscripción.
- Validación de celular (9 dígitos) y DNI (8 dígitos), aviso de DNI duplicado y búsqueda por DNI.
- El Excel incluye una hoja de **Pagos** del mes seleccionado.

### Landing
- Imágenes en WebP con miniaturas para la galería: **~71 MB → ~11 MB**. Se eliminó `vendas.png` de 14 MB.
- La tienda se genera desde el array `PRODUCTOS`: precios y productos se editan en un solo lugar.
- Links de WhatsApp rotos arreglados ("Empieza tu historia" y "Solicitar día de prueba").
- El video ya no activa el sonido con cualquier clic: tiene un botón 🔇/🔊, se reproduce en bucle y se pausa fuera de pantalla.
- Se quitó la imagen rota (`equipo13.jpg`) y los placeholders ("Categoría · Año del logro", `alt="Nombre Apellido"`).
- "Precios" en el menú, **mapa de Google**, favicon, `og:image` para compartir por WhatsApp y schema de negocio local para Google.
- Swipe en el lightbox, pausa del carrusel con hover y accesibilidad (aria-labels, foco visible, reduced-motion).
- Hero en móvil corregido.

## Dónde editar
| Qué | Dónde |
|---|---|
| Productos y precios de la tienda | `index.html` → `const PRODUCTOS` |
| Fotos de la galería | `index.html` → `const GALERIA` (archivo en `img/` + miniatura en `img/thumbs/`) |
| Dirección del mapa | `index.html` → `DIRECCION_MAPA` |
| WhatsApp, grupo, días de membresía, matrícula | `js/config.js` |
