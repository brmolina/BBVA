/**-------------------------------------------------------------------------------------------
* @Name     DMT_Opp_Currency_Conversion_Utils
* @Author   Juan Ramírez <jjuandavid.ramirez.jaramillo.contractor@bbva.com>
* @Date     Created: 2025-26-05
* --------------------------------------------------------------------------------------------
* @Description Clase que recibe datos y les aplica un factor de conversion de unidades
* por ejemplo puede recibir un monto de 10 y converirlo en 10'000.000 o recibir 10'000.000
* y convertirlo en 10 dependiendo del factor de conversion que se haya definido en el metadata
* DMT_Currency_Conversion__mdt, la llave es el code currency establecido en el objeto.    
* --------------------------------------------------------------------------------------------
*/
public with sharing class DMT_Opp_Currency_Conversion_Utils {
    
    public static final Map<String, String> localeFormats = new Map<String, String> {
        'en_US' => '#,###.00',
        'es_ES' => '#.###,00',
        'es_CO' => '#.###,00',
        'es_PE' => '#.###,00'
    };

    public static Map<String, Object> DMT_Array_Amount_Conversion(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

        try {
            // Obtener Record Id
            Id recordId = (inputMap.containsKey('recordId') && inputMap.get('recordId') instanceof Id) ? (Id) inputMap.get('recordId') : null;

            // Obtener action, esto determina si la conversion sera para grabar en la base de datos o consultar la base de datos
            String action = (inputMap.containsKey('action') && inputMap.get('action') instanceof String) ? (String) inputMap.get('action') : null;

            //Si alguna de estas dos variables no existe, se retorna un error
            if (recordId == null || String.isBlank(action)) {
                throw new DTM_Currency_Exception('recordId o action no están presentes o son inválidos, por lo tanto no se puede ejecutar la conversión');
            }

            // Buscamos el Currency adecuado. Puede estar en la Opp en CurrencyIsoCode o puede ser el elegido para los XSells de la Opp
            String strCurrencyToLook = '';
            Opportunity objOpp = [SELECT CurrencyIsoCode FROM Opportunity WHERE Id = :recordId LIMIT 1];

            List<DMT_X_Sell__c> listobjXSell = [SELECT DMT_Currency__c FROM DMT_X_Sell__c  WHERE Opportunity__c =: recordId LIMIT 1];
            
            DMT_X_Sell__c objXSell;
            
            if(!listobjXSell.isEmpty()){
                objXSell = listobjXSell.get(0);
            }

            // Si no se encuentra la Opp o CurrencyIsoCode es nulo, retornar error
            if (objOpp == null || objOpp.CurrencyIsoCode == null) {
                throw new DTM_Currency_Exception('No se encontró la oportunidad o el CurrencyIsoCode para el recordId por lo tanto no se puede ejecutar la conversión');
            }

            // Si existen XSell para la Opp, revisar si el Currency es diferente al de la Opp y usar ese
            if (objXsell != null && objXsell.DMT_Currency__c != null) {
                strCurrencyToLook = (objXsell.DMT_Currency__c != objOpp.CurrencyIsoCode) ? objXsell.DMT_Currency__c : objOpp.CurrencyIsoCode;
            } else {
                strCurrencyToLook = objOpp.CurrencyIsoCode;
            }

            // Buscar si existe algun factor de Conversion asociado a la currency
            List<DMT_Currency_Conversion__mdt> objConversionFactorList = [SELECT Conversion_Factor__c FROM DMT_Currency_Conversion__mdt WHERE CurrencyIsoCode__c = :strCurrencyToLook LIMIT 1];

            // Si no se encuentra la configuración de conversión, no ejecutar la conversión y no reportar log
            if (objConversionFactorList.isEmpty()) {
                outMap.put('error', 'No se encontró configuración en DMT_Currency_Conversion__mdt para esta linea');
                outMap.putAll(copyInputToOutput(inputMap));
                return outMap;
            }

            //Verifico si Conversion Factor contiene un valor numérico
            Decimal conversionFactor;
            conversionFactor = Decimal.valueOf(String.valueOf(objConversionFactorList[0].Conversion_Factor__c));
            
            // Recorro la estructura del JSON en busca de valores Enteros, Dobles o Decimales para convertir
            for (String key : inputMap.keySet()) {
                if (key == 'action' || key == 'recordId') {
                    outMap.put(key, inputMap.get(key));
                } else {
                    outMap.put(key, scaleNumbers(inputMap.get(key), conversionFactor));
                }
            }
        } catch (Exception e) {
            // Logging centralizado
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Opp_Currency_Conversion_Utils', 'DMT_Array_Amount_Conversion', 'DMT', '');
            exceptionList.add(dmtEcx);
            outMap.putAll(copyInputToOutput(inputMap));
        }

        if(exceptionList.size() > 0){
            outMap.put('exceptionList', exceptionList);
            outMap.put('error', 'Error en la conversión');
        }

        return outMap;
    }

    /*
    public static Map<String, Object> DMT_Test_Taxo(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

        try {
            // Obtener Record Id
            String strCatalogId = (inputMap.containsKey('catalogId') && inputMap.get('catalogId') instanceof String) ? (String) inputMap.get('catalogId') : null;
            String strCatalogInitialId = (inputMap.containsKey('catalogInitialId') && inputMap.get('catalogInitialId') instanceof String) ? (String) inputMap.get('catalogInitialId') : null;
            String strCatalogFinalId = (inputMap.containsKey('catalogFinalId') && inputMap.get('catalogFinalId') instanceof String) ? (String) inputMap.get('catalogFinalId') : null;

            // Obtener action, esto determina si la conversion sera para grabar en la base de datos o consultar la base de datos
            String action = (inputMap.containsKey('action') && inputMap.get('action') instanceof String) ? (String) inputMap.get('action') : null;

            //Si alguna de estas dos variables no existe, se retorna un error
            if (String.isBlank(strCatalogId)) {
                throw new DTM_Currency_Exception('recordId o action no están presentes o son inválidos, por lo tanto no se puede ejecutar la conversión');
            }

            List<DMT_Taxonomy_Relationship__c> lstTaxonomyRelationship = [SELECT Id, DMT_Id_Catalog_Initial__c, DMT_Id_Catalog_Final__c, DMT_Id_Catalog__c, DMT_Value_Catalog_Initial__c, DMT_Value_Catalog_Final__c, DMT_Initial_Taxonomy_Value__r.DMT_Name__c, DMT_Final_Taxonomy_Value__r.DMT_Name__c FROM  DMT_Taxonomy_Relationship__c WHERE DMT_Id_Catalog__c =: strCatalogId ORDER BY DMT_Value_Catalog_Final__c, DMT_Value_Catalog_Initial__c];
            if (lstTaxonomyRelationship.size() > 0) {
                Map<String,List<WrapperCatalogValues>> mapToReturn = new Map<String,List<WrapperCatalogValues>>();
                for (DMT_Taxonomy_Relationship__c objTaxonomyRelationship : lstTaxonomyRelationship) {
                    String strFinalCatalogId = objTaxonomyRelationship.DMT_Value_Catalog_Final__c;
                    WrapperCatalogValues objWrapperCatalogValue = new WrapperCatalogValues();
                    objWrapperCatalogValue.label = objTaxonomyRelationship.DMT_Initial_Taxonomy_Value__r.DMT_Name__c;
                    objWrapperCatalogValue.value = objTaxonomyRelationship.DMT_Value_Catalog_Initial__c;
                    List<WrapperCatalogValues> lstNewWrapperCatalogValue = new List<WrapperCatalogValues>();
                    if (mapToReturn.containsKey(strFinalCatalogId) == false) {
                        lstNewWrapperCatalogValue.add(objWrapperCatalogValue);
                        
                    } else {
                        List<WrapperCatalogValues> lstGetWrapperCatalogValues = mapToReturn.get(strFinalCatalogId);
                        lstGetWrapperCatalogValues.add(objWrapperCatalogValue);
                        lstNewWrapperCatalogValue = lstGetWrapperCatalogValues;
                    }
                    mapToReturn.put(strFinalCatalogId, lstNewWrapperCatalogValue);
                }
                system.debug(JSON.serializePretty(mapToReturn));
                outMap.put('taxOptions', 'funciona');
                return outMap;
            } else {
                outMap.put('exceptionList', exceptionList);
                outMap.put('error', 'Error en la conversión');
            }
        } catch (Exception e) {
            // Logging centralizado
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Opp_Currency_Conversion_Utils', 'DMT_Array_Amount_Conversion', 'DMT', '');
            exceptionList.add(dmtEcx);
            outMap.putAll(copyInputToOutput(inputMap));
        }

        if(exceptionList.size() > 0){
            outMap.put('exceptionList', exceptionList);
            outMap.put('error', 'Error en la conversión');
        }

        return outMap;
    }
    */

    public static Map<String, Object> getOpportunityProductsMinAndMaxDates(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

        try {
            // Obtener Record Id
            Id recordId = (inputMap.containsKey('recordId') && inputMap.get('recordId') instanceof Id) ? (Id) inputMap.get('recordId') : null;

            //Si alguna de estas dos variables no existe, se retorna un error
            if (recordId == null || String.isBlank(recordId)) {
                throw new DTM_Currency_Exception('recordId no está presentes o es inválido, por lo tanto no se puede ejecutar la operación');
            }

            List<OpportunityLineItem> lstOppLineItems = [SELECT Id, gf_initial_date__c, gf_maturity_date__c FROM OpportunityLineItem WHERE OpportunityId =: recordId];

            Date minInitialDate;
            Date maxMaturityDate;

            for (OpportunityLineItem item : lstOppLineItems) {
                if (item.gf_initial_date__c != null) {
                    if (minInitialDate == null || item.gf_initial_date__c < minInitialDate) {
                        minInitialDate = item.gf_initial_date__c;
                    }
                }

                if (item.gf_maturity_date__c != null) {
                    if (maxMaturityDate == null || item.gf_maturity_date__c > maxMaturityDate) {
                        maxMaturityDate = item.gf_maturity_date__c;
                    }
                }
            }

            // Añadir los valores calculados al outMap
            outMap.put('minInitialDate', minInitialDate);
            outMap.put('maxMaturityDate', maxMaturityDate);
        } catch (Exception e) {
            // Logging centralizado
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Opp_Currency_Conversion_Utils', 'DMT_Array_Amount_Conversion', 'DMT', '');
            exceptionList.add(dmtEcx);
            outMap.putAll(copyInputToOutput(inputMap));
        }

        if(exceptionList.size() > 0){
            outMap.put('exceptionList', exceptionList);
            outMap.put('error', 'Error en la conversión');
        }

        return outMap;
    }
    
    /*
    private Map<String, Object> getTaxonomyMap(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        String strCatalogId = (String) inputMap.get('catalogId');
        
        List<DMT_Taxonomy_Relationship__c> lstTaxonomyRelationship = [
            SELECT Id, DMT_Id_Catalog_Initial__c, DMT_Id_Catalog_Final__c, DMT_Id_Catalog__c, 
                DMT_Value_Catalog_Initial__c, DMT_Value_Catalog_Final__c, 
                DMT_Initial_Taxonomy_Value__r.DMT_Name__c, DMT_Final_Taxonomy_Value__r.DMT_Name__c
            FROM DMT_Taxonomy_Relationship__c 
            WHERE DMT_Id_Catalog__c = :strCatalogId 
            AND DMT_Value_Catalog_Final__c = 'M'
            ORDER BY DMT_Value_Catalog_Final__c, DMT_Value_Catalog_Initial__c
        ];

        if (!lstTaxonomyRelationship.isEmpty()) {
            Map<String, List<WrapperCatalogValues>> mapToReturn = new Map<String, List<WrapperCatalogValues>>();

            for (DMT_Taxonomy_Relationship__c obj : lstTaxonomyRelationship) {
                String key = obj.DMT_Value_Catalog_Final__c;
                WrapperCatalogValues wrapper = new WrapperCatalogValues();
                wrapper.label = obj.DMT_Initial_Taxonomy_Value__r.DMT_Name__c;
                wrapper.value = obj.DMT_Value_Catalog_Initial__c;

                if (!mapToReturn.containsKey(key)) {
                    mapToReturn.put(key, new List<WrapperCatalogValues>{wrapper});
                } else {
                    mapToReturn.get(key).add(wrapper);
                }
            }
            system.debug(JSON.serializePretty(mapToReturn));
            outMap.put('taxonomyMap', mapToReturn); // Add to outMap under a descriptive key
        }

        return outMap;
    }*/

    private static Map<String, Object> copyInputToOutput(Map<String, Object> inputMap) {
        Map<String, Object> result = new Map<String, Object>();
        for (String key : inputMap.keySet()) {
            if (key != 'recordId' && key != 'action') {
                result.put(key, inputMap.get(key));
            }
        }
        return result;
    }

    public static Object scaleNumbers(Object value, Decimal conversionFactor) {
        Boolean validFactor = (conversionFactor != null && conversionFactor != 0);

        if (value instanceof Map<String, Object>) {
            Map<String, Object> newMap = new Map<String, Object>();
            for (String key : ((Map<String, Object>)value).keySet()) {
                newMap.put(key, scaleNumbers(((Map<String, Object>)value).get(key), conversionFactor));
            }
            return newMap;

        } else if (value instanceof List<Object>) {
            List<Object> newList = new List<Object>();
            for (Object item : (List<Object>)value) {
                newList.add(scaleNumbers(item, conversionFactor));
            }
            return newList;

        } else if (value instanceof Integer && validFactor) {
            return ((Integer)value) / conversionFactor;

        } else if (value instanceof Decimal && validFactor) {
            return ((Decimal)value) / conversionFactor;

        } else if (value instanceof Double && validFactor) {
            return ((Double)value) / conversionFactor;

        } else {
            return value;
        }
    }

    public class WrapperCatalogValues {
        String label;
        String value;
    }

    public virtual class DTM_Currency_Exception extends Exception {}
}