/**********************************************************************************
* @author       Global Desktop 
* @date         08/07/2019
* @description  Flow helper class
* @Revision     
**********************************************************************************/
global without sharing class Flow_Helper { //NOSONAR
    /*
    * Invocable
    */
    public class FlowHelper {
        /**
         * Method name 
         */
        @InvocableVariable(label='method' required=true)
        public String method; //NOSONAR
        /**
         * Account Plannings list
         */
        @InvocableVariable(label='accountPlanningList' required=false)
        public List<acpl__Account_Planning__c> accountPlanningList; //NOSONAR
        /**
         * Notification message
         */
        @InvocableVariable(label='notificationMessage' required=false)
        public String notificationMessage; //NOSONAR
        /**
         * Record Id
         */
        @InvocableVariable(label='recordId' required=false)
        public Id recordId; //NOSONAR
        /**
         * userOrGroupId
         */
        @InvocableVariable(label='userOrGroupId' required=false)
        public Id userOrGroupId; //NOSONAR
        /**
         * String variable
         */
        @InvocableVariable(label='string variable' required=false)
        public String stringVar; //NOSONAR
        /**
        * Id set
        */
        @InvocableVariable(label='idList' required=false)
        public List<Id> idList; //NOSONAR
        /**
        * String set
        */
        @InvocableVariable(label='inactiveUserList' required=false)
        public List<String> inactiveUserList; //NOSONAR
        /**
        * String set
        */
        @InvocableVariable(label='chatterUserList' required=false)
        public List<String> chatterUserList; //NOSONAR
        /**
        * List AP tem members
        */
        @InvocableVariable(label='apTeamList' required=false)
        public List<bupl__AP_Team__c> apTeamList; //NOSONAR
        /**
        * Boolean
        */
        @InvocableVariable(label='booleanVar' required=false)
        public Boolean booleanVar; //NOSONAR
    } 
    
    /*
    * @author Global Desktop
    * @Description Invocable method - flow helper
    */
    @InvocableMethod(label='Flow Helper' description='Flow Helper')
    
    public static List<FlowHelper> callFromFlow(List<FlowHelper> flowHelperList) {
        List<FlowHelper> flowHelperListAux = flowHelperList;
        
        if(flowHelperList[0].method == 'notifyAPTeam') {
            notifyAPTeam(flowHelperListAux);
        } else if(flowHelperList[0].method == 'createShare') {
            createShare(flowHelperListAux);
        } else if(flowHelperList[0].method == 'notifyUsers') {
            notifyUsers(flowHelperListAux);
        } else if(flowHelperList[0].method == 'separateUsers') {
            separateUsers(flowHelperListAux);
        } else if(flowHelperList[0].method == 'checkUserChatter') {
            checkUserChatter(flowHelperListAux);
        }
        
        return flowHelperListAux;

    }
      
    /*
    * @author Global Desktop
    * @Description Notifies the AP team
    */
    
    public static void notifyAPTeam(List<FlowHelper> flowHelperListAux) {
        System.debug('Dentro de notifyAPTeam');
        System.debug('flowHelperListAux[0].accountPlanningList: ' + flowHelperListAux[0].accountPlanningList);
        FlowHelper flowHelperVar = flowHelperListAux[0];
        Set<Id> apIdSet;
        apIdSet = new Set<Id>();
        for(acpl__Account_Planning__c apAux : flowHelperVar.accountPlanningList) {
           if(!apIdSet.contains(apAux.Id)) {
                apIdSet.add(apAux.Id);
            } 
        }
            
        
        final List<bupl__AP_Team__c> apTeamList = [SELECT Id, bupl__gf_ap_team_user_id__c, bupl__gf_ap_team_user_id__r.DES_Disable_Chatter__c,bupl__gf_ap_team_user_id__r.IsActive FROM bupl__AP_Team__c WHERE 
                                                        acpl__gf_account_planning_id__c IN :apIdSet
                                                        AND bupl__gf_ap_team_user_id__r.DES_Disable_Chatter__c = false AND bupl__gf_ap_team_user_id__r.IsActive = true];
        List<Id> userIdList;
        userIdList = new List<Id>();
        if(!apTeamList.isEmpty()) {
            for(bupl__AP_Team__c apTeamAux : apTeamList) {
                if(!userIdList.contains(apTeamAux.bupl__gf_ap_team_user_id__c)) {
                    userIdList.add(apTeamAux.bupl__gf_ap_team_user_id__c);
                }
            }
        }
        
        Set<Id> userIdSet;
        userIdSet = new Set<Id>();
        //guardo los usuarios a notificar
        for(Id idAuxSet : userIdList) {
        userIdSet.add(idAuxSet);
        }
        //notifico
        for(Id userIdAux : userIdSet) {
        Desktop_Utils_aux.generarPostChatter(userIdAux, flowHelperVar.notificationMessage);
        }
        //si Desktop_Utils_aux.batchFeedItemInputs < 500 notifico a los restantes
        if(!Desktop_Utils_aux.batchFeedItemInputs.isEmpty()) {
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils_aux.batchFeedItemInputs);
        }
    }
    
     /*
    * @author Global Desktop
    * @Description Notifies the AP team
    */
    @AuraEnabled
    public static void createShare(List<FlowHelper> flowHelperListAux) {
        System.debug('Dentro de createShare');
        FlowHelper flowHelperVar = flowHelperListAux[0];
        System.debug('flowHelperVar: ' + flowHelperVar);
        acpl__Account_Planning__Share apShare = Desktop_Utils_aux.newManualSharingAccountPlanning(flowHelperVar.recordId, flowHelperVar.userOrGroupId, flowHelperVar.stringVar);
        if(apShare != null) {
            insert apShare;
        }
    }
    
    /*
    * @author Global Desktop
    * @Description Notifies the AP team
    */
    public static void notifyUsers(List<FlowHelper> flowHelperListAux) {
        System.debug('Dentro de notifyUsers');
        System.debug('flowHelperListAux[0].idList: ' + flowHelperListAux[0].idList);
        FlowHelper flowHelperVar;
        flowHelperVar = flowHelperListAux[0];
        Set<Id> apTeamUserIdSet;
        apTeamUserIdSet = new Set<Id>();

        for(String userIdAux : flowHelperVar.idList) {
            if(!apTeamUserIdSet.contains(userIdAux)) {
                apTeamUserIdSet.add(userIdAux);
            }
        }
        System.debug('apTeamUserIdSet: ' + apTeamUserIdSet);
        
        final List<User> notifUserList = [SELECT Id, Name, IsActive, DES_Disable_Chatter__c FROM User 
                                    WHERE Id IN :apTeamUserIdSet
                                    AND IsActive = true AND DES_Disable_Chatter__c = false];
        Set<Id> notifUserSet;
        notifUserSet = new Set<Id>();
        //guardo los usuarios a notificar
        for(User userAux : notifUserList) {
			notifUserSet.add(userAux.Id);
        }

        //notifico
        for(Id userIdAux : notifUserSet) {
            Desktop_Utils_aux.generarPostChatter(userIdAux, flowHelperVar.notificationMessage);
        }
        //si AP_Utils.batchFeedItemInputs < 500 notifico a los restantes
        if(!Desktop_Utils_aux.batchFeedItemInputs.isEmpty()) {
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), Desktop_Utils_aux.batchFeedItemInputs);
        }
    }
    
    /*
    * @author Global Desktop
    * @Description Checks if any user is inactive or does not have chatter
    */
    public static List<FlowHelper> separateUsers(List<FlowHelper> flowHelperListAux) {
        System.debug('Dentro de checkFailedUsers');
        System.debug('flowHelperListAux[0].apTeamList: ' + flowHelperListAux[0].apTeamList);
        FlowHelper flowHelperVar = flowHelperListAux[0];
        Set<Id> apTeamUserIdSet;
        apTeamUserIdSet = new Set<Id>();
        Set<Id> errorIdSet;
        errorIdSet = new Set<Id>();
        List<bupl__AP_Team__c> okApteam;
        okApteam = new List<bupl__AP_Team__c>();

        for(bupl__AP_Team__c aptAux : flowHelperVar.apTeamList) {
            apTeamUserIdSet.add(aptAux.Id);
        }
        
        final List<bupl__AP_Team__c> apTeamList = [SELECT Id, Name, bupl__gf_ap_team_user_id__c, bupl__gf_ap_team_role_user_name__c, 
                                             bupl__gf_ap_team_user_id__r.DES_Disable_Chatter__c, bupl__gf_ap_team_user_id__r.isActive
                                            FROM bupl__AP_Team__c WHERE Id IN :apTeamUserIdSet];
        
        //separo: IF: AP team members activos y con chatter y ELSE: ids de usuarios inactivos o sin chatter
        for(bupl__AP_Team__c aptAux : apTeamList) {
            if(!aptAux.bupl__gf_ap_team_user_id__r.DES_Disable_Chatter__c && aptAux.bupl__gf_ap_team_user_id__r.isActive) {
                okApteam.add(aptAux);
            } else {
                errorIdSet.add(aptAux.bupl__gf_ap_team_user_id__c);
            }
        }
        //busco los usuarios inactivos o sin chatter
        final List<User> notifUserList = [SELECT Id, Name, IsActive, DES_Disable_Chatter__c FROM User 
                                    WHERE Id IN :errorIdSet];
        List<String> inactiveList;
        inactiveList = new List<String>();
        List<String> chatterList;
        chatterList = new List<String>();

        //guardo los usuarios a notificar
        for(User userAux : notifUserList) {
            if(!userAux.IsActive) {
                inactiveList.add(userAux.Name);
            } 
            if(userAux.DES_Disable_Chatter__c) {
                chatterList.add(userAux.Name);
            }
        }
        
        flowHelperListAux.clear();
        
        flowHelperVar = chatterInactiveOK(flowHelperVar, inactiveList, chatterList, okApteam);
        
        flowHelperListAux.add(flowHelperVar);
        return flowHelperListAux;
    }
    
    /*
    * @author Global Desktop
    * @Description Fill chatter, inactive and OK lists
    */
    public static FlowHelper chatterInactiveOK(FlowHelper flowHelperVar, List<String> inactiveList, List<String> chatterList, List<bupl__AP_Team__c> okApteam) {
        FlowHelper varAux;
        varAux = flowHelperVar;
        if(inactiveList.isEmpty()) {
            varAux.inactiveUserList = null;//NOSONAR flow
        } else {
            varAux.inactiveUserList = inactiveList;
        }
		if(chatterList.isEmpty()) {
            varAux.chatterUserList = null;//NOSONAR flow
        } else {
            varAux.chatterUserList = chatterList;
        }
		if(okApteam.isEmpty()) {
            varAux.apTeamList = null;//NOSONAR flow
        } else {
            varAux.apTeamList = okApteam;
        }
        return varAux;
    }
    
    /*
    * @author Global Desktop
    * @Description Checks if any user is inactive or does not have chatter
    */
    public static List<FlowHelper> checkUserChatter(List<FlowHelper> flowHelperListAux) {
        System.debug('Dentro de checkUserChatter');
        System.debug('flowHelperListAux[0].userOrGroupId: ' + flowHelperListAux[0].userOrGroupId);
        FlowHelper flowHelperVar = flowHelperListAux[0];
        Id currentUser = flowHelperVar.userOrGroupId;
        flowHelperVar.booleanVar = [SELECT Id, DES_Disable_Chatter__c FROM User WHERE Id = :currentUser].DES_Disable_Chatter__c;
        
        flowHelperListAux.clear();
        flowHelperListAux.add(flowHelperVar);
        return flowHelperListAux;
    }

}