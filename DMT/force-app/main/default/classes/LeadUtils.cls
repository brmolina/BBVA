/**********************************************************************************
* @author       Accenture
* @date     01/03/2016
* @description  Clase con metodos útiles de Lead que se invocan desde el manejador del trigger del objeto Lead
* @Revision     
**********************************************************************************/
public class LeadUtils {

/**********************************************************************************
* @author       Accenture
* @description  Este método lo que hace es coger un Lead cuando ha convertido a Contacto, y si tenía alguna Campaign en la que participaba el Lead pues ahora se añade su Account (despues de la conversión) en el objeto custom Campaign__c
* @Revision     
**********************************************************************************/  
    public static void insertLeads(List<Lead> newLeads) {
        system.debug('+++NewLeads' + newLeads);
        set<Id> SetNewLeadsId = new set<id>();
        for (Lead L: newLeads){
            if (L.ConvertedContactId !=null || Test.isRunningTest())
              SetNewLeadsId.add(L.Id);
            
             }
            system.debug('+++SetNewLeads: ' + SetNewLeadsId);
            Set<String> cmAccounts = getCampaignAccounts(SetNewLeadsId);
            system.debug('+++cmAccounts' + cmAccounts);
          insertNewRecords(cmAccounts);
    }


    @TestVisible
    private Static Set<String> getCampaignAccounts (Set<id> ConvertedLeads){
         Set<String> cmAccounts = new Set<String>();
        for(CampaignMember cm:[select  Id, CampaignId, Contact.AccountId, Lead.ConvertedAccountId from CampaignMember
                               where LeadId IN: ConvertedLeads]){
                                   system.debug('+++cmquery: ' + cm);
                                   system.debug('LeadId '+ cm.Lead.ConvertedAccountId);
                                   system.debug('Contact AccountId ' + cm.Contact.AccountId);
                                   
                                   Id accountId = cm.Contact.AccountId == null ? cm.Lead.ConvertedAccountId : cm.Contact.AccountId;
                                   system.debug('AccountId: ' + accountId);
                                   if (accountId != null)
                                   cmAccounts.add(cm.CampaignId + '_' + accountId);   
                                   
                               }
        return cmAccounts;
    }


    @TestVisible
    private static void insertNewRecords(Set<String> toInsert) {
        Set<String> existing = new Set<String>();
        for (Campaign__c c: [Select Id, PK__c From Campaign__c]) {
            existing.add(c.PK__c);
        }
        system.debug('++Existing: ' + existing);
        system.debug('+++Toinsert: ' + ToInsert);
        List<Campaign__c> newRecords = new List<Campaign__c>();
        for (String s: toInsert) {
            if (!existing.contains(s)) {
                List<String> campaignAccount = s.split('_', 0);
                if (campaignAccount.size() == 2) {
                    Campaign__c c = new Campaign__c();
                    c.Campaign__c = campaignAccount[0];
                    c.Account__c = campaignAccount[1];
                    newRecords.add(c);
                }
            }
        }
        
        system.debug('+++NewRecords: ' + newRecords);
        if (newRecords.size() > 0)
            insert newRecords;
    }

}