public with sharing class DMT_Rules_Feature {


    @AuraEnabled
    public static String getAllsValidate(String lineId, String opptyId, List<String> featureType) {

        SObject objectRecord;

        if(!String.isEmpty(opptyId))
        {
            objectRecord = DMT_Rules_Feature_Selector.getOpportunity(opptyId);
        }
        else if(!String.isEmpty(lineId))
        {
            objectRecord = DMT_Rules_Feature_Selector.getLine(lineId);
        }

        Map<String, Map<String,Object>> allValidates = new Map<String, Map<String,Object>>();
        List<String> featuresValidateList = new List<String>();
        List<String> capabilityValidatesLst = new List<String>();

        Map<String, Map<String,Object>> featuresValidates = checkValidates(objectRecord,featureType,'Feature');
        Map<String, Map<String,Object>> workflowValidates = new Map<String, Map<String,Object>>();
        Map<String, Map<String,Object>> capabilityValidates = new Map<String, Map<String,Object>>();

        for(String f : featuresValidates.keySet())
        {
            if(((Map<String,Object>)featuresValidates.get(f)).get('isValid') == true)
            {
                featuresValidateList.add(f);
            }
        }

        if(!featuresValidateList.isEmpty())
        {
            capabilityValidates = checkValidates(objectRecord, featuresValidateList,'Capability'); 

            for(String f : capabilityValidates.keySet())
            {
                if(((Map<String,Object>)capabilityValidates.get(f)).get('isValid') == true)
                {
                    capabilityValidatesLst.add(f);
                }
            }

            if(!capabilityValidatesLst.isEmpty()) {
                workflowValidates = checkValidates(objectRecord, capabilityValidatesLst,'Workflow');    
            }
        }

        for(String f : featureType)
        {
            Map<String,Object> features = new Map<String,Object>();
            features.put('feature', featuresValidates.get(f));
            features.put('capability', capabilityValidates.get(f));
            features.put('workflow', workflowValidates.get(f));


            allValidates.put(f, features);
        }

        return JSON.serialize(allValidates);
    }

    public static Map<String, Map<String,Object>> checkValidates(SObject objectRecord, List<String> featureType,String validateType) {

        List<DMT_Fuature_Rule__c> featureRulesList = DMT_Rules_Feature_Selector.getFeatureRules(featureType,validateType);
        return isNullFieldLine(objectRecord,featureRulesList);    
    }

    public static Map<String, Map<String,Object>> isNullFieldLine(SObject objectRecord, List<DMT_Fuature_Rule__c> featureRulesList) {

        Map<String, Map<String,Object>> mapFeatureResult = new Map<String, Map<String,Object>>();

        for (DMT_Fuature_Rule__c featureRule : featureRulesList) {

            Map<String,Object> result; 

            if(mapFeatureResult.containsKey(featureRule.DMT_Feature_Type__c))
            {
                result = mapFeatureResult.get(featureRule.DMT_Feature_Type__c);
            }
            else
            {
                result = new Map<String,Object>(); 
                result.put('isValid',true);
            }

            Object value = objectRecord.get(featureRule.DMT_Field__c);

            if(featureRule.DMT_Is_Required_Field__c && value == null) {
                result.put('isValid',false);
                result.put('message',featureRule.dmt_message__c);
            }

            mapFeatureResult.put(featureRule.DMT_Feature_Type__c, result);
        }

        return mapFeatureResult;
    }
}