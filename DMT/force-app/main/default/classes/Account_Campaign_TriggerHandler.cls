/**********************************************************************************
* @author       Global Desktop
* @date         16/01/2020
* @description  Handler del trigger de cond__Account_Campaign__c
**********************************************************************************/
public with sharing class Account_Campaign_TriggerHandler {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Account_Campaign_TriggerHandler instance;

  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Account_Campaign_TriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Account_Campaign_TriggerHandler();
    }
    return instance;
  }

  /**
   * @author Global Desktop
   * @description Empty Constructor
   */
  private Account_Campaign_TriggerHandler() {
    System.debug('Constructor empty');
  }

  /**
   * @author Global Desktop
   * @Description onBeforeInsert
   */
  public static void onBeforeInsert(final List<cond__Account_Campaign__c> newList) {
    Account_Campaign_Helper.assignClientIDFiltered(newList);
    Account_Campaign_Helper.setNameAccountCampaing(newList);
  }

   /**
   * @author Global Desktop
   * @Description trunck description for fix a error
   */
  public static void trunckDescription(final List<cond__Account_Campaign__c> newList) {
    //se agrego esta linea para arreglar un error
    for(Integer i=0;i<newList.size();i++) {
        if(newList[i].cond__campaign_desc__c!=null&&newList[i].cond__campaign_desc__c.length()>250) {
                 newList[i].cond__campaign_desc__c = newList[i].cond__campaign_desc__c.substring(0, 250);
        }
    }

  }
  /**
   * @author Global Desktop
   * @Description onAfterInsert
   */
  public static void onAfterInsert(final List<cond__Account_Campaign__c> newList) {
    Account_Campaign_Helper.newTeamInitiative(newList);
  }

  /**
   * @author Global Desktop
   * @Description onBeforeUpdate
   */
  public static void onBeforeUpdate(final Map<Id, cond__Account_Campaign__c> newMap, final Map<Id, cond__Account_Campaign__c> oldMap) {
    final List<cond__Account_Campaign__c> listAccCampaign = new List<cond__Account_Campaign__c>();
    for(cond__Account_Campaign__c iAccountCampaign : newMap.values()) {
      if(newMap.get(iAccountCampaign.Id).cond__Campaign_status_approval_type__c != oldMap.get(iAccountCampaign.Id).cond__Campaign_status_approval_type__c
        && newMap.get(iAccountCampaign.Id).cond__Campaign_status_approval_type__c == Label.Discarted_for_intt) {
        listAccCampaign.add(iAccountCampaign);
      }
    }

    if(!listAccCampaign.isEmpty()) {
      Account_Campaign_Helper.checkDiscartedStatus(listAccCampaign);
    }
  }
}