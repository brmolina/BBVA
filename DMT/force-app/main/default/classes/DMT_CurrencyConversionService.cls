public with sharing class DMT_CurrencyConversionService {
    
    @AuraEnabled
    public static List<ProductWrapper> convertProductList(List<Object> rawList) {
        
        List<ProductWrapper> result = new List<ProductWrapper>();

        for (Object rawItem : rawList) {

            String jsonStr = JSON.serialize(rawItem);
            ProductWrapper product = (ProductWrapper) JSON.deserialize(jsonStr, ProductWrapper.class);
             
            if (product.amount != null) {
                Map<String, Object> inputMap = new Map<String, Object>{
                    'recordId' => product.line,
                    'amount' => product.amount,
                    'currency' => product.currencyIsoCode,
                    'action' => 'output'
                };
                Map<String, Object> outMap = new Map<String, Object>();
                Map<String, Object> options = new Map<String, Object>();

                DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outMap, options);

                // Asume que el valor convertido viene bajo 'convertedAmount'
                if (outMap.containsKey('amount')) {
                    product.amount = (Decimal) outMap.get('amount');
                }          
            }
            result.add(product);
        }

        return result;
    }

    public static Map<String, Object> DMT_convertProductList(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        
        List<Object> originalList;
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();
        List<ProductWrapper> result = new List<ProductWrapper>();
       // Procesar la lista
        List<Object> convertedList = new List<Object>();

         try {

            Object rawList = inputMap.get('list');

            if (rawList == null) {
                throw new DTM_Currency_Exception('No se encontró el parámetro list');
            }

            originalList = new List<Object>();

            if (rawList instanceof List<Object>) {
                originalList = (List<Object>) rawList;
            } else if (rawList instanceof Map<String, Object>) {
                originalList.add((Map<String, Object>) rawList); // Envolver en una lista
            } else {
                throw new DTM_Currency_Exception('El parámetro list no tiene un formato válido (debe ser lista o mapa)');
            }

            // Configuración desde metadata
            Map<String, Map<String, Object>> DMT_Currency_Factors = new Map<String, Map<String, Object>>();
        
            for (DMT_Currency_Conversion__mdt mdt : [
                SELECT CurrencyIsoCode__c, Conversion_Factor__c, Currency_Label__c
                FROM DMT_Currency_Conversion__mdt
            ]) {
                DMT_Currency_Factors.put(mdt.CurrencyIsoCode__c, new Map<String, Object>{
                    'Conversion_Factor__c' => mdt.Conversion_Factor__c,
                    'Currency_Label__c' => mdt.Currency_Label__c
                });
            }

            for (Object rawItem : originalList) {

                if (!(rawItem instanceof Map<String, Object>)) continue;

                Map<String, Object> item = new Map<String, Object>((Map<String, Object>) rawItem);

                String jsonStr = JSON.serialize(rawItem);
                ProductWrapper product = (ProductWrapper) JSON.deserialize(jsonStr, ProductWrapper.class);
             
                if (product.amount != null) {
                    
                    Map<String, Object> inputMapProduct = new Map<String, Object>{
                    'recordId' => product.line,
                    'amount' => product.amount,
                    'currency' => product.currencyIsoCode,
                    'action' => 'output'
                    };
                
                
                Map<String, Object> outMapProduct = new Map<String, Object>();
                Map<String, Object> optionsProduct = new Map<String, Object>();

                DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMapProduct, outMapProduct, optionsProduct);

                if (outMapProduct.containsKey('amount')) {
                    product.amount = (Decimal) outMapProduct.get('amount');
                    item.put('amount', product.amount);
                }

                if (DMT_Currency_Factors.containsKey(product.currencyIsoCode)) {
                    Map<String, Object> conversionInfo = DMT_Currency_Factors.get(product.currencyIsoCode);system.debug('label'+ conversionInfo.get('Currency_Label__c'));
                    product.currencyLabel = String.valueOf(conversionInfo.get('Currency_Label__c'));
                    item.put('currencyLabel', product.currencyLabel);
                }
                
            }

            convertedList.add(item);
        }

        outMap.put('list', convertedList);
     
        } catch (Exception e) {
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Currency_Conversion_Utils', 'convertCurrencyFieldsInList', 'DMT', '');
            exceptionList.add(dmtEcx);
            outMap.put('list', inputMap.get('list'));
        }

       if (exceptionList.size() > 0) {
          outMap.put('exceptionList', exceptionList);
          outMap.put('error', 'Error en la conversión');
      }

       return outMap;
    }

    public static Map<String, Object> DMT_convertProductListSanctions(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {

        List<Object> originalList;
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();
        List<Object> convertedList = new List<Object>();
        Boolean wasOriginallyASingleObject = false; // Flag para recordar la estructura original

        try {
        
            Object rawData = inputMap.get('list');

            if (rawData == null) {
                throw new DTM_Currency_Exception('No se encontró el parámetro "list" en el inputMap.');
            }

            originalList = new List<Object>();

            // Si 'list' es un objeto, lo trata como una lista de uno.
            if (rawData instanceof List<Object>) {
                originalList = (List<Object>) rawData;
            } else if (rawData instanceof Map<String, Object>) {
                originalList.add((Map<String, Object>) rawData);
                wasOriginallyASingleObject = true;
            } else {
                throw new DTM_Currency_Exception('El parámetro "list" no tiene un formato válido (debe ser lista o mapa).');
            }

            // Configuración desde metadata (sin cambios)
            Map<String, Map<String, Object>> DMT_Currency_Factors = new Map<String, Map<String, Object>>();
        
            for (DMT_Currency_Conversion__mdt mdt : [
                SELECT CurrencyIsoCode__c, Conversion_Factor__c, Currency_Label__c
                FROM DMT_Currency_Conversion__mdt
            ]) {
                DMT_Currency_Factors.put(mdt.CurrencyIsoCode__c, new Map<String, Object>{
                    'Conversion_Factor__c' => mdt.Conversion_Factor__c,
                    'Currency_Label__c' => mdt.Currency_Label__c
                });
            }

            // Iterar sobre la lista
            for (Object rawItem : originalList) {
            
                if (!(rawItem instanceof Map<String, Object>)) continue;

                // Crear una copia del objeto para modificarla
                Map<String, Object> item = new Map<String, Object>((Map<String, Object>) rawItem);

                //Acceder a los campos
                Decimal amount = item.containsKey('amount') ? (Decimal) item.get('amount') : null;
                String currencyCode = item.containsKey('CurrencyIsoCode') ? String.valueOf(item.get('CurrencyIsoCode')) : null;
                String lineRiskId = item.containsKey('lineRisk') ? String.valueOf(item.get('lineRisk')) : null;

                if (amount != null && currencyCode != null && lineRiskId != null) {
                    Map<String, Object> inputMapProduct = new Map<String, Object>{
                        'recordId' => lineRiskId,
                        'amount' => amount,
                        'currency' => currencyCode,
                        'action' => 'output'
                    };

                    Map<String, Object> outMapProduct = new Map<String, Object>();
                    Map<String, Object> optionsProduct = new Map<String, Object>();

                    DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMapProduct, outMapProduct, optionsProduct);

                    //Actualizar directamente el objeto 'item'
                    if (outMapProduct.containsKey('amount')) {
                        Decimal convertedAmount = (Decimal) outMapProduct.get('amount');
                        item.put('amount', convertedAmount);
                    }

                    if (DMT_Currency_Factors.containsKey(currencyCode)) {
                        Map<String, Object> conversionInfo = DMT_Currency_Factors.get(currencyCode);
                        String currencyLabel = String.isBlank((String)conversionInfo.get('Currency_Label__c')) ? '' : (String)conversionInfo.get('Currency_Label__c');
                        item.put('currencyLabel', currencyLabel);
                    }
            }

            convertedList.add(item);
        }

        //Devolver el resultado bajo la clave 'list', respetando si era un objeto o una lista.
        if (wasOriginallyASingleObject && !convertedList.isEmpty()) {
            // Si originalmente era un objeto, devolvemos solo el primer (y único) objeto de la lista.
            outMap.put('list', convertedList[0]);
        } else {
            // Si originalmente era una lista, devolvemos la lista completa.
            outMap.put('list', convertedList);
        }

    } catch (Exception e) {
        DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Currency_Conversion_Utils', 'convertProductListSanctions', 'DMT', '');
        exceptionList.add(dmtEcx);
        // En caso de error, devolver el mapa original sin modificar
        outMap.putAll(inputMap);
    }

    if (exceptionList.size() > 0) {
        outMap.put('exceptionList', exceptionList);
        outMap.put('error', 'Error en la conversión');
    }

        return outMap;
    }

    public class ProductWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String name;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public String currencyLabel;
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public String line;
        @AuraEnabled public Decimal amount;
    }

/**
* @Description Excepción personalizada utilizada dentro de la clase DMT_Currency_Conversion_Utils
*              para señalar errores específicos relacionados con la conversión de divisas,
*              como parámetros faltantes o inválidos.
*/
    public virtual class DTM_Currency_Exception extends Exception {}
}