/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-27-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('sf:TooManyMethods,PMD.ExcessivePublicCount,PMD.ExcessiveParameterList')
global with sharing class GDT_ArceSummary_Controller {
  
  /**
  * @Description Activity relationship metadata list
  */
  public static Set<String> actRelMdt;
   
  /**
  * --------------------------------------------------------------------------------------
  * @description Checks Path for standalone in IFIS.
  * @param Record of the Account.
  * @return Returns a String.
  **/
  @AuraEnabled
  public static String getAccountIfisPath(String account) {
    final List <arce__Account_has_Analysis__c> ahaList = [select id, arce__Customer__r.DES_Activity__c, arce__AHA_Extension__r.arce__IFIS_Path__c, CreatedDate from arce__Account_has_Analysis__c where arce__Customer__c =: account order by CreatedDate desc LIMIT 1];
    String activityPicklistLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(ahaList[0].arce__Customer__r.DES_Activity__c);
    if(isIfisClient(activityPickListLabel)){
          return ahaList[0].arce__AHA_Extension__r.arce__IFIS_Path__c;
    }
     else{
         return '';
     }
  }
  
  @AuraEnabled  
  public static Boolean isIfisClient(String econActSec) {
  	if(actRelMdt == null) {
    	actRelMdt = new Set<String>();
        for(arce__IFIS_Activity_relationship__mdt arMDT: [select arce__IFIS_ActivitySector__c from arce__IFIS_Activity_relationship__mdt]) {
          actRelMdt.add(arMDT.arce__IFIS_ActivitySector__c);
        }
      }
      return actRelMdt.contains(econActSec);
  }
  
  @AuraEnabled
  public static String getAccAHA(String account) {
    final List <arce__Account_has_Analysis__c> ahaList = [select id from arce__Account_has_Analysis__c where arce__Customer__c =: account order by CreatedDate desc LIMIT 1];
    if(ahaList != null && !ahaList.isEmpty()){
          return ahaList[0].id;
    }
     else{
         return '';
    }
  }
}