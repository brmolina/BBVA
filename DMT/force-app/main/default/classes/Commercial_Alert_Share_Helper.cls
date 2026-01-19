/**********************************************************************************
* @author       Global Desktop
* @date         20/05/2020
* @description  Helper del share de altm__Commercial_Alert__c
**********************************************************************************/
public without sharing class Commercial_Alert_Share_Helper {
  /**
  * @author Global Desktop
  * @Description createManualSharingInsertGetShare
  */
  public static void insertCommAlertShare(List<altm__Commercial_Alert__Share> newCommAlertShare) {
    if(!newCommAlertShare.isEmpty()) {
      insert newCommAlertShare;
    }
  }
}