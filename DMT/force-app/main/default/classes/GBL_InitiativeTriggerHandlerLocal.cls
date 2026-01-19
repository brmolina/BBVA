/*
 * Clase GBL_InitiativeTriggerHandlerLocal
 * Relaciona los grupos a la iniciativa en un met0d0 futuro para que no llegue al limite de tiempo cuando el numero es elevado.
*/
public with sharing class GBL_InitiativeTriggerHandlerLocal {

    public static void afterInsert(List<Campaign> lstCampanaNew) {
        Id devRecordTypeId = Schema.SObjectType.cond__Account_Campaign__c.getRecordTypeInfosByName().get('Initiative').getRecordTypeId();
        List<intt__Team_initiative__c> lstInitiativeTeam = new List<intt__Team_initiative__c>();
    
        if(lstCampanaNew.size() == 1) {
          Campaign campana = lstCampanaNew[0];
          List<intt__GBL_InitiativeConf__mdt> lstInitiativeConfig = new List<intt__GBL_InitiativeConf__mdt>();
    
          if(Test.isRunningTest()) {
            intt__GBL_InitiativeConf__mdt iMetadata = new intt__GBL_InitiativeConf__mdt(
              DeveloperName = 'Sample',
              intt__Custom_FilterClient__c = false,
              intt__Enable_TaskNotification__c = true,
              intt__InitialState_Initiative__c = 'Draft');
            lstInitiativeConfig.add(iMetadata);
          } else {
            lstInitiativeConfig = [select intt__ClassName_UserFilter__c, intt__InitialState_Initiative__c, intt__ClassName_CientFilter__c, intt__Custom_FilterClient__c from intt__GBL_InitiativeConf__mdt WHERE DeveloperName != 'GBL_InitiativeConf' limit 1];
          }
    
          //created de team initiative
          if(lstInitiativeConfig.size()>0 && lstCampanaNew.size()>0) {
            GBL_InitiativeTriggerHandlerLocal.InitiativeTeamFilter(lstCampanaNew[0],lstInitiativeConfig);
          }
    
          List<intt__GBL_MappingInitiativeGroup__mdt> lstMapping = [select intt__GroupField__c,intt__InitiativeField__c from intt__GBL_MappingInitiativeGroup__mdt];
    
          String strIdCampana = campana.id;
    
          Campaign objCampana = GBL_InitiativeTriggerHandlerLocal.getQueryDinamicInitiative(lstMapping,strIdCampana);
          objCampana.Status = 'Draft';//lstInitiativeConfig[0].InitialState_Initiative__c;
          update objCampana;
    
          List<cond__Account_Campaign__c> lstRelatedAccount = new List<cond__Account_Campaign__c>();
              
          List<Account> lstAccount = GBL_InitiativeTriggerHandlerLocal.ClientFilter(Campana,lstInitiativeConfig);
          Database.executeBatch(new Batch_InsertInitiatives(lstAccount, campana, lstMapping, objCampana), 100);
    
        }
    }
    
    
    public static void initiativeTeamFilter(Campaign campana, List<intt__GBL_InitiativeConf__mdt> lstInitiativeConfig) {

    if(lstInitiativeConfig.size() > 0 && lstInitiativeConfig[0].intt__ClassName_UserFilter__c != null && lstInitiativeConfig[0].intt__ClassName_UserFilter__c.length() > 0) {

      String className = lstInitiativeConfig[0].intt__ClassName_UserFilter__c;
      Type typeCustomCLass = Type.forName(className);
      Object classCustom = typeCustomCLass.newInstance();
      intt.GBL_Initiative_interface infCustomFilter = (intt.GBL_Initiative_interface) classCustom;
      List<intt__Team_initiative__c> lstInitiativeTeam = infCustomFilter.InitiativeTeamFilter(Campana);

      if(lstInitiativeTeam.size() > 0) {
        upsert lstInitiativeTeam;
      }
    }
  }
    
    public static Campaign getQueryDinamicInitiative(List<intt__GBL_MappingInitiativeGroup__mdt> lstMapping, String strIdCampana) {

    String query = 'select ';

    for(Integer i = 0; i < lstMapping.size(); i++) {
      query = query + lstMapping[i].intt__InitiativeField__c;

      if(i < (lstMapping.size() - 1)) {
        query = query + ',';
      }
    }

    if(query.indexOf('name') == -1) {

      if(lstMapping.size() > 0) {
        query = query.replace('select', 'select name,');

      } else {
        query = query.replace('select', 'select id ');
      }
    }

    query = query + ' from Campaign where id= :strIdCampana';
    List<Campaign> lstCampaign = Database.query(String.escapeSingleQuotes(query));

    if(lstCampaign.size() > 0) {
      return lstCampaign[0];

    } else {
      return new Campaign();
    }
  }
    
    public static List<Account> clientFilter(Campaign campana, List<intt__GBL_InitiativeConf__mdt> lstInitiativeConfig) {

    if(lstInitiativeConfig.size() > 0 && lstInitiativeConfig[0].intt__Custom_FilterClient__c && lstInitiativeConfig[0].intt__ClassName_CientFilter__c.length() > 0) {
      String className = lstInitiativeConfig[0].intt__ClassName_CientFilter__c;
      Type typeCustomCLass = Type.forName(className);
      Object classCustom = typeCustomCLass.newInstance();

      intt.GBL_ClientFilter_interface infCustomFilter = (intt.GBL_ClientFilter_interface) classCustom;
      return infCustomFilter.ClientFilter(Campana);

    } else {
      return intt.GBL_InitiativeTriggerHandler.DefaultClientFilter(campana);
    }
  }
    
    /*Met0d0 futuro que referencia al componente manejad de iniciativas*/
    /*@future
    public static void afterInsertLocal(String jsonList) {
        final List<Campaign> newList =
            (List<Campaign>) JSON.deserialize(jsonList, List<Campaign>.class);
		intt.GBL_InitiativeTriggerHandler.AfterInsert(newList);
    }*/

}