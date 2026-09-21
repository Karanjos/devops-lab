package com.devopslab.orders.kafka;

import com.devopslab.orders.order.Order;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true", matchIfMissing = true)
public class OrderEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(OrderEventPublisher.class);

    private final KafkaTemplate<String, String> kafka;
    private final ObjectMapper mapper;

    public OrderEventPublisher(KafkaTemplate<String, String> kafka, ObjectMapper mapper) {
        this.kafka = kafka;
        this.mapper = mapper;
    }

    /** Plain JSON event, consumed by our own OrderEventConsumer. */
    public void publishCreated(Order order) {
        Map<String, Object> event = new LinkedHashMap<>();
        event.put("id", order.getId().toString());
        event.put("customer", order.getCustomer());
        event.put("item", order.getItem());
        event.put("quantity", order.getQuantity());
        event.put("notes", order.getNotes());   
        send(KafkaTopics.ORDERS_CREATED, order, event);
    }

    /**
     * Event for Kafka Connect's JDBC sink. That connector needs to know column types, so with the
     * JSON converter each message must carry its own schema next to the payload (the "envelope").
     * In production you would use Avro + Schema Registry instead of repeating the schema per message.
     */
    public void publishProcessed(Order order) {
        Map<String, Object> schema = new LinkedHashMap<>();
        schema.put("type", "struct");
        schema.put("name", "orders_report");
        schema.put("optional", false);
        schema.put("fields", List.of(
                field("string", "id"),
                field("string", "customer"),
                field("string", "item"),
                field("int32", "quantity"),
                field("string", "status"),
                field("string", "processed_at"),
                field("string", "notes")));

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("id", order.getId().toString());
        payload.put("customer", order.getCustomer());
        payload.put("item", order.getItem());
        payload.put("quantity", order.getQuantity());
        payload.put("notes", order.getNotes()); 
        payload.put("status", order.getStatus().name());
        payload.put("processed_at", String.valueOf(order.getProcessedAt()));

        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put("schema", schema);
        envelope.put("payload", payload);
        send(KafkaTopics.ORDERS_PROCESSED, order, envelope);
    }

    private static Map<String, Object> field(String type, String name) {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("type", type);
        f.put("optional", false);
        f.put("field", name);
        return f;
    }

    private void send(String topic, Order order, Object body) {
        try {
            // Key = order id: all events for one order land on the same partition, in order.
            kafka.send(topic, order.getId().toString(), mapper.writeValueAsString(body))
                    .whenComplete((result, error) -> {
                        if (error != null) {
                            log.error("Failed to publish to {} for order {}", topic, order.getId(), error);
                        } else {
                            log.info("Published to {} partition={} offset={} order={}", topic,
                                    result.getRecordMetadata().partition(),
                                    result.getRecordMetadata().offset(), order.getId());
                        }
                    });
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not serialise event for order " + order.getId(), e);
        }
    }
}
