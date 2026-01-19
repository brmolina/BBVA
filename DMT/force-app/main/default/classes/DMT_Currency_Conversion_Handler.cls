/**-------------------------------------------------------------------------------------------
* @Name     DMT_Currency_Conversion_Handler
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-04-24
* --------------------------------------------------------------------------------------------
* @Description Callable class for Omnistudio
* --------------------------------------------------------------------------------------------
*/
global with sharing class DMT_Currency_Conversion_Handler implements Callable {

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try{ 
            Map<String, Object> result;

            if (methodName == 'convertAmount') {
                result = DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap,outMap,options);
            } else if (methodName == 'convertAmountMultipleFields') {
                result = DMT_Currency_Conversion_Utils.DMT_Multiple_Amount_Conversion(inputMap,outMap,options);
            } else if (methodName == 'formatAmount') {
                result = DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(inputMap,outMap,options);
            } else if (methodName == 'convertList') {
                result = DMT_Currency_Conversion_Utils.DMT_List_Amount_Conversion(inputMap,outMap,options);
            } else if (methodName == 'convertFieldsInList') {
                result = DMT_Currency_Conversion_Utils.DMT_List_convertCurrencyFieldsInList(inputMap,outMap,options);    
            } else if (methodName == 'convertRiskLineTerm') {
                result = DMT_Currency_Conversion_Utils.DMT_Risk_Term_Conversion(inputMap,outMap,options);
            } else if (methodName == 'replaceNodeInObject') {
                result = DMT_Currency_Conversion_Utils.DMT_Replace_Node_In_Object(inputMap,outMap,options);
            } else if (methodName == 'convertProductList') {
                result = DMT_CurrencyConversionService.DMT_convertProductList(inputMap,outMap,options);
            } else if (methodName == 'convertProductListRisk') {
                result = DMT_CurrencyConversionService.DMT_convertProductListSanctions(inputMap,outMap,options);
            }else if (methodName == 'fixAmountscientificNotation') {
                result = DMT_Currency_Conversion_Utils.formatAmountScientificNotation(inputMap,outMap,options);
            } else {
                throw new DTM_Currency_Exception('Metodo no definido');
            }

            if (result != null) {
                outMap.putAll(result);
            }

        }catch(exception e){
            Boolean logged = false;
            logged = DES_Exception_Utils.logException(e,
                                                  'DES_Exception_Handler',
                                                  'invokeMethod',
                                                  'DMT',
                                                  '');
            outMap.put('error', logged);
        }
        return outMap;
    }

    // Inner class para lanzar excepciones con mensaje personalizado en Apex
    public virtual class DTM_Currency_Exception extends Exception {}

}