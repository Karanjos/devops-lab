package com.devopslab.orders.order;

import com.devopslab.orders.kafka.OrderEventPublisher;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.beans.factory.ObjectProvider;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    OrderRepository repository;

    @Mock
    ObjectProvider<OrderEventPublisher> publisher;

    OrderService service;

    @BeforeEach
    void setUp() {
        service = new OrderService(repository, publisher);
    }

    @Test
    void createWithoutKafkaProcessesSynchronously() {
        when(publisher.getIfAvailable()).thenReturn(null);
        when(repository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        Order order = service.create(new CreateOrderRequest("Asha", "Widget", 2, "Please gift wrap"));

        assertThat(order.getStatus()).isEqualTo(OrderStatus.PROCESSED);
    }

    @Test
    void createWithKafkaPublishesEventAndStaysCreated() {
        OrderEventPublisher kafka = mock(OrderEventPublisher.class);
        when(publisher.getIfAvailable()).thenReturn(kafka);
        when(repository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        Order order = service.create(new CreateOrderRequest("Asha", "Widget", 2, "Please gift wrap"));

        assertThat(order.getStatus()).isEqualTo(OrderStatus.CREATED);
        verify(kafka).publishCreated(order);
    }

    @Test
    void processMarksOrderProcessedAndPublishesResult() {
        OrderEventPublisher kafka = mock(OrderEventPublisher.class);
        Order order = new Order("Asha", "Widget", 2, "Please gift wrap");
        when(repository.findById(order.getId())).thenReturn(Optional.of(order));
        when(repository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(publisher.getIfAvailable()).thenReturn(kafka);

        service.process(order.getId());

        assertThat(order.getStatus()).isEqualTo(OrderStatus.PROCESSED);
        verify(kafka).publishProcessed(order);
    }

    @Test
    void processIsIdempotent() {
        Order order = new Order("Asha", "Widget", 2, "Please gift wrap");
        order.markProcessed();
        when(repository.findById(order.getId())).thenReturn(Optional.of(order));

        service.process(order.getId());

        verify(repository, never()).save(any());
        verifyNoInteractions(publisher);
    }

    @Test
    void getThrowsWhenMissing() {
        java.util.UUID id = java.util.UUID.randomUUID();
        when(repository.findById(id)).thenReturn(Optional.empty());

        org.junit.jupiter.api.Assertions.assertThrows(OrderNotFoundException.class, () -> service.get(id));
    }
}
