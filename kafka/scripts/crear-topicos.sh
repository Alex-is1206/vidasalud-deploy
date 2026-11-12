#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${KAFKA_CONTAINER:-kafka1}"
BOOTSTRAP="${KAFKA_BOOTSTRAP:-kafka1:29092,kafka2:29092,kafka3:29092}"

echo "============================================================"
echo " Creando tópicos de VidaSalud en: ${BOOTSTRAP}"
echo "============================================================"

# 1. Tópico de eventos de atenciones (cleanup.policy=delete, retención 7 días)
docker exec "${CONTAINER}" kafka-topics \
  --bootstrap-server "${BOOTSTRAP}" \
  --create --if-not-exists \
  --topic vidasalud.atenciones.eventos \
  --partitions 3 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000

echo "[OK] Tópico 'vidasalud.atenciones.eventos' verificado/creado."

# 2. Tópico de estado de boxes (cleanup.policy=compact, segment.ms=10 min)
docker exec "${CONTAINER}" kafka-topics \
  --bootstrap-server "${BOOTSTRAP}" \
  --create --if-not-exists \
  --topic vidasalud.boxes.estado \
  --partitions 3 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config cleanup.policy=compact \
  --config segment.ms=600000

echo "[OK] Tópico 'vidasalud.boxes.estado' verificado/creado."

# 3. Dead Letter Topic (DLT) de atenciones
docker exec "${CONTAINER}" kafka-topics \
  --bootstrap-server "${BOOTSTRAP}" \
  --create --if-not-exists \
  --topic vidasalud.atenciones.eventos.DLT \
  --partitions 3 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000

echo "[OK] Tópico 'vidasalud.atenciones.eventos.DLT' verificado/creado."

# 4. Dead Letter Topic (DLT) de boxes
docker exec "${CONTAINER}" kafka-topics \
  --bootstrap-server "${BOOTSTRAP}" \
  --create --if-not-exists \
  --topic vidasalud.boxes.estado.DLT \
  --partitions 3 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config cleanup.policy=delete \
  --config retention.ms=604800000

echo "[OK] Tópico 'vidasalud.boxes.estado.DLT' verificado/creado."

echo "============================================================"
echo " Listado actual de tópicos:"
docker exec "${CONTAINER}" kafka-topics \
  --bootstrap-server "${BOOTSTRAP}" \
  --list
echo "============================================================"