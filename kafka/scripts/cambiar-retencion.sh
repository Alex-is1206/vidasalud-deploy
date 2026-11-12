#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${KAFKA_CONTAINER:-kafka1}"
BOOTSTRAP="${KAFKA_BOOTSTRAP:-kafka1:29092,kafka2:29092,kafka3:29092}"

TOPICO="${1:-vidasalud.atenciones.eventos}"
RETENCION_MS="${2:-1209600000}" # Por defecto: 14 días (1209600000 ms)

echo "============================================================"
echo " Modificando retention.ms en '${TOPICO}' -> ${RETENCION_MS} ms"
echo "============================================================"

docker exec "${CONTAINER}" kafka-configs \
  --bootstrap-server "${BOOTSTRAP}" \
  --entity-type topics \
  --entity-name "${TOPICO}" \
  --alter \
  --add-config "retention.ms=${RETENCION_MS}"

echo ""
echo "Configuración actualizada del tópico '${TOPICO}':"
docker exec "${CONTAINER}" kafka-configs \
  --bootstrap-server "${BOOTSTRAP}" \
  --entity-type topics \
  --entity-name "${TOPICO}" \
  --describe