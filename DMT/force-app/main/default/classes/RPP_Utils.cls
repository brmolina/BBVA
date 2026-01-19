/**
* ____________________________________________________________________________
* Utils class for RPP Calculator Application
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-04-10
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class RPP_Utils {
    /**
    * @description Private constructor to avoid sonar err
    */
    @TestVisible
    public RPP_Utils() {}
    /**
    * @description method to invoke service
    * @param serviceName Service Name
    * @return HttpResponse HttpResponse
    */
    public static HttpResponse callWebService(String serviceName, Map<String,String> jsonInputMap) {
        HttpResponse response;
        final iaso__GBL_integration_service__mdt service = iaso__GBL_integration_service__mdt.getInstance(serviceName);
        if(Test.isRunningTest() || service.iaso__Retrieve_Mock_LTA__c)
        {
            response = getMock(serviceName);
        } else{
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, jsonInputMap);
        }
        return response;
    }
    /**
    * @description Retrieves mock configuration from IASO metadata
    * @param serviceName: Name of the metadata record
    * @param statusCode: Status code to add to response (If needed)
    * @return HttpResponse HttpResponse
    */
    public static HttpResponse getMock(String serviceName) {
        final iaso__GBL_integration_service__mdt service = [SELECT iaso__Mock_LTA__c, iaso__Http_Method__c FROM iaso__GBL_integration_service__mdt WHERE DeveloperName =:serviceName LIMIT 1];
        final HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type','application/json');
        response.setBody(service.iaso__Mock_LTA__c);
        response.setStatusCode(service.iaso__Http_Method__c == 'POST' ? 201 : 200);
        return response;
    }
    /**
    * @description Returns a map containing the label and API name for each field
    * @param objectName: Object API name
    * @return retMap Map with name and label
    */
    public static Map<String, String> getObjectFields(String objectName) {
        Map<String, String> fields = new Map<String, String>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType != null) {
            Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                fields.put(fieldName, fieldDescribe.getLabel());
            }
        }
        return fields;
    }
    /**
    * @description Returns picklist values
    * @param objectName : Object name
    * @param fieldName : Field name
    * @return retMap Picklist values
    */
    @AuraEnabled
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        List<Schema.PicklistEntry> picklistEntries = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();
        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            if (picklistEntry.isActive()) {
                picklistValues.add(picklistEntry.getValue());
            }
        }
        return picklistValues;
    }
    /**
    * @description Returns picklist values
    * @param objectName : Object name
    * @param fieldName : Field name
    * @return retMap Picklist values
    */
    @AuraEnabled
    public static List<PicklistValue_Wrapper> getPicklistData(String objectName, String fieldName) {
        List<PicklistValue_Wrapper> picklistDataList = new List<PicklistValue_Wrapper>();
        List<Schema.PicklistEntry> picklistEntries = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();
        PicklistValue_Wrapper picklistNone = new PicklistValue_Wrapper();
        picklistNone.label = '';
        picklistNone.value = '';
        picklistDataList.add(picklistNone);
        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            if (picklistEntry.isActive()) {
                PicklistValue_Wrapper picklistData = new PicklistValue_Wrapper();
                picklistData.label = picklistEntry.getLabel();
                picklistData.value = picklistEntry.getValue();
                picklistDataList.add(picklistData);
            }
        }
        return picklistDataList;
    }
    /**
    * @description Returns picklist values
    * @param objectName : Object name
    * @param fieldName : Field name
    * @return retMap Picklist values
    */
    @AuraEnabled
    public static Boolean checkPermissionSet(Id userid) {
        Boolean hasPermission = false;
        List<PermissionSetAssignment> psAssigmentList;
        psAssigmentList = new List<PermissionSetAssignment>();
        try {
            psAssigmentList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userid AND PermissionSetId IN (SELECT Id FROM PermissionSet WHERE Name = 'RPP_Calculator_Manage')];
            if(!psAssigmentList.isEmpty()) {
                hasPermission = true;
            }
        } catch(exception e) {
            System.debug(e);
        }
        return hasPermission;
      }
    /**
    * @description Wrapper for picklist values
    */
	public class PicklistValue_Wrapper {
		@AuraEnabled
		public String label {get; set;}
		@AuraEnabled
		public String value {get; set;}
	}
}