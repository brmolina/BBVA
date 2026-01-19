public with sharing class OPS_VE_OpportunityMethods {
	@InvocableMethod
    public static void setPrivateOpp(List<Opportunity> opps) {
        Opportunity opp = opps[0];
        If(opp.AccountId != null) {
            Account acc = [select Id,DES_Country_Client__c from Account where Id = :opp.AccountId limit 1][0];
            if(acc.DES_Country_Client__c  == 'VE') {
                Opportunity aux = new Opportunity(Id = opp.Id, Private_opportunity__c = true);
                update aux;
            }
        }
    }
}