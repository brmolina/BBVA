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
  public Batch_AP_UpdatePipelineAndRevenues(String paramAPstatus) {
      this.bQuery = 'SELECT Id, bupl__gf_business_plan_version_id__c, bupl__gf_booking_operation_cntry_id__c, bupl__solution_category_desc__c, bupl__customer_open_oppy_amount__c, bupl__gf_total_revenues_ytd_amount__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Country_Client__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba__c ' + 
                            'FROM bupl__BusinessPlan_Item__c ' + 
                            'WHERE bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_status_type_name__c IN (' + paramAPstatus + ') AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_substatus_type_name__c != \'' + Label.AP_Timed_Out + '\' AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = \'Yes\' ';
      
      this.listStatusAP = paramAPstatus.replace('\'','').split(',');
      System.debug('********* Starting Batch_AP_UpdatePipeline -> Query: ' + this.bQuery);
  }


  //--------------------------------------- BATCHABLE METHODS -------------------------------------

  public Database.QueryLocator start(Database.BatchableContext batchContext) {
    return Database.getQueryLocator(bQuery);
  }


  public void execute(Database.BatchableContext batchContext,List<bupl__BusinessPlan_Item__c> scope) {
    System.debug('********** Batch_AP_UpdatePipeline.  \r\n***** scope (' + scope.size() + '): ' + scope);
    Map<String,bupl__BusinessPlan_Item__c> mapBPItoUpsert;
	mapBPItoUpsert = new Map<String,bupl__BusinessPlan_Item__c>();
    Map<Id,Id> mapGroupToBPV;
	mapGroupToBPV = new Map<Id,Id>();
    Map<Id,Id> mapGroupToBP;
	mapGroupToBP = new Map<Id,Id>();
    for (bupl__BusinessPlan_Item__c bpi : scope) {
        mapGroupToBPV.put(bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c,bpi.bupl__gf_business_plan_version_id__c);
        mapGroupToBP.put(bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c,bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c);
//        String keyMapBPi = bpi.gf_business_plan_version_id__r.gf_business_plan_id__r.participant_id__c + '++' 
//			+ bpi.gf_booking_operation_cntry_id__c + '++' + bpi.solution_category_desc__c;
//        mapBPItem.put(keyMapBPi,bpi);
    }


    List<bupl__BusinessPlan_Item__c> allBPIfromGroup = [SELECT Id, bupl__gf_business_plan_version_id__c, bupl__gf_booking_operation_cntry_id__c, bupl__solution_category_desc__c, bupl__customer_open_oppy_amount__c, bupl__gf_total_revenues_ytd_amount__c, 
                                                  bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c, 
                                                  bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Country_Client__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba__c
                                                  FROM bupl__BusinessPlan_Item__c 
                                                  WHERE bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c IN :mapGroupToBPV.keySet() AND 
                                                  bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_status_type_name__c IN :listStatusAP AND 
                                                  bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__r.acpl__gf_ap_substatus_type_name__c !=  :Label.AP_Timed_Out AND 
                                                  bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = 'Yes'];
    final Map<String,bupl__BusinessPlan_Item__c> mapBPItem = new Map<String,bupl__BusinessPlan_Item__c>();
    for (bupl__BusinessPlan_Item__c bpi : allBPIfromGroup) {
        String keyMapBPi = bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c + '++' + bpi.bupl__gf_booking_operation_cntry_id__c + '++' + bpi.bupl__solution_category_desc__c;
        mapBPItem.put(keyMapBPi,bpi);
    }    


    // fill mapPipelineBPI with pipeline from: all open opportunities, and all closed win opportunities after last EnglobaUpdate
    final Map<String,Decimal> mapPipelineBPI = DES_APloadUtils.getMapPipelineBPI(mapGroupToBPV.keySet());

    // get all previous BPI in orde to fill annual_expect_profit_py_amount__c later
    final Map<String,bupl__BusinessPlan_Item__c> mapPreviousBPI = DES_APloadUtils.getMapPreviousBPI(mapGroupToBP.keySet(), mapGroupToBP.values());

    final List<DES_Booking__c> listBooking = DES_APloadUtils.getListBookingsBPI(mapGroupToBPV.keySet(),System.Today().year()-2);

    final Map<String,DES_Booking__c> mapBooking = new Map<String,DES_Booking__c>();
    for (DES_Booking__c booking : listBooking) {
        String keyMapBPi = booking.DES_Client__c + '++' + DES_APloadUtils.getCountryLabelFromCountryBooking(booking.DES_Country__c) + '++' + booking.SOLUTION_CATEGORY_NAME__c + '++' + booking.DES_Year__c;
        if(mapBooking.containskey(keyMapBPi)) {
            booking.DES_Revenues__c += mapBooking.get(keyMapBPi).DES_Revenues__c;    
        }
        mapBooking.put(keyMapBPi, booking);
        System.debug('>>>>> mapBooking(' + keyMapBPi + '): '+ mapBooking.get(keyMapBPi));
    }


  // 1) FOR para actualizar los BPI que ya existían
    for (bupl__BusinessPlan_Item__c bpi : scope) {
        String keyMapBPi = bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c + '++' +bpi.bupl__gf_booking_operation_cntry_id__c + '++' + bpi.bupl__solution_category_desc__c;      

        System.debug('1) FOR >>>>> keyMapBPi: ' + keyMapBPi);
        // solo se actualizan si se ha modificado su pipeline o su renevue YTD, si no no (para no sobrescribir grabando los mismos valores)
        System.debug('mapPipelineBPI.containsKey(keyMapBPi): ' + mapPipelineBPI.containsKey(keyMapBPi));
        System.debug('bpi.bupl__customer_open_oppy_amount__c: ' + bpi.bupl__customer_open_oppy_amount__c);
        System.debug('mapPipelineBPI.get(keyMapBPi): ' + mapPipelineBPI.get(keyMapBPi));
        
        System.debug('mapBooking.containsKey(keyMapBPi): ' + mapBooking.containsKey(keyMapBPi));
        System.debug('bpi.bupl__gf_total_revenues_ytd_amount__c: ' + bpi.bupl__gf_total_revenues_ytd_amount__c);
        //System.debug('mapBooking.get(keyMapBPi).DES_Revenues__c: ' + mapBooking.get(keyMapBPi).DES_Revenues__c);
        
         if ( (mapPipelineBPI.containsKey(keyMapBPi) && bpi.bupl__customer_open_oppy_amount__c != mapPipelineBPI.get(keyMapBPi)) || 
             (mapBooking.containsKey(keyMapBPi + '++' + (System.Today().year()-2))) || (mapBooking.containsKey(keyMapBPi + '++' + (System.Today().year()-1)) ) || (mapBooking.containsKey(keyMapBPi + '++' + System.Today().year())) ) {
              //(mapBooking.containsKey(keyMapBPi) && bpi.bupl__gf_total_revenues_ytd_amount__c != mapBooking.get(keyMapBPi).DES_Revenues__c) 
			  //&& Integer.valueOf(mapBooking.get(keyMapBPi).DES_Year__c) == System.Today().year()) {
                bupl__BusinessPlan_Item__c bpiAux = new bupl__BusinessPlan_Item__c (id=bpi.id);
 
System.debug('1) FOR dentro del IF >>>>> keyMapBPi: ' + keyMapBPi);                
                 
                if (mapPipelineBPI.containsKey(keyMapBPi)) {
                        bpiAux.bupl__customer_open_oppy_amount__c = mapPipelineBPI.get(keyMapBPi);
                }
                 				
                if (mapBooking.containsKey(keyMapBPi + '++' + (System.Today().year()-2))) {
                    System.debug('>>>> estamos en 2018');
                    bpiAux.bupl__expected_profit_2py_amount__c  = mapBooking.get(keyMapBPi  + '++' + (System.Today().year()-2)).DES_Revenues__c;
                }
                if (mapBooking.containsKey(keyMapBPi + '++' + (System.Today().year()-1))) {
                    System.debug('>>>>> estamos en 2019');
                    bpiAux.bupl__total_revenues_py_amount__c  = mapBooking.get(keyMapBPi + '++' + (System.Today().year()-1)).DES_Revenues__c;
                }
                if (mapBooking.containsKey(keyMapBPi + '++' + System.Today().year())) {
                    System.debug('>>>>> estamos en 2020');
                    bpiAux.bupl__gf_total_revenues_ytd_amount__c  = mapBooking.get(keyMapBPi + '++' + System.Today().year()).DES_Revenues__c;
                }
                    
                    //  if (Integer.valueOf(mapBooking.get(keyMapBPi).DES_Year__c) == System.Today().year()-2) {                          
                    //    bpiAux.bupl__expected_profit_2py_amount__c  = mapBooking.get(keyMapBPi).DES_Revenues__c;
                    //  } else If (Integer.valueOf(mapBooking.get(keyMapBPi).DES_Year__c) == System.Today().year()-1) {
                    //      bpiAux.bupl__total_revenues_py_amount__c  = mapBooking.get(keyMapBPi).DES_Revenues__c;
                    //  } else If (Integer.valueOf(mapBooking.get(keyMapBPi).DES_Year__c) == System.Today().year()) {
                    //      bpiAux.bupl__gf_total_revenues_ytd_amount__c  = mapBooking.get(keyMapBPi).DES_Revenues__c;
                    //  }
					
                    
				System.debug('mapBPItoUpsert: ' + mapBPItoUpsert);                
                mapBPItoUpsert.put(keyMapBPi,bpiAux);
         }
    }

  // 2) FOR para crear nuevos BPI consecuencia de nuevos Bookings de un país y grupo 
  // insertados después desde engloba (que no existían en la creación del Account Planning y vinieron luego)
    for (DES_Booking__c booking : mapBooking.values()) {
        String keyMapBooking = booking.DES_Client__c + '++' + DES_APloadUtils.getCountryLabelFromCountryBooking(booking.DES_Country__c) + '++' + booking.SOLUTION_CATEGORY_NAME__c;
        if (!mapBPItem.containsKey(keyMapBooking)) { // si no existe en la lista de BPI
            // Si es un producto que ya se acaba de inicializar (cada vez que se encuentra un nuevo pais en un grupo se inicializan todos los productos para dicho país)
            if (!mapBPItoUpsert.containsKey(keyMapBooking) && DES_APloadUtils.isInListProductsEngloba(booking.SOLUTION_CATEGORY_NAME__c)) {
              Map<String, bupl__BusinessPlan_Item__c> mapBPiAux = DES_APloadUtils.initBPItemsClientCountry (booking, mapGroupToBPV.get(booking.DES_Client__c));
			        mapBPItoUpsert.putAll(mapBPiAux);
            }

            if (mapBPItoUpsert.containskey(keyMapBooking)) { 
              // complete BusinessPlan_Item information: pipeline, previousBusinessPlanItem, total revenues (py, ytd, bpy)
              if (mapPipelineBPI.containsKey(keyMapBooking) /*&& mapBPItoUpsert.get(keyMapBooking).customer_open_oppy_amount__c == 0*/) {
                mapBPItoUpsert.get(keyMapBooking).bupl__customer_open_oppy_amount__c = mapPipelineBPI.get(keyMapBooking);
              }
              if (mapPreviousBPI.containsKey(keyMapBooking) /*&& mapBPItoUpsert.get(keyMapBooking).annual_expect_profit_py_amount__c == 0*/) {
                mapBPItoUpsert.get(keyMapBooking).bupl__annual_expect_profit_py_amount__c = mapPreviousBPI.get(keyMapBooking).bupl__expected_revenue_amount__c;
              }

               System.debug('System.Today().year(): ' + System.Today().year()); 
              if (Integer.valueOf(booking.DES_Year__c) == System.Today().year()-2) {
                  mapBPItoUpsert.get(keyMapBooking).bupl__expected_profit_2py_amount__c = booking.DES_Revenues__c;
              } else If (Integer.valueOf(booking.DES_Year__c) == System.Today().year()-1) {
                  mapBPItoUpsert.get(keyMapBooking).bupl__total_revenues_py_amount__c  = booking.DES_Revenues__c;
              } else if (Integer.valueOf(booking.DES_Year__c) == System.Today().year()) {
                  mapBPItoUpsert.get(keyMapBooking).bupl__gf_total_revenues_ytd_amount__c  = booking.DES_Revenues__c;
              }
            }
        }
    }

    if (!mapBPItoUpsert.isEmpty()) {
        upsert mapBPItoUpsert.values();
        recordsUpserted += mapBPItoUpsert.size();
    }


  }

  public void finish(Database.BatchableContext batchContext) {
    AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchContext.getJobId()];

    System.debug('*********** SUMMARY: ');
    System.debug('***********   Records Upserted: ' + recordsUpserted);
    System.debug('***********   Batches Created: ' + job.JobItemsProcessed);
    System.debug('***********   Number of Errors: ' + job.NumberOfErrors);
    System.debug('***********   Status: ' + job.Status);
  }

}