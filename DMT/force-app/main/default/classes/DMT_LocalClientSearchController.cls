public with sharing class DMT_LocalClientSearchController {

    @AuraEnabled(cacheable=true)
    public static List<Account> searchLocalClients(String searchTerm, String entityId) {
        if (String.isBlank(searchTerm)) return new List<Account>();
        
        Boolean noEntity = String.isBlank(entityId) 
            || entityId == 'null' 
            || entityId == 'undefined';

        String sosl = String.escapeSingleQuotes(searchTerm) + '*';
        List<List<SObject>> results = Search.query(
            'FIND :sosl IN ALL FIELDS RETURNING Account(Id, Name, g_customer_id__c, DES_Tax_Identification_Number__c LIMIT 20)'
        );
        List<Account> accounts = (List<Account>) results[0];

        if (noEntity) {
            return accounts;
        }

        // Filter by entityId prefix in Apex (encrypted fields cannot use SOQL LIKE)
        String prefix = entityId.toLowerCase();
        List<Account> filtered = new List<Account>();
        for (Account acc : accounts) {
            if (acc.g_customer_id__c != null && acc.g_customer_id__c.toLowerCase().startsWith(prefix)) {
                filtered.add(acc);
            }
        }
        return filtered;
    }

    @AuraEnabled(cacheable=true)
    public static Account getLocalClientById(String recordId) {
        if (String.isBlank(recordId) || recordId == 'null' || recordId == 'undefined') {
            return null;
        }

        List<Account> records = [
            SELECT Id, Name, g_customer_id__c, DES_Tax_Identification_Number__c
            FROM Account
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }
}