# Kafka Connect worker with the Confluent JDBC connector baked in.
# Connectors are plugins: the worker image stays generic, the plugin is installed into plugin.path.
# (On Kubernetes, Strimzi builds an image like this for you from a KafkaConnect resource.)
FROM confluentinc/cp-kafka-connect:7.9.0

# Needs internet access at build time (Confluent Hub). Pin the version for reproducible builds.
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.8.2
