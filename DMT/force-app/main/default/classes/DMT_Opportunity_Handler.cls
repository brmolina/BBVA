/**-------------------------------------------------------------------------------------------
* @Name     DMT_Opportunity_Handler
* @Author   Javier Portilla <javieralberto.portilla.contractor@bbva.com>
* @Date     Created: 2025-03-11
* --------------------------------------------------------------------------------------------
* @Description Callable class for Omnistudio
* --------------------------------------------------------------------------------------------
*/
global with sharing class DMT_Opportunity_Handler implements Callable {

    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            Map<String, Object> result;
            
            if(methodName == 'getCustomerHPGS') {
                result = DMT_HPG_Utils.getCustomerHPGS(inputMap,outMap,options);
            } else if (methodname == 'getMinAndMaxDates') {
                result = DMT_Opportunity_Utils.getOpportunityProductsMinAndMaxDates(inputMap,outMap,options);
            } else if (methodname == 'tenorsValidation') {
                System.debug('inputMap --> ' + json.serialize(inputMap));
                System.debug('outMap --> ' + outMap);
                System.debug('options --> ' + json.serialize(options));

                // Read tenors payload
                List<Object> rawTenors = (List<Object>) inputMap.get('myTenors');

                // Read anchors (could be null, '', 'undefined')
                Date initialDate  = safeParseDate(inputMap.get('gf_initial_date__c'));
                Date maturityDate = safeParseDate(inputMap.get('gf_maturity_date__c'));

                result = DMT_Opportunity_Utils.validateTenorsFromRaw(rawTenors, initialDate, maturityDate);

            } else if (methodname == 'validateRealGuaratorsFromRaw') {
                Object rawValue = inputMap.get('myRealGuarantees');
                List<Object> myRealGuarantees = new List<Object>();

                if (rawValue instanceof List<Object>) {
                    myRealGuarantees = (List<Object>) rawValue;
                } else if (rawValue != null) {
                    myRealGuarantees.add(rawValue);
                }
                result = DMT_Opportunity_Utils.validateRealGuaratorsFromRaw(myRealGuarantees);
            } else if (methodname == 'createProducts') {
                Object rawValue = inputMap.get('productsToCreate');
                List<Object> products;
                if (rawValue != null) {
                    Map<String, Object> productsToCreateMap = (Map<String, Object>) rawValue;
                    if (productsToCreateMap.containsKey('productToCreate')) {
                         products= (List<Object>) productsToCreateMap.get('productToCreate');
                    } 
                } 

                Object rawValueOppId = inputMap.get('oppId');
                result = DMT_Opportunity_Utils.createProductsOpportunity(products,rawValueOppId);

            } else if (methodName == 'getComparisonAccount') {
                result = DMT_Opportunity_Utils.getComparisonAccount(inputMap, outMap, options);

            }  
            else {
                throw new DTM_Currency_Exception('Metodo no definido');
            }
            
            if (result != null) {
                outMap.putAll(result);
            }
        } catch(exception e) {
            outMap.put('error', true);
            outMap.put('errorMessage', e.getMessage());
            List<DMT_AsyncPayload> batchPayloads = new List<DMT_AsyncPayload>();
            batchPayloads.add(new DMT_LogExceptionPayload(e.getMessage(), e.getStackTraceString(), e.getLineNumber(), e.getTypeName(), 'DES_Exception_Handler', 'invokeMethod', 'DMT', ''));
            Database.executeBatch(new DMT_AsyncBatchJob(batchPayloads), 1);
        }
        System.debug(' outMap final --> ' + JSON.serialize(outMap));
        return outMap;
    }

    private static Date safeParseDate(Object raw) {
        if (raw == null) {
            return null;
        }
        String stringValue = String.valueOf(raw).trim();
        if (stringValue == '' || stringValue.equalsIgnoreCase('undefined') || stringValue.equalsIgnoreCase('null')) {
            return null;
        }
        try {
            return Date.valueOf(stringValue);
        } catch (Exception e) {
            System.debug('safeParseDate() failed: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getWebLinkUrl(String recordDeveloperName) {
        // Fetch the metadata record from cache using its DeveloperName
        DMT_Web_Link__mdt webLinkConfig = DMT_Web_Link__mdt.getInstance(recordDeveloperName);

        if (webLinkConfig != null) {
            return webLinkConfig.url__c;
        }
        return null; // Return null if the record isn't found
    }

    @AuraEnabled(cacheable=true)
    public static AssociatedLineInfo getAssociatedSanctionLine(String opportunityExternalId) {
        if (String.isBlank(opportunityExternalId)) {
            return null;
        }

        Opportunity opportunityRecord = DMT_Opportunity_Selector.getOpportunityByExternalIdWithSanction(opportunityExternalId);

        if (opportunityRecord == null || opportunityRecord.DMT_Sanction__c == null) {
            return null;
        }

        return new AssociatedLineInfo(
            opportunityRecord.DMT_Sanction__c,
            opportunityRecord.DMT_Sanction__r.Name
        );
    }

    public class AssociatedLineInfo {
        @AuraEnabled public Id lineId { get; set; }
        @AuraEnabled public String lineLabel { get; set; }

        public AssociatedLineInfo(Id lineId, String lineLabel) {
            this.lineId = lineId;
            this.lineLabel = lineLabel;
        }
    }

    // Inner class para lanzar excepciones con mensaje personalizado en Apex
    public virtual class DTM_Currency_Exception extends Exception {}
}