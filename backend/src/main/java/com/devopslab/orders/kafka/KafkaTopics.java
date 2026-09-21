package com.devopslab.orders.kafka;

public final class KafkaTopics {

    /** Written by the API when an order is placed. Read by the consumer. */
    public static final String ORDERS_CREATED = "orders.created";

    /** Written after processing. Read by Kafka Connect (JDBC sink -> orders_report table). */
    public static final String ORDERS_PROCESSED = "orders.processed";

    private KafkaTopics() {
    }
}
