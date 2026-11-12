#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${KAFKA_CONTAINER:-kafka1}"
BOOTSTRAP="${KAFKA_BOOTSTRAP:-kafka1:29092,kafka2:29092,kafka3:29092}"

echo "============================================================"
echo " 1. DETALLE DE TÓPICOS (Particiones, Líder, Réplicas, ISR)"
echo "============================================================"
for TOPICO in \
  "vidasalud.atenciones.eventos" \
  "vidasalud.boxes.estado" \
  "vidasalud.atenciones.eventos.DLT" \
  "vidasalud.boxes.estado.DLT"; do
  echo "--- Tópico: ${TOPICO} ---"
  docker exec "${CONTAINER}" kafka-topics \
    --bootstrap-server "${BOOTSTRAP}" \
    --describe \
    --topic "${TOPICO}" || true
  echo ""
done

echo "============================================================"
echo " 2. CONFIGURACIONES DINÁMICAS DE LOS TÓPICOS"
echo "============================================================"
docker exec "${CONTAINER}" kafka-configs \
  --bootstrap-server "${BOOTSTRAP}" \
  --entity-type topics \
  --describe

echo ""
echo "============================================================"
echo " 3. CONSUMER GROUPS ACTIVOS Y LAG POR PARTICIÓN"
echo "============================================================"
docker exec "${CONTAINER}" kafka-consumer-groups \
  --bootstrap-server "${BOOTSTRAP}" \
  --list

for GRUPO in "vidasalud-analitica" "vidasalud-historial"; do
  echo ""
  echo "--- Consumer Group: ${GRUPO} ---"
  docker exec "${CONTAINER}" kafka-consumer-groups \
    --bootstrap-server "${BOOTSTRAP}" \
    --describe \
    --group "${GRUPO}" || echo "(El grupo '${GRUPO}' aún no tiene offsets registrados)"
done