package com.devopslab.orders.kafka;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

/**
 * Declares the topics. Spring's KafkaAdmin creates them on startup if they do not exist.
 * Partitions/replicas are deliberately tiny: this is a single-broker lab.
 */
@Configuration
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true", matchIfMissing = true)
public class KafkaTopicConfig {

    @Bean
    NewTopic ordersCreated() {
        return TopicBuilder.name(KafkaTopics.ORDERS_CREATED).partitions(3).replicas(1).build();
    }

    @Bean
    NewTopic ordersProcessed() {
        return TopicBuilder.name(KafkaTopics.ORDERS_PROCESSED).partitions(3).replicas(1).build();
    }
}
