// https://github.com/alozano3/kafka/blob/KAFKA-8863-connect-insertHeaders-dropHeaders/connect/transforms/src/test/java/org/apache/kafka/connect/transforms/InsertHeaderTest.java
package de.novatec.kafka.connect.transforms;

import org.apache.kafka.common.config.ConfigException;
import org.apache.kafka.connect.data.SchemaAndValue;
import org.apache.kafka.connect.data.Time;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.Timestamp;
import org.apache.kafka.connect.data.SchemaBuilder;
import org.apache.kafka.connect.header.ConnectHeaders;
import org.apache.kafka.connect.header.Headers;
import org.apache.kafka.connect.source.SourceRecord;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

public class InsertHeaderTest {
    private InsertHeader<SourceRecord> xform = new InsertHeader<>();

    @AfterEach
    public void teardown() {
        xform.close();
    }

    @Test
    public void shouldFailWithEmptyHeaderName() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "");
        props.put("literal.value", "dummy value");

        assertThrows(ConfigException.class, () -> {
            xform.configure(props); 
        });
    }

    @Test
    public void shouldFailWithBlankHeaderName() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "    ");
        props.put("literal.value", "dummy value");

        assertThrows(ConfigException.class, () -> {
            xform.configure(props); 
        });
    }

    @Test
    public void insertHeaderWithNullValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().add("AAA", null);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void shouldFailWithBlankHeaderValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", " ");

        assertThrows(ConfigException.class, () -> {
            xform.configure(props); 
        });
    }

    @Test
    public void shouldFailWithEmptyHeaderValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "");

        assertThrows(ConfigException.class, () -> {
            xform.configure(props); 
        });
    }

    @Test
    public void insertHeaderOnNullRecord() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "dummy header");
        props.put("literal.value", "dummy value");

        xform.configure(props);

        final SourceRecord transformedRecord = xform.apply(null);

        assertNull(transformedRecord);
    }

    @Test
    public void insertHeaderWithStringValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "dummy header");
        props.put("literal.value", "dummy value");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addString("dummy header", "dummy value");

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithStringValueWhenOneExists() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "dummy value");

        xform.configure(props);

        Headers existentHeaders = new ConnectHeaders().addString("BBB", "existent value");

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, existentHeaders);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addString("BBB", "existent value")
                .addString("AAA", "dummy value");

        assertEquals(2, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }


    @Test
    public void insertHeaderWithStringValueWithSameKey() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "dummy value");

        xform.configure(props);

        Headers existentHeaders = new ConnectHeaders().addString("AAA", "existent value")
                .addString("BBB", "existent value");

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, existentHeaders);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addString("AAA", "existent value")
                .addString("BBB", "existent value")
                .addString("AAA", "dummy value");


        assertEquals(3, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithInt8Value() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "2");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addByte("AAA", (byte) 2);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithInt16Value() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "18000");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addShort("AAA", (short) 18000);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithInt32Value() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "50000");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addInt("AAA", 50000);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithInt64Value() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "87474836647");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addLong("AAA", 87474836647L);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithFloatValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "2353245343456.435435");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addDouble("AAA", 2353245343456.435435);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithDateValue() throws ParseException {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "2019-08-23");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        SchemaAndValue schemaAndValue = new SchemaAndValue(org.apache.kafka.connect.data.Date.SCHEMA,
                new SimpleDateFormat("yyyy-MM-dd").parse("2019-08-23"));

        Headers expected = new ConnectHeaders().add("AAA", schemaAndValue);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithTimeValue() throws ParseException {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "14:34:54.346Z");
        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        SchemaAndValue schemaAndValue = new SchemaAndValue(Time.SCHEMA,
                new SimpleDateFormat("HH:mm:ss.SSS'Z'").parse("14:34:54.346Z"));

        Headers expected = new ConnectHeaders().add("AAA", schemaAndValue);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithTimestampValue() throws ParseException {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "AAA");
        props.put("literal.value", "2019-08-23T14:34:54.346Z");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        SchemaAndValue schemaAndValue = new SchemaAndValue(Timestamp.SCHEMA,
                new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse("2019-08-23T14:34:54.346Z"));

        Headers expected = new ConnectHeaders().add("AAA", schemaAndValue);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithBooleanValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "dummy header");
        props.put("literal.value", "true");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Headers expected = new ConnectHeaders().addBoolean("dummy header", true);

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithMapValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "dummy header");
        props.put("literal.value", "{\"foo\":\"abc\",\"bar\":\"def\"}");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Map<String, String> map = new LinkedHashMap<>();
        map.put("foo", "abc");
        map.put("bar", "def");
        Headers expected = new ConnectHeaders().addMap("dummy header", map, SchemaBuilder.map(
                Schema.STRING_SCHEMA, Schema.STRING_SCHEMA).build());

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }

    @Test
    public void insertHeaderWithListValue() {
        final Map<String, Object> props = new HashMap<>();
        props.put("header", "dummy header");
        props.put("literal.value", "[\"one\",\"two\",\"three\"]");

        xform.configure(props);

        final SourceRecord record = new SourceRecord(null, null, "test",
                0, null, null, null, null, null, null);
        final SourceRecord transformedRecord = xform.apply(record);

        Map<String, String> map = new LinkedHashMap<>();
        map.put("foo", "abc");
        map.put("bar", "def");
        Headers expected = new ConnectHeaders().addList("dummy header", Arrays.asList(
                "one", "two", "three"), SchemaBuilder.array(Schema.STRING_SCHEMA).build());

        assertEquals(1, transformedRecord.headers().size());
        assertEquals(expected, transformedRecord.headers());
    }
}