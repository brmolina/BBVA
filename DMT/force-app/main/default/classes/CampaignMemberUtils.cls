public with sharing class CampaignMemberUtils {
    
    public static void insertCampaignMembers(List<CampaignMember> newCMs) {
        System.debug('+++InsertCampaignMembers, newCMS: ' + newCMs);
        Set<String> cmAccounts = getCampaignAccounts(newCMs);
        System.debug('+++InsertCampaignMembers, cmAccounts: ' + cmAccounts);
        insertNewRecords(cmAccounts);
    }
    
    public static void deleteCampaignMembers(List<CampaignMember> oldCMs) {
        Set<String> toDelete = getCampaignAccounts(oldCMs);
        
        Set<Id> campaigns = new Set<Id>();
        for (CampaignMember cm: oldCMs) {
            campaigns.add(cm.CampaignId);
        }
        
        Set<String> toDeleteFiltered = new Set<String>();
        for (AggregateResult ar: [
            Select count(Id) c, CampaignId, Contact.AccountId, Lead.ConvertedAccountId
            From CampaignMember 
            Where CampaignId In :campaigns
            Group By CampaignId, Contact.AccountId, Lead.ConvertedAccountId
        ]) {
            Integer counter = (Integer) ar.get('c');
            String accountId = ar.get('AccountId') == null ? ((String) ar.get('ConvertedAccountId')) : ((String) ar.get('AccountId'));
                
                String PK = ((String) ar.get('CampaignId')) + '_' + accountId;
            
            if (counter == 1 && toDelete.contains(PK)) {
                toDeleteFiltered.add(PK);
            }
        }
        
        List<Campaign__c> oldRecords = [Select Id From Campaign__c Where PK__c In :toDeleteFiltered];
        if (oldRecords.size() > 0)
            delete oldRecords;
    }
    
    private static Set<String> getCampaignAccounts(List<CampaignMember> cms) {
        Set<String> cmAccounts = new Set<String>();
        for (CampaignMember cm: [
            Select Id, CampaignId, Contact.AccountId, Lead.ConvertedAccountId
            From CampaignMember
            Where Id In :cms
        ]) {
            system.debug ('+++QueryCM' + cm);
            Id accountId = cm.Contact.AccountId == null ? cm.Lead.ConvertedAccountId : cm.Contact.AccountId;
            system.debug('LeadId '+ cm.Lead.ConvertedAccountId);
            system.debug('Contact AccountId ' + cm.Contact.AccountId);
            system.debug('AccountId: ' + accountId);
            if (accountId != null)
                cmAccounts.add(cm.CampaignId + '_' + accountId);       
        }
        system.debug('+++getCampaignAccount: ' + cmAccounts);
        return cmAccounts;
    }
    @future
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