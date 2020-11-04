package de.novatec.ksql.functions;

import io.confluent.ksql.function.udf.Udf;
import io.confluent.ksql.function.udf.UdfDescription;
import io.confluent.ksql.function.udf.UdfParameter;
import org.apache.commons.lang3.StringUtils;

@UdfDescription(name = "determine_status", description = "Map the status of a client to 0 or 1.")
public class DetermineStatus {

    @Udf(description = "map the status of a client to 0 or 1")
    public int determine_status(
            @UdfParameter(value = "NEW_STATUS", description = "New status") final String newStatus,
            @UdfParameter(value = "OLD_STATUS", description = "Old status") final String oldStatus
            )
    {
        if (StringUtils.containsIgnoreCase(newStatus, "ready")) return 1;
        if (StringUtils.containsIgnoreCase(newStatus, "amount requested, no charging process")) {
            if (StringUtils.containsIgnoreCase(oldStatus, "ready")) {
                return 1;
            }else {
                return 0;
            }
        }
        return 0;
    }
}
