/*
*  Contabiliza las visitas totales de un account
*/
public without sharing class TotalAccountVisit {

    /*
    *  Este método se encarga de eliminar la visita que tiene relacionada la Denorm Account Visit
    */
    public static void denVisitAfterDenormDelete(Set<Id> setIdsAccount) {
        final List<Account> lAcc = [SELECT id, name, visit_current_year_number__c, (SELECT id FROM Denorm_Account_Visits__r WHERE DES_Start_Date__c = THIS_YEAR AND DES_Start_Date__c <= TODAY) FROM Account WHERE id = :setIdsAccount];
        for(Account acc : lAcc) {
            acc.visit_current_year_number__c = acc.Denorm_Account_Visits__r==null?0:acc.Denorm_Account_Visits__r.size();
        }
        update lAcc;
    }

    /*
    *  Este método se encarga de eliminar la visita que tiene relacionada la Denorm Account Visit
    */
    public static void denVisitAfterAccountDelete(Map<Id, Integer> accountNumber) {
  		final List<Account> accsUpdate = new List<Account>();
        final List<Account> accountList = new List <Account>([
    		SELECT Id, Name, visit_current_year_number__c
    		FROM Account
    		WHERE Id In :accountNumber.keySet()
    	]);

    	for (Account acc: accountList) {
    		system.debug('**acc.visit_current_year_number__c -> ' + acc.Name + ' ' + acc.visit_current_year_number__c);
    		acc.visit_current_year_number__c = acc.visit_current_year_number__c - accountNumber.get(acc.Id);
    		system.debug('**acc.visit_current_year_number__c -> ' + acc.Name + ' ' + acc.visit_current_year_number__c);
    		accsUpdate.add(acc);
    	}

    	if(!accsUpdate.isEmpty()) {
    		update accsUpdate;
    	}
    }
}