# Taller Bintec 2026 — Flujo bancario multiagente con n8n

Entorno para el taller: **n8n vacío** y tres servicios de negocio simulados (Risk, Fraud y CRM).
El flujo lo construyes tú siguiendo la guía; para el modelo solo tienes que indicar **la URL y la
llave** en un archivo.

**Guías** (en `docs/`):
- [`GUIA-PASO-A-PASO.pdf`](docs/GUIA-PASO-A-PASO.pdf) ([versión web](docs/GUIA-PASO-A-PASO.md)):
  el flujo clic a clic, con capturas, para quien usa n8n por primera vez. Ya está adaptada a este
  repositorio.
- [`VIDEO-PASO-A-PASO.mp4`](docs/VIDEO-PASO-A-PASO.mp4) (10:46, sin audio, con subtítulos): el flujo
  construido en n8n de principio a fin, ejecutado y publicado. Capítulos: 0:00 Webhook · 1:05 Preparar
  payload · 1:59 Risk, Fraud y CRM · 3:50 Merge y Combinar respuestas · 4:40 Gemini Agent ·
  5:46 Parsear, auditoría y guardrail · 7:03 If, revisión humana y respuesta · 9:08 Probar y publicar.
- [`snippets/`](snippets/): el código, los bodies JSON y el prompt de cada nodo en texto plano,
  listos para copiar sin errores (la guía y el video indican qué archivo va en cada nodo).
- [`Taller_Bintec_Guia_Completa.pdf`](docs/Taller_Bintec_Guia_Completa.pdf): la guía original del
  taller, con los ajustes de la sección 2 de este README.

Puedes trabajar **con Docker en tu equipo** (sección 1A) o, si no puedes instalarlo, **en GitHub
Codespaces** desde el navegador (sección 1B).

```
Cliente ──POST──▶ n8n webhook /solicitud-bancaria
                    ├─▶ risk-api   (score crediticio)
                    ├─▶ fraud-api  (IP, canal, monto)
                    └─▶ crm-api    (perfil del cliente)
                  Merge ─▶ Modelo (LLM) ─▶ Auditoría ─▶ Guardrail ─┬─▶ Respuesta
                                                                   └─▶ Revisión humana ─▶ Respuesta
```

## Requisitos

- La URL y la llave del modelo: las del taller (te llegan por correo) o tu propia API key de Gemini.
- **Con Docker (1A):** [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker
  Engine con Compose v2) en ejecución, y Git.
- **Sin Docker (1B):** una cuenta de GitHub y un navegador.

## 1A. Puesta en marcha con Docker

**Clona el repositorio**

```bash
git clone https://github.com/juan-manjarr/taller-n8n-bintec-2026.git
cd taller-n8n-bintec-2026
```

**Crea tu archivo `.env`**

```bash
cp .env.example .env            # PowerShell: Copy-Item .env.example .env
```

Ábrelo y completa las dos líneas:

```
LLM_BASE_URL=<la URL que recibiste>
LLM_API_KEY=<tu llave>
```

