/**
*
* @author: Global Desktop
*/
public with sharing class NameRelatedListOver {
	
	//SINGLETON PATTERN
    private static NameRelatedListOver instance;
    public static NameRelatedListOver getInstance() {
        if (instance == null) instance = new NameRelatedListOver();
        return instance;
    }
    
	@AuraEnabled
	public static String checkNBC(String idVisit){
		try{
			String committeeVisit = 'false';
			List<dwp_kitv__Visit__c> listVisit = new List<dwp_kitv__Visit__c>([
													SELECT Committee_id__c
													FROM dwp_kitv__Visit__c
													WHERE Id =: idVisit AND Committee_id__c != null]);
			if(!listVisit.isEmpty()){ 
				committeeVisit = 'true';
				
			}
		
			return committeeVisit;

		}catch(Exception e){
			throw new AuraHandledException('de'+e);
		}
	}
}