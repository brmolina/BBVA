/**
* @author       Global Desktop
* @date         12/03/2020
* @description
**/
public without sharing class DES_AP_ConfigurationHandler {

    /*instance*/
    public static DES_AP_ConfigurationHandler instance;


    /*
    * @author       Global Desktop
    * @Description  Constructor
    */
    private DES_AP_ConfigurationHandler() {
        System.debug('CONSTRUCTOR');
    }

    /*
    * @author       Global Desktop
    * @Description  getInstance
    */
    public static DES_AP_ConfigurationHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_AP_ConfigurationHandler();
        }
        return instance;
    }
    
    /*
    * @author       Global Desktop
    * @Description  Updates the Due Date when event days change
    */
    public void fillDueDate(List<acpl__AP_PeriodConfiguration__c> triggernew, Map<Id, acpl__AP_PeriodConfiguration__c> triggerOldMap) {
        System.debug('fillDueDate');
        if(triggernew.get(0).acpl__gf_ap_edit_days_left_number__c != triggerOldMap.get(triggernew.get(0).Id).acpl__gf_ap_edit_days_left_number__c) {
            List<acpl__AP_Period__c> periodList = [SELECT Id, acpl__gf_ap_priority_edit_type__c, acpl__gf_ap_edit_end_date__c  FROM acpl__AP_Period__c LIMIT 2000];
            List<acpl__Account_Planning__c> apList = [SELECT Id, acpl__gf_ap_limit_date__c, acpl__gf_ap_priority_type_name__c, acpl__gf_event_date__c FROM acpl__Account_Planning__c 
                                                     WHERE acpl__gf_ap_launch_name__c = 'Event driven' AND acpl__gf_ap_limit_date__c != null 
                                                      AND acpl__gf_ap_substatus_type_name__c != :Label.AP_Timed_Out AND RecordType.DeveloperName ='Account_Planning'
                                                     AND acpl__gf_event_date__c != null];
            System.debug('apList: ' + apList);
            List<acpl__Account_Planning__c> apsToUpdate;
            apsToUpdate = new List<acpl__Account_Planning__c>();
            
            if(triggernew.get(0).acpl__gf_ap_edit_prms_type_name__c == 'General') {
                for(acpl__Account_Planning__c apAux : apList) {
                    System.debug('apAux de AP_CONFIG:' + apAux);
                    Date eventDrivenDate = calculateDate(apAux, triggernew);
                    if(apAux.acpl__gf_ap_priority_type_name__c == null || apAux.acpl__gf_ap_priority_type_name__c == '') {
                        if(!periodList.isEmpty() && periodList.get(0).acpl__gf_ap_edit_end_date__c < eventDrivenDate) {
                            System.debug('tiene fecha de evento y > la configurada');
                        	apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                        	apsToUpdate.add(apAux);
                        } else if(!periodList.isEmpty() && apAux.acpl__gf_ap_limit_date__c != periodList.get(0).acpl__gf_ap_edit_end_date__c) {
                            apAux.acpl__gf_ap_limit_date__c = periodList.get(0).acpl__gf_ap_edit_end_date__c;
                            apsToUpdate.add(apAux);
                        }
                    } else {//si no tiene prioridad, cambiamos su due date sólo si tiene evento
                    	apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                        apsToUpdate.add(apAux);
                    }
                }
            } else if(triggernew.get(0).acpl__gf_ap_edit_prms_type_name__c == 'Wave') {
                System.debug('prioridad!');
                Map<String, Date> priorityDateMap;
                priorityDateMap = new Map<String, Date>();
                for(acpl__AP_Period__c periodAux : periodList) {
                    priorityDateMap.put(periodAux.acpl__gf_ap_priority_edit_type__c, periodAux.acpl__gf_ap_edit_end_date__c);
                }
                System.debug('priorityDateMap: ' + priorityDateMap);
                for(acpl__Account_Planning__c apAux : apList) {
                    System.debug('apAux:' + apAux);
                    System.debug('apAux.acpl__gf_ap_limit_date__c:' + apAux.acpl__gf_ap_limit_date__c);
                    System.debug('apAux.acpl__gf_event_date__c:' + apAux.acpl__gf_event_date__c);
                    System.debug('priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c):' + priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c));
                    
                    Date eventDrivenDate = calculateDate(apAux, triggernew);
                    if(priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) == null) {//si no tiene prioridad configurada
                        apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                        apsToUpdate.add(apAux);
                    } else { 
                    	System.debug('eventDrivenDate:' + eventDrivenDate);
                        if(priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) > eventDrivenDate) {
                            if(apAux.acpl__gf_ap_limit_date__c != eventDrivenDate) {
                                System.debug('le planto la prioridad');
                                apAux.acpl__gf_ap_limit_date__c = priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c);
                                apsToUpdate.add(apAux);
                            }
                        } else if(apAux.acpl__gf_ap_limit_date__c != eventDrivenDate) {
                            System.debug('le planto el evento');
                            apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                            apsToUpdate.add(apAux);
                        }
                    }
                }
            } else { //si no hay periodos configurados, ponemos siempre la fecha del evento
                for(acpl__Account_Planning__c apAux : apList) {
                    Date eventDrivenDate = calculateDate(apAux, triggernew);
                    if(apAux.acpl__gf_ap_limit_date__c != eventDrivenDate) {
                        apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                        apsToUpdate.add(apAux);
                    }
                }
            }
            update apsToUpdate;
        }
    }
 
    /*
    * @author       Global Desktop
    * @Description  Calculates the evend driven date end
    */
    public Date calculateDate(acpl__Account_Planning__c apAux, List<acpl__AP_PeriodConfiguration__c> triggernew) {
        Integer numOfDays = 0;
        Date returnDate = apAux.acpl__gf_event_date__c;
        System.debug('returnDate1:' + returnDate);
        if(triggernew.get(0).acpl__gf_ap_edit_days_left_number__c != null) {
            numOfDays = (Integer)triggernew.get(0).acpl__gf_ap_edit_days_left_number__c;
            System.debug('numOfDays:' + numOfDays);
        }
        if(apAux.acpl__gf_event_date__c < apAux.acpl__gf_event_date__c.addDays(numOfDays)) {
            returnDate = apAux.acpl__gf_event_date__c.addDays(numOfDays);
            System.debug('returnDate2:' + returnDate);
        }
        System.debug('returnDate:' + returnDate);
        return returnDate;
    }
            
}