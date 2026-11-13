# vidasalud-deploy

Despliegue completo de VidaSalud con Docker Compose: backend (Oracle, microservicios y BFF), clúster de RabbitMQ y clúster de Kafka con Kafka UI.

## Estructura esperada

Los repositorios deben estar clonados uno al lado del otro:

```
carpeta/
├── ms-vidasalud-appointments/
├── ms-vidasalud-catalog/
├── ms-vidasalud-bff/              (en desarrollo local: ms-vidasalud-bff-mio, ver BFF_DIR)
├── ms-vidasalud-notify/
├── ms-vidasalud-rabbit-admin/
├── ms-vidasalud-analytics/
├── ms-vidasalud-kafka-admin/
└── vidasalud-deploy/              ← este repositorio
    ├── docker-compose.yml         backend
    ├── mq/compose.yml             clúster RabbitMQ (2 nodos)
    └── kafka/compose.yml          3 ZooKeeper + 3 brokers + Kafka UI
```

## Puesta en marcha

El orden importa: las tres partes comparten la red externa `vidasalud-net`, y los servicios que publican o consumen eventos necesitan los brokers encendidos.

```bash
# 1. Red compartida (solo la primera vez)
docker network create vidasalud-net

# 2. Variables (solo la primera vez): completar las claves en cada .env
cp .env.example .env
cp mq/.env.example mq/.env
cp kafka/.env.example kafka/.env

# 3. Construir las imágenes, una por una (compilan y corren los tests)
docker compose build appointments
docker compose build catalog
docker compose build bff
docker compose build notify
docker compose build rabbit-admin
docker compose build analytics
docker compose build kafka-admin

# 4. Brokers
docker compose -f mq/compose.yml up -d
docker compose -f kafka/compose.yml up -d
docker compose -f kafka/compose.yml ps     # esperar los 7 en "healthy"

# 5. Backend
docker compose up -d
docker ps --format "table {{.Names}}\t{{.Status}}"
```

En una máquina con poca memoria (por ejemplo una t3.large) conviene construir **antes** de encender Kafka, como en el orden de arriba: compilar con Maven ocupa bastante memoria.

La primera vez Oracle tarda unos minutos en inicializarse; los microservicios esperan a que esté sano. Los que dependen de los brokers se reintentan solos (`restart: unless-stopped`).

Comprobaciones:

```bash
curl http://localhost:8080/actuator/health          # BFF
curl -s localhost:8085/api/kafka/cluster; echo      # kafka-admin: 3 brokers
curl -s localhost:8085/api/kafka/topicos; echo      # 4 tópicos de 3 particiones y 3 réplicas
```

## Servicios y puertos

| Servicio | Puerto | Acceso |
|---|---|---|
| bff | 8080 | Público: única entrada al backend (detrás del API Gateway) |
| appointments | 8081 | Red interna |
| catalog | 8082 | Red interna |
| notify | 8083 | Red interna (solo consume RabbitMQ) |
| rabbit-admin | 8084 | Solo `127.0.0.1`: túnel SSH |
| kafka-admin | 8085 | Solo `127.0.0.1`: túnel SSH |
| analytics | 8086 | Red interna (consume Kafka; el BFF lo consulta) |
| oracle | 1521 | Red interna |
| RabbitMQ consola | 15672 | Solo `127.0.0.1`: túnel SSH |
| Kafka UI | 8090 | Solo `127.0.0.1`: túnel SSH |
| Kafka brokers | 9092–9094 | Listener externo para desarrollo local; no se abren en el grupo de seguridad |

Dentro de Docker los servicios se encuentran por nombre (`oracle`, `rabbit1`, `kafka1:29092`...): nunca `localhost`.

Túnel desde el PC para las herramientas de administración:

```bash
ssh -i labsuser.pem -L 8090:localhost:8090 -L 8085:localhost:8085 -L 8084:localhost:8084 -L 15672:localhost:15672 ubuntu@<ip-ec2>
```

## Kafka

| Tópico | Particiones × réplicas | Política | Clave |
|---|---|---|---|
| `vidasalud.atenciones.eventos` | 3 × 3 | `delete`, retención 7 días | `atencionId` |
| `vidasalud.boxes.estado` | 3 × 3 | `compact` | `boxId` |
| `vidasalud.atenciones.eventos.DLT` | 3 × 3 | `delete` | — |
| `vidasalud.boxes.estado.DLT` | 3 × 3 | `delete` | — |

Los crea `ms-vidasalud-kafka-admin` al arrancar (la creación automática de tópicos está desactivada en los brokers). Scripts de apoyo en `kafka/scripts/`:

- `crear-topicos.sh`: crea los 4 tópicos con sus parámetros; se puede ejecutar varias veces.
- `inspeccionar.sh`: líder, réplicas e ISR por partición, configuraciones y lag de los consumer groups.
- `cambiar-retencion.sh <tópico> <ms>`: cambia `retention.ms` en caliente.

Consumer groups: `vidasalud-analitica` (métricas, 3 consumidores) y `vidasalud-historial` (historial en Oracle).

## Persistencia

Los datos de Oracle persisten en el volumen `oracle-data`; los de Kafka y ZooKeeper, en los volúmenes `kafka1_data` a `kafka3_data` y `zk1_data` a `zk3_data`.
