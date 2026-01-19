/**********************************************************************************
* @author  		Global Desktop
* @date         22/08/2019
* @description  Batch que asigna los usuarios a los correspondientes territories
* @Revision
**********************************************************************************/
public without sharing class UserToTerritoryBatch implements Database.Batchable<Sobject>, Database.Stateful {
    /*
     *  VARIABKE
    **/
    private String pQuery = 'SELECT Id, gf_user_work_country_desc__c, gf_user_work_segment_desc__c, gf_user_work_product_desc__c, gf_user_auth_level_name__c, All_CES_Attributes_chk__c  FROM User WHERE Profile.Name LIKE \'%Desktop%\' AND All_CES_Attributes_chk__c = true'+ (Test.isRunningTest()?' LIMIT 1':'');//NOSONAR
    /*
     *  VARIABKE
    **/
    private Map<String, Territory2> mapStrTerritory;//NOSONAR


    /*
     *  CONSTRCUTOR
     *
    **/
    public UserToTerritoryBatch() {
        List<Territory2> listTerritory = [SELECT Id, country_name__c, segment_name__c, product_name_type__c, gf_user_auth_level_name__c, Name, Territory2TypeId, DeveloperName, Territory2ModelId, ParentTerritory2Id FROM Territory2];//NOSONAR
        mapStrTerritory = new Map<String, Territory2>();
        for(Territory2 territ : listTerritory) {
            mapStrTerritory.put(territ.product_name_type__c.toUpperCase() + '' + territ.country_name__c.toUpperCase() + '' + territ.segment_name__c.toUpperCase() + '' + territ.gf_user_auth_level_name__c.toUpperCase(), territ);
        }
        system.debug('::::: mapStrTerritory : ' + JSON.serialize(mapStrTerritory.keySet()));

        system.debug('>>>>> pQuery : ' + pQuery);
    }

    /*
     *  START
     *
    **/
    public Database.QueryLocator start(Database.BatchableContext batchCtx) {
        return Database.getQueryLocator(pQuery);
    }

    /*
     *  EXECUTE
     *
    **/
    public void execute(Database.BatchableContext batchCtx, List<User> listUsers) {

        UserTerritorySharing.manageUserTerritories(mapStrTerritory, listUsers);

    }//FIN execute

    /*
     *  FINISH
     *
    **/
    public void finish(Database.BatchableContext batchCtx) {    }


}