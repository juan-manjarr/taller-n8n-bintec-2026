# snippets/

Texto plano para copiar al armar el flujo en n8n.
Todo sale literalmente de `solucion/flujo-bancario-multiagente.json` (el flujo verificado), sin retocar.
La guía paso a paso (`docs/GUIA-PASO-A-PASO.pdf`) y el video (`docs/VIDEO-PASO-A-PASO.mp4`) indican
en cada nodo qué archivo de esta carpeta usar.

## Por que existe esta carpeta

Copiar codigo desde un PDF o una diapositiva falla silenciosamente: parte textos en varias
lineas, pierde la indentacion, cambia "fi"/"fl" por ligaduras de un solo caracter, y puede
colar caracteres invisibles (U+200B). n8n no avisa de nada de eso: solo responde con
"Field required", "resource not found" o "Invalid or unexpected token".
Los archivos de esta carpeta no tienen nada de eso — son bytes exactos del flujo verificado.

## Reglas

1. **Lo largo se copia del archivo. Lo corto se escribe a mano.**
   Nombres, URLs cortas y valores de una linea van como tabla en este README para escribirlos.
   Bodies, codigo y el prompt de Gemini se copian del archivo.
2. **Copia desde VS Code** (abre el archivo, Ctrl+A, Ctrl+C) o con el boton "Raw" de GitHub.
   No copies desde el PDF ni desde esta ventana del navegador.
3. **Los `.txt` que empiezan con `{{` van en modo Expression.**
   Antes de pegar, pulsa el boton **Expression** en el campo de n8n.
   Al pegar debe aparecer una vista previa del valor evaluado; si no aparece, el campo
   sigue en Fixed y n8n lo trata como texto literal.
4. **Una linea larguisima no es un error.**
   Los `.txt` son UNA sola linea. El body de Gemini tiene 1389 chars en una linea.
   Copia el archivo completo (Ctrl+A, Ctrl+C): no trae nada mas que el valor del campo.
   No la partas y no agregues salto de linea al final.
5. **Dos nombres de nodo son obligatorios**, porque otros nodos los citan por nombre:
   - `Combinar respuestas`  (Nodo 07)
   - `Gemini Agent`  (Nodo 08)
   Los demas nombres son sugerencias. Si renombras uno de esos dos, actualiza tambien
   el codigo que lo cita: `$('Combinar respuestas')` en los Nodos 10 y 11,
   `$('Gemini Agent')` en el Nodo 10.

---

## Indice: que archivo va en que campo

| Nodo | Archivo | Se pega en | Modo |
|------|---------|-----------|------|
| 02 Set             | `02-preparar-payload.node.json` | pegar el nodo entero en el lienzo | JSON de nodo |
| 03 HTTP Risk API   | `03-risk-body.txt`          | JSON Body                  | Expression |
| 04 HTTP Fraud API  | `04-fraud-body.txt`         | JSON Body                  | Expression |
| 05 HTTP CRM API    | `05-crm-body.txt`           | JSON Body                  | Expression |
| 07 Code            | `07-combinar-respuestas.js` | campo JavaScript            | Code       |
| 08 HTTP Gemini     | `08-gemini-url.txt`         | URL                        | Expression |
| 08 HTTP Gemini     | `08-gemini-body.txt`        | JSON Body                  | Expression |
| 09 Code            | `09-parsear-respuesta.js`   | campo JavaScript            | Code       |
| 10 Code            | `10-auditoria.js`           | campo JavaScript            | Code       |
| 11 Code            | `11-guardrail.js`           | campo JavaScript            | Code       |
| 12 If              | `12-if-body.txt`            | value1 de la condicion     | Expression |
| 13 Set             | `13-mensaje-revision.txt`   | valor del campo `customer_message` | Fixed |
| 15 Respond to Webhook | `14-respond-webhook.txt` | Response Body              | Expression |

En los `.js`, VS Code puede subrayar `$json`, `$workflow` o `return` en rojo.
Es normal: son variables que solo existen dentro de n8n.

---

## Paso previo: archivo .env

El flujo lee tres variables de entorno. Antes de levantar los contenedores:

```
cp .env.example .env
```

Abre `.env` y completa:

| Variable | Valor | Ejemplo |
|----------|-------|---------|
| `LLM_API_KEY`  | La llave del taller (del correo) o tu API key de Gemini | `sk-bintec-...` o `AIzaSy...` |
| `LLM_BASE_URL` | La URL del correo, o la de la API de Google — **sin `/` al final** | `https://generativelanguage.googleapis.com` |
| `LLM_MODEL`    | Modelo a usar | `gemini-3.5-flash-lite` |

