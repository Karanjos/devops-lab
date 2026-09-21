package com.devopslab.orders.kafka;

import com.devopslab.orders.order.OrderService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true", matchIfMissing = true)
public class OrderEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(OrderEventConsumer.class);

    private final OrderService service;
    private final ObjectMapper mapper;

    public OrderEventConsumer(OrderService service, ObjectMapper mapper) {
        this.service = service;
        this.mapper = mapper;
    }

    // One consumer group => running several replicas splits the partitions between them.
    @KafkaListener(topics = KafkaTopics.ORDERS_CREATED, groupId = "order-processor")
    public void onOrderCreated(String message) throws JsonProcessingException {
        log.info("Received orders.created: {}", message);
        UUID id = UUID.fromString(mapper.readTree(message).get("id").asText());
        service.process(id);
    }
}
