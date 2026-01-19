/**
* @author       Global Desktop
* @date         2019/11/08
* @description  Handler del trigger de Business Plan. No se deberá entregar en el paquete de BP ya que son métodos para procesos utilizados en Global Desktop
* @Revision
* 
* Version   Date            Author          Summary of changes
*
*/
public without sharing class DES_BusinessPlanVersion_TriggerHandler {
    /*instance*/
    private static DES_BusinessPlanVersion_TriggerHandler instance;


    /*
    * @author       Global Desktop
    * @Description  Constructor
    */
    private DES_BusinessPlanVersion_TriggerHandler() {
        System.debug('DES_BusinessPlanVersion_TriggerHandler Constructor');
    }

    /*
    * @author       Global Desktop
    * @Description  getInstance
    */
    public static DES_BusinessPlanVersion_TriggerHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_BusinessPlanVersion_TriggerHandler();
        }
        return instance;
    }


    /*
    * @author       Global Desktop
    * @Description  Set correct name, check version... for a new Business Plan Version record
    */
    public void populateFieldsBPVersion(List<bupl__BusinessPlan_Version__c> triggerNew) {
        List<id> listBPid = new List<id>();
        for (bupl__BusinessPlan_Version__c bpv : triggerNew) {
            listBPid.add(bpv.bupl__gf_business_plan_id__c);
        }
         map<id,bupl__BusinessPlan__c> mapBP = new Map<ID, bupl__BusinessPlan__c>([Select Id, Name, bupl__gf_counter_number__c From bupl__BusinessPlan__c Where id IN :listBPid]);

        for (bupl__BusinessPlan_Version__c bpv : triggerNew) {
            //Integer bpiVersion = mapBP.get(bpv.bupl__gf_business_plan_id__c).bupl__gf_counter_number__c.intValue() + 1;
            //bpv.Name = mapBP.get(bpv.bupl__gf_business_plan_id__c).Name + ' v' + bpiVersion;
            bpv.Name = mapBP.get(bpv.bupl__gf_business_plan_id__c).Name + '_Draft_' + date.today().format();
            bpv.bupl__gf_business_plan_act_ind_type__c = 'Yes';
        }
    }


    /*
    * @author       Global Desktop
    * @Description  Create the BP Items related to the Business Plan Version
    */
    public void initRelatedBPitems(List<bupl__BusinessPlan_Version__c> triggerNew) {
        final List<bupl__BusinessPlan_Item__c> listBPi = new List<bupl__BusinessPlan_Item__c>();
        final Map<String,bupl__BusinessPlan_Item__c> mapBPi = new map<String,bupl__BusinessPlan_Item__c>(); //keymap = Client + Country + Product
        final Map<Id,bupl__BusinessPlan_Version__c> mapBPVByGroupId = new Map<Id,bupl__BusinessPlan_Version__c>();
        final Map<Id,Id> mapBPVToUpdatePreviousBPV = new Map<Id,Id>(); //There are more BPVersion for that BP (current BPVersion is NOT the first one)

        // client Group list
        final List<bupl__BusinessPlan_Version__c> listBPV = [Select Id, bupl__gf_business_plan_id__c, bupl__gf_business_plan_id__r.bupl__participant_id__c, bupl__gf_business_plan_id__r.bupl__gf_counter_number__c, bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Country_Client__c, bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba__c 
                /* estos campos los comento porque se traen en otra query o se traen de la query de booking y podrían no hacer falta aqui, así es más comodo para tener toda la info necesaria en la lista de bookings
                    gf_business_plan_id__r.AccountPlanning__r.AA_Launch_period__c, gf_business_plan_id__r.participant_id__r.DES_Segment__c, gf_business_plan_id__r.participant_id__r.DES_Tier__c, gf_business_plan_id__r.participant_id__r.DES_Country_of_Management__c, gf_business_plan_id__r.participant_id__r.DES_Segment__c */
                                     from bupl__BusinessPlan_Version__c Where Id In :triggerNew];
        for (bupl__BusinessPlan_Version__c bpv : listBPV) {
            if (bpv.bupl__gf_business_plan_id__r.bupl__gf_counter_number__c == 0) { //There is only one BPVersion (current BPVersion is the first one)
                mapBPVByGroupId.put(bpv.bupl__gf_business_plan_id__r.bupl__participant_id__c, bpv);

            } else {//There are more BPVersion for that BP (current BPVersion is NOT the first one)
                mapBPVToUpdatePreviousBPV.put(bpv.bupl__gf_business_plan_id__c, bpv.Id); // map (BPid, BPVid)
            }
        }

    // 1) Logic for the case: There is only one BPVersion (current BPVersion is the first version inserted)
        if (!mapBPVByGroupId.isEmpty()) {
            // get all previous BPI in orde to fill annual_expect_profit_py_amount__c later
            List<Id> listCurrentBPid = new List<Id>();
            for (bupl__BusinessPlan_Version__c bpv : mapBPVByGroupId.values()) {
                listCurrentBPid.add(bpv.bupl__gf_business_plan_id__c);
            }
            final Map<String,bupl__BusinessPlan_Item__c> mapPreviousBPI = DES_APloadUtils.getMapPreviousBPI(mapBPVByGroupId.keySet(), listCurrentBPid);

            // fill mapPipelineBPI with pipeline from: all open opportunities, and all closed win opportunities after last EnglobaUpdate
            final Map<String,Decimal> mapPipelineBPI = DES_APloadUtils.getMapPipelineBPI(mapBPVByGroupId.keySet());

            // get all booking list since last 2 years and store them in 3 maps (currentYear, lastYear, beforeLastYear)  with keyfield = AccountId
            final List<DES_Booking__c> listBooking = DES_APloadUtils.getListBookingsBPI(mapBPVByGroupId.keySet(),System.Today().year()-2);

            //At the end of the FOR loop, the map mapBPi will have all the initialized BPIs (and completed with booking information where avaible) to be inserted 
            for (DES_Booking__c booking : listBooking) {
                    String keyMapBPi = booking.DES_Client__c + '++' + DES_APloadUtils.getCountryLabelFromCountryBooking(booking.DES_Country__c) + '++' + booking.SOLUTION_CATEGORY_NAME__c; // Si viene de la carga de AP sólo puede venir un AP por cliente (group), por lo que el clientId nos sirve de indentificador (1 group => 1 AP => 1 BP)
                    if (!mapBPi.containskey(keyMapBPi) && DES_APloadUtils.isInListProductsEngloba(booking.SOLUTION_CATEGORY_NAME__c)) {
                        //El método initBPItemsClientCountry inicializa y devuelve todos los productos de ese "booking.DES_Client__c + '++' + DES_APloadUtils.getCountryLabelFromCountryBooking(booking.DES_Country__c)"
                        Map<String, bupl__BusinessPlan_Item__c> mapBPiAux = DES_APloadUtils.initBPItemsClientCountry (booking,mapBPVByGroupId.get(booking.DES_Client__c).Id);
                        mapBPi.putAll(mapBPiAux);
                    }

                    if (mapBPi.containskey(keyMapBPi)) { // de nuevo se vuelve a preguntar por si el Booking era un producto Engloba de los que no se tiene que tener encuenta en AP
                        // complete BusinessPlan_Item information: pipeline, previousBusinessPlanItem, total revenues (py, ytd, bpy)
                        //Se cambia la forma de calcular el campo bupl__annual_expect_profit_py_amount__c. Antes se traia el dato de bupl__expected_revenue_amount__c (expectitivas del año en curso del BP anterior),
                        // ahora se va a traer el campo bupl__pre_expct_prft_next_12m_amount__c, que tendrá las expectativas del año siguiente en el BP anterior 
                        if (mapPreviousBPI.containsKey(keyMapBPi) && mapBPi.get(keyMapBPi).bupl__annual_expect_profit_py_amount__c == 0) {
                            //mapBPi.get(keyMapBPi).bupl__annual_expect_profit_py_amount__c = mapPreviousBPI.get(keyMapBPi).bupl__expected_revenue_amount__c;
                            mapBPi.get(keyMapBPi).bupl__annual_expect_profit_py_amount__c = mapPreviousBPI.get(keyMapBPi).bupl__pre_expct_prft_next_12m_amount__c;
                        }

                        if (mapPipelineBPI.containsKey(keyMapBPi) && mapBPi.get(keyMapBPi).bupl__customer_open_oppy_amount__c == 0) {
                            mapBPi.get(keyMapBPi).bupl__customer_open_oppy_amount__c = mapPipelineBPI.get(keyMapBPi);
                        }

                        if (Integer.valueOf(booking.DES_Year__c) == System.Today().year()-2) {
                                mapBPi.get(keyMapBPi).bupl__expected_profit_2py_amount__c += booking.DES_Revenues__c;
                        } else If (Integer.valueOf(booking.DES_Year__c) == System.Today().year()-1) {
                                mapBPi.get(keyMapBPi).bupl__total_revenues_py_amount__c  += booking.DES_Revenues__c;
                        } else If (Integer.valueOf(booking.DES_Year__c) == System.Today().year()) {
                                mapBPi.get(keyMapBPi).bupl__gf_total_revenues_ytd_amount__c  += booking.DES_Revenues__c;
                        }
                    }
            }// fin FOR
        } // Fin IF(!mapBPVByGroupId.isEmpty()
    /////////////////////////////////////////////////


    // 2) Logic for the case: There are more BPVersion for that BP (current BPVersion is NOT the first one)
        if (!mapBPVToUpdatePreviousBPV.isEmpty()) {
        //After insert a new BPversion in a BP with previous versions, it is necessary to update previous versions (making them as inactive), and BP Items are cloned from old BPversion to new BPversion
            mapBPi.putAll(setInactivePreviousBPVandCloneBPI(mapBPVToUpdatePreviousBPV));
        }
    /////////////////////////////////////////////////

        //insert all new BPIs from 1) + 2)
        if (!mapBPi.isEmpty()) {
            insert mapBPi.values();
        }


    }


   /*
    * @author       Global Desktop
    * @Description  After insert a new BPversion in a BP with previous versions, update previous versions (making them as inactive)
    *               and then clone the BP Items from old BPversion to new BPversion
    */
    private Map<String,bupl__BusinessPlan_Item__c> setInactivePreviousBPVandCloneBPI (Map<Id,Id> mapActiveBpv) {
        Map<String,bupl__BusinessPlan_Item__c> mapNewBPICloned = new Map<String,bupl__BusinessPlan_Item__c>();
        Map<Id,bupl__BusinessPlan_Version__c> mapBPVtoUpdate = new Map<Id,bupl__BusinessPlan_Version__c>();

        List<bupl__BusinessPlan_Item__c> listBPItoClone = [Select Id,bupl__gf_business_plan_version_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c, 
                            bupl__gf_cross_border_rev_ind_type__c, bupl__gf_cross_sell_rev_ind_type__c, bupl__solution_category_desc__c, industry_desc__c, tier_desc__c, bupl__gf_booking_operation_cntry_id__c, bupl__solution_category_id__c, 
                            bupl__annual_expect_profit_py_amount__c, bupl__customer_open_oppy_amount__c, bupl__gf_total_revenues_ytd_amount__c, bupl__total_revenues_py_amount__c, bupl__expected_profit_2py_amount__c, 
                            bupl__pre_expct_prft_next_12m_amount__c, bupl__expected_revenue_amount__c, bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c
                            From bupl__BusinessPlan_Item__c 
                            Where bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c IN :mapActiveBpv.keySet() And 
                                        bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_act_ind_type__c = 'Yes' And 
                                        bupl__gf_business_plan_version_id__c NOT IN :mapActiveBpv.values()];

        if (!listBPItoClone.isEmpty()) {
            for (bupl__BusinessPlan_Item__c bpi : listBPItoClone) {
                // add BP previous version to update it (set inactive)
                if (!mapBPVtoUpdate.containsKey(bpi.bupl__gf_business_plan_version_id__c)) {
                    mapBPVtoUpdate.put(bpi.bupl__gf_business_plan_version_id__c,new bupl__BusinessPlan_Version__c(Id=bpi.bupl__gf_business_plan_version_id__c,bupl__gf_business_plan_act_ind_type__c='No'));
                }

                // add the cloned new BP items
                String keyMapBPi = bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c + '++' + bpi.bupl__gf_booking_operation_cntry_id__c + '++' + bpi.bupl__solution_category_desc__c; 
                bupl__BusinessPlan_Item__c newClonedBPI = new bupl__BusinessPlan_Item__c (
                    bupl__gf_cross_border_rev_ind_type__c = bpi.bupl__gf_cross_border_rev_ind_type__c,
                    bupl__gf_cross_sell_rev_ind_type__c = bpi.bupl__gf_cross_sell_rev_ind_type__c,
                    bupl__solution_category_desc__c = bpi.bupl__solution_category_desc__c,
                    industry_desc__c = bpi.industry_desc__c,
                    tier_desc__c = bpi.tier_desc__c,
                    bupl__gf_business_plan_version_id__c = mapActiveBpv.get(bpi.bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__c),
                    bupl__gf_booking_operation_cntry_id__c =  bpi.bupl__gf_booking_operation_cntry_id__c,
                    bupl__solution_category_id__c = bpi.bupl__solution_category_id__c,
                    bupl__annual_expect_profit_py_amount__c = bpi.bupl__annual_expect_profit_py_amount__c,
                    bupl__customer_open_oppy_amount__c = bpi.bupl__customer_open_oppy_amount__c,
                    bupl__gf_total_revenues_ytd_amount__c = bpi.bupl__gf_total_revenues_ytd_amount__c,
                    bupl__total_revenues_py_amount__c = bpi.bupl__total_revenues_py_amount__c,
                    bupl__expected_profit_2py_amount__c = bpi.bupl__expected_profit_2py_amount__c,
                    bupl__pre_expct_prft_next_12m_amount__c = bpi.bupl__pre_expct_prft_next_12m_amount__c,
                    bupl__expected_revenue_amount__c = bpi.bupl__expected_revenue_amount__c
                );
                mapNewBPICloned.put(keyMapBPi,newClonedBPI);

            } // for
        }// IF

        if (!mapBPVtoUpdate.isEmpty()) {
           update mapBPVtoUpdate.values();
        }

        return mapNewBPICloned;
    }
    
    /*
    * @author       Global Desktop
    * @Description  Creates audit records
    */
    public void insertAudit(List<bupl__BusinessPlan_Version__c> triggerNew) {
        final List<dwp_cvad__Action_Audit__c> actAudToInsert = new List<dwp_cvad__Action_Audit__c>();
        
        Set<Id> bpSet;
        bpSet = new Set<Id>();
        for(bupl__BusinessPlan_Version__c bpVersion : triggerNew) {
            bpSet.add(bpVersion.bupl__gf_business_plan_id__c);
        }
        System.debug('bpSet: ' + bpSet);
        //para luego comprobar si se está insertando la primera versión o no
        final List<AggregateResult> bpvList = [SELECT bupl__gf_business_plan_id__c bpId, count(id)bpvSum FROM bupl__BusinessPlan_Version__c WHERE bupl__gf_business_plan_id__c IN :bpSet GROUP BY bupl__gf_business_plan_id__c ];
        System.debug('bpvList: ' + bpvList);
        Map<String, Integer> bpvSumMap;
        bpvSumMap = new Map<String, Integer>();
        
        for(AggregateResult bpvAux : bpvList) {
            bpvSumMap.put((String)bpvAux.get('bpId'), (Integer)bpvAux.get('bpvSum'));
        }
        System.debug('bpvSumMap: ' + bpvSumMap);
        //obtengo los ap de los bp
        final Map<Id, bupl__BusinessPlan__c> bpMap = new Map<Id, bupl__BusinessPlan__c>([SELECT Id, acpl__gf_account_planning_id__c FROM bupl__BusinessPlan__c WHERE Id IN :bpSet]);
        
        for (bupl__BusinessPlan_Version__c bpvAux : triggerNew) {
            System.debug('la suma de versiones de bp es: ' + bpvSumMap.get(bpvAux.bupl__gf_business_plan_id__c));
            if (bpMap.get(bpvAux.bupl__gf_business_plan_id__c).acpl__gf_account_planning_id__c != null
               && bpvSumMap.get(bpvAux.bupl__gf_business_plan_id__c) > 1) {
                    //final String audName = 'Business Plan Version created by';
                    final Id audUserId = bpvAux.CreatedById;
                    //final String audStyle =  'infoAlt';
                    final dwp_cvad__Action_Audit__c newActAud = createActionAudit(bpMap.get(bpvAux.bupl__gf_business_plan_id__c).acpl__gf_account_planning_id__c, 'Business Plan Version created by', audUserId, 'infoAlt');
                    actAudToInsert.add(newActAud);
                }
        }
        if (!actAudToInsert.isEmpty()) {
            final List<dwp_cvad__Action_Audit_Detail__c> actAudDetToInsert = new List<dwp_cvad__Action_Audit_Detail__c>();
            insert actAudToInsert;            
            for (dwp_cvad__Action_Audit__c aa : actAudToInsert) {
                String detailContent = string.valueOf(date.today());
                if (Trigger.isInsert) {
                    detailContent = 'Creation date: <b>' + detailContent + '</b>';
                }
                final dwp_cvad__Action_Audit_Detail__c newActAudDet = createActionAuditDetail(aa.Id, detailContent);
                actAudDetToInsert.add(newActAudDet);
            }
            insert actAudDetToInsert;
        }
    }
 
        
    /*
    * @author       Global Desktop
    * @Description  Create a record on Action Audit object.
    */
    public static dwp_cvad__Action_Audit__c createActionAudit(Id accountPlanningId, String auditName, Id auditUserId, String auditStyle) {
        return new dwp_cvad__Action_Audit__c(
            dwp_cvad__action_audit_date__c = Datetime.now(),
            dwp_cvad__action_audit_object_api_name__c = 'acpl__Account_Planning__c',
            dwp_cvad__action_audit_record_id__c = accountPlanningId,
            dwp_cvad__action_audit_style__c = auditStyle,
            dwp_cvad__action_audit_type__c = 'AccountPlanning',
            dwp_cvad__action_audit_name__c = auditName,
            dwp_cvad__action_audit_user_id__c = auditUserId
            );
    }
    
    /*
    * @author       Global Desktop
    * @Description  Create a record on Auction Audit Details object.
    */
    public static dwp_cvad__Action_Audit_Detail__c createActionAuditDetail(Id actionAuditId, String detailContent) {
        return new dwp_cvad__Action_Audit_Detail__c(
            dwp_cvad__action_audit_detail_content_format__c = 'HTML',
            dwp_cvad__action_audit_detail_display_order__c = 1,
            dwp_cvad__action_audit_detail_display_type__c = 'Embedded',
            dwp_cvad__action_audit_detail_content__c = detailContent,
            dwp_cvad__action_audit_id__c = actionAuditId
        	);
    }
    

}