**Ojo con LLM_BASE_URL:** la expresion del Nodo 08 agrega `/v1beta/models/...` por su cuenta.
Si pones `https://generativelanguage.googleapis.com/v1beta` (con el path incluido), la URL
final quedara duplicada y Gemini respondera 404.
Valor correcto: `https://generativelanguage.googleapis.com`

---

## Nodo a nodo: valores exactos para configurar

### 01 Webhook — nombre sugerido: `Webhook`

| Campo              | Valor                                    |
|--------------------|------------------------------------------|
| HTTP Method        | `POST`                                   |
| Path               | `solicitud-bancaria`                     |
| Respond            | `Immediately` mientras construyes; `Using 'Respond to Webhook' Node` al agregar el Nodo 15 |
| Authentication     | None                                     |

Si eliges `Using 'Respond to Webhook' Node` antes de que exista el Nodo 15, la prueba del
Webhook falla con *"No Respond to Webhook node found in the workflow"*.

---

### 02 Set (Edit Fields) — nombre: `Preparar payload`

Pega el nodo completo directamente en el lienzo desde `02-preparar-payload.node.json`:

1. Abre `02-preparar-payload.node.json` en VS Code
2. Ctrl+A → Ctrl+C
3. Haz clic sobre el lienzo de n8n (que no haya ningun nodo seleccionado)
4. Ctrl+V — el nodo aparece listo con los 7 campos ya configurados

El nodo ya trae el nombre `Preparar payload`, los 7 campos con su tipo correcto
(`requested_amount` y `term_months` como Number, el resto como String) y todas
las expresiones apuntando a `$json.body.*`. No hay que configurar nada adicional.

---

### 03 HTTP Request (Risk API) — nombre sugerido: `HTTP Request - Risk API`

| Campo               | Valor                      |
|---------------------|----------------------------|
| Method              | `POST`                     |
| URL                 | `http://risk-api:8000/score` |
| Authentication      | None                       |
| Send Body           | ON                         |
| Body Content Type   | `JSON`                     |
| Specify Body        | `Using JSON`               |
| JSON (Expression)   | copia `03-risk-body.txt`   |

---

### 04 HTTP Request (Fraud API) — nombre sugerido: `HTTP Request - Fraud API`

| Campo               | Valor                       |
|---------------------|-----------------------------|
| Method              | `POST`                      |
| URL                 | `http://fraud-api:8000/check` |
| Authentication      | None                        |
| Send Body           | ON                          |
| Body Content Type   | `JSON`                      |
| Specify Body        | `Using JSON`                |
| JSON (Expression)   | copia `04-fraud-body.txt`   |

---

### 05 HTTP Request (CRM API) — nombre sugerido: `HTTP Request - CRM API`

| Campo               | Valor                          |
|---------------------|--------------------------------|
| Method              | `POST`                         |
| URL                 | `http://crm-api:8000/profile`  |
| Authentication      | None                           |
| Send Body           | ON                             |
| Body Content Type   | `JSON`                         |
| Specify Body        | `Using JSON`                   |
| JSON (Expression)   | copia `05-crm-body.txt`        |

**Importante:** desde dentro de n8n (que corre en Docker) los servicios se llaman por
nombre de servicio (`risk-api`, `fraud-api`, `crm-api`), no por `localhost`.
`localhost:8001` solo funciona desde tu propia terminal.

---

### 06 Merge — nombre sugerido: `Merge`

| Campo          | Valor      |
|----------------|------------|
| Mode           | `Combine`  |
| Combine By     | `Position` |
| Number of Inputs | `3`      |

Por defecto trae 2 entradas. Cambialo a 3 primero; entonces aparece la tercera entrada
en el lienzo. Conecta en este orden:
- Risk API  → entrada 1  (index 0)
- Fraud API → entrada 2  (index 1)
- CRM API   → entrada 3  (index 2)

---

### 07 Code — nombre: `Combinar respuestas` **(OBLIGATORIO)**

Borra el codigo de ejemplo y pega el contenido de `07-combinar-respuestas.js`.

---

### 08 HTTP Request (Gemini) — nombre: `Gemini Agent` **(OBLIGATORIO)**

