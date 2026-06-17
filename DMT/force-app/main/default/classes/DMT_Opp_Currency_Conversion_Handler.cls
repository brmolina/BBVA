/**-------------------------------------------------------------------------------------------
* @Name     DMT_Opp_Currency_Conversion_Handler
* @Author   Juan Ramírez <jjuandavid.ramirez.jaramillo.contractor@bbva.com>
* @Date     Created: 2025-05-26
* --------------------------------------------------------------------------------------------
* @Description Callable class for Omnistudio
* --------------------------------------------------------------------------------------------
*/
global with sharing class DMT_Opp_Currency_Conversion_Handler implements Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try{ 
            Map<String, Object> result;

            if (methodName == 'convertArrayAmount') {
                result = DMT_Opp_Currency_Conversion_Utils.DMT_Array_Amount_Conversion(inputMap,outMap,options);
            //} else if (methodname == 'testTaxo') {
                //result = DMT_Opp_Currency_Conversion_Utils.DMT_Test_Taxo(inputMap,outMap,options);
            } else if (methodName == 'getMinAndMaxDates') {
                result = DMT_Opp_Currency_Conversion_Utils.getOpportunityProductsMinAndMaxDates(inputMap,outMap,options);
            } else {
                throw new DTM_Currency_Exception('Metodo no definido');
            }

            if (result != null) {
                outMap.putAll(result);
            }

        } catch(exception e){
            Boolean logged = false;
            logged = DES_Exception_Utils.logException(e,
                                                    'DES_Exception_Handler',
                                                    'invokeMethod',
                                                    'DMT',
                                                    '');
            outMap.put('error', true);
        }
        return outMap;
    }

    // Inner class para lanzar excepciones con mensaje personalizado en Apex
    public virtual class DTM_Currency_Exception extends Exception {}
}