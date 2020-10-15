package de.novatec.kafka.streams.interceptors;

import static java.nio.charset.StandardCharsets.UTF_8;
import static java.util.Optional.ofNullable;

import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.clients.consumer.ConsumerInterceptor;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.common.TopicPartition;

public class TracingConsumerInterceptor<K, V> implements ConsumerInterceptor<K, V> {

    private Map<String, ?> configs;

    @Override
    public void configure(Map<String, ?> configs) {
        this.configs = new HashMap<>(configs);
    }

    @Override
    public ConsumerRecords<K, V> onConsume(ConsumerRecords<K, V> records) {
        records.forEach(record -> {
            record.headers().add("groupid", ofNullable(configs.get("group.id").toString()).orElse("null").getBytes(UTF_8));
            record.headers().add("topic-in", record.topic().getBytes(UTF_8));
        });
        return records;
    }

    @Override
    public void onCommit(Map<TopicPartition, OffsetAndMetadata> offsets) {
    }

    @Override
    public void close() {}

}
