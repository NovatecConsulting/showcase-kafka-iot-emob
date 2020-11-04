package de.novatec.ksql.functions;

import io.confluent.ksql.function.udaf.Udaf;
import io.confluent.ksql.function.udaf.UdafDescription;
import io.confluent.ksql.function.udaf.UdafFactory;
import java.util.HashMap;
import java.util.Map;
import org.apache.commons.lang3.StringUtils;

@UdafDescription(name = "custom_aggregation", description = "Keep the old and the new status for each client.")
public class CustomAggregation {
    private CustomAggregation() {
    }

    @UdafFactory(description = "keep the old and new state")
    public static Udaf<String, Map<String, String>, String> createUdaf() {
        return new Udaf<String, Map<String, String>, String>() {

            //Specify an inital value for the aggregation
            @Override
            public Map<String, String> initialize() {
                final Map<String, String> states = new HashMap<>();
                states.put("old", "initial");
                states.put("new", "initial");
                return states;
            }

            //perform aggregation whenever a new record appears in the stream
            @Override
            public Map<String, String> aggregate(
                    final String newState,
                    final Map<String, String> stateValues
            ) {
                String currentNew = stateValues.getOrDefault("new", "initial");
                stateValues.put("old", currentNew);
                stateValues.put("new", newState);
                return stateValues;
            }

            //called to merge two aggregates together, e.g. when using session windows
            //the 'later' value is taken because it is by definition the more current value
            //maybe needs to be refactored when there are acutal use cases for this scenario
            @Override
            public Map<String, String> merge(
                    final Map<String, String> states1,
                    final Map<String, String> states2
            ) {
                return states2;
            }

            //called when Ksqldb interacts with the aggregation value
            public String map(
                    Map<String, String> stateValues
            ) {
                String newState = stateValues.getOrDefault("new", "initial");
                String oldState = stateValues.getOrDefault("old", "initial");
                String states = newState + "; " + oldState;
                return states;
            }
        };
    }
}
