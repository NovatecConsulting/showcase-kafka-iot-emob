// https://github.com/alozano3/kafka/tree/KAFKA-8863-connect-insertHeaders-dropHeaders/connect/transforms/src/main/java/org/apache/kafka/connect/transforms
package de.novatec.kafka.connect.transforms.utils;

import org.apache.kafka.common.config.AbstractConfig;
import org.apache.kafka.common.config.ConfigDef;

import java.util.Map;

/**
 * A barebones concrete implementation of {@link AbstractConfig}.
 */
public class SimpleConfig extends AbstractConfig {

    public SimpleConfig(ConfigDef configDef, Map<?, ?> originals) {
        super(configDef, originals, false);
    }

}