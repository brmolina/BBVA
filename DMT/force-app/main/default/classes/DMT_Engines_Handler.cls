/*
Autor: vido
Fecha: 2024-02-27
*/

// Clase para manejar los motores HPG
@JsonAccess(serializable='always' deserializable='always')
global with  sharing class DMT_Engines_Handler implements Callable {
    // Método para invocar un método específico
    public Object call(String methodName, Map<String, Object> args) {
        // Debug para indicar que se está dentro del método call
        //system.debug('Inside call');
        // Retorna el resultado de invocar un método específico
        return DMT_Engines_Service.invokeMethod(methodName, args);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCurrenciesD() {
        // Tu lógica para obtener los datos
        DMT_Engines_Wrapper.CurrencyResponse currencyR = DMT_Engines_Service.getCurrenciesD();
        Map<String, Object> result = new Map<String, Object>();
        result.put('pickList', currencyR.pickList); // Método que devuelve la lista de valores
        result.put('currencyMap', currencyR.currencyMap); // Método que devuelve el mapa de monedas
        return result;
    }
}