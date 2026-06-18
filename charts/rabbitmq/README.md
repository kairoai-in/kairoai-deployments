# RabbitMQ

RabbitMQ is the planned broker for Celery-based async work.

Early deployment options:

- Add a RabbitMQ Helm dependency here.
- Deploy a standalone RabbitMQ chart with environment-specific values.

Hosted PostgreSQL should remain Azure Database for PostgreSQL Flexible Server, not a pod in AKS.
