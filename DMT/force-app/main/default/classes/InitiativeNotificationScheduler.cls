/*
* @author GlobalDesktop
* @description Clase para programar el batch InitiativeNotificationBatch.
*/
global with sharing class InitiativeNotificationScheduler implements Schedulable {      //NOSONAR

  /*
  *Met0d0 de implementar Schedulable.
  */
  global void execute(SchedulableContext scheContext) {
    final String query = 'SELECT Id, intt__manager_team_id__c, intt__manager_team_id__r.Email, ' +
      'intt__campaign_id__c, intt__gf_group_campaign_id__c, ' +
      'intt__campaign_id__r.Id, intt__campaign_id__r.Name, intt__campaign_id__r.EndDate, ' +
      'intt__gf_group_campaign_id__r.cond__campaign_id__c, ' +
      'intt__gf_group_campaign_id__r.cond__campaign_id__r.Id, intt__gf_group_campaign_id__r.cond__campaign_id__r.Name, ' +
      'intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate ' +
      'FROM intt__Team_initiative__c ' +
      'WHERE (intt__campaign_id__r.EndDate = :expiration1 ' +
      'OR intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate = :expiration1 ' +
      'OR intt__campaign_id__r.EndDate = :expiration2 ' +
      'OR intt__gf_group_campaign_id__r.cond__campaign_id__r.EndDate = :expiration2)';

    final Id batchJobId = Database.executeBatch(new InitiativeNotificationBatch(query));
    System.debug(batchJobId);
  }
}