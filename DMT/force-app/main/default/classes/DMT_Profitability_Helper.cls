public with sharing class DMT_Profitability_Helper {

    public static void callProfitabilityMatrixService(Map<String, Object> request, Map<String, Object> outMap) {
        HttpResponse response;
        String serviceName='DMT_ProfitabilityMatrix';
      
        response = DMT_HPG_Utils.callService_DMT(serviceName, request);

        if( (response.getStatusCode() == 200 || response.getStatusCode() == 201) ){
            System.debug('*** Response OK');
            String bodyResponse = response.getBody();
            outMap.put('result', true);
            outMap.put('bodyResponse', bodyResponse );
            System.debug(response);
        } else {
            
            String bodyResponse = response.getBody();
            Map<String,Object> errorResponse = ( Map<String,Object>)JSON.deserializeUntyped(bodyResponse);
            String errorMsg = errorResponse.get('message')!= null ? (String) errorResponse.get('message') : 'Unknown';
            System.debug('*** Response KO: '+bodyResponse);
            System.debug('*** Response: '+errorResponse);

            outMap.put('result', false);
            outMap.put('messageTitle', 'External service call failed');
            outMap.put('message', 'Error '+response.getStatusCode()+':\r\n '+errorMsg);
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<DMT_Taxonomy_Values__c> getTaxonomyValues() {

        // Query the DMT_Taxonomy_Values__c object to fetch the relevant data
        List<DMT_Taxonomy_Values__c> taxonomyValues = [
            SELECT gf_catalog_atrb_val1_name_c__c,DMT_Value__c, DMT_Name__c, DMT_Catalog__c
             FROM DMT_Taxonomy_Values__c WHERE DMT_Catalog__c ='C204' AND DMT_Active__c=true
        ];
        return taxonomyValues;
    }
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> callOrderCatalogs(List<Map<String, Object>> items) {
        List<Object> normalizedItems = new List<Object>();
        for (Map<String, Object> item : items) {
            Map<String, Object> normalized = new Map<String, Object>();
            normalized.put('label', item.get('label'));
            normalized.put('value', item.get('value'));
            normalized.put('orden', item.get('orden'));
            normalizedItems.add(normalized);
        }
        Map<String, Object> inputMap = new Map<String, Object>{
            'data' => normalizedItems
        };
        Map<String, Object> outMap = new Map<String, Object>();
        orderCatalogs(inputMap, outMap);
        return outMap;
    }

    public static void orderCatalogs(Map<String, Object> inputMap,  Map<String, Object> outMap) {
        List<Object> catalogList = new List<Object>();
        for(String catalogKey:inputMap.keySet()){
            if(inputMap.get(catalogKey) instanceof List<Object>){

                List<Object> catalogValues = (List<Object>)inputMap.get(catalogKey);
                System.debug('Mi lista de '+catalogKey+' con valores: '+catalogValues);

                // Convertir a lista de envoltorios ordenables
                List<OrderWrapper> wrappers = new List<OrderWrapper>();
                for (Object obj : catalogValues) {
                    wrappers.add(new OrderWrapper(obj));
                }
                wrappers.sort();

                // Volver a dejar solo los objetos originales, ya ordenados
                List<Object> sortedCatalogValues = new List<Object>();
                for (OrderWrapper w : wrappers) {
                    sortedCatalogValues.add(w.original);
                }
                outMap.put(catalogKey, sortedCatalogValues);
                System.debug('Mi lista de '+catalogKey+' ordenada: '+sortedCatalogValues);
            }
        }
    }

    public class OrderWrapper implements Comparable {
        protected Object original;
        protected Integer orden;

    public OrderWrapper(Object obj) {
        this.original = obj;
        Map<String, Object> mapObj = (Map<String, Object>)obj;
        this.orden = mapObj.containsKey('orden') && mapObj.get('orden') != null && String.valueOf(mapObj.get('orden')).isNumeric()
        ? Integer.valueOf(String.valueOf(mapObj.get('orden')))
        : 2147483647 ;
    }

    public Integer compareTo(Object other) {
        OrderWrapper o = (OrderWrapper)other;
        if (this.orden == o.orden) return 0;
        if (this.orden > o.orden) return 1;
        return -1;
    }
}

    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> calculateIsPercentageValue(String axisX, String axisY, String axisCentral) {
        Map<String, Boolean> result = new Map<String, Boolean>{ 'x' => false, 'y' => false, 'c' => false };
        // Build a set of non-blank axis names to query
        Set<String> axisNames = new Set<String>();
        if (!String.isBlank(axisX)) axisNames.add(axisX);
        if (!String.isBlank(axisY)) axisNames.add(axisY);
        if (!String.isBlank(axisCentral)) axisNames.add(axisCentral);

        if (axisNames.isEmpty()) return result;

        List<DMT_Profitability_Axis__c> axes = [
            SELECT gf_axis_data_type_desc__c, gf_percentage_1_sign_type__c
            FROM DMT_Profitability_Axis__c
            WHERE gf_axis_data_type_desc__c IN :axisNames
        ];

        for (DMT_Profitability_Axis__c a : axes) {
            if (a.gf_axis_data_type_desc__c == axisX) result.put('x', a.gf_percentage_1_sign_type__c);
            if (a.gf_axis_data_type_desc__c == axisY) result.put('y', a.gf_percentage_1_sign_type__c);
            if (a.gf_axis_data_type_desc__c == axisCentral) result.put('c', a.gf_percentage_1_sign_type__c);
        }
        return result;
    }

    /**
    * @description retrives Passport__c record by Opportunity Id to check is obsoleted
    * @author BBVA DMT | 16-10-2025 
    * @param oppId 
    * @return Passport__c 
    **/
    @AuraEnabled
    public static Passport__c getPassportByOpp(String oppId) {
        return DMT_Passport_Selector.passportByOppExtId(oppId);
    }
}