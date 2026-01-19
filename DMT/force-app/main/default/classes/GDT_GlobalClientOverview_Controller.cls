@SuppressWarnings('sf:TooManyMethods,PMD.ExcessivePublicCount,PMD.ExcessiveParameterList')
global with sharing class GDT_GlobalClientOverview_Controller {
	
    /**
  * --------------------------------------------------------------------------------------
  * @description Checks Local Client of Client and get last ARCE created.
  * @param Record of the Account.
  * @return Returns a String.
  **/
  @AuraEnabled
  public static String getAccountAnalysis(String account) {
      final List <Local_Client__c> lclList = [SELECT Id, Cib_Client__c  FROM Local_Client__c WHERE Cib_Client__c =: account LIMIT 1];
      final List <arce__Account_has_Analysis__c> accHasList = [SELECT Id, arce__Customer__c,  arce__Analysis__c, DES_Local_Client__c,  CreatedDate FROM arce__Account_has_Analysis__c 
          															WHERE arce__Customer__c =: account AND DES_Local_Client__c =: lclList[0].Id  order by CreatedDate desc LIMIT 1];
      if(accHasList != null && !accHasList.isEmpty()){
          return accHasList[0].arce__Analysis__c;
      }
      else{
          return '';
      }
  }
    
}