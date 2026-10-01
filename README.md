# Taller Bintec 2026 — Flujo bancario multiagente con n8n

Entorno para el taller: **n8n vacío** y tres servicios de negocio simulados (Risk, Fraud y CRM).
El flujo lo construyes tú siguiendo la guía; para el modelo solo tienes que indicar **la URL y la
llave** en un archivo.

```
Cliente ──POST──▶ n8n webhook /solicitud-bancaria
                    ├─▶ risk-api   (score crediticio)
                    ├─▶ fraud-api  (IP, canal, monto)
                    └─▶ crm-api    (perfil del cliente)
                  Merge ─▶ Modelo (LLM) ─▶ Auditoría ─▶ Guardrail ─┬─▶ Respuesta
                                                                   └─▶ Revisión humana ─▶ Respuesta
```

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker Engine con Compose v2), en ejecución.
- Git.
- La URL y la llave del modelo: las del taller (te llegan por correo) o tu propia API key de Gemini.

## 1. Puesta en marcha

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

## 2. Construye el flujo

Sigue `docs/Taller_Bintec_Guia_Completa.pdf` (sección 7, 15 nodos) con estos ajustes:

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

Mientras lo construyes: pulsa *Execute workflow* en el editor (queda escuchando una solicitud) y envía:

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
├── docs/Taller_Bintec_Guia_Completa.pdf   # guía para construir el flujo nodo por nodo
├── mock_services/              # Risk, Fraud y CRM (FastAPI)
├── requests/                   # solicitudes de ejemplo
├── scripts/test-flow.{sh,ps1}  # envía las solicitudes al webhook
└── solucion/                   # flujo terminado, para importar al final
```

## Notas

- Tu llave vive solo en `.env`, que no se sube a Git. No la compartas ni la pegues en capturas.
- Esta configuración es para uso local durante el taller: usuario, contraseña y clave de cifrado
  son públicos, y los nodos pueden leer las variables de entorno del contenedor. No la expongas a internet.
