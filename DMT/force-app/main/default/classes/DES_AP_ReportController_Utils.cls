/**
 * Author	:	Global Desktop
 * Desc		:	DES_AP_CircleGauge_YTD utils
 * */
public with sharing class DES_AP_ReportController_Utils {//NOSONAR
	/**
	* Calculates the information about ytd booking for country
	**/
	public static List<DES_Booking__c> queryBookingCountry(Boolean currentYear, string  groupId) {
        	List<DES_Booking__c> lstBoocking = new List <DES_Booking__c>();
			lstBoocking = [select id,DES_Current_Year_Revenues__c,DES_Country__c from DES_Booking__c where DES_Current_Year__c=:currentYear and DES_Client__c=:groupId];
		return lstBoocking;
    }
	/**
	* Calculates the information about bpitem for country
	**/
	public static List <AggregateResult> queryBusinessPlanCountry(string groupId, string apId, string launchPeriod) {
            final string yearToday =  string.valueOf(System.Today().year());
            final List<DES_Booking__c> lstBoocking = queryBookingCountry(true,groupId);//NOSONAR
            List <AggregateResult> queryBusinessPlan = new List <AggregateResult>();
                     if(launchPeriod.substring(0,2).contains(YearToday.substring(2,4))) {
    	System.debug('El AP corresponde al año actual');
             //Si el AP corresponde con el año actual y existen registros de booking para este año obtenemos los bpitems
 
    			  queryBusinessPlan  = [SELECT bupl__gf_booking_operation_cntry_id__c country,sum(bupl__gf_total_revenues_ytd_amount__c) current,sum(bupl__expected_revenue_amount__c) expected
                                                FROM bupl__BusinessPlan_Item__c 
                                                WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c=:groupId
                                          		AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                group by bupl__gf_booking_operation_cntry_id__c];
		
         
         } else {
	   		 System.debug('El AP no corresponde al año actual');
            //Si no existen registros de booking de este año, utilizamos los campos del año anterior del bpitem
             if (lstBoocking.isEmpty()) {
                   queryBusinessPlan  = [SELECT bupl__gf_booking_operation_cntry_id__c country,sum(bupl__gf_total_revenues_ytd_amount__c) current,sum(bupl__expected_revenue_amount__c) expected
                                                FROM bupl__BusinessPlan_Item__c 
                                                WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c=:groupId
                                          		AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                group by bupl__gf_booking_operation_cntry_id__c];
		
          } else {
                queryBusinessPlan  = [SELECT bupl__gf_booking_operation_cntry_id__c country,sum(bupl__gf_total_revenues_ytd_amount__c) current,sum(bupl__pre_expct_prft_next_12m_amount__c) expected
                                                FROM bupl__BusinessPlan_Item__c 
                                                WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c=:groupId
                                          		AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                group by bupl__gf_booking_operation_cntry_id__c];
		
          } 
        }
			
             return queryBusinessPlan;
			}
    
    /**
	* Calculates the information about ytd product for bpitem logic
	**/
	public static List<DES_Booking__c> queryBookingProduct(string groupId) {
        	List<DES_Booking__c> lstBoocking = new List <DES_Booking__c>();
			lstBoocking = [select id,DES_Current_Year_Revenues__c,DES_Type__c from DES_Booking__c where DES_Current_Year__c= true and DES_Client__c=:groupId];
		return lstBoocking;
    }

       /**
	* Calculates the information about ytd product
	**/
	public static List<DES_Booking__c> queryBookingProductfalse(string groupId) {
        List<DES_Booking__c> lstBoocking = new List <DES_Booking__c>();
        	if (queryBookingProduct(groupId).isEmpty()) {
            lstBoocking = [select id,DES_Current_Year_Revenues__c,DES_Type__c from DES_Booking__c where DES_Current_Year__c=false and DES_Client__c=:groupId];

          } else {
            lstBoocking = queryBookingProduct(groupId);
          }
          return lstBoocking;
    }
    /**
	* Calculates the information about bpitem for product
	**/
    public static List <AggregateResult> queryBusinessPlanProduct(string groupId, string apId, string launchPeriod) {
            final string yearToday =  string.valueOf(System.Today().year());
            final List<DES_Booking__c> lstBoocking = queryBookingProduct(groupId);//NOSONAR
            List <AggregateResult> queryBusinessPlan = new List <AggregateResult>();
                     if(launchPeriod.substring(0,2).contains(YearToday.substring(2,4))) {
    	System.debug('El AP corresponde al año actual');
             //Si el AP corresponde con el año actual y existen registros de booking para este año obtenemos los bpitems
       
       	 	queryBusinessPlan  = [SELECT bupl__solution_category_id__c product,sum(bupl__gf_total_revenues_ytd_amount__c) current,sum(bupl__expected_revenue_amount__c) expected
                                                FROM bupl__BusinessPlan_Item__c 
                                                WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                           						AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c=:groupId
                                                group by bupl__solution_category_id__c];

      
        } else {
	   		 System.debug('El AP no corresponde al año actual');
            //Si no existen registros de booking de este año, utilizamos los campos del año anterior del bpitem
             if (lstBoocking.isEmpty()) {
                 queryBusinessPlan  = [SELECT bupl__solution_category_id__c product,sum(bupl__gf_total_revenues_ytd_amount__c) current,sum(bupl__expected_revenue_amount__c) expected
                                                FROM bupl__BusinessPlan_Item__c 
                                                WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                               				 	AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c=:groupId
                                                group by bupl__solution_category_id__c];

          } else {
              queryBusinessPlan  = [SELECT bupl__solution_category_id__c product,sum(bupl__gf_total_revenues_ytd_amount__c) current,sum(bupl__pre_expct_prft_next_12m_amount__c) expected
                                                FROM bupl__BusinessPlan_Item__c 
                                                WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                             					AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c=:groupId
                                                group by bupl__solution_category_id__c];
          }
        }
			
             return queryBusinessPlan;
			}
		}