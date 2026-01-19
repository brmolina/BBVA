/**********************************************************************************
* @author       Global Desktop
* @date         03/07/2019
* @description  Manejador del batch para la notificación de miembros de AP
* @Revision
**********************************************************************************/
public with sharing class AP_NotificationBatchHandler {
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    private static List<ConnectApi.BatchInput> batchFeedItemInputs = new List<ConnectApi.BatchInput>();

    /*
    * @author       Global Desktop
    * @Description  Notifies the AP team members
    */
    public static void notifyAPTeam(List<acpl__AP_Period__c> listAPConfig) {
        // recojo los AP pendientes
        List<acpl__Account_Planning__c> apList = [SELECT Id, acpl__gf_ap_priority_type_name__c FROM acpl__Account_Planning__c
                                            WHERE (acpl__gf_ap_status_type_name__c = 'Not started' OR acpl__gf_ap_status_type_name__c = 'In Progress') AND acpl__gf_mandatory_type__c = 'Mandatory'];
        
        Set<Id> apSet = fillApSet(apList);

        // recojo los miembros del equipo de los AP pendientes
        List<bupl__AP_Team__c> apTeamList = [SELECT Id, bupl__gf_ap_team_user_id__c, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_ap_priority_type_name__c FROM bupl__AP_Team__c
                                       WHERE acpl__gf_account_planning_id__c IN :apSet
                                      AND bupl__gf_ap_team_user_id__r.DES_Disable_Chatter__c = false
                                      AND bupl__gf_ap_team_user_id__r.IsActive = true];

        // si listAPConfig tiene 1 registro con priority = '', notifico a todos los miembros de apList
        Set<Id> userIdSet = new Set<Id>();
        for(bupl__AP_Team__c apTeamAux : apTeamList) {
            if(!userIdSet.contains(apTeamAux.bupl__gf_ap_team_user_id__c)) {
                userIdSet.add(apTeamAux.bupl__gf_ap_team_user_id__c);
            }
        }

        // recojo el registro de configuración
        List<acpl__AP_PeriodConfiguration__c> apPeriod = [SELECT Id, acpl__gf_ap_edit_prms_type_name__c FROM acpl__AP_PeriodConfiguration__c LIMIT 1];

        Map<String, acpl__AP_Period__c> apConfigPriorityMap = new Map<String, acpl__AP_Period__c>();
        Set<Id> userIdsNotified = new Set<Id>();

        //si el periodo es general sólo hay 1 registro en AP_PeriodConfiguration__c y AP_Period__c
        if(apPeriod.get(0).acpl__gf_ap_edit_prms_type_name__c == 'General') {
            for(Id apTeamIdAux : userIdSet) {
                //AP_Utils.generarPostChatter(apTeamIdAux, listAPConfig.get(0).gf_ap_next_date_msg_desc__c);
                generateNotification(listAPConfig, userIdsNotified, apTeamIdAux);
            }

        // si es por prioridad, me guardo todos los registros en un mapa con key=prioridad
        } else {
            for (acpl__AP_Period__c apConfigAux : listAPConfig) {
                apConfigPriorityMap.put(apConfigAux.acpl__gf_ap_priority_edit_type__c, apConfigAux);
            }
            // recorro el mapa de prioridades
            for(acpl__AP_Period__c apConfigAux : apConfigPriorityMap.values()) {
                // recorro la lista de usuarios
                loopApmAndNotify(apTeamList, apConfigAux, userIdsNotified);
                // cuando acabo con una prioridad, borro el set de ids
                userIdsNotified.clear();
            }
        }
        //si Desktop_Utils_aux.batchFeedItemInputs < 500 notifico a los restantes
        if(!Desktop_Utils_aux.batchFeedItemInputs.isEmpty() && !Test.isRunningTest()) {
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils_aux.batchFeedItemInputs);
        } else if(!Desktop_Utils_aux.batchFeedItemInputs.isEmpty()) {
            final Task successTask = new Task();
            successTask.Subject = 'Success';
            insert successTask;
        }
    }//End of notifyAPTeam
    
    /*
    * @author       Global Desktop
    * @Description  Notifies the AP team members
    */
    public static void generateNotification(List<acpl__AP_Period__c> listAPConfig, Set<Id> userIdsNotified, Id apTeamIdAux) {
    	if(!userIdsNotified.contains(apTeamIdAux)) {
            // miro qué fecha es la de hoy y notifico al usuario
            if(listAPConfig.get(0).acpl__gf_ap_edit_start_date__c == Date.today()) {
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux, listAPConfig.get(0).acpl__gf_ap_start_date_msg_desc__c);
            }
            if(listAPConfig.get(0).acpl__gf_ap_notfn_next_close_date__c == Date.today()) {
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux, listAPConfig.get(0).acpl__gf_ap_next_date_msg_desc__c);
            }
            if(listAPConfig.get(0).acpl__gf_ap_edit_end_date__c == Date.today()) {
                Desktop_Utils_aux.generarPostChatter(apTeamIdAux, listAPConfig.get(0).acpl__gf_ap_close_date_msg_desc__c);
            }
            // meto al usuario en el set de usuarios notificados
            userIdsNotified.add(apTeamIdAux);
        }
    }//END of generateNotification
    
    /*
    * @author       Global Desktop
    * @Description  Notifies the AP team members
    */
    public static void loopApmAndNotify(List<bupl__AP_Team__c> apTeamList, acpl__AP_Period__c apConfigAux, Set<Id> userIdsNotified) {
    	for(bupl__AP_Team__c apTeamAux : apTeamList) {
            System.debug('apTeamAux: ' + apTeamAux);
            System.debug('apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_ap_priority_type_name__c: ' + apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_ap_priority_type_name__c);
            System.debug('apConfigAux.acpl__gf_ap_priority_edit_type__c: ' + apConfigAux.acpl__gf_ap_priority_edit_type__c);
            // compruebo si el usuario está en el set de usuarios notificados
            if(!userIdsNotified.contains(apTeamAux.bupl__gf_ap_team_user_id__c) && apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_ap_priority_type_name__c == apConfigAux.acpl__gf_ap_priority_edit_type__c) {
                // miro qué fecha es la de hoy y notifico al usuario
                if(apConfigAux.acpl__gf_ap_edit_start_date__c == Date.today()) {
                    Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, apConfigAux.acpl__gf_ap_start_date_msg_desc__c);
                }
                if(apConfigAux.acpl__gf_ap_notfn_next_close_date__c == Date.today()) {
                    Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, apConfigAux.acpl__gf_ap_next_date_msg_desc__c);
                }
                if(apConfigAux.acpl__gf_ap_edit_end_date__c == Date.today()) {
                    Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, apConfigAux.acpl__gf_ap_close_date_msg_desc__c);
                }
                // meto al usuario en el set de usuarios notificados
                userIdsNotified.add(apTeamAux.bupl__gf_ap_team_user_id__c);
            }
        }
	}//END of loopApmAndNotify
    
    /*
    * @author       Global Desktop
    * @Description  Fills the AP set
    */
    public static Set<Id> fillApSet(List<acpl__Account_Planning__c> apList) {
        Set<Id> apSet = new Set<Id>();
        // guardo los ids de los account planning
        for(acpl__Account_Planning__c apAux : apList) {
            if(!apSet.contains(apAux.Id)) {
                apSet.add(apAux.Id);
            }
        }
        return apSet;
    }//END of fillApSet
        
        
}