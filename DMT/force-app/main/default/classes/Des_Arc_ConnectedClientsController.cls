/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-31-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('sf:TooManyMethods,PMD.ExcessivePublicCount,PMD.ExcessiveParameterList')
global with sharing class Des_Arc_ConnectedClientsController {
    
  /**
  * --------------------------------------------------------------------------------------
  * @description Checks Local Client of Client.
  * @param Record of the Account.
  * @return Returns a String.
  **/
  @AuraEnabled
  public static String getAccountHasAnalysis(String account) {
    final List<dwp_acmh__GBL_Account_Relationship__c> lstAccChild = [SELECT Id, dwp_acmh__Parent_Account__c, dwp_acmh__Child_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Vision__c = 'Riesgos' AND 
                                                                      dwp_acmh__Parent_Account__c = :account AND dwp_acmh__Child_Account__r.account_client__c = 's' and DES_Main_Parent__c = 'S' AND dwp_acmh__Child_Account__r.business_group_header_type__c = true];
    if(lstAccChild != null && !lstAccChild.isEmpty()){
      final List <arce__Account_has_Analysis__c> accHasList = [SELECT Id, arce__Customer__c, arce__Analysis__c, CreatedDate from arce__Account_has_Analysis__c where arce__Customer__c =: lstAccChild[0].dwp_acmh__Child_Account__c ORDER by CreatedDate DESC limit 1];
      System.debug('REVISAR AHAS ' + accHasList);
      if(accHasList != null && !accHasList.isEmpty()){
          return accHasList[0].Id;
      }
      else{
          return '';
      }
    }else{
        return '';
    }
  }

}