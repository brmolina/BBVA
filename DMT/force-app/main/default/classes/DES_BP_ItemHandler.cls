/**
* @author       Global Desktop
* @date         2020/06/16
* @description  Handler del trigger de Business Plan Item
* @Revision
*/
public without sharing class DES_BP_ItemHandler {
    /*instance*/
    private static DES_BP_ItemHandler instance;


    /*
    * @author       Global Desktop
    * @Description  Constructor
    */
    private DES_BP_ItemHandler() {
        System.debug('DES_BP_ItemHandler Constructor');
    }

    /*
    * @author       Global Desktop
    * @Description  getInstance
    */
    public static DES_BP_ItemHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_BP_ItemHandler();
        }
        return instance;
    }


    /*
    * @author       Global Desktop
    * @Description  Insert Local Analysis
    */
    public void insertLocalAnalysis(List<bupl__BusinessPlan_Item__c> triggerNew) {
        Set<Id> bpiIdSet;
        bpiIdSet = new Set<Id>();
        Set<String> countrySet;
        countrySet = new Set<String>();
        Map<String, String> bpiCountryMap;
        bpiCountryMap = new Map<String, String>();
        
        for(bupl__BusinessPlan_Item__c bpItemAux : triggerNew) {
            bpiIdSet.add(bpItemAux.Id);
            countrySet.add(bpItemAux.bupl__gf_booking_operation_cntry_id__c);
        }
        final List<bupl__BusinessPlan_Item__c> bpiList = [SELECT Id, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c,
                                                          bupl__gf_booking_operation_cntry_id__c
                                                    FROM bupl__BusinessPlan_Item__c WHERE Id IN :bpiIdSet AND bupl__gf_booking_operation_cntry_id__c IN :countrySet];
        System.debug('bpiList: ' + bpiList);
        Set<Id> apIdSet;
        apIdSet = new Set<Id>();
        for(bupl__BusinessPlan_Item__c bpItemAux : bpiList) {
            apIdSet.add(bpItemAux.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c);
            bpiCountryMap.put(bpItemAux.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c+'_'+bpItemAux.bupl__gf_booking_operation_cntry_id__c, 
                              bpItemAux.bupl__gf_booking_operation_cntry_id__c);
        }
        final List<DES_Local_Analysis__c> laList = [SELECT Id, gf_account_planning_id__c, country_name__c
                                                    FROM DES_Local_Analysis__c WHERE gf_account_planning_id__c IN :apIdSet AND country_name__c IN :countrySet];
        System.debug('laList: ' + laList);
        Map<String, String> apCountryMap;
        apCountryMap = new Map<String, String>();
        if(laList.isEmpty()) {
            //insertamos un LA por cada país (voy a necesitar id del AP y país)
            for(bupl__BusinessPlan_Item__c bpItemAux : bpiList) {
                System.debug('apCountryMap en el loop sin LA: ' + apCountryMap);    
                apCountryMap.put(bpItemAux.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c + '_' + bpItemAux.bupl__gf_booking_operation_cntry_id__c, 
                                     bpItemAux.bupl__gf_booking_operation_cntry_id__c);
                
            } 
        } else {
            //ya existían Local Analysis así que sólo insertamos si el país de bpiCountryMap no está en laCountryMap
            Map<String, String> laCountryMap;
        	laCountryMap = new Map<String, String>();

            for(DES_Local_Analysis__c laAux : laList) {
                laCountryMap.put(laAux.gf_account_planning_id__c + '_' + laAux.country_name__c, laAux.country_name__c);
            }
            for(String bpiCaux : bpiCountryMap.keySet()) {
                if(laCountryMap.get(bpiCaux) == null) {
                    apCountryMap.put(bpiCaux, bpiCountryMap.get(bpiCaux));
                }
            }
        }

        System.debug('apCountryMap: ' + apCountryMap);
        List<DES_Local_Analysis__c> laToInsert;
        laToInsert = new List<DES_Local_Analysis__c>();
        for(String mapAux : apCountryMap.keySet()) {
            final List<String> apCountrySplit = mapAux.split('_');
            laToInsert.add(new DES_Local_Analysis__c(
                gf_account_planning_id__c = apCountrySplit.get(0),
                country_name__c = apCountrySplit.get(1)));
        }
        System.debug('laToInsert: ' + laToInsert);
        insert laToInsert;
    }
}