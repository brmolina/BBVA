/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-17-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('sf:TooManyMethods,PMD.ExcessivePublicCount,PMD.ExcessiveParameterList')
global with sharing class Des_Arc_ExternalRating_Controller {
  
  /**
  * --------------------------------------------------------------------------------------
  * @description Checks Local Client of Client.
  * @param Record of the Account.
  * @return Returns a String.
  **/
  @AuraEnabled
  public static String getRatingSource(String account) {
    final List <Local_Client__c> lclList = [SELECT Id, local_customer_id__c FROM Local_Client__c WHERE Cib_Client__c =: account LIMIT 1];
    final List <arce__Rating_Sources__c> rtingSrcList = [SELECT id, arce__g_golden_customer_id__c, CreatedDate FROM arce__Rating_Sources__c WHERE arce__g_golden_customer_id__c =: lclList[0].local_customer_id__c ORDER by arce__g_golden_customer_id__c , CreatedDate DESC LIMIT 1];
      if(rtingSrcList != null && !rtingSrcList.isEmpty()){
          return rtingSrcList[0].Id;
      }
      else{
          return '';
      }
  }
}