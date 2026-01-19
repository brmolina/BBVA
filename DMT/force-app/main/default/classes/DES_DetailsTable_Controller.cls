/*
	* @author Global Desktop
	* @Description DES_DetailsTable_Controller class
	*/
global with sharing class DES_DetailsTable_Controller {

	/*
	* @author Global Desktop
	* @Description devuelveo un string con un JSON
	*/
    @AuraEnabled
    global static String getTableJSON(String recordId, String objectName, String fieldsToDisplay, String country){
        List<String> fieldLabels = new List<String>();
        List<String> isAccessible = new List<String>();
        List<String> stringList = new List<String>();
        List<childFieldDescription> childFieldDescriptionList = new List<childFieldDescription>();

        Map<String, String> labelMap = new Map<String, String>();

        //Get Sobjects and get the Child objects of component record
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SobjectType oType = globalDescribe.get(objectName);
        Schema.DescribeSObjectResult objectDescribe = oType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();

        Final List<String> userFields = fieldsToDisplay.split(',');
        String selectFields = '';
        // validate FLS
        for (String fieldName: userFields){
            System.debug(fieldName);
            if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
                isAccessible.add(fieldName);
            } else {
                System.debug('This user does not have access to the field');
            }
            String fieldNameFix = String.escapeSingleQuotes(fieldName);
            if(fieldMap.get(fieldNameFix).getDescribe().getType() == Schema.DisplayType.CURRENCY) {
                System.debug('Type '+ fieldMap.get(fieldNameFix).getDescribe().getType());
                System.debug('field '+ fieldName);
                fieldNameFix = 'convertCurrency(' + fieldNameFix + ')';
                System.debug('fieldNameFix '+ fieldNameFix);
            }
            selectFields += fieldNameFix + ',';
        }
        if(selectFields != '' ) {
            System.debug('selectFields con coma '+ selectFields);
            selectFields = selectFields.removeEnd(',');
            System.debug('selectFields fixed last csemicolon'+ selectFields);
        }


        Final String recordIdEscaped = String.escapeSingleQuotes(recordId);
        Final String soql = 'SELECT CurrencyIsoCode, id, ' + selectFields + ' FROM ' + objectName + ' WHERE id=:recordIdEscaped';

        System.debug('soql ' + soql);
        System.debug('isAccessible ' + isAccessible);

        Final List<SObject> queryResult = Database.query(soql);//NOSONAR

        if(queryResult.isEmpty()){
            System.debug('::::lista vacia return null');
            return null;
        }

        if(isAccessible != null && !isAccessible.isEmpty()) {
            for (String fieldName : isAccessible){
                fieldLabels.add(fieldMap.get(fieldName).getDescribe().getLabel()); //It provides to get the object fields label.
            }

            for (String fieldName : isAccessible) {
                for (sObject sObj : queryResult) {
                    String objectId = String.valueOf(sObj.get(String.valueOf('ID')));
                    String objectFieldName = fieldName;
                    String objectFieldType = String.valueOf(fieldMap.get(fieldName).getDescribe().getType());

                    String objectFieldValue = String.valueOf(sObj.get(String.valueOf(fieldName)));
                    childFieldDescriptionList.add(new childFieldDescription(objectId,objectFieldName,objectFieldType,objectFieldValue));
                    System.debug(childFieldDescriptionList);
                }
            }
        }

        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        gen.writeFieldName('ParentRecords');
        gen.writeStartObject();
        gen.writeObjectField('ParentRecord', queryResult);
        gen.writeEndObject();
        gen.writeFieldName('fLabelstList');
        gen.writeStartObject();
        gen.writeObjectField('fieldLabels', fieldLabels);
        gen.writeEndObject();
        gen.writeFieldName('childFieldDescriptions');
        gen.writeStartObject();
        gen.writeObjectField('childFieldDescriptionList', childFieldDescriptionList);
        gen.writeEndObject();
        gen.writeEndObject();

        // Get the JSON string.
        String pretty = gen.getAsString();
        System.debug(pretty);


        return pretty;
    }

    /*
	* @author Global Desktop
	* @Description obtiene los revenues
	*/
    @AuraEnabled
    global static Account getRevenuesData(String recordId, String objectName, String country){
        Account acc = new Account();
        if(objectName == 'Account'){
            acc = [SELECT id, convertCurrency(gf_ibf_previous_revenue_amount__c), convertCurrency(gm_previous_revenue_amount__c),
                    convertCurrency(gtb_previous_revenue_amount__c), convertCurrency(gf_ibf_cyr_revenue_amount__c),
                    convertCurrency(gm_revenue_cyr_amount__c), convertCurrency(gtb_revenue_cyr_amount__c)
                    FROM Account
                    WHERE id = :recordId
                    LIMIT 1];
            System.debug(':::acc: ' + acc);
        }
        return acc;
    }

    /**
     * @description Wrapper Class to store the Child object field descriptions
     **/
    private class childFieldDescription {
        String recid;
        String fieldName;
        String fieldType;
        String fieldValue;

        /**
         * @description Constructor of the wrapper
         * @param rId the record Id
         * @param fNa the field Name
         * @param fTy the field Type
         * @param fVa the field Value
         **/
        public childFieldDescription(String rID, String fNa, String fTy, String fVa) {
            recid = rID;
            fieldName = fNa;
            fieldType = fTy;
            fieldValue = fVa;
        }

    }
}