public with sharing class DMT_Client_Selector {
    
    @AuraEnabled
    public static Account getStructureTypeByGroupCode(String groupCode) {
      
        return [SELECT Id, Name, DES_Structure_Type__c FROM Account WHERE DES_Group_Code__c =: groupCode WITH USER_MODE LIMIT 1 ];
    }

    @AuraEnabled
    public static Account getAccountById(String accountId) {
        return [SELECT Id, Name, DES_Structure_Type__c, RecordType.Id, DES_Group_Code__c FROM Account WHERE Id =: accountId WITH USER_MODE LIMIT 1 ];
    }
    
    @AuraEnabled
    public static List<Account> searchClient(String searchTerm) {
        if(String.isBlank(searchTerm)) {
            return new List<Account>();
        }
        String searchClientClone = searchTerm + '*';
        String searchQuery = 'FIND :searchClientClone IN ALL FIELDS RETURNING Account(Id, Name, DES_Group_Code__c)';
        List<List<SObject>> searchResults = search.query(searchQuery);
        List<Account> accounts = (List<Account>) searchResults[0];
        return accounts;      
    }

    public static String getAccountRecordCode(String accountId){ // CIBGLOBALD-2119
        String recordCode = '';
        Account acc = [SELECT Id, Name, DES_Group_Code__c, DES_Main_Parent__c, DES_Main_Parent__r.Name, Client_STAR_ID__c, DES_Client_Type__c, DES_Tax_Identification_Number__c, Group_Code_EGS__c, DES_Structure_Type__c,
                    /* Child Local Client */
                    (
                        SELECT Id, Alpha_code__c FROM Local_Clients__r LIMIT 1
                    )
                FROM Account
                WHERE Id = :accountId
                WITH USER_MODE LIMIT 1];

        if(String.isNotBlank(acc.DES_Group_Code__c)){
            recordCode = acc.DES_Group_Code__c;
        } else {
            recordCode = acc.Local_Clients__r[0].Alpha_code__c;
        }

        return recordCode;
    }
}