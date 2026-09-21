package com.devopslab.orders.order;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "orders")
public class Order {

    @Id
    private UUID id;

    @Column(nullable = false)
    private String customer;

    @Column(nullable = false)
    private String item;

    @Column(nullable = false)
    private int quantity;

    @Column(nullable = true)
    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;

    @Column(nullable = false)
    private Instant createdAt;

    private Instant processedAt;

    protected Order() {
        // required by JPA
    }

    public Order(String customer, String item, int quantity) {
        this(customer, item, quantity,null);
    }

    public Order(String customer, String item, int quantity, String notes) {
        this.id = UUID.randomUUID();
        this.customer = customer;
        this.item = item;
        this.quantity = quantity;
        this.notes = notes;
        this.status = OrderStatus.CREATED;
        this.createdAt = Instant.now();
    }

    public void markProcessed() {
        this.status = OrderStatus.PROCESSED;
        this.processedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public String getCustomer() { return customer; }
    public String getItem() { return item; }
    public int getQuantity() { return quantity; }
    public String getNotes() { return notes; }
    public OrderStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getProcessedAt() { return processedAt; }
}
