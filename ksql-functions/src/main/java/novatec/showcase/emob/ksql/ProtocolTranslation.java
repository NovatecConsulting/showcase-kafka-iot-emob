package novatec.showcase.emob.ksql;

import io.confluent.ksql.function.udf.Udf;
import io.confluent.ksql.function.udf.UdfDescription;
import io.confluent.ksql.function.udf.UdfParameter;

@UdfDescription(name = "protocol_translation", description = "Translate new messages to protocol 0.8")
public class ProtocolTranslation {

    @Udf(description = "Translate new message to protocol 0.8")
    public String protocol_translation(
      @UdfParameter(value = "STATUS", description = "Charging status") final String status,
      @UdfParameter(value = "EVENT", description = "Charging event") final String event,
      @UdfParameter(value = "ACTION", description = "Charging action") final String action,
      @UdfParameter(value = "AMOUNT", description = "Charging amount") final long amount,
      @UdfParameter(value = "MAX", description = "Charging max") final long max,
      @UdfParameter(value = "RESPONSE_AMOUNT", description = "Charging response amount") final long response_amount,
      @UdfParameter(value = "RESPONSE_MAX", description = "Charging response max") final long response_max) {
      //if (status.equals("ready") || event.equals("EV_lost")) return "ready";
      //if (event.equals("ev"))  return "ev";
      //if (event.equals("start")) return "charging 0/" + max;
      //if (event.equals("stop")) return "charged " + amount + "/" + max;
      //if (action.equals("amount")) return "charging " + response_amount + "/" + response_max;
      return "ready";
    }
}
