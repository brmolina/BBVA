/**********************************************************************************
* @author       Global Desktop
* @date         14/11/2019
* @description  Handler that notifies the AP team
* @Revision
**********************************************************************************/
public with sharing class AP_EventNotificationBatchHandler {
    private static List<ConnectApi.BatchInput> batchFeedItemInputs = new List<ConnectApi.BatchInput>();

    /*
    * @author       Global Desktop
    * @Description  Notifies the APteam based on event date
    */
    public static void notifyAPTeam(List<acpl__AP_PeriodConfiguration__c> listAPConfig) {
        System.debug('dentro de notifyAPTeam');
        Integer numOfDays = (Integer)listAPConfig.get(0).acpl__gf_ap_edit_days_left_number__c;
        //recojo los AP pendientes
        List<acpl__Account_Planning__c> apList = [SELECT Id, acpl__gf_event_date__c FROM acpl__Account_Planning__c 
                                            WHERE (acpl__gf_ap_status_type_name__c = 'Not started' OR acpl__gf_ap_status_type_name__c = 'In Progress') AND acpl__gf_mandatory_type__c = 'Mandatory' 
                                            AND acpl__gf_event_date__c != null /*este estaba comentado antes AND gf_event_date__c + :numOfDays = TODAY*/];
        System.debug('apList: ' + apList);
        Set<Id> apSet = new Set<Id>();
        //guardo los ids de los account planning
        for(acpl__Account_Planning__c apAux : apList) {
            //Decimal sum = apAux.gf_event_date__c + numOfDays;
            if(!apSet.contains(apAux.Id) && (((apAux.acpl__gf_event_date__c + numOfDays) == date.today()) || apAux.acpl__gf_event_date__c == date.today())) {
                apSet.add(apAux.Id);
            }
        }
        System.debug('apSet: ' + apSet);

        //recojo los miembros del equipo de los AP pendientes
        List<bupl__AP_Team__c> apTeamList = [SELECT Id, bupl__gf_ap_team_user_id__c, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_event_date__c,
                                       acpl__gf_account_planning_id__r.Name FROM bupl__AP_Team__c 
                                       WHERE acpl__gf_account_planning_id__c IN :apSet AND bupl__gf_ap_team_user_id__r.DES_Disable_Chatter__c = false
                                       AND bupl__gf_ap_team_user_id__r.IsActive = true];

        System.debug('apTeamList: ' + apTeamList);
        if(!apTeamList.isEmpty()) {
            for(bupl__AP_Team__c apTeamAux : apTeamList) {
                System.debug('fecha del PF= ' + apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_event_date__c);
                System.debug('días= ' + numOfDays);
                System.debug('hoy= ' + date.today());
                System.debug('fecha del PF +- días= ' + apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_event_date__c.addDays(numOfDays));
                System.debug('apTeamAux.gf_ap_team_user_id__c: ' + apTeamAux.bupl__gf_ap_team_user_id__c);
                generateNotification(numOfDays, apTeamAux);
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
    }//END of notifyAPTeam
    
    /*
    * @author       Global Desktop
    * @Description  Notifies the APteam based on event date
    */
    public static void generateNotification(Integer numOfDays, bupl__AP_Team__c apTeamAux) {
        //-N dias: se abre la fecha
        if(numOfDays < 0 && date.today() == apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_event_date__c.addDays(numOfDays)) {
            Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, 'Your PF will expire in ' + ((-1)*numOfDays) + ' day(s). Please review the Account Plan for ' + apTeamAux.acpl__gf_account_planning_id__r.Name + ' before the ' + Label.acpl.AP_event_date + ' is reached');
            //-N dias: se cierra la fecha
        } else if(numOfDays < 0 && date.today() == apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_event_date__c) {
            Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, 'Your PF is expiring today. Please review the Account Plan for ' + apTeamAux.acpl__gf_account_planning_id__r.Name + ' before the end of the day');
            //N días: se abre la fecha
        } else if(numOfDays > 0 && date.today() == apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_event_date__c) {
            Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, 'Your PF is expiring today. You now have ' + numOfDays + ' day(s) to review the Account Plan for ' + apTeamAux.acpl__gf_account_planning_id__r.Name);
            //N días: se cierra la fecha
        } else if(numOfDays > 0 && date.today() == apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_event_date__c.addDays(numOfDays)) {
            Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, 'The period for reviewing the Account Plan for ' + apTeamAux.acpl__gf_account_planning_id__r.Name + ' is expiring today. Please review it before the end of the day');
            //0 días: se abre y cierra la fecha hoy
        } else if(numOfDays == 0 && date.today() == apTeamAux.acpl__gf_account_planning_id__r.acpl__gf_event_date__c) {
            Desktop_Utils_aux.generarPostChatter(apTeamAux.bupl__gf_ap_team_user_id__c, 'Your PF is expiring today. Please review the Account Plan for ' + apTeamAux.acpl__gf_account_planning_id__r.Name + ' before the end of the day');
        }
    }//END of generateNotification
}