/**********************************************************************************
* @author       Global Desktop
* @date         14/01/2020
* @description  GBL_InitiativeTriggerEmailHandler class
**********************************************************************************/
public without sharing class GBL_InitiativeTriggerEmailHandler {

  /**
   * SINGLETON PATTERN
   */
  private static GBL_InitiativeTriggerEmailHandler instance;

  /**
   * getInstance
   */
  public static GBL_InitiativeTriggerEmailHandler gtInstance() {
    if (instance == null) {
      instance = new GBL_InitiativeTriggerEmailHandler();
    }
    return instance;
  }

  /*
   * Met0d0 para pasar sonar
   */
  private GBL_InitiativeTriggerEmailHandler() {
  }

  /**
  * @author Global Desktop
  * @Description afterUpdate
  */
  public static void afterUpdate(List<Campaign> lstNew,List<Campaign> lstOld) {

    if(lstNew.size() == 1 && lstOld[0].Status == 'Draft' && lstNew[0].Status == 'Pending') {

      String subject = system.Label.EmailNotification_Newsubject;
      subject = subject.replace('[NAME]', lstOld[0].Name);
      String body = system.Label.EmailNotification_Newbody;
      body = body.replace('[NAME]', lstOld[0].Name);
      final List<intt__Team_initiative__c> lstTeam = [SELECT Id, intt__manager_team_id__c, intt__manager_team_id__r.Email FROM intt__Team_initiative__c WHERE intt__campaign_id__c =:lstNew[0].id or intt__gf_group_campaign_id__r.cond__campaign_id__c =:lstNew[0].id];
      UtilInitiatives.sendMailPaquete(subject, body, lstTeam,true);
    }
  }
}