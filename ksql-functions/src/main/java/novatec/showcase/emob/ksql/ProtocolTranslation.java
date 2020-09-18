package novatec.showcase.emob.ksql;

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
      if (StringUtils.equals(status,"ready") || StringUtils.equals(event,"EV_lost")) return "ready";
      if (StringUtils.equals(event,"ev"))  return "ev";
      if (StringUtils.equals(event,"start")) return "charging 0/" + max;
      if (StringUtils.equals(event,"stop")) return "charged " + amount + "/" + max;
      if (StringUtils.equals(action,"amount")) return "charging " + response_amount + "/" + response_max;
      return "ready";
    }
}
