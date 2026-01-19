/**********************************************************************************
* @author  		Global Desktop
* @date         06/09/2021
* @description  Handler del trigger del objeto TIER 
**********************************************************************************/
public with sharing class GtbTierTriggerHandler {//NOSONAR
  /*
  * @author Global Desktop
  **/
    
     public static map <String,String>countrysFilter (List<tier_gtb__c> countryList) {
           final map <String,String> listGtbCuntrys = new map <String,String>();  
        for(tier_gtb__c objTier : countryList) {
             listGtbCuntrys.put(objTier.gf_sf_concatenated_key_id__c , objTier.g_country_id__c);
   	 }
         system.debug('lista de paises con id' + listGtbCuntrys);
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
        system.debug('lista de paises en total' + listCntrysQ);
        return listCntrysQ;
    }    
/*
* @author Global Desktop
**/
    public static map <String,String> tieridsmap (List<tier_gtb__c> countryList) {
         final map <String,String> mapTier = new map <String,String>();
             for(tier_gtb__c objTier : countryList) {
             mapTier.put(objTier.gf_sf_concatenated_key_id__c , objTier.gf_gtb_area_gsg_tier_type_name__c);
   	 }
        system.debug('mapita de id y TIER' + mapTier);
        return mapTier;
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
* @author Global Desktop
**/        
    public static void updateRelatedAccTier(List<tier_gtb__c> listTierGtb) {   
        final Map <String , String> mapTierId = tieridsmap(listTierGtb);
        final Map <String , String> listGtbCuntrys = countrysFilter(listTierGtb);
        final Set <String> listCntrysQ = countrys(listTierGtb);
        final Set <String> listTierId = tierIDs(listTierGtb);
        final List<Batches_Process_Parameters__mdt> batchParams = new List<Batches_Process_Parameters__mdt>([SELECT DeveloperName, MasterLabel, Batch_Param__c, Batch_Size__c FROM Batches_Process_Parameters__mdt WHERE DeveloperName = 'DES_BatchSize_accountTierUpdateBatch' LIMIT 1]);
        final Integer batchSize = (Test.isRunningTest() || batchParams.isEmpty() ? 1 : batchParams.get(0).Batch_Size__c.intValue());//NOSONAR
  		final List<Account> myList = new List<Account>();
        final List <Account> accountToUpdate = [SELECT Id, gf_gtb_area_gsg_tier_type_name__c, DES_Main_Parent__c, DES_Main_Parent__r.DES_group_code__c, DES_Structure_Type__c, DES_Country_Client__c FROM Account Where DES_Main_Parent__c IN: listTierId  AND DES_Country_Client__c IN: listCntrysQ AND DES_Structure_Type__c = 'Subsidiary'];
            for(Account acc:accountToUpdate) {
                if (acc.DES_Country_Client__c == listGtbCuntrys.get(acc.DES_Main_Parent__r.DES_group_code__c + '_' + acc.DES_Country_Client__c)  &&   acc.gf_gtb_area_gsg_tier_type_name__c != mapTierId.get(acc.DES_Main_Parent__r.DES_group_code__c + '_' + acc.DES_Country_Client__c)) {
                			acc.gf_gtb_area_gsg_tier_type_name__c = mapTierId.get(acc.DES_Main_Parent__r.DES_group_code__c + '_' + acc.DES_Country_Client__c);   
                            myList.add(acc);
    }
            }
        system.debug('tamaño de la lista' + myList.size());

        Database.executeBatch(new AccountTierUpdateBatch(myList), batchSize);

        	
}
/*
* @author Global Desktop
**/    
    public static void updateTierName(List<tier_gtb__c> listTierGtb) {
        
        for(tier_gtb__c tierGtbName: listTierGtb) {
            tierGtbName.Name = tierGtbName.g_country_name__c +' '+ tierGtbName.gf_gtb_area_gsg_tier_type_name__c;
        }
    
    }
    
    
}