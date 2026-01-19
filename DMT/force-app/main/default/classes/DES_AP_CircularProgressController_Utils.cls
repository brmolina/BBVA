/**
 * Author	:	Global Desktop
 * Desc		:	DES_AP_CircleGauge_YTD utils
 * */
public with sharing class DES_AP_CircularProgressController_Utils {//NOSONAR
	/**
	* Calculates the information about ytd booking
	**/
	public static List<DES_Booking__c> queryBooking(Boolean currentYear, string  groupId) {
        	List<DES_Booking__c> lstBoocking = new List <DES_Booking__c>();
			lstBoocking = [select id,convertCurrency(DES_Current_Year_Revenues__c),DES_XB__c from DES_Booking__c where DES_Current_Year__c =: currentYear and DES_Client__c=:groupId];
		return lstBoocking;
    }
	/**
	* Calculates the information about bpitem
	**/
	public static List<bupl__BusinessPlan_Item__c> queryBusinessPlan(string groupId, string apId, string launchPeriod) {
            final string yearToday =  string.valueOf(System.Today().year());
            final List<DES_Booking__c> lstBoocking = queryBooking(true,groupId);//NOSONAR
            List<bupl__BusinessPlan_Item__c> queryBusinessPlan = new List<bupl__BusinessPlan_Item__c>();
             if(launchPeriod.substring(0,2).contains(YearToday.substring(2,4))) {
    	System.debug('El AP corresponde al año actual');
             //Si el AP corresponde con el año actual y existen registros de booking para este año obtenemos los bpitems
         queryBusinessPlan = [SELECT convertCurrency(bupl__gf_total_revenues_ytd_amount__c)current, 
                                           				convertCurrency(bupl__expected_revenue_amount__c)expected, bupl__gf_cross_border_rev_ind_type__c,
                                                       	convertCurrency(bupl__total_revenues_py_amount__c)lastYearR,
                                                       bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba_Month__c
                                                       	FROM bupl__BusinessPlan_Item__c 
                                                       	WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                             AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                       AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = :groupId];
         
        //El AP no corresponde al año actual
      } else {
	   		 System.debug('El AP no corresponde al año actual');
            //Si no existen registros de booking de este año, utilizamos los campos del año anterior del bpitem
             if (lstBoocking.isEmpty()) {
        		 queryBusinessPlan = [SELECT convertCurrency(bupl__gf_total_revenues_ytd_amount__c)current, 
                                           				convertCurrency(bupl__expected_revenue_amount__c)expected, bupl__gf_cross_border_rev_ind_type__c,
                                                       	convertCurrency(bupl__total_revenues_py_amount__c)lastYearR,
                                                       bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba_Month__c
                                                       	FROM bupl__BusinessPlan_Item__c 
                                                       	WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                             AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                       AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = :groupId];
          
            //si existen registros de booking del año actual, utilizamos los campos n+1 del AP
           } else {
               //Entro al else que coge los expected del n+1
                 queryBusinessPlan = [SELECT convertCurrency(bupl__gf_total_revenues_ytd_amount__c)current, 
                                           				convertCurrency(bupl__pre_expct_prft_next_12m_amount__c)expected, bupl__gf_cross_border_rev_ind_type__c,
                                                       	convertCurrency(bupl__gf_total_revenues_ytd_amount__c)lastYearR,
                                                       bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba_Month__c
                                                       	FROM bupl__BusinessPlan_Item__c 
                                                       	WHERE bupl__gf_business_plan_version_id__r.bupl__gf_bus_pl_lst_vldt_vr_ind_type__c = true
                                                           AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.acpl__gf_account_planning_id__c = :apId
                                                       AND bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = :groupId];
            }
			}
			
             return queryBusinessPlan;
			}
		}