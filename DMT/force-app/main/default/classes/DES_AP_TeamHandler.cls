/**
* @author        Global Desktop
* @date         25/07/2019
* @description  Handler del trigger de Account Planning Team
* @Revision
*
* Version   Date            Author          Summary of changes
*/
public with sharing class DES_AP_TeamHandler {

    /** Desktop Integration profile **/
    private static final String DESINT = 'Desktop Integration';

    /*
    * @author     Global Desktop
    * @Description  Notifies the new APTeam member Global Banker
    */
    public static void notifyGB(List<bupl__AP_Team__c> triggerNew) {
        //String inclusionMessage = [SELECT Id, gf_ap_team_message_desc__c from AP_PeriodConfiguration__c limit 1].gf_ap_team_message_desc__c;
        final Set<Id> userIdsToNotify = new Set<Id>();
        //incluyo a los miembros de AP Team a los que voy a notificar
        for(bupl__AP_Team__c apTeamAux : triggerNew) {
            if(!userIdsToNotify.contains(apTeamAux.bupl__gf_ap_team_user_id__c) && apTeamAux.bupl__gf_ap_team_role_user_name__c == Label.DES_ROLE_GLOBAL_BANKER) {
                userIdsToNotify.add(apTeamAux.bupl__gf_ap_team_user_id__c);
                apTeamAux.bupl__gf_ap_team_new_member_date__c = Date.TODAY();
            }
        }

        //genero un mensaje para los usuarios a los que voy a notificar
        for(Id apTeamIdAux : userIdsToNotify) {
            //Desktop_Utils_aux.generarPostChatter(apTeamIdAux, inclusionMessage);
            Desktop_Utils_aux.generarPostChatter(apTeamIdAux, 'You have been included as a member of an Account Planning Team. Please go to your Home to check the Account Plans you participate in');
        }

        //si Desktop_Utils_aux.batchFeedItemInputs < 500 notifico a los restantes
        if(!Desktop_Utils_aux.batchFeedItemInputs.isEmpty() && !Test.isRunningTest()) {
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils_aux.batchFeedItemInputs);
        }

    } //FIN de notifyGB


    /*
	* @author 		Global Desktop
	* @Description  Controls which profiles/members can add/modify new Planning Team Members and their roles
	*/
    public static void checkNotGlobalBanker(List<bupl__AP_Team__c> triggerNew) {
        final String profileName = getProfileName();
        final Map<String,bupl__AP_Team__c> mapByAP = getMapMembersByAP();
        Boolean userIsGB;
        Boolean userAdminAP=FeatureManagement.checkPermission('AP_Administrator');

        for(bupl__AP_Team__c apMember : triggerNew) {
            userIsGB = mapByAP.get(apMember.acpl__gf_account_planning_id__c)!=null;
            if(!userIsGB && profileName!=Label.DES_ADMIN_PROFILE && !userAdminAP && profileName!=DESINT) { //NOSONAR
                apMember.addError(Label.DES_AP_ONLY_GB_CAN);
            } else if(apMember.bupl__gf_ap_team_role_user_name__c == Label.DES_ROLE_GLOBAL_BANKER && !userAdminAP  && profileName != Label.DES_ADMIN_PROFILE && profileName != DESINT) {
                apMember.addError(Label.DES_AP_ONLY_ONE_GB);
            }
        }
    } //FIN checkNotGlobalBanker

    /*
	* @author 		Global Desktop
	* @Description  Controls which profiles/members can delete existing Planning Team Members
	*/
    public static void checkUserDeleting(List<bupl__AP_Team__c> triggerOld) {
        final String profileName = getProfileName();
        final Map<String,bupl__AP_Team__c> mapByAP = getMapMembersByAP();
        Boolean userIsGB;
        Boolean userAdminAP=FeatureManagement.checkPermission('AP_Administrator');

        for(bupl__AP_Team__c apMember : triggerOld) {
            userIsGB = mapByAP.get(apMember.acpl__gf_account_planning_id__c)!=null;
            if(!userIsGB && profileName!=Label.DES_ADMIN_PROFILE && profileName!=DESINT && !userAdminAP) {
                apMember.addError(Label.DES_AP_ONLY_GB_DELETE);
            } else if(apMember.bupl__gf_ap_team_role_user_name__c == Label.DES_ROLE_GLOBAL_BANKER && !userAdminAP && profileName != Label.DES_ADMIN_PROFILE && profileName != DESINT) {
                apMember.addError(Label.DES_AP_NOT_DELETE_GB);
            }
        }
    } //FIN checkUserDeleting

    /*
	* @author 		Global Desktop
	* @Description  Returns Name field of executing user's profile
	*/
    private static String getProfileName() {
        String profileName = '';
        List<Profile> liProfile = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
        if(!liProfile.isEmpty()) {
            profileName = liProfile.get(0).Name;
        }

        return profileName;
    }

    /*
	* @author 		Global Desktop
	* @Description  Returns Map of AP Team Members being their related AP Id the key of map
	*/
    private static Map<String,bupl__AP_Team__c> getMapMembersByAP() {
        final Map<String,bupl__AP_Team__c> mapByAP = new Map<String,bupl__AP_Team__c>();
        final List<bupl__AP_Team__c> liUserAsGB = [SELECT acpl__gf_account_planning_id__c FROM bupl__AP_Team__c
                                            WHERE bupl__gf_ap_team_user_id__c =: UserInfo.getUserId() AND bupl__gf_ap_team_role_user_name__c =: Label.DES_ROLE_GLOBAL_BANKER];
        for(bupl__AP_Team__c apMember : liUserAsGB) {
            mapByAP.put(apMember.acpl__gf_account_planning_id__c, apMember);
        }

        return mapByAP;
    }
    
    /*
    * @author       Global Desktop
    * @Description  Check if AP Team Member (other than Global Banker) has been added and propagates this change on Status field in related AP.
    */
    public static void updateStatusOnAP(Map<Id, bupl__AP_Team__c> triggerNewMap) {
        final Set<Id> listAPIds = new Set<Id>();
        for (bupl__AP_Team__c apt : triggerNewMap.values()) {
            if (apt.bupl__gf_ap_team_role_user_name__c != Label.DES_ROLE_GLOBAL_BANKER) { //Global Banker is automatically added when creating a new AP creation
                //save de ap id's to query on it later
                listAPIds.add(apt.acpl__gf_account_planning_id__c);
            }
        }

        if (!listAPIds.isEmpty()) {
            final list<acpl__Account_Planning__c> listAPtoUpdate = [SELECT Id, acpl__gf_ap_status_type_name__c, acpl__gf_ap_substatus_type_name__c FROM acpl__Account_Planning__c WHERE Id IN :listAPIds AND acpl__gf_ap_status_type_name__c = 'Not started']; 
            for (acpl__Account_Planning__c ap : listAPtoUpdate) {
                ap.acpl__gf_ap_status_type_name__c='In Progress';
                ap.acpl__gf_ap_substatus_type_name__c='AP team not invited';
            }
            if (!listAPtoUpdate.isEmpty()) {
                update listAPtoUpdate;
            }
        }
    }

}