/*
Autor: vido
Fecha: 2024-02-27
*/

// Clase para proporcionar servicios relacionados con los motores HPG
@JsonAccess(serializable='always' deserializable='always')
public class DMT_Engines_Service {

    // Método para invocar un método específico
    public static Boolean invokeMethod(String methodName, Map<String, Object> args) {
        Boolean outputMapBool = false;
        try {
            if (('getFeatures').equals(methodName)) {//Atencion
                final DMT_IP_Wrapper ipWrapper = new DMT_IP_Wrapper(methodName, args);
                DMT_Engines_Wrapper.Request requestAttr = DMT_Engines_Helper.setIPAttributes(ipWrapper);
                getFeatures(requestAttr,ipWrapper);
                outputMapBool = true;
            }
        } catch (Exception e) {
            System.debug('JACG' + e.getLineNumber());
            System.debug('Exception --> ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_Engines_Service', 'invokeMethod', 'DMT', '');
        }
        return outputMapBool;
    }

    public static void getFeatures(DMT_Engines_Wrapper.Request requestAttr,DMT_IP_Wrapper ipWrapper){
        List<DMT_Engines_Wrapper> wrapperList = DMT_Engines_Helper.callEngines(requestAttr);
        DMT_Engines_Helper.getResponse(requestAttr,wrapperList,ipWrapper);
    }

    public static DMT_Engines_Wrapper.CurrencyResponse getCurrenciesD() {
        return DMT_Engines_Helper.getCurrenciesD();
    }

}