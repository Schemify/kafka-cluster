#!/bin/bash
NODES=$1
CLUSTER_ID="EmptNWtoR4GGWx-BH6nGLQ"
NETWORK="schemify-nestjs_schemify-kafka-net"

echo "networks:"
echo "  $NETWORK:"
echo "    external: external"
echo "  kafka-net:"
echo "    driver: bridge"
echo ""
echo "services:"

# Generar nodos Kafka
for i in $(seq 1 $NODES); do
  BROKER_PORT=$((9090 + $i * 2))
  CTRL_PORT=$((9091 + $i * 2))
  echo "  kafka$i:"
  echo "    image: confluentinc/cp-kafka:7.8.0"
  echo "    container_name: kafka$i"
  echo "    hostname: kafka$i"
  echo "    ports:"
  echo "      - \"$BROKER_PORT:9092\""
  echo "      - \"$CTRL_PORT:9093\""
  echo "    volumes:"
  echo "      - ./kafka$i/data:/var/lib/kafka/data"
  echo "    environment:"
  echo "      KAFKA_NODE_ID: $i"
  echo "      KAFKA_BROKER_ID: $i"
  echo "      KAFKA_PROCESS_ROLES: 'broker,controller'"
  echo "      KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'"
  echo "      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT'"
  echo "      KAFKA_LISTENERS: 'PLAINTEXT://kafka$i:9092,CONTROLLER://kafka$i:9093'"
  echo "      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka$i:9092'"
  echo "      KAFKA_INTER_BROKER_LISTENER_NAME: 'PLAINTEXT'"
  echo "      KAFKA_CONTROLLER_QUORUM_VOTERS: '$(seq -s, 1 $NODES | sed "s/\([0-9]\+\)/\1@kafka\1:9093/g")'"
  echo "      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: $NODES"
  echo "      KAFKA_DEFAULT_REPLICATION_FACTOR: $NODES"
  echo "      KAFKA_MIN_INSYNC_REPLICAS: 2"
  echo "      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0"
  echo "      CLUSTER_ID: '$CLUSTER_ID'"
  echo "    networks:"
  echo "      - kafka-net"
  echo ""
done

# Concatenar lista de bootstrap servers dinámicamente
BOOTSTRAPSERVERS=$(seq -s, 1 $NODES | sed "s/\([0-9]\+\)/kafka\1:9092/g")

# Agregar kafka-ui
echo "  kafka-ui:"
echo "    image: provectuslabs/kafka-ui:latest"
echo "    container_name: kafka-cluster-ui"
echo "    ports:"
echo "      - \"8081:8080\""
echo "    environment:"
echo "      KAFKA_CLUSTERS_0_NAME: local"
echo "      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: $BOOTSTRAPSERVERS"
echo "    depends_on:"
for i in $(seq 1 $NODES); do
  echo "      - kafka$i"
done
echo "    networks:"
echo "      - kafka-net"
echo "      - $NETWORK"
