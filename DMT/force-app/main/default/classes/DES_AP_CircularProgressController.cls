/**
 * Author	:	Global Desktop
 * Desc		:	DES_AP_CircleGauge_YTD controller
 * */
public with sharing class DES_AP_CircularProgressController {
    /* Declarando variable */
    public static final String ZERONUM = '0';
    @AuraEnabled
    /**
	* Calculates the information needed in DES_AP_CircleGauge_YTD chart
	**/
    public static List<String> calculateCircleInfo(String recordId) {
        final String groupId = getGroupId(recordId);
        final String apId = getApId(recordId);
        List<String> revenuesList;
        revenuesList = new List<String>();
        final string launchPeriod = getLaunchPeriod(recordId);
        //Comprobamos si existen registros de booking
		List<DES_Booking__c>  lstBoocking       =  DES_AP_CircularProgressController_Utils.queryBooking(true,groupId);//NOSONAR
        final List<bupl__BusinessPlan_Item__c> bpitemList = DES_AP_CircularProgressController_Utils.queryBusinessPlan (groupId, apId, LaunchPeriod);   
        System.debug('bpitemList: ' + bpitemList);
        Decimal englobaMonth;

        if(!bpitemList.isEmpty()) {

            final Date currentDate = Date.today();
            Decimal currentRevenues = 0;
            Decimal currentRevenuesXB = 0;
            Decimal expRevenues = 0;
            Decimal expRevenuesXB = 0;
            Decimal lastYearRev = 0;
            Decimal lastYearRevXB = 0;

            if(bpitemList.get(0).bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba_Month__c == null) {
            	englobaMonth = 0;
            } else {
                englobaMonth = bpitemList.get(0).bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__r.DES_Revenue_Update_Engloba_Month__c;
            }
            for (bupl__BusinessPlan_Item__c bpitemAux : bpitemList) {
                currentRevenues += (Decimal)bpitemAux.get('current');
                expRevenues += (Decimal)bpitemAux.get('expected');
                lastYearRev += (Decimal)bpitemAux.get('lastYearR');
                if(bpitemAux.bupl__gf_cross_border_rev_ind_type__c == Label.DES_YES) {
                    currentRevenuesXB += (Decimal)bpitemAux.get('current');
                    expRevenuesXB += (Decimal)bpitemAux.get('expected');
                    lastYearRevXB += (Decimal)bpitemAux.get('lastYearR');
                }
            } 
			system.debug('groupId========='+groupId+' currentRevenues=='+currentRevenues);
			//AJUSTE recalcula las revenues del año actual
			currentRevenues = 0; 
            currentRevenuesXB = 0;
           if (lstBoocking.isEmpty()) {
            //Entra al current year booking false
                lstBoocking       = DES_AP_CircularProgressController_Utils.queryBooking(false,groupId);
           } 
       
            for(Integer i=0;i<lstBoocking.size();i++) {
              
                if(lstBoocking[i].DES_XB__c==true) {
                    currentRevenuesXB += lstBoocking[i].DES_Current_Year_Revenues__c;
                }
                currentRevenues += lstBoocking[i].DES_Current_Year_Revenues__c;
            }
            system.debug('currentRevenues=='+currentRevenues);

            final Decimal currVSexp = calculateVS(currentRevenues, expRevenues);
            final Decimal currVSexpXB = calculateVS(currentRevenuesXB, expRevenuesXB);
            final Decimal prorrateMonth = calculateMonth(englobaMonth, currentDate.month());
            final Decimal yoy = calculateYoy(currentRevenues, lastYearRev/12*prorrateMonth);
            final Decimal yoyXB = calculateYoy(currentRevenuesXB, lastYearRevXB/12*prorrateMonth);
            revenuesList.add(formatNum(currVSexp));
            revenuesList.add(formatNum(currVSexpXB));
            revenuesList.add(formatNum(currentRevenues));
            revenuesList.add(formatNum(currentRevenuesXB));
            revenuesList.add(formatNum(expRevenues));
            revenuesList.add(formatNum(expRevenuesXB));
            revenuesList.add(formatNum(yoy));
            revenuesList.add(formatNum(yoyXB));
        }
        System.debug('revenuesList: ' + revenuesList);
        return revenuesList;
    }
    
    /**
	* gets the group id
	**/
    public static String getGroupId(String recordId) {
        return [SELECT participant_id__c FROM DES_Group_Analysis__c WHERE Id = :recordId LIMIT 1].participant_id__c;
    }
    
    /**
	* gets the AP id
	**/
    public static String getApId(String recordId) {
        return [SELECT gf_account_planning_id__c FROM DES_Group_Analysis__c WHERE Id = :recordId LIMIT 1].gf_account_planning_id__c;
    }
    
     /**
	* gets the AP Launch period
	**/
    public static String getLaunchPeriod (String recordId) {
        return [SELECT gf_account_planning_id__r.acpl__gf_ap_launch_period_desc__c FROM DES_Group_Analysis__c WHERE Id = :recordId LIMIT 1].gf_account_planning_id__r.acpl__gf_ap_launch_period_desc__c;
    }
    
    /**
	* Calculates the yoy
	**/
    public static Decimal calculateYoy(Decimal currentRevenues, Decimal lastRevenues) {
        Decimal yoy;
        yoy = 0;
        if(lastRevenues == 0) {
            yoy = 0;
        } else {
            yoy = (currentRevenues - lastRevenues) / lastRevenues * 100;
        }
        return yoy.setScale(2);
    }
    
    /**
	* Calculates the month for calculating the YoY
	**/
    public static Decimal calculateMonth(Decimal englobaMonth, Decimal currentMonth) {
        Decimal prorrateMonth = englobaMonth;
        system.debug(prorrateMonth);
        if(englobaMonth == 0) {
            prorrateMonth = currentMonth;
            system.debug(prorrateMonth);
        }
        return prorrateMonth;
      
        
    }
    
    /**
	* Calculates current VS expected revenues
	**/
    public static Decimal calculateVS(Decimal currentRevenues, Decimal expectedRevenues) {
        Decimal currVSexp;
        currVSexp = 0;
        if(expectedRevenues == 0) {
            system.debug(expectedRevenues + 'expected revenues');
            currVSexp = 100;
        } else {
            currVSexp = 100*(currentRevenues / expectedRevenues);
            system.debug(currVSexp + 'division');
        }
        return currVSexp.setScale(2);
    }
    
    /**
	* Formato número 
	**/
    private static String formatNum(Decimal aux) {
       String auy = String.valueOf(aux);
       String auz = '.';
       String returnVal;
       returnVal = String.valueOf(aux);
       if(auy.contains(',')) {
           auz = ',';
       }
        if(auy == ZERONUM) {
            auy = '0';
        } else {
            auy = auy.substring(0, auy.indexOf(auz));
        }       
       if(aux - Decimal.valueOf(auy) == 0) {
           returnVal = aux.format() + auz + '00';
       } else {
           returnVal = aux.format();
       }
       return returnVal;
   }
}