| Campo               | Valor                                |
|---------------------|--------------------------------------|
| Method              | `POST`                               |
| URL (Expression)    | copia `08-gemini-url.txt`            |
| Authentication      | None (la key va como header)         |
| Send Headers        | ON                                   |
| Specify Headers     | `Using Fields Below`                 |
| Header — Name       | `x-goog-api-key`  (escribe a mano)  |
| Header — Value (Expression) | `{{ $env.LLM_API_KEY.trim() }}` (escribe a mano) |
| Send Body           | ON                                   |
| Body Content Type   | `JSON`                               |
| Specify Body        | `Using JSON`                         |
| JSON (Expression)   | copia `08-gemini-body.txt`           |

**Pestaña Settings del nodo 08** (pestana Settings, no Parameters):

| Campo            | Valor |
|------------------|-------|
| Retry On Fail    | activado |
| Max Tries        | `3`   |
| Wait Between Tries | `2000` ms |

Si no configuras el retry, un 503 de Gemini (alta demanda) corta el flujo.
Con el retry el nodo lo intenta 3 veces esperando 2 segundos entre intentos.

---

### 09 Code — nombre sugerido: `Parsear respuesta del agente`

Pega el contenido de `09-parsear-respuesta.js`.

---

### 10 Code — nombre sugerido: `Registro de auditoria`

Pega el contenido de `10-auditoria.js`.

---

### 11 Code — nombre sugerido: `Calcular guardrail`

Pega el contenido de `11-guardrail.js`.

---

### 12 If — nombre sugerido: `Guardrail: necesita revision humana?`

| Campo        | Valor |
|--------------|-------|
| Value 1 (Expression) | `{{ $json.needs_human_review }}` (o copia `12-if-body.txt`) |
| Operator     | Boolean → `is true` |
| Combinator   | `AND` (solo hay una condicion, da igual) |

La rama **TRUE** (salida 0) va al Nodo 13.
La rama **FALSE** (salida 1) va directo al Nodo 15 (Respond to Webhook).

---

### 13 Set (Edit Fields) — nombre sugerido: `Marcar para revision humana`

Mode: **Manual Mapping**

| Name               | Type    | Value                                       |
|--------------------|---------|---------------------------------------------|
| `human_review`     | Boolean | `true`                                      |
| `decision`         | String  | `PENDIENTE_REVISION_HUMANA`                 |
| `customer_message` | String  | copia `13-mensaje-revision.txt` (modo Fixed)|

---

### 14 No Operation, do nothing — nombre sugerido: `Notificar equipo de riesgo`

Sin parametros. Es un placeholder — reemplazalo por un nodo de Slack o Gmail
cuando tengas listo ese canal.

---

### 15 Respond to Webhook — nombre sugerido: `Respond to Webhook`

| Campo           | Valor                    |
|-----------------|--------------------------|
| Respond With    | `JSON`                   |
| Response Body (Expression) | `{{ $json }}` (o copia `14-respond-webhook.txt`) |

---

## Conexiones

Conecta los nodos en este orden despues de crearlos todos:

```
01 -> 02
02 -> 03  (paralela)
02 -> 04  (paralela)
02 -> 05  (paralela)
03 -> 06  (entrada 1 del Merge)
04 -> 06  (entrada 2 del Merge)
05 -> 06  (entrada 3 del Merge)
06 -> 07
07 -> 08
08 -> 09
09 -> 10
10 -> 11
11 -> 12
12 -> 13  (salida TRUE)
12 -> 15  (salida FALSE)
13 -> 14
14 -> 15
```

---

## Comprobaciones rapidas

1. **Vista previa en Expression:** en cada campo Expression debe verse el resultado
   evaluado debajo del campo. Si ves `undefined` o el texto `{{ ... }}` sin evaluar,
   algo quedo mal escrito o el campo sigue en Fixed.

2. **Merge con 3 entradas:** antes de conectar, abre el nodo Merge y confirma que
   `Number of Inputs` diga 3. Si dice 2, cambialo primero — hasta que no este en 3
   no aparece la tercera entrada en el lienzo.

3. **Nombres obligatorios:** abre los Nodos 07 y 08 y confirma que el titulo diga
   exactamente `Combinar respuestas` y `Gemini Agent`.

4. **Caracteres invisibles:** exporta el flujo (menu de tres puntos → Download),
   abrelo en VS Code, pulsa Ctrl+F, activa regex (Alt+R o el icono `.*`) y busca:
   ```
   [\u200B-\u200D\uFEFF]
   ```
   Debe decir "No results". Si encuentra algo, el campo que lo tiene va a fallar
   en ejecucion aunque visualmente se vea bien.

5. **Variables de entorno:** antes de ejecutar, confirma que `.env` tiene las tres
   variables (`LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL`) y que levantaste los
   contenedores despues de editar el archivo (`docker compose down && docker compose up -d`).
