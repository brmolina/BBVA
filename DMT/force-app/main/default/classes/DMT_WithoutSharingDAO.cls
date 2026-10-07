/**
 * @description       : Class for execute DMLs or SOQL without sharing restrictions.
 * @author            : BBVA DMT
 * @last modified on  : 27-11-2024
 * @last modified by  : BBVA DMT
**/
public without sharing class DMT_WithoutSharingDAO {

    /**
    * @description 
    * @author BBVA DMT | 27-11-2024 
    * @param so 
    **/
    public static void insertRecord(sObject so){
        insertRecords(new sObject[]{so});
    }

    /**
    * @description 
    * @author BBVA DMT | 27-11-2024 
    * @param soList 
    **/
    public static void insertRecords(sObject[] soList){
        try {

            String sObjectType = soList[0].getSObjectType().getDescribe().getName();
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
            if (!describeResult.isCreateable()) {
                return; // Salir si el usuario no tiene permisos de creación
            }

            Database.SaveResult[] saveResults = Database.insert(soList, false); // 'false' insert with errors
        } catch (Exception e) {
            // Exceptions when try insert
            System.debug('Error on insert sObjects: ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_WithoutSharingDAO', 'insertRecords', 'DMT', '');
        }
    }

    /**
    * @description 
    * @author BBVA DMT | 27-11-2024 
    * @param query Use String.escapeSingleQuotes() for variables in the where params
    * @return sObject[] 
    **/
    public static sObject[] query(String query, String sObjectTypeQuery){
        if (String.isEmpty(query)) {
            return new sObject[0];
        }

        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectTypeQuery).getDescribe();

        if (!describeResult.isQueryable()) {
            return new sObject[0]; // Retornar una lista vacía si no tiene permisos de lectura
        }

        try {
            return Database.query(String.escapeSingleQuotes(query).replaceAll('\\\\', ''));

        } catch (Exception e) {

            System.debug('Error SOQL: ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_WithoutSharingDAO', 'query', 'DMT', '');
            return new sObject[0];
        }
    }

    public static void updateRecord(sObject so){
        updateRecords(new sObject[]{so});
    }

    /**
    * @description 
    * @author BBVA DMT | 27-11-2024 
    * @param soList 
    **/
    public static void updateRecords(sObject[] soList){
        try {

            String sObjectType = soList[0].getSObjectType().getDescribe().getName();
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
            if (!describeResult.isUpdateable()) {
                return; // Salir si el usuario no tiene permisos de creación
            }

            Database.SaveResult[] saveResults = Database.update(soList, false); // 'false' insert with errors
        } catch (Exception e) {
            // Exceptions when try insert
            System.debug('Error on insert sObjects: ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_WithoutSharingDAO', 'updateRecords', 'DMT', '');
        }
    }

    /**
    * @description AuraEnabled wrapper to delete a single record by Id from LWC without sharing restrictions.
    * @author BBVA DMT
    * @param recordId Id of the record to delete
    **/
    @AuraEnabled
    public static void deleteRecordById(Id recordId){
        deleteRecords(new sObject[]{ recordId.getSObjectType().newSObject(recordId) });
    }

    /**
    * @description 
    * @author BBVA DMT
    * @param so 
    **/
    public static void deleteRecord(sObject so){
        deleteRecords(new sObject[]{ so });
    }

    /**
    * @description 
    * @author BBVA DMT
    * @param soList 
    **/
    public static void deleteRecords(sObject[] soList){
        try {
            String sObjectType = soList[0].getSObjectType().getDescribe().getName();
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectType).getDescribe();
            if (!describeResult.isDeletable()) {
                return; // Salir si el usuario no tiene permisos de borrado
            }
            Database.DeleteResult[] deleteResults = Database.delete(soList, false);
        } catch (Exception e) {
            System.debug('Error on delete sObjects: ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_WithoutSharingDAO', 'deleteRecords', 'DMT', '');
        }
    }


}