| | `LLM_BASE_URL` | `LLM_API_KEY` |
|---|---|---|
| Llave del taller | la URL que viene con tu llave | `sk-bintec-…` |
| Tu propia llave de Gemini | `https://generativelanguage.googleapis.com` | tu API key de [Google AI Studio](https://aistudio.google.com/api-keys) |

**Levanta el entorno**

```bash
docker compose up -d
```

La primera vez descarga las imágenes y tarda uno o dos minutos. Está listo cuando
`docker compose ps` muestra `n8n` como `healthy`.

**Abre n8n**

http://localhost:5678 — usuario `admin@bintec.local`, contraseña `Bintec2026!`

## 1B. Puesta en marcha sin Docker: GitHub Codespaces

El repositorio incluye una configuración de Codespaces (`.devcontainer/`): GitHub crea una máquina
en la nube con este mismo entorno (el mismo `docker-compose.yml`) y la usas desde el navegador.

1. En esta página: **Code → Codespaces → Create codespace on main**.
2. Se abre VS Code en el navegador. La primera vez tarda 3–5 minutos (descarga las imágenes); al
   terminar, la terminal muestra *"Imágenes descargadas. Falta un paso"*.
3. En el explorador de archivos abre **`.env`** (ya viene creado), completa `LLM_BASE_URL` y
   `LLM_API_KEY` como en la tabla de 1A y guarda (`Ctrl+S`).
4. En la terminal del codespace ejecuta:

   ```bash
   docker compose up -d
   ```

5. Abre la pestaña **PORTS**, fila **n8n (5678)**, ícono del globo: n8n se abre en
   `https://<tu-codespace>-5678.app.github.dev`. Usuario `admin@bintec.local`, contraseña `Bintec2026!`.

En Codespaces:
- En el codespace, `docker compose` agrega solo un nginx delante de n8n (`n8n-proxy`): corrige los
  encabezados del reenvío de puertos de GitHub para que el editor no pierda la conexión en vivo
  (*Connection lost*). Usa siempre `docker compose up -d` sin `-f`, para que se aplique.
- Los comandos de este README van en la **terminal del codespace** y son los de **bash**
  (`./scripts/test-flow.sh`). Las URLs de webhook que muestra n8n (`http://localhost:5678/...`)
  funcionan desde esa terminal.
- **Deja el puerto 5678 en *Private*** (es lo predeterminado). Si lo haces público, cualquiera con la
  URL podría entrar con la contraseña del taller.
- El codespace se suspende tras 30 minutos sin uso; al reabrirlo desde https://github.com/codespaces
  los servicios se levantan solos y tu flujo se conserva.
- Las cuentas personales de GitHub incluyen horas gratuitas de Codespaces al mes. Al terminar el
  taller, elimina el codespace en https://github.com/codespaces.

## 2. Construye el flujo

La forma más fácil es seguir [`docs/GUIA-PASO-A-PASO.pdf`](docs/GUIA-PASO-A-PASO.pdf), que ya
incluye todo lo de esta sección. Si sigues la guía original
[`docs/Taller_Bintec_Guia_Completa.pdf`](docs/Taller_Bintec_Guia_Completa.pdf) (sección 7, 15 nodos),
aplica estos ajustes:

**Servicios de negocio.** Desde n8n se llaman por su nombre de red:
`http://risk-api:8000/score`, `http://fraud-api:8000/check` y `http://crm-api:8000/profile`.
Su documentación interactiva está en http://localhost:8001/docs, http://localhost:8002/docs y
http://localhost:8003/docs.

**Pasos 5 y 6 de la guía (API key y credencial): no hacen falta.** La URL y la llave ya están en tu
`.env` y el flujo las lee de ahí.

**Paso 8 — nodo HTTP Request del agente.** Configúralo así:

| Campo | Valor |
|---|---|
| Method | `POST` |
| URL (modo *Expression*) | `{{ $env.LLM_BASE_URL }}/v1beta/models/{{ $env.LLM_MODEL }}:generateContent` |
| Authentication | `None` |
| Send Headers | activado — Name: `x-goog-api-key`, Value (modo *Expression*): `{{ $env.LLM_API_KEY }}` |
| Body | JSON, tal como aparece en la guía |

El resto de la guía (parseo de la respuesta, auditoría, guardrail, revisión humana) se aplica igual:
la respuesta del modelo llega en `candidates[0].content.parts[0].text` con cualquiera de las dos llaves.

## 3. Prueba el flujo

Mientras lo construyes: pulsa *Execute workflow* en el editor (queda escuchando una solicitud) y envía
(en Codespaces, desde la terminal del codespace con el comando de bash):

```bash
WEBHOOK_PATH=webhook-test ./scripts/test-flow.sh requests/01-cliente-preferencial.json
# PowerShell: .\scripts\test-flow.ps1 -Test -Files requests\01-cliente-preferencial.json
```

Con el flujo publicado (*Publish*):

```bash
./scripts/test-flow.sh          # PowerShell: .\scripts\test-flow.ps1
```

| Solicitud | Resultado esperado |
|---|---|
| `01-cliente-preferencial.json` | Aprobación |
| `02-fraude-alto.json` | `PENDIENTE_REVISION_HUMANA` (el guardrail fuerza revisión humana) |
| `03-cliente-nuevo.json` | Decisión del modelo para un cliente sin historial |

Cada ejecución queda en la pestaña *Executions* del flujo, con el detalle nodo por nodo.

## 4. La solución (para el final)

Si te atascas o quieres comparar, el flujo terminado está en `solucion/flujo-bancario-multiagente.json`:

1. En n8n: *Create workflow* → menú **⋯** (arriba a la derecha) → **Import from file…**
2. Elige `solucion/flujo-bancario-multiagente.json`.
3. Pulsa **Publish**. Si ya tienes publicado tu propio flujo con el mismo webhook, despublícalo
   primero: dos flujos no pueden usar la misma ruta a la vez.

No requiere credenciales: usa la URL y la llave de tu `.env`.

## Si algo falla

| Síntoma | Causa y solución |
|---|---|
| `Falta LLM_BASE_URL en el archivo .env` al hacer `up` | No creaste `.env` o dejaste la línea vacía. |
| `access to env vars denied` en un nodo | Estás usando otro n8n, no el de este repositorio. Usa http://localhost:5678 tras `docker compose up -d`. |
| El nodo del agente falla con **401** | Llave mal copiada, vencida o revocada. Corrige `LLM_API_KEY` y ejecuta `docker compose up -d`. |
| El nodo falla con **429** | Superaste el límite de peticiones por minuto o el presupuesto de tu llave. Espera un minuto y reintenta. |
| El nodo falla con **404** | URL incorrecta. `LLM_BASE_URL` debe ser solo el dominio, sin `/` al final ni rutas adicionales. |
| La respuesta dice *"Solicitud bloqueada…"* | La llave del taller solo admite peticiones del flujo bancario; el contenido fuera de ese tema se bloquea. |
| `The requested webhook … is not registered` | El flujo no está publicado, o usaste la URL de producción mientras probabas (usa `webhook-test`). |
| `port is already allocated` | El puerto 5678 está ocupado: define `N8N_PORT=5679` en `.env` y usa ese puerto en el navegador (y `BASE_URL=http://localhost:5679` con los scripts). |
| Cambié `.env` y no pasa nada | Ejecuta de nuevo `docker compose up -d` para que n8n tome los valores. |
| Codespaces: n8n no aparece en PORTS | Aún no ejecutaste `docker compose up -d` (paso 4 de 1B), o falló porque `.env` está incompleto. |
| Codespaces: el editor de n8n dice *Connection lost* todo el tiempo | El codespace se creó antes de la corrección de `.devcontainer/` (nginx delante de n8n). Actualiza el repositorio (`git pull`) y ejecuta *Rebuild Container* (F1 → `Codespaces: Rebuild Container`), o crea un codespace nuevo. Comprueba con `docker compose ps` que aparece el servicio `n8n-proxy`. |
| Codespaces: *Connection lost* aparece un segundo y desaparece | El reenvío de puertos de GitHub puede cerrar la conexión en vivo cada cierto tiempo; n8n reconecta solo y no se pierde nada. |

Logs: `docker compose logs -f n8n`

## Detener

```bash
docker compose down             # detiene; conserva tu flujo
docker compose down -v          # detiene y borra todo (n8n vuelve a quedar vacío)
```

## Qué hay en el repositorio

```
.
├── docker-compose.yml          # n8n (vacío) + 3 servicios simulados
├── .env.example                # plantilla de configuración (cópiala a .env)
├── .devcontainer/              # configuración de GitHub Codespaces (sección 1B)
├── docs/
│   ├── GUIA-PASO-A-PASO.pdf    # guía clic a clic con capturas (y .md + img/ para verla en GitHub)
│   ├── VIDEO-PASO-A-PASO.mp4   # el mismo proceso en video (10:46)
│   └── Taller_Bintec_Guia_Completa.pdf   # guía original del taller
├── mock_services/              # Risk, Fraud y CRM (FastAPI)
├── requests/                   # solicitudes de ejemplo
├── scripts/test-flow.{sh,ps1}  # envía las solicitudes al webhook
├── snippets/                   # valores de cada nodo en texto plano, para copiar
└── solucion/                   # flujo terminado, para importar al final
```

## Notas

- Tu llave vive solo en `.env`, que no se sube a Git. No la compartas ni la pegues en capturas.
- Esta configuración es para uso local durante el taller: usuario, contraseña y clave de cifrado
  son públicos, y los nodos pueden leer las variables de entorno del contenedor. No la expongas a internet.
