package de.novatec.ksql.functions;

import io.confluent.ksql.function.udf.Udf;
import io.confluent.ksql.function.udf.UdfDescription;
import io.confluent.ksql.function.udf.UdfParameter;
import org.apache.commons.lang3.StringUtils;

@UdfDescription(name = "protocol_translation", description = "Translate new messages to protocol 0.8")
public class ProtocolTranslation {

    @Udf(description = "Translate new message to protocol 0.8")
    public String protocol_translation(
      @UdfParameter(value = "STATUS", description = "Charging status") final String status,
      @UdfParameter(value = "EVENT", description = "Charging event") final String event,
      @UdfParameter(value = "ACTION", description = "Charging action") final String action,
      @UdfParameter(value = "AMOUNT", description = "Charging amount") final Long amount,
      @UdfParameter(value = "MAX", description = "Charging max") final Long max,
      @UdfParameter(value = "RESPONSE_AMOUNT", description = "Charging response amount") final Long response_amount,
      @UdfParameter(value = "RESPONSE_MAX", description = "Charging response max") final Long response_max) {
      if (StringUtils.equalsIgnoreCase(status,"ready") || StringUtils.equalsIgnoreCase(event,"EV_lost")) return "ready";
      if (StringUtils.equalsIgnoreCase(event,"ev"))  return "ev";
      if (StringUtils.equalsIgnoreCase(event,"start")) return "charging 0/" + max;
      if (StringUtils.equalsIgnoreCase(event,"stop")) return "charged " + amount + "/" + max;
      if (StringUtils.equalsIgnoreCase(action,"amount")) return "charging " + response_amount + "/" + response_max;
      return "ready";
    }
}
