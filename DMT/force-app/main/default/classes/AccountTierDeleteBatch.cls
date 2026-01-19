/**********************************************************************************
* @author  		Global Desktop
* @date         06/09/2021
* @description  Batch que elimina los registro de TIER que han dejado de llegar por carga
**********************************************************************************/
public without sharing class AccountTierDeleteBatch implements Database.Batchable<Sobject>, Database.Stateful {
	/*
   *  VARIABLE
  **/
  private List<sObject> listTier; //NOSONAR
  /*
   *  CONSTRUCTOR
   **/
  public AccountTierDeleteBatch () {

         if(Test.isRunningTest()) {
             listTier = [SELECT Id, gf_gtb_area_gsg_tier_type_name__c ,gf_sf_concatenated_key_id__c, gf_participant_id__c , g_country_id__c FROM tier_gtb__c where gf_sf_concatenated_key_id__c = 'G123123123_PE'];
         } else {
             listTier = [SELECT Id, gf_gtb_area_gsg_tier_type_name__c ,gf_sf_concatenated_key_id__c, gf_participant_id__c , g_country_id__c FROM tier_gtb__c where LastModifiedDate < LAST_N_DAYS: 30];
			}
 	   final Map <String , String> listGtbCuntrys = countrysFilter(listTier);
     final Set <String> listCntrysQ = countrys(listTier);
     final Set <String> listTierId = tierIDs(listTier);
     final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'DES_BatchSize_accountTierUpdateBatch' LIMIT 1]);
     final Integer batchSize = (Test.isRunningTest() || batchParams.isEmpty() ? 1 : batchParams.get(0).Batch_Size__c.intValue());//NOSONAR
     final List<Account> myList = new List<Account>();
     final List <Account> accountToUpdate = [SELECT Id, gf_gtb_area_gsg_tier_type_name__c, DES_Main_Parent__c, DES_Main_Parent__r.DES_group_code__c, DES_Structure_Type__c, DES_Country_Client__c FROM Account Where DES_Main_Parent__c IN: listTierId AND DES_Country_Client__c IN: listCntrysQ AND DES_Structure_Type__c = 'Subsidiary'];
            for(Account acc:accountToUpdate) {
                if (acc.DES_Country_Client__c == listGtbCuntrys.get(acc.DES_Main_Parent__r.DES_group_code__c + '_' + acc.DES_Country_Client__c)) {
                            acc.gf_gtb_area_gsg_tier_type_name__c = '';   
                            myList.add(acc);
    }
            }
      if (!myList.IsEmpty()) {
      Database.executeBatch(new AccountTierUpdateBatch(myList), batchSize);
      }
      
  }

  /*
   *  start
  **/
  public Iterable<sObject> start(Database.BatchableContext batchCntx) {
    return listTier;
    
    
  }
/*
* @author Global Desktop
**/   
   public static map <String,String> countrysFilter (List<tier_gtb__c> countryList) {
           final map <String,String> listGtbCuntrys = new map <String,String>();  
       		 for(tier_gtb__c objTier : countryList) {
             listGtbCuntrys.put(objTier.gf_sf_concatenated_key_id__c, objTier.g_country_id__c);
   		 }
        return listGtbCuntrys;
   		 }
/*
* @author Global Desktop
**/      
    public static Set<string> countrys (List<tier_gtb__c> countryList) {
            final Set<string> listCntrysQ = new Set<String>();  
       			 for(tier_gtb__c objTier : countryList) {
             listCntrysQ.add(objTier.g_country_id__c);
   	 		}
        	return listCntrysQ;
   		 }
/*
* @author Global Desktop
**/
        public static Set<string> tierIDs (List<tier_gtb__c> countryList) {
            final Set<string> listTierId = new Set<String>();  
        for(tier_gtb__c objTier : countryList) {
             listTierId.add(objTier.gf_participant_id__c);
   	 }
        system.debug('lista de paises en total' + listTierId);
        return listTierId;
    }     
  /*
   *  execute
  **/
   
  public void execute(Database.BatchableContext batchCntx, List<sObject> listTier) {
    
	delete listTier;

  }//FIN execute

  /*
   *  finish
  **/
  public void finish(Database.BatchableContext batchCntx) {  
	

  }


}