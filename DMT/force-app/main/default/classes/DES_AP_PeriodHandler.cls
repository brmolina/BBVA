/**
* @author       Global Desktop
* @date         12/03/2020
* @description
**/
public without sharing class DES_AP_PeriodHandler {

    /*instance*/
    public static DES_AP_PeriodHandler instance;


    /*
    * @author       Global Desktop
    * @Description  Constructor
    */
    private DES_AP_PeriodHandler() {
        System.debug('CONSTRUCTOR');
    }

    /*
    * @author       Global Desktop
    * @Description  getInstance
    */
    public static DES_AP_PeriodHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new DES_AP_PeriodHandler();
        }
        return instance;
    }
    
    /*
    * @author       Global Desktop
    * @Description  Updates the Due Date when new periods are inserted
    */
    public void fillDueDate(List<acpl__AP_Period__c> triggernew, Map<Id, acpl__AP_Period__c> triggerOldMap) {
        System.debug('fillDueDate');
        String notThePeriod = '';
        // cuando nuevos periodos se insertan, busco los APs que cumplen las condiciones
        if(triggernew.get(0).acpl__gf_ap_priority_edit_type__c == '' || triggernew.get(0).acpl__gf_ap_priority_edit_type__c == null) {
            System.debug('periodo general con este triggernew: ' + triggernew);
            //actualizo la due date de los launch type = general y event driven con fecha menor
            updateNewGeneralAPs(triggernew.get(0).acpl__gf_ap_edit_end_date__c);
            //borro la due date de los launch type = prioridad
            if(triggerOldMap == null) {
                System.debug('periodo general de inserción');
                notThePeriod = 'Period by wave';
            	emptyDueDateAPs(notThePeriod);
            }
        } else {
            System.debug('periodo prioridad');
            List<acpl__AP_Period__c> periodList = [SELECT Id, acpl__gf_ap_priority_edit_type__c, acpl__gf_ap_edit_end_date__c FROM acpl__AP_Period__c];
            Map<String, Date> priorityDateMap;
            priorityDateMap = new Map<String, Date>();
            for(acpl__AP_Period__c periodAux : periodList) {
                priorityDateMap.put(periodAux.acpl__gf_ap_priority_edit_type__c, periodAux.acpl__gf_ap_edit_end_date__c);
            }
            //actualizo la due date de los launch type = prioridad y event driven con fecha menor
            updateNewPriorityAPs(priorityDateMap);
            //borro la due date de los launch type = general
            if(triggerOldMap == null) {
                System.debug('periodo prioridad de inserción');
            	notThePeriod = 'General period';
            	emptyDueDateAPs(notThePeriod);
            }
        }
    } 
    
    /*
    * @author       Global Desktop
    * @Description  Actualiza la due date de los APs de GENERAL o por evento con fecha menor que el periodo general
    */
    public void updateNewGeneralAPs(Date endDate) {
        final acpl__AP_PeriodConfiguration__c config = [SELECT Id, acpl__gf_ap_edit_prms_type_name__c, acpl__gf_ap_edit_days_left_number__c FROM acpl__AP_PeriodConfiguration__c LIMIT 1];

        System.debug('updateNewGeneralAPs');
         List<acpl__Account_Planning__c> apsToUpdate;
        apsToUpdate = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> apList = [SELECT Id, acpl__gf_ap_limit_date__c, acpl__gf_event_date__c, acpl__gf_ap_launch_name__c, acpl__gf_ap_priority_type_name__c FROM acpl__Account_Planning__c 
                                                  WHERE acpl__gf_ap_substatus_type_name__c != :Label.AP_Timed_Out AND RecordType.DeveloperName ='Account_Planning'
                                                  AND (
                                                      acpl__gf_ap_launch_name__c = 'General period'
                                                      OR  (acpl__gf_ap_launch_name__c = 'Event driven'))
                                                  ];
        System.debug('apList: ' + apList);
        
        List<acpl__Account_Planning__c> generalList;
        generalList = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> eventList;
        eventList = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> eventListP;
        eventListP = new List<acpl__Account_Planning__c>();
       
        
        for(acpl__Account_Planning__c apAux : apList) {
            if(apAux.acpl__gf_ap_launch_name__c == 'General period') {
                generalList.add(apAux);
            } else if(apAux.acpl__gf_ap_priority_type_name__c == null || apAux.acpl__gf_ap_priority_type_name__c == '') {
                eventList.add(apAux);
            } else {
                eventListP.add(apAux);
            }
        }
        //APs General Period
        for(acpl__Account_Planning__c apAux : generalList) {
            if(apAux.acpl__gf_ap_limit_date__c != endDate) { //si la configurada es diferente, le pongo la nueva
                apAux.acpl__gf_ap_limit_date__c = endDate;
                apsToUpdate.add(apAux);
            }
        }
        
        //APs Event driven con prioridad
        for(acpl__Account_Planning__c apAux : eventListP) {
            if(apAux.acpl__gf_event_date__c == null) {
                if(apAux.acpl__gf_ap_limit_date__c != null) {
                    apAux.acpl__gf_ap_limit_date__c = null;
                    apsToUpdate.add(apAux);
                }
            } else {
                Date eventDrivenDate = calculateDate(apAux, config);
                if(apAux.acpl__gf_ap_limit_date__c != eventDrivenDate) {
                    apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                    apsToUpdate.add(apAux);
                }
            }
        }
        
        //APs Event driven sin prioridad
        for(acpl__Account_Planning__c apAux : eventList) {
            if(apAux.acpl__gf_event_date__c == null) { //si no tiene evento, pongo la configurada si ha cambiado
                if(apAux.acpl__gf_ap_limit_date__c != endDate) {
                    apAux.acpl__gf_ap_limit_date__c = endDate;
                    apsToUpdate.add(apAux);
                }
            } else {//si tiene evento calculo la eventDrivenDate
                Date eventDrivenDate = calculateDate(apAux, config);
                if(endDate > eventDrivenDate) { //si la configurada es mayor que la calculada, pongo la nueva configurada
                    apAux.acpl__gf_ap_limit_date__c = endDate;
                    apsToUpdate.add(apAux);
                } else if(apAux.acpl__gf_ap_limit_date__c != eventDrivenDate) { //si no, si la calculada y la due date son diferentes, pongo la calculada
                    apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                    apsToUpdate.add(apAux);
                }
            }
        }
		System.debug('apsToUpdate: ' + apsToUpdate);
        if(!apsToUpdate.isEmpty()) {
            update apsToUpdate;
        } 
    }
    
    /*
    * @author       Global Desktop
    * @Description  Actualiza la due date de los APs de PRIORIDAD o por evento con fecha menor que el periodo general
    */
    public void updateNewPriorityAPs(Map<String, Date> priorityDateMap) {
        System.debug('updateNewPriorityAPs');
        final acpl__AP_PeriodConfiguration__c config = [SELECT Id, acpl__gf_ap_edit_prms_type_name__c, acpl__gf_ap_edit_days_left_number__c FROM acpl__AP_PeriodConfiguration__c LIMIT 1];
        List<acpl__Account_Planning__c> apsToUpdate;
        apsToUpdate = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> apList = [SELECT Id, acpl__gf_ap_limit_date__c, acpl__gf_ap_priority_type_name__c, acpl__gf_ap_launch_name__c, acpl__gf_event_date__c
                                                  FROM acpl__Account_Planning__c 
                                                  WHERE acpl__gf_ap_substatus_type_name__c != :Label.AP_Timed_Out AND RecordType.DeveloperName ='Account_Planning'
                                                  AND 
                                                  (acpl__gf_ap_launch_name__c = 'Period by wave'
                                                   OR  
                                                   (acpl__gf_ap_launch_name__c = 'Event driven'))
                                                  ];
        System.debug('apList: ' + apList);
        
        List<acpl__Account_Planning__c> priorityList;
        priorityList = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> eventList;
        eventList = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> eventListG0P;
        eventListG0P = new List<acpl__Account_Planning__c>();
        
        for(acpl__Account_Planning__c apAux : apList) {
            if(apAux.acpl__gf_ap_priority_type_name__c == null || apAux.acpl__gf_ap_priority_type_name__c == '' 
                      || priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) == null) {
                eventListG0P.add(apAux);
            } else if(apAux.acpl__gf_ap_launch_name__c == 'Period by wave') {
                priorityList.add(apAux);
            } else {
                eventList.add(apAux);
            }
        }
        System.debug('eventListG0P: ' + eventListG0P);
        System.debug('priorityList: ' + priorityList);
        System.debug('eventList: ' + eventList);
       
        //APs Priority Period
        for(acpl__Account_Planning__c apAux : priorityList) {
            if(apAux.acpl__gf_ap_limit_date__c != priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c)) { //si la configurada es diferente, le pongo la nueva
                apAux.acpl__gf_ap_limit_date__c = priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c);
                	apsToUpdate.add(apAux);
            }
        }
        
        //APs Event driven sin prioridad
        for(acpl__Account_Planning__c apAux : eventListG0P) {
            if(apAux.acpl__gf_event_date__c == null) {
                if(apAux.acpl__gf_ap_limit_date__c != null) {
                    apAux.acpl__gf_ap_limit_date__c = null;
                    apsToUpdate.add(apAux);
                }
            } else {
                Date eventDrivenDate = calculateDate(apAux, config);
                if(apAux.acpl__gf_ap_limit_date__c != eventDrivenDate) {
                    apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                    apsToUpdate.add(apAux);
                }
            }
        }
        
        //APs event driven con prioridad
        for(acpl__Account_Planning__c apAux : eventList) {            
            if(apAux.acpl__gf_event_date__c == null) { //si no tiene evento, pongo la configurada si ha cambiado
                 if(priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) != null //si la prioridad coincide
               && apAux.acpl__gf_ap_limit_date__c != priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c)) { //si la configurada es diferente, le pongo la nueva
                    apAux.acpl__gf_ap_limit_date__c = priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c);
                	apsToUpdate.add(apAux);
                }
            } else {//si tiene evento calculo la eventDrivenDate
                Date eventDrivenDate = calculateDate(apAux, config);
                if(priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) != null //si la prioridad coincide
                  && priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) > eventDrivenDate) {
                    apAux.acpl__gf_ap_limit_date__c = priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c);
                      apsToUpdate.add(apAux);
                } else if(priorityDateMap.get(apAux.acpl__gf_ap_priority_type_name__c) != null
                          && apAux.acpl__gf_ap_limit_date__c != eventDrivenDate) {
                             apAux.acpl__gf_ap_limit_date__c = eventDrivenDate;
                    		apsToUpdate.add(apAux);
                }
            }
        }
        
        System.debug('apsToUpdate: ' + apsToUpdate);
        if(!apsToUpdate.isEmpty()) {
            update apsToUpdate;
        }  
    }
	
    /*
    * @author       Global Desktop
    * @Description  Borra la due date de los APs del periodo que reciba por parámetro
    */
    public void emptyDueDateAPs(String notThePeriod) {
        System.debug('dentro de emptyDueDateAPs');
        List<acpl__Account_Planning__c> apsToUpdate;
        apsToUpdate = new List<acpl__Account_Planning__c>();
        List<acpl__Account_Planning__c> apList = [SELECT Id, acpl__gf_ap_limit_date__c FROM acpl__Account_Planning__c 
                                                  WHERE acpl__gf_ap_substatus_type_name__c != :Label.AP_Timed_Out AND RecordType.DeveloperName ='Account_Planning'
                                                  AND acpl__gf_ap_launch_name__c = :notThePeriod AND acpl__gf_ap_limit_date__c != null];
        System.debug('apList: ' + apList);
        for(acpl__Account_Planning__c apAux : apList) {
            apAux.acpl__gf_ap_limit_date__c = null;
            apsToUpdate.add(apAux);
        }
		System.debug('apsToUpdate: ' + apsToUpdate);        
       if(!apsToUpdate.isEmpty()) {
            update apsToUpdate;
        } 
    }
    
    /*
    * @author       Global Desktop
    * @Description  Calculates the evend driven date end
    */
    public Date calculateDate(acpl__Account_Planning__c apAux, acpl__AP_PeriodConfiguration__c config) {
        Integer numOfDays = 0;
        Date returnDate = null;
        if(config.acpl__gf_ap_edit_days_left_number__c != null) {
            numOfDays = (Integer)config.acpl__gf_ap_edit_days_left_number__c;
        }
        if(apAux.acpl__gf_event_date__c != null && apAux.acpl__gf_event_date__c < apAux.acpl__gf_event_date__c.addDays(numOfDays)) {
            returnDate = apAux.acpl__gf_event_date__c.addDays(numOfDays);
        } else if(apAux.acpl__gf_event_date__c != null && apAux.acpl__gf_event_date__c >= apAux.acpl__gf_event_date__c.addDays(numOfDays)) {
            returnDate = apAux.acpl__gf_event_date__c;
        }
        return returnDate;
    }
}