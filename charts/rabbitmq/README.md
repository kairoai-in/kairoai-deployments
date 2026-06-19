# RabbitMQ

RabbitMQ is retained only as a local/compatibility option for the original Celery worker path.

Hosted Azure environments should use Azure Service Bus for review dispatch. Do not add a RabbitMQ dependency for AKS unless the Azure Service Bus direction changes again.
