/**
* @author       Global Desktop
* @date         22/11/2019
* @description  Batch para actualizar diariamente el campo de BusinessPlanItem con la información de Pipeline 
*				de las oportunidades abiertas y las cerradas después de la última actualización de Engloba
*
* Version   Date            Author          Summary of changes
*
* ----------------------------------------------------------------------------------
*/
public without sharing class Batch_AP_UpdatePipelineAndRevenues implements Database.Batchable<sObject>, Database.Stateful {

  //--------------------------------------- PRIVATE ATTRIBUTES ------------------------------------
  /*Declaración de variable*/
  private Integer recordsUpserted = 0;
  /*Declaración de variable*/
  private String bQuery = '';
  /*Declaración de variable*/
  private List<String> listStatusAP = new List<String>();
  //--------------------------------------- CONSTRUCTOR METHODS -----------------------------------
  public Batch_AP_UpdatePipelineAndRevenues(String paramAPstatus){

    this.bQuery = 
            'SELECT Id, ' + 
            '       bupl__gf_business_plan_version_id__c, ' + 
            '       bupl__gf_booking_operation_cntry_id__c, ' + 
            '       bupl__solution_category_desc__c, ' + 
            '       bupl__customer_open_oppy_amount__c, ' + 
            '       bupl__gf_total_revenues_ytd_amount__c, ' + 
            '       bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c, ' + 
            '       bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c, ' + 
            '       bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Country_Client__c, ' + 
            '       bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba__c ' + 
            'FROM bupl__BusinessPlan_Item__c ' + 
            'WHERE bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_status_type_name__c IN (' + paramAPstatus + ') ' + 
            'AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_substatus_type_name__c != \'' + Label.AP_Timed_Out + '\' ' + 
            'AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = \'Yes\'';

    this.listStatusAP = paramAPstatus.replace('\'', '').split(',');
  }

  //--------------------------------------- BATCHABLE METHODS -------------------------------------
  public Database.QueryLocator start(Database.BatchableContext bc){
    return Database.getQueryLocator(bQuery);
  }
  
  public void execute(Database.BatchableContext bc, List<bupl__BusinessPlan_Item__c> scope){

    Set<Id> scopeParticipantIds = new Set<Id>();
    Set<Id> scopeBPVIds = new Set<Id>();
    Set<Id> scopeBPIds = new Set<Id>();

    for (bupl__BusinessPlan_Item__c bpi : scope){
      scopeParticipantIds.add(bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c);
      scopeBPVIds.add(bpi.bupl__gf_business_plan_version_id__c);
      scopeBPIds.add(bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c);
    }
    
    List<bupl__BusinessPlan_Item__c> allBPIfromGroup = [SELECT Id, bupl__gf_business_plan_version_id__c, bupl__gf_booking_operation_cntry_id__c, bupl__solution_category_desc__c, bupl__customer_open_oppy_amount__c, bupl__gf_total_revenues_ytd_amount__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Country_Client__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba__c
                                                        FROM bupl__BusinessPlan_Item__c
                                                        WHERE bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c IN:scopeParticipantIds AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_status_type_name__c IN:listStatusAP AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_substatus_type_name__c != :Label.AP_Timed_Out AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = 'Yes'];


    Map<String, bupl__BusinessPlan_Item__c> mapBPItem = new Map<String, bupl__BusinessPlan_Item__c>();
    for (bupl__BusinessPlan_Item__c bpi : allBPIfromGroup){
      String key = bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c + 
                '++' + bpi.bupl__gf_booking_operation_cntry_id__c + 
                '++' + bpi.bupl__solution_category_desc__c;

      mapBPItem.put(key, bpi);
    }
    
    Map<String, Decimal> mapPipelineBPI = DES_APloadUtils.getMapPipelineBPI(scopeParticipantIds);

    List<Id> scopeBPIdList = new List<Id>(scopeBPIds);

    Map<String, bupl__BusinessPlan_Item__c> mapPreviousBPI = DES_APloadUtils.getMapPreviousBPI(scopeParticipantIds, scopeBPIdList);

    List<DES_Booking__c> listBooking = DES_APloadUtils.getListBookingsBPI(scopeParticipantIds, System.today().year() - 2);

    Map<String, DES_Booking__c> mapBooking = new Map<String, DES_Booking__c>();

    for (DES_Booking__c booking : listBooking){
      String key = booking.DES_Client__c + '++' + DES_APloadUtils.getCountryLabelFromCountryBooking(booking.DES_Country__c) + '++' + booking.SOLUTION_CATEGORY_NAME__c + '++' + booking.DES_Year__c;

      if (mapBooking.containsKey(key)){
        booking.DES_Revenues__c += mapBooking.get(key).DES_Revenues__c;
      }
      mapBooking.put(key, booking);
    }
    
    Map<String, bupl__BusinessPlan_Item__c> mapBPItoUpsert = new Map<String, bupl__BusinessPlan_Item__c>();

    for (bupl__BusinessPlan_Item__c bpi : scope){

      String key = bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c + 
                '++' + bpi.bupl__gf_booking_operation_cntry_id__c + 
                '++' + bpi.bupl__solution_category_desc__c;

      if (mapPipelineBPI.containsKey(key) || mapBooking.containsKey(key + '++' + (System.today().year() - 2)) || mapBooking.containsKey(key + '++' + (System.today().year() - 1)) || mapBooking.containsKey(key + '++' + System.today().year())){

        bupl__BusinessPlan_Item__c upd = new bupl__BusinessPlan_Item__c(
          Id = bpi.Id
        );

        if (mapPipelineBPI.containsKey(key)){
          upd.bupl__customer_open_oppy_amount__c = mapPipelineBPI.get(key);
        }
        if (mapBooking.containsKey(key + '++' + (System.today().year() - 2))){
          upd.bupl__expected_profit_2py_amount__c = mapBooking.get(key + '++' + (System.today().year() - 2)).DES_Revenues__c;
        }
        if (mapBooking.containsKey(key + '++' + (System.today().year() - 1))){
          upd.bupl__total_revenues_py_amount__c = mapBooking.get(key + '++' + (System.today().year() - 1)).DES_Revenues__c;
        }
        if (mapBooking.containsKey(key + '++' + System.today().year())){
          upd.bupl__gf_total_revenues_ytd_amount__c = mapBooking.get(key + '++' + System.today().year()).DES_Revenues__c;
        }

        mapBPItoUpsert.put(key, upd);
      }
    }

    if (!mapBPItoUpsert.isEmpty()){
      upsert mapBPItoUpsert.values();
      recordsUpserted += mapBPItoUpsert.size();
    }
  }
  
  public void finish(Database.BatchableContext bc){

    AsyncApexJob job = [SELECT Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                        FROM AsyncApexJob
                        WHERE Id = :bc.getJobId()];

    System.debug('Records Upserted: ' + recordsUpserted);
    System.debug('Batches: ' + job.JobItemsProcessed);
    System.debug('Errors: ' + job.NumberOfErrors);
    System.debug('Status: ' + job.Status);
  }

}