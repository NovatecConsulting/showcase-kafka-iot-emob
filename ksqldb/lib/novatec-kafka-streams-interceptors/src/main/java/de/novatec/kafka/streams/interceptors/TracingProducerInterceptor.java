package de.novatec.kafka.streams.interceptors;

import static java.nio.charset.StandardCharsets.UTF_8;
import static java.util.Optional.ofNullable;

import java.util.Map;

import org.apache.kafka.clients.producer.ProducerInterceptor;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.header.Headers;

public class TracingProducerInterceptor<K, V> implements ProducerInterceptor<K, V> {

    @Override
    public void configure(Map<String, ?> configs) {}

    @Override
    public ProducerRecord<K, V> onSend(ProducerRecord<K, V> record) {
        return new ProducerRecord<>(record.topic(), record.partition(),
            record.timestamp(), record.key(), record.value(),
            record.headers()
                .remove("producerid")
                .add("producerid", buildProducerId(record.headers(), "groupid", "topic-in").getBytes(UTF_8))
                .add("topic-out", record.topic().getBytes(UTF_8)));
    }

    @Override
    public void onAcknowledgement(RecordMetadata metadata, Exception exception) {
    }

    @Override
    public void close() {
    }

    private static String buildProducerId(Headers headers, String fieldGroupId, String fieldTopic) {
        return buildProducerId(headers.lastHeader(fieldGroupId), headers.lastHeader(fieldTopic));
    }

    private static String buildProducerId(Header groupId, Header topic) {
        return buildProducerId(
            ofNullable(groupId).map(Header::value).orElse(null),
            ofNullable(topic).map(Header::value).orElse(null));
    }

    private static String buildProducerId(byte[] groupId, byte[] topic) {
        return buildProducerId(
            ofNullable(groupId).map(v -> new String(v, UTF_8)).orElse("null"),
            ofNullable(topic).map(v -> new String(v, UTF_8)).orElse("null"));
    }

    private static String buildProducerId(String groupId, String topic) {
        return groupId + "-" + topic;
    }
}
