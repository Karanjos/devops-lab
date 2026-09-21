package com.devopslab.orders.order;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateOrderRequest(
        @NotBlank @Size(max = 80) String customer,
        @NotBlank @Size(max = 80) String item,
        @Min(1) @Max(1000) int quantity,
        @Size(max=200) String notes) {
}
