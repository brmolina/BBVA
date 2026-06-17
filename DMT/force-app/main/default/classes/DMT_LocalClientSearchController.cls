public with sharing class DMT_LocalClientSearchController {

    @AuraEnabled(cacheable=true)
    public static List<Local_Client__c> searchLocalClients(String searchTerm, String entityId) {
        String search = '%' + searchTerm + '%';
        
        Boolean noEntity = String.isBlank(entityId) 
            || entityId == 'null' 
            || entityId == 'undefined';

        if (noEntity) {
            return [
                SELECT Id, Name, Alpha_code__c, Cib_Client__r.DES_ID_Fiscal__c
                FROM Local_Client__c
                WHERE (
                    Name LIKE :search
                    OR Alpha_code__c LIKE :search
                    OR Cib_Client__r.DES_ID_Fiscal__c LIKE :search
                )
                ORDER BY Name
                LIMIT 20
            ];
        }

        String entitySearch = '%' + entityId + '%';
        return [
            SELECT Id, Name, Alpha_code__c, Cib_Client__r.DES_ID_Fiscal__c
            FROM Local_Client__c
            WHERE Alpha_code__c LIKE :entitySearch
            AND (
                Name LIKE :search
                OR Alpha_code__c LIKE :search
                OR Cib_Client__r.DES_ID_Fiscal__c LIKE :search
            )
            ORDER BY Name
            LIMIT 20
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Local_Client__c getLocalClientById(String recordId) {
        if (String.isBlank(recordId) || recordId == 'null' || recordId == 'undefined') {
            return null;
        }

        List<Local_Client__c> records = [
            SELECT Id, Name, Alpha_code__c, Cib_Client__r.DES_ID_Fiscal__c
            FROM Local_Client__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }
}