package com.devopslab.orders.order;

import java.time.Instant;
import java.util.UUID;

public record OrderResponse(
        UUID id,
        String customer,
        String item,
        int quantity,
        String notes,
        OrderStatus status,
        Instant createdAt,
        Instant processedAt) {

    public static OrderResponse from(Order o) {
        return new OrderResponse(o.getId(), o.getCustomer(), o.getItem(), o.getQuantity(), o.getNotes(),
                o.getStatus(), o.getCreatedAt(), o.getProcessedAt());
    }
}
