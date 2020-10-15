package de.novatec.ksql.functions;

import org.junit.Test;
import static org.junit.Assert.assertEquals;


public class ProtocolTranslationTest{ 
    @Test
    public void protocolTranslation(){
        ProtocolTranslation translator = new ProtocolTranslation();
        String charge = translator.protocol_translation(null,null,null,null,null,null,null);
        assertEquals(charge,"ready");
        charge = translator.protocol_translation("ready",null,null,null,null,null,null);
        assertEquals(charge,"ready");
        charge = translator.protocol_translation(null,"ev",null,null,null,null,null);
        assertEquals(charge,"ev");
        charge = translator.protocol_translation(null,"start",null,null,40L,null,null);
        assertEquals(charge,"charging 0/40");
        charge = translator.protocol_translation(null,"stop",null,30L,40L,null,null);
        assertEquals(charge,"charged 30/40");
    }
}