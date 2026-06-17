public with sharing class ONB_createGestorasController {
    
    static final String ONB_ACTIVITY_FUND = System.Label.ONB_ACTIVITY_FUND;
    static final String ONB_ACTIVITY_ASSET_MANAGER = System.Label.ONB_ACTIVITY_ASSET_MANAGER;
    static final String ONB_NEW_CLIENT_ONB_RTNAME = System.Label.ONB_NEW_CLIENT_ONB_RTNAME;

    @AuraEnabled
    public static List<Account> getGestorasByContrato(Id contratoMarcoId) {
        return [
            SELECT Id, Name, lei_id__c, Client_STAR_ID__c, SER_CClient__c
            FROM Account
            WHERE Id IN (
                SELECT ONB_Client__c FROM ONB_Master_Agreement__c WHERE ONB_Contrato__c = :contratoMarcoId AND ONB_Type__c = :ONB_ACTIVITY_ASSET_MANAGER
            )
        ];
    }
    
	@AuraEnabled
    public static Account createAccount(Id contratoMarcoId, String name, String clientType, Id parentId, String lei, String star, String codigoCliente) {
        Id rtId = [SELECT Id FROM RecordType WHERE sObjectType='Account' AND DeveloperName = :ONB_NEW_CLIENT_ONB_RTNAME].Id;
        
        Account acc = new Account(
            Name = name,
            RecordTypeId = rtId,
            ParentId = parentId,
            lei_id__c = lei,
			Client_STAR_ID__c = star,
            SER_CClient__c = codigoCliente,
            DES_Activity__c = clientType
        );
        
        insert acc;
        
        if(clientType == ONB_ACTIVITY_ASSET_MANAGER){
            ONB_Master_Agreement__c rel = new ONB_Master_Agreement__c(
                ONB_Contrato__c = contratoMarcoId,
                ONB_Client__c = acc.Id
            );
            insert rel;
        }
        
        return acc;
    }

    @AuraEnabled
    public static void asociarFondoGestoras(Id contratoId, List<Id> fondosId) {
        List<ONB_Master_Agreement__c> rels = new List<ONB_Master_Agreement__c>();
        
        for(Id fundId: fondosId){
            rels.add(new ONB_Master_Agreement__c(
                ONB_Contrato__c = contratoId,
                ONB_Client__c = fundId
            ));
        }
        insert rels;
    }
    
    @AuraEnabled
    public static List<Account> getFondosByGestoras(List<Id> gestoraIds, Id contratoMarcoId) {
        
        return [
            SELECT Id, Name, Parent.Name, lei_id__c, Client_STAR_ID__c, SER_CClient__c
            FROM Account
            WHERE DES_Activity__c = :ONB_ACTIVITY_FUND
            AND ParentId IN :gestoraIds
            AND Id NOT IN (SELECT ONB_Client__c FROM ONB_Master_Agreement__c WHERE ONB_Contrato__c = :contratoMarcoId AND ONB_Type__c = :ONB_ACTIVITY_FUND)
        ];
    }
    
}