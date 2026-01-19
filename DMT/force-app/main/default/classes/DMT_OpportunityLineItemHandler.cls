public with sharing class DMT_OpportunityLineItemHandler implements Callable{

     public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

        private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        try {
            Map<String, Object> result;

            if(methodName == 'recalculatePriority') {
                String oppId=  String.valueOf(inputMap.get('oppId'));
                recalculatePriority(oppId);
            }
                
        } catch(exception e) {
            Boolean logged = false;
            logged = DES_Exception_Utils.logException(e,
                                                    'DES_Exception_Handler',
                                                    'invokeMethod',
                                                    'DMT',
                                                    '');
            outMap.put('error', true);
            outMap.put('errorMessage', e.getMessage());
        }
        return outMap;
    }


    public static void recalculatePriority(String opportunityId) {

        List<OpportunityLineItem> allLines = DMT_Opportunity_Selector.getAllOpportunityLineItems(opportunityId);

        Map<Id, List<OpportunityLineItem>> groupedByOpp = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : allLines) {
            if (!groupedByOpp.containsKey(oli.OpportunityId)) {
                groupedByOpp.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            groupedByOpp.get(oli.OpportunityId).add(oli);
        }

        List<OpportunityLineItem> updates = new List<OpportunityLineItem>();

        for (Id oppId : groupedByOpp.keySet()) {
            List<OpportunityLineItem> lineItems = groupedByOpp.get(oppId);
            Integer index = 1;

            for (OpportunityLineItem oli : lineItems) {

                // Conversión a formato '01', '02', ...
                String paddedValue = toPadded2(index);
                oli.gf_group_priority_opportunity_id__c = paddedValue;
                updates.add(oli);
                index++;
            }
        }

        if (!updates.isEmpty()) {
            try {
                update updates;
            } catch (DmlException e) {
                System.debug(' Error updating gf_group_priority_opportunity_id__c: ' + e.getMessage());
            }
        }
    }

    public static void handleAfterInsertOrUpdate(List<OpportunityLineItem> newRecords) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : newRecords) {
            if (oli.OpportunityId != null) {
                oppIds.add(oli.OpportunityId);
            }
        }

        OpportunityLineItem lastOppLineItem =
            DMT_Opportunity_Selector.getLastOppLineItem(oppIds);

        Integer currentMax;

        if (lastOppLineItem.gf_group_priority_opportunity_id__c != null) {
            try {
                currentMax = Integer.valueOf(lastOppLineItem.gf_group_priority_opportunity_id__c);
            } catch (Exception e) {
                currentMax = 0; 
            }
        } else {
            currentMax = 0;
        }

        Integer nextIndex = currentMax + 1;

            for (OpportunityLineItem oli2 : newRecords) {
                
                String paddedValue = toPadded2(nextIndex);
                oli2.gf_group_priority_opportunity_id__c = paddedValue;

            nextIndex++;
            }


        
    } 
    private static String toPadded2(Integer num) {
    if (num == null) return null;
    return (num < 10 ? '0' : '') + String.valueOf(num);
}


public static void calculateTenorYears(List<OpportunityLineItem> oliList) {
    
    for (OpportunityLineItem oli : oliList) {
        
        Date startDate = oli.gf_initial_date__c;
        Date endDate = oli.gf_maturity_date__c;

        if (startDate == null || endDate == null) {

            oli.DES_Tenor_years__c = null;

        }else{

            Integer diffDays = startDate.daysBetween(endDate);
            Decimal diffYears = Decimal.valueOf(diffDays) / 365;
            Integer roundedYears = (Integer)Math.round(diffYears);
            oli.DES_Tenor_years__c = roundedYears;

        }
    }
}

}