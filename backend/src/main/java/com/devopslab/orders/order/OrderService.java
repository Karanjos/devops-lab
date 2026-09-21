package com.devopslab.orders.order;

import com.devopslab.orders.kafka.OrderEventPublisher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class OrderService {

    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    private final OrderRepository repository;
    // Absent when app.kafka.enabled=false (Phase 1: run without Kafka).
    private final ObjectProvider<OrderEventPublisher> publisher;

    public OrderService(OrderRepository repository, ObjectProvider<OrderEventPublisher> publisher) {
        this.repository = repository;
        this.publisher = publisher;
    }

    public Order create(CreateOrderRequest request) {
        // Saved in its own transaction, so the row is committed BEFORE the event is published
        // and the consumer can always find it. (Production answer: the transactional outbox pattern.)
        Order order = repository.save(new Order(request.customer(), request.item(), request.quantity()));

        OrderEventPublisher kafka = publisher.getIfAvailable();
        if (kafka != null) {
            kafka.publishCreated(order);
        } else {
            log.info("Kafka disabled, processing order {} synchronously", order.getId());
            order.markProcessed();
            order = repository.save(order);
        }
        return order;
    }

    /** Called by the Kafka consumer for every orders.created event. */
    public void process(UUID id) {
        Order order = get(id);
        if (order.getStatus() == OrderStatus.PROCESSED) {
            return; // consumers must be idempotent: Kafka delivers at-least-once
        }
        order.markProcessed();
        order = repository.save(order);
        log.info("Processed order {}", id);

        OrderEventPublisher kafka = publisher.getIfAvailable();
        if (kafka != null) {
            kafka.publishProcessed(order);
        }
    }

    public List<Order> latest() {
        return repository.findTop50ByOrderByCreatedAtDesc();
    }

    public Order get(UUID id) {
        return repository.findById(id).orElseThrow(() -> new OrderNotFoundException(id));
    }
}
