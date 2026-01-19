/**
* ____________________________________________________________________________
* Toolkit Alert Sample
* Implementation of the interface cstk.Alert_Itf
* ____________________________________________________________________________
* @author      Manuel Canellas <manuel.canellas.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-06-06
* @modified
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ExcessiveParameterList, PMD.EmptyStatementBlock')

/**
* @description Implementation of the interface cstk.Alert_Itf
*/
global with sharing class CSTK_Alert implements cstk.Alert_Itf {

    /**
    * @description create alert record associate to user and toolkit
    * @param alertWrapper : wrapper Alert
    */
    global static void createUserAlert(cstk.Alert_Wrapper alertWrapper) {
        final List<User> users = [SELECT FederationIdentifier FROM User WHERE Id =: alertWrapper.userId];
        final String rtIdToolkitAlert = [SELECT Id FROM RecordType WHERE DeveloperName = 'Commercial_Task_Toolkit' AND SobjectType = 'altm__Commercial_Alert__c'][0]?.Id;
        if(users.isEmpty()) {
             throw new IllegalArgumentException('The provided User ID is not valid.');
        }
        if(String.isBlank(users[0]?.FederationIdentifier) ) {
             throw new IllegalArgumentException('The User ID dont have federation identifier');
        }
        try {
            final altm__Commercial_Alert__c alert = getCommercialAlertRecord(alertWrapper, users[0]?.FederationIdentifier, rtIdToolkitAlert);
            insert alert;
        } catch (Exception e) {
            System.debug('Error CSTK_Alert.createUserAlert: ' + e.getMessage());
        }
    }

    /**
    * @description create alert record associate to users in a profile and toolkit
    * @param alertWrapper : wrapper Alert
    */
    global static void createProfileAlert(cstk.Alert_Wrapper alertWrapper) {}

    /**
    * @description create alert record associate to users in a public group and toolkit
    * @param alertWrapperList : List of wrapper Alert
    */
    global static void createGroupAlert(List<cstk.Alert_Wrapper> alertWrapperList) {
        final Set<String> groupDeveloperNames = new Set<String>();
        final List<User> users = [SELECT FederationIdentifier FROM User WHERE Id =: UserInfo.getUserId()];
        final String rtIdTeamMember = [SELECT Id FROM RecordType WHERE DeveloperName = 'Commercial_Alert' AND SobjectType = 'ctcp__Custom_Team__c'][0]?.Id;
        final String rtIdToolkitAlert = [SELECT Id FROM RecordType WHERE DeveloperName = 'Commercial_Task_Toolkit' AND SobjectType = 'altm__Commercial_Alert__c'][0]?.Id;
        final List<ctcp__Custom_Team__c> alertTeamMembers = new List<ctcp__Custom_Team__c>();
        final Map<String, List<GroupMember>> mapGroupNameMembers = new Map<String, List<GroupMember>>();
        final List<altm__Commercial_Alert__c> alertsToInsert = new List<altm__Commercial_Alert__c>();
        try {
            for(cstk.Alert_Wrapper alertWrapper :  alertWrapperList) {
                groupDeveloperNames.add(alertWrapper.groupDeveloperName);
            }
            for(GroupMember member : [SELECT UserOrGroupId, Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName =: groupDeveloperNames]) {
                if(mapGroupNameMembers.get(member.Group.DeveloperName) == null) {
                    mapGroupNameMembers.put(member.Group.DeveloperName, new List<GroupMember>());
                }
                mapGroupNameMembers.get(member.Group.DeveloperName).add(member);
            }
            for(cstk.Alert_Wrapper alertWrapper :  alertWrapperList) {
                alertsToInsert.add(getCommercialAlertRecord(alertWrapper, users[0]?.FederationIdentifier, rtIdToolkitAlert));
            }
            insert alertsToInsert;
            for(Integer index = 0; index < alertWrapperList.size(); index ++) {
                for(GroupMember member : mapGroupNameMembers.get(alertWrapperList[index].groupDeveloperName)) {
                    final ctcp__Custom_Team__c alertTeamMember = new ctcp__Custom_Team__c();
                    alertTeamMember.commercial_alert_id__c = alertsToInsert[index].Id;
                    alertTeamMember.ctcp__Object_Name__c = 'altm__Commercial_Alert__c';
                    alertTeamMember.RecordTypeId = rtIdTeamMember;
                    alertTeamMember.ctcp__gf_team_users_desc__c = member.UserOrGroupId;
                    alertTeamMembers.add(alertTeamMember);
                }
            }
            insert alertTeamMembers;
        } catch (Exception e) {
            System.debug('Error CSTK_Alert.createGroupAlert: ' + e.getMessage());
        }
    }

    /**
    * @description create alert record associate to users in a rol and toolkit
    * @param alertWrapperList : List of wrapper Alert
    */
    global static void createRolAlert(List<cstk.Alert_Wrapper> alertWrapperList) {
        final Set<String> rolesNames = new Set<String>();
        final List<User> users = [SELECT FederationIdentifier FROM User WHERE Id =: UserInfo.getUserId()];
        final String rtIdTeamMember = [SELECT Id FROM RecordType WHERE DeveloperName = 'Commercial_Alert' AND SobjectType = 'ctcp__Custom_Team__c'][0]?.Id;
        final String rtIdToolkitAlert = [SELECT Id FROM RecordType WHERE DeveloperName = 'Commercial_Task_Toolkit' AND SobjectType = 'altm__Commercial_Alert__c'][0]?.Id;
        final List<ctcp__Custom_Team__c> alertTeamMembers = new List<ctcp__Custom_Team__c>();
        final Map<String, List<User>> mapRolNameUsers = new Map<String, List<User>>();
        final List<altm__Commercial_Alert__c> alertsToInsert = new List<altm__Commercial_Alert__c>();
        try {
            for(cstk.Alert_Wrapper alertWrapper :  alertWrapperList) {
                rolesNames.add(alertWrapper.rolName);
            }
            for(User user : [SELECT id, UserRole.name, name FROM user WHERE UserRole.name =: rolesNames AND id !=: UserInfo.getUserId() AND IsActive = TRUE]) {//NOSONAR
                if(mapRolNameUsers.get(user.UserRole.name) == null) {
                    mapRolNameUsers.put(user.UserRole.name, new List<User>());
                }
                mapRolNameUsers.get(user.UserRole.name).add(user);
            }
            for(cstk.Alert_Wrapper alertWrapper :  alertWrapperList) {
                alertsToInsert.add(getCommercialAlertRecord(alertWrapper, users[0]?.FederationIdentifier, rtIdToolkitAlert));
            }
            insert alertsToInsert;
            for(Integer index = 0; index < alertWrapperList.size(); index ++) {
                for(User user : mapRolNameUsers.get(alertWrapperList[index].rolName)) {
                    final ctcp__Custom_Team__c alertTeamMember = new ctcp__Custom_Team__c();
                    alertTeamMember.commercial_alert_id__c = alertsToInsert[index].Id;
                    alertTeamMember.ctcp__Object_Name__c = 'altm__Commercial_Alert__c';
                    alertTeamMember.RecordTypeId = rtIdTeamMember;
                    alertTeamMember.ctcp__gf_team_users_desc__c = user.id;
                    alertTeamMembers.add(alertTeamMember);
                }
            }
            insert alertTeamMembers;
        } catch (Exception e) {
            System.debug('Error CSTK_Alert.createRolAlert: ' + e.getMessage());
        }
    }

    /**
    * @description get alerts associate to user
    * @param alertWrapper : wrapper Alert
    * @return List of alerts
    */
    global static List<altm__Commercial_Alert__c>  getUserAlerts(cstk.Alert_Wrapper alertWrapper) {
        final List<String> alertIds = new List<String>();
        for (ctcp__Custom_Team__c member : [SELECT commercial_alert_id__c FROM ctcp__Custom_Team__c WHERE commercial_alert_id__c != null AND RecordType.DeveloperName = 'Commercial_Alert' AND ctcp__gf_team_users_desc__c =: alertWrapper.userId]) {//NOSONAR
            alertIds.add(member.commercial_alert_id__c);
        }
        return [SELECT Id, Name FROM altm__Commercial_Alert__c WHERE id IN: alertIds AND RecordType.DeveloperName = 'Commercial_Task_Toolkit'];
    }

    /**
    * @description get unread alerts associate to user if the user is in the some public group
    * @param alertWrapper: Wrapper with the data to get the users alert filter by group
    * @return List of alerts
    */
    global static List<altm__Commercial_Alert__c>  getUnreadUserAlertsFilterByPublicGroup(cstk.Alert_Wrapper alertWrapper) {
        final List<GroupMember> members = [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName =: alertWrapper.groupDeveloperNames AND UserOrGroupId =: alertWrapper.userId];
        List<altm__Commercial_Alert__c> alerts;
        if(members?.isEmpty()) {
            alerts = new List<altm__Commercial_Alert__c>();
        } else {
            final List<String> alertIds = new List<String>();
            for (ctcp__Custom_Team__c member : [SELECT commercial_alert_id__c FROM ctcp__Custom_Team__c WHERE commercial_alert_id__c != null AND RecordType.DeveloperName = 'Commercial_Alert' AND ctcp__gf_team_users_desc__c =: alertWrapper.userId]) {//NOSONAR
                alertIds.add(member.commercial_alert_id__c);
            }
            alerts = [SELECT Id, Name FROM altm__Commercial_Alert__c WHERE id IN: alertIds AND altm__alert_stage_type__c =: Label.COMMERCIAL_ALERT_STATUS_UNREAD AND RecordType.DeveloperName = 'Commercial_Task_Toolkit'];
        }
        return alerts;
    }

    /**
    * @description update alert status
    * @param alertWrapper: Wrapper with the data to get the users alert
    * @return result of update
    */
    global static Boolean updateAlertStatus(cstk.Alert_Wrapper alertWrapper) {
        Boolean result = false;
        try {
            final List<altm__Commercial_Alert__c> alerts = new List<altm__Commercial_Alert__c>();
            for (String alertId : alertWrapper.alertIds) {
                final altm__Commercial_Alert__c alert = new altm__Commercial_Alert__c();
                alert.Id = alertId;
                alert.altm__alert_stage_type__c = alertWrapper.status;
                alerts.add(alert);
            }
            update alerts;
            result = true;
        } catch (Exception e) {
            System.debug('Error CSTK_Alert.updateAlertStatus: ' + e.getMessage());
        }
        return result;
    }

    /**
    * @description get commercial alert record
    * @param alertWrapper: Wrapper with the data to get the alert
    * @return commercial alert record
    */
    private static altm__Commercial_Alert__c getCommercialAlertRecord(cstk.Alert_Wrapper alertWrapper, String federationId, String rtIdToolkitAlert) {
        final altm__Commercial_Alert__c alert = new altm__Commercial_Alert__c();
        alert.altm__participant_id__c = alertWrapper.accountId;
        alert.altm__owner_access_alert_id__c = federationId;
        alert.Name = alertWrapper.name;
        alert.altm__commercial_product_type__c = 'Toolkit';
        alert.altm__commercial_alert_desc__c = alertWrapper.description;
        alert.cstk__Toolkit__c = alertWrapper.toolkitId;
        alert.altm__alert_stage_type__c = 'Unread';
        alert.altm__commercial_alert_end_date__c = Date.today().addDays(30);
        alert.recordTypeId = rtIdToolkitAlert;
        alert.cstk__Alert_type__c = alertWrapper.alertType;
        alert.cstk__Year__c = alertWrapper.year;
        alert.altm__priority_alert_type__c = alertWrapper.priority;
        alert.altm__commercial_alert_id__c = String.isBlank(alertWrapper.alertId) ? federationId + '-' + String.valueOf(Datetime.now()) : federationId + '-' + alertWrapper.alertId;
        return alert;
    }

    /**
    * @description get unread alerts associate to user if the user is in the some public rol
    * @param alertWrapper Wrapper with the data to get the users alert filter by rol
    * @return List of alerts
    */
    global static List<altm__Commercial_Alert__c>  getUnreadUserAlertsFilterByRol(cstk.Alert_Wrapper alertWrapper) {
        final List<String> alertIds = new List<String>();
        for (ctcp__Custom_Team__c member : [SELECT commercial_alert_id__c FROM ctcp__Custom_Team__c WHERE commercial_alert_id__c != null AND RecordType.DeveloperName = 'Commercial_Alert' AND ctcp__gf_team_users_desc__c =: alertWrapper.userId AND ctcp__gf_team_users_desc__r.UserRole.Name =: alertWrapper.rolesNames]) {//NOSONAR
            alertIds.add(member.commercial_alert_id__c);
        }
        return [SELECT Id, Name FROM altm__Commercial_Alert__c WHERE id IN: alertIds AND altm__alert_stage_type__c =: Label.COMMERCIAL_ALERT_STATUS_UNREAD AND RecordType.DeveloperName = 'Commercial_Task_Toolkit'];
    }

}