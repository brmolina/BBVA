/**
* @author        Global Desktop
* @date         02/12/2019
* @description  Handler del trigger de Business Plan Team
* @Revision
*
* Version   Date            Author          Summary of changes
* 0.1       02/12/2019      MSV             Class creation to manage access to BP by Team
*/
global with sharing class BP_TeamHandler {

    /*instance*/
    private static BP_TeamHandler instance;

    /*
    * @author     Global Desktop
    * @Description  Constructor
    */
    private BP_TeamHandler() {
        System.debug('CONSTRUCTOR');
    }

    /*
    * @author     Global Desktop
    * @Description  getInstance
    */
    global static BP_TeamHandler getInstance() { //NOSONAR
        if (instance == null) {
            instance = new BP_TeamHandler();
        }
        return instance;
    }

    /*
	* @author 		Global Desktop
	* @Description  Gives edit access to BPTeam Member
	*/
    global void giveBPEditAccess(List<bupl__AP_Team__c> triggernew) {
        // Business Plan Sharing
        final List<bupl__BusinessPlan__Share> bpShareList = new List<bupl__BusinessPlan__Share>();
        for(bupl__AP_Team__c bpTeamMemberAux : triggernew) {
			final bupl__BusinessPlan__Share bpShare = Desktop_Utils_aux.newManualSharingBusinessPlan(bpTeamMemberAux.bupl__gf_business_plan_id__c, bpTeamMemberAux.bupl__gf_ap_team_user_id__c, 'Edit');
            if(bpShare != null) {
                bpShareList.add(bpShare);
            }
        }
        Desktop_Utils_aux.insertSharingBP(bpShareList);
    } //FIN giveEditAccess

    /*
	* @author 		Global Desktop
	* @Description  Remove edit access to former AP Team Member
	*/
    global void removeBPEditAccess(List<bupl__AP_Team__c> triggerOld) { //NOSONAR
        final Set<Id> setAPIds = new Set<Id>();
        System.debug('triggerOld: ' + triggerOld);
        final Map<Id, List<bupl__AP_Team__c>> mapTeamByAP = new Map<Id, List<bupl__AP_Team__c>>();
        // Retrieve members related to same AP Team in triggerOld
        for(bupl__AP_Team__c apMember : triggerOld) {
            setAPIds.add(apMember.acpl__gf_account_planning_id__c);
        }
        final Map<Id, bupl__BusinessPlan__c> mapBusPlanOld = new Map<Id, bupl__BusinessPlan__c>([SELECT Id, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_ap_validator_user_id__c
                                                                                                        FROM bupl__BusinessPlan__c
                                                                                                        WHERE acpl__gf_account_planning_id__c IN :setAPIds]);
        final List<bupl__AP_Team__c> liMembersRelated = [SELECT Id, acpl__gf_account_planning_id__c, acpl__gf_account_planning_id__r.acpl__gf_ap_validator_user_id__c,
                                                                bupl__gf_business_plan_id__c, bupl__gf_ap_team_user_id__c
                                                    FROM bupl__AP_Team__c WHERE acpl__gf_account_planning_id__c IN: setAPIds];
        System.debug('liMembersRelated: ' + liMembersRelated);
        // Fill map with different AP Team members grouped by AP's Id
        List<bupl__AP_Team__c> liTeamByAP;
        for(bupl__AP_Team__c apMember : liMembersRelated) {
            liTeamByAP = mapTeamByAP.get(apMember.acpl__gf_account_planning_id__c);
            if(liTeamByAP == null) {
                liTeamByAP = new List<bupl__AP_Team__c>();
            }
            liTeamByAP.add(apMember);
            mapTeamByAP.put(apMember.acpl__gf_account_planning_id__c, liTeamByAP);
        }
        // Fill List with users not present with another role on the same AP Team
        final List<bupl__AP_Team__c> liRemoveAccess = new List<bupl__AP_Team__c>();
        liRemoveAccess.addAll(triggerOld);
        for(Id apId : setAPIds) {
            List<bupl__AP_Team__c> liCheckUsers = mapTeamByAP.get(apId);
            if(liCheckUsers==null) {
                liCheckUsers = new List<bupl__AP_Team__c>(); //NOSONAR
            }
            for(Integer memberCounter = 0; memberCounter<liRemoveAccess.size(); memberCounter++) {
                if(liRemoveAccess.get(memberCounter) != null) {
                    final bupl__AP_Team__c apMember = liRemoveAccess.get(memberCounter);
                    for(bupl__AP_Team__c apMemberAux : liCheckUsers) {
                        if(apMember.bupl__gf_ap_team_user_id__c == apMemberAux.bupl__gf_ap_team_user_id__c && apMember.Id != apMemberAux.Id) {
                            liRemoveAccess.remove(memberCounter);
                        }
                    }
                }
            }
        }
        // If user associated to AP Team Member is not present in the team also with another role,
        // delete the share registry for that user, for Business Plan associated
        final List<bupl__BusinessPlan__Share> bpDeleteList = new List<bupl__BusinessPlan__Share>();
        for(bupl__AP_Team__c bpMember : liRemoveAccess) {
			final bupl__BusinessPlan__Share bpDelete = Desktop_Utils_aux.getManualSharingBusinessPlan(bpMember.bupl__gf_business_plan_id__c, bpMember.bupl__gf_ap_team_user_id__c);
            system.debug(':::::  mapBusPlanOld: ' + mapBusPlanOld);
            system.debug(':::::  bpMember.bupl__gf_business_plan_id__c: ' + bpMember.bupl__gf_business_plan_id__c);
            // system.debug(':::::  mapBusPlanOld.get(bpMember.bupl__gf_business_plan_id__c).acpl__gf_account_planning_id__r.acpl__gf_ap_validator_user_id__c : ' + mapBusPlanOld.get(bpMember.bupl__gf_business_plan_id__c).acpl__gf_account_planning_id__r.acpl__gf_ap_validator_user_id__c);
            // system.debug(':::::  mapBusPlanOld.get(bpMember.acpl__gf_account_planning_id__c).acpl__gf_account_planning_id__r.acpl__gf_ap_validator_user_id__c : ' + mapBusPlanOld.get(bpMember.acpl__gf_account_planning_id__c).acpl__gf_account_planning_id__r.acpl__gf_ap_validator_user_id__c);
            // system.debug(':::::  bpMember.bupl__gf_ap_team_user_id__c : ' + bpMember.bupl__gf_ap_team_user_id__c);

            if(bpDelete!=null && mapBusPlanOld.get(bpMember.bupl__gf_business_plan_id__c).acpl__gf_account_planning_id__r.acpl__gf_ap_validator_user_id__c != bpMember.bupl__gf_ap_team_user_id__c) {
                bpDeleteList.add(bpDelete);
            }
        }
        System.debug('bpDeleteList: ' + bpDeleteList);
        Desktop_Utils_aux.deleteSharingBP(bpDeleteList);
    } //FIN removeEditAccess

    /*
	* @author 		Global Desktop
	* @Description  Gives edit access to APTeam Member
	*/
    global void giveAPEditAccess(List<bupl__AP_Team__c> triggernew) {
        // Account Planning Sharing
		final List<acpl__Account_Planning__Share> apShareList = new List<acpl__Account_Planning__Share>();
        for(bupl__AP_Team__c apTeamMemberAux : triggernew) {
			final acpl__Account_Planning__Share apShare = Desktop_Utils_aux.newManualSharingAccountPlanning(apTeamMemberAux.acpl__gf_account_planning_id__c, apTeamMemberAux.bupl__gf_ap_team_user_id__c, 'Edit');
            if(apShare != null) {
                apShareList.add(apShare);
            }
        }
        Desktop_Utils_aux.insertSharingAP(apShareList);
    } //FIN giveEditAccess

    /*
	* @author 		Global Desktop
	* @Description  Remove edit access to former AP Team Member
	*/
    global void removeAPEditAccess(List<bupl__AP_Team__c> triggerOld) { //NOSONAR
        final Set<Id> setAPIds = new Set<Id>();
        final Map<Id,List<bupl__AP_Team__c>> mapTeamByAP = new Map<Id,List<bupl__AP_Team__c>>();
        // Retrieve members related to same AP Team in triggerOld
        for(bupl__AP_Team__c apMember : triggerOld) {
            setAPIds.add(apMember.acpl__gf_account_planning_id__c);
        }
        final Map<Id, acpl__Account_Planning__c> mapAccPlanOld = new Map<Id, acpl__Account_Planning__c>([SELECT Id, acpl__gf_ap_validator_user_id__c
                                                                                                        FROM acpl__Account_Planning__c
                                                                                                        WHERE Id IN :setAPIds]);
        final List<bupl__AP_Team__c> liMembersRelated = [SELECT Id, acpl__gf_account_planning_id__c, bupl__gf_business_plan_id__c, bupl__gf_ap_team_user_id__c
                                                    FROM bupl__AP_Team__c WHERE acpl__gf_account_planning_id__c IN: setAPIds];
        // Fill map with different AP Team members grouped by AP's Id
        List<bupl__AP_Team__c> liTeamByAP;
        for(bupl__AP_Team__c apMember : liMembersRelated) {
            liTeamByAP = mapTeamByAP.get(apMember.acpl__gf_account_planning_id__c);
            if(liTeamByAP == null) {
                liTeamByAP = new List<bupl__AP_Team__c>();
            }
            liTeamByAP.add(apMember);
            mapTeamByAP.put(apMember.acpl__gf_account_planning_id__c, liTeamByAP);
        }
        // Fill List with users not present with another role on the same AP Team
        final List<bupl__AP_Team__c> liRemoveAccess = new List<bupl__AP_Team__c>();
        liRemoveAccess.addAll(triggerOld);
        for(Id apId : setAPIds) {
            List<bupl__AP_Team__c> liCheckUsers = mapTeamByAP.get(apId);
            if(liCheckUsers==null) {
                liCheckUsers = new List<bupl__AP_Team__c>(); //NOSONAR
            }
            for(Integer memberCounter = 0; memberCounter<liRemoveAccess.size(); memberCounter++) {
                if(liRemoveAccess.get(memberCounter) != null) {
                    final bupl__AP_Team__c apMember = liRemoveAccess.get(memberCounter);
                    for(bupl__AP_Team__c apMemberAux : liCheckUsers) {
                        if(apMember.bupl__gf_ap_team_user_id__c == apMemberAux.bupl__gf_ap_team_user_id__c && apMember.Id != apMemberAux.Id) {
                            liRemoveAccess.remove(memberCounter);
                        }
                    }
                }
            }
        }
        // If user associated to AP Team Member is not present in the team also with another role,
        // delete the share registry for that user, both for Account Planning and Business Plan associated
        final List<acpl__Account_Planning__Share> apDeleteList = new List<acpl__Account_Planning__Share>();
        for(bupl__AP_Team__c apMember : liRemoveAccess) {
			final acpl__Account_Planning__Share apDelete = Desktop_Utils_aux.getManualSharingAccountPlanning(apMember.acpl__gf_account_planning_id__c, apMember.bupl__gf_ap_team_user_id__c);
            if(apDelete != null && mapAccPlanOld.get(apMember.acpl__gf_account_planning_id__c).acpl__gf_ap_validator_user_id__c != apMember.bupl__gf_ap_team_user_id__c) {
                apDeleteList.add(apDelete);
            }
        }
        Desktop_Utils_aux.deleteSharingAP(apDeleteList);
    } //FIN removeEditAccess

}