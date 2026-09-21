# vidasalud-deploy

Despliegue del backend de VidaSalud con Docker Compose.

## Estructura esperada

Los repositorios deben estar clonados uno al lado del otro:

```
carpeta/
├── ms-vidasalud-appointments/
├── ms-vidasalud-catalog/
├── ms-vidasalud-bff/
└── vidasalud-deploy/        ← este repositorio
```

## Uso

```bash
cp .env.example .env      # completar las contraseñas
docker compose up -d --build
docker compose ps
```

La primera vez Oracle tarda unos minutos en inicializarse; los microservicios
esperan a que esté sano antes de arrancar.

Comprobar que el BFF responde:

```bash
curl http://localhost:8080/actuator/health
```

## Arquitectura

| Servicio | Puerto | Expuesto |
|---|---|---|
| bff | 8080 | Sí: única entrada al backend |
| appointments | 8081 | No: red interna |
| catalog | 8082 | No: red interna |
| oracle | 1521 | No: red interna |

Los datos de Oracle persisten en el volumen `oracle-data`.
