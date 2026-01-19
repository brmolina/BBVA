/*
* Class that overwrite the validations of prospect
*/
global with sharing class ProspectHandler implements nonc.NonClient_interface_prospect {    //NOSONAR

  /*
  * Method to check merge_insert when the createdby user is Integrator or Admin and exists a prospect with same fiscal Id.
  */
  global static String checkConvertedClients(List<Account> lProspect, Map<String, Account> mapUniqIDAcc) {
    system.debug('++ mapUniqIDAcc -> ' + JSON.serialize(mapUniqIDAcc));
    system.debug('++ lProspect -> ' + JSON.serialize(lProspect));
    final List<User> users = new List <User>([
      SELECT Id, Profile.Name FROM User Where ID = :UserInfo.getuserid()
    ]);
    system.debug('++ users -> ' + JSON.serialize(users));
    if(users.get(0).Profile.Name == 'System Administrator' || users.get(0).Profile.Name == 'Desktop Integration' || users.get(0).Profile.Name == 'Desktop Administrator') {
      for(Account aux : mapUniqIDAcc.values()) {
        if(aux.DES_Structure_Type__c != null) {
          aux.Merge_Insert__c = true;
        }
      }
    }
    return 'ok';
  }
  /*
  * Empty method
  */
  global static String checkDuplicateNonClients(String strSearchName, String strFieldNameCode, String strFielValueCode) {
    return null;
  }
  /*
  * Empty method
  */
  global static String validateNonCliente(Account acc) {
    return null;
  }
  /*
  * Future method delete prospect group
  */
  public static void deleteProspectGroup(Map <Id, Account> mapOld, List<Account> triggerNew) {
    if(System.IsBatch() == false && System.isFuture() == false) {
      ProspectHandler.deleteProspectGroupFut(JSON.serialize(mapOld), JSON.serialize(triggerNew));
    }
  }
  /*
  * Method to delete prospect group in after update
  */
  @future
  public static void deleteProspectGroupFut(String mapOldJSON, String triggerNewJSON) {
    final Map <Id, Account> mapOld = (Map <Id, Account>)JSON.deserialize(mapOldJSON, Map<Id, Account>.class);
    final List<Account> triggerNew = (List<Account>)JSON.deserialize(triggerNewJSON, List<Account>.class);
    final Set <Id> setParticipants = new Set <Id>();
    final Set <Id> prospectsUpdate = new Set <Id>();
    for(Account acc : triggerNew) {
      if(mapOld.get(acc.Id).RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId() &&
      acc.RecordTypeId != Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId()) {
        setParticipants.add(mapOld.get(acc.Id).participant_id__c);
        prospectsUpdate.add(acc.Id);
      }
    }

    final List <Account> prospNoUpdate = new List <Account>([
      SELECT Id, DES_ID_Fiscal__c, participant_id__c FROM Account WHERE participant_id__c IN :setParticipants AND RecordType.DeveloperName = 'Prospect_Subsidiary' AND Id NOT IN :prospectsUpdate
    ]);

    final Set <Id> idGroupNoUpdate = new Set <Id>();
    for(Account acc : prospNoUpdate) {
      idGroupNoUpdate.add(acc.participant_id__c);
    }

    final List <Account> participantsToDel = new List <Account>([
      SELECT Id, RecordTypeId from Account Where Id IN :setParticipants AND Id NOT IN :idGroupNoUpdate AND RecordType.DeveloperName = 'Prospect_Group'
    ]);

    if(!participantsToDel.isEmpty()) {
      delete participantsToDel;
    }
  }
}