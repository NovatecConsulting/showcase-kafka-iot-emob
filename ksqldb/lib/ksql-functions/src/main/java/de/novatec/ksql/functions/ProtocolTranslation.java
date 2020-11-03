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
      @UdfParameter(value = "AMOUNT", description = "Charging amount") final String amount,
      @UdfParameter(value = "MAX", description = "Charging max") final String max,
      @UdfParameter(value = "RESPONSE_AMOUNT", description = "Charging response amount") final String response_amount,
      @UdfParameter(value = "RESPONSE_MAX", description = "Charging response max") final String response_max,
      @UdfParameter(value = "RESPONSE_STATUS", description = "Status response") final String response_status,
      @UdfParameter(value = "ERROR", description = "Error response") final String error)
    {
      if (StringUtils.equalsIgnoreCase(status,"ready") || StringUtils.equalsIgnoreCase(event,"EV_lost")) return "ready";
      if (StringUtils.equalsIgnoreCase(event,"ev"))  return "ev";
      if (StringUtils.equalsIgnoreCase(event,"start")) return "charging 0/" + max;
      if (StringUtils.equalsIgnoreCase(event,"stop")) return "charged " + amount + "/" + max + ", ready again";
      if (StringUtils.equalsIgnoreCase(action,"amount") &&
              StringUtils.equalsIgnoreCase(error,"No charging process")) return "amount requested, no charging process";
      if (StringUtils.equalsIgnoreCase(action,"amount")) return "charging " + response_amount + "/" + response_max;
      if (StringUtils.equalsIgnoreCase(action,"status") && (
              StringUtils.equalsIgnoreCase(response_status,"charging") ||
              StringUtils.equalsIgnoreCase(response_status,"ev"))) return "status requested, " + response_status;
      return "ready";
    }
}
