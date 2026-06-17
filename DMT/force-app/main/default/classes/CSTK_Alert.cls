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
    * @param alertWrapperList : List of wrapper Alert
    */
    global static void createUserAlerts(List<cstk.Alert_Wrapper> alertWrapperList) {
        final String rtIdToolkitAlert = [SELECT Id FROM RecordType WHERE DeveloperName = 'Commercial_Task_Toolkit' AND SobjectType = 'altm__Commercial_Alert__c'][0]?.Id;
        final List<altm__Commercial_Alert__c> alertsToInsert = new List<altm__Commercial_Alert__c>();
        altm__Commercial_Alert__c alert = new altm__Commercial_Alert__c();

        try {
            for(cstk.Alert_Wrapper alertWrapper :  alertWrapperList) {
                if (String.isNotBlank(alertWrapper.userId)) {
                    alert = getCommercialAlertRecord(alertWrapper, alertWrapper.federationId, rtIdToolkitAlert);
                    alert.OwnerId = alertWrapper.userId;
                    alertsToInsert.add(alert);
                }
            }
            if (!alertsToInsert.isEmpty()) {
                insert alertsToInsert;
            }
        } catch (Exception e) {
            System.debug('Error CSTK_Alert.createUserAlerts: ' + e.getMessage());
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
                alert.cstk__Read_date__c = Date.today();
                alert.cstk__ReadBy__c = UserInfo.getUserId();
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
        alert.cstk__Tri_Generic__c = alertWrapper.triGeneric;
        alert.cstk__Tri_Autoparts__c = alertWrapper.triAutoparts;
        alert.cstk__Tri_multisector__c = alertWrapper.triMultiSector;
        alert.cstk__Tri__c = alertWrapper.tri;
        alert.altm__priority_alert_type__c = alertWrapper.priority;
        alert.altm__commercial_alert_id__c = String.isBlank(alertWrapper.alertId) ? federationId + '-' + String.valueOf(Datetime.now()) : federationId + '-' + alertWrapper.alertId;
        return alert;
    }

    /**
    * @description get unread toolkit alerts
    * @return List of alerts
    */
    global static List<altm__Commercial_Alert__c> getUnreadToolkitAlerts() {
        final List<altm__Commercial_Alert__c> alertsList = new List<altm__Commercial_Alert__c>();
        final List<ctcp__Custom_Team__c > alertMembers = [SELECT commercial_alert_id__c, commercial_alert_id__r.name, commercial_alert_id__r.cstk__Alert_type__c
                                                    FROM ctcp__Custom_Team__c
                                                    WHERE commercial_alert_id__r.altm__alert_stage_type__c =: Label.COMMERCIAL_ALERT_STATUS_UNREAD
                                                        AND commercial_alert_id__r.RecordType.DeveloperName = 'Commercial_Task_Toolkit'
                                                        AND ctcp__gf_team_users_desc__r.Profile.Name = 'BBVA Standard User'
                                                        AND ctcp__gf_team_users_desc__c =: UserInfo.getUserId()];
        for(ctcp__Custom_Team__c alertMember : alertMembers){
            final altm__Commercial_Alert__c alert = new altm__Commercial_Alert__c();
            alert.id = alertMember.commercial_alert_id__c;
            alert.name = alertMember.commercial_alert_id__r.name;
            alert.cstk__Alert_type__c = alertMember.commercial_alert_id__r.cstk__Alert_type__c;
            alertsList.add(alert);
        }
        return alertsList;
    }

    /**
    * @description Sends tri alerts emails
    * @param alertWrapperList Wrapper with the data to get the users alert
    */
    global static void sendTriAlertsEmails(List<cstk.Alert_Wrapper> alertWrapperList){
        Map<String, String> toolkitRecordsMap = getTriRecipientEmails(alertWrapperList);
        final List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>();
        final EmailTemplate template = [SELECT Id, Subject, HtmlValue, Name FROM EmailTemplate WHERE Name = 'tri_alert_expiration'];
        for(cstk.Alert_Wrapper alertWrapper : alertWrapperList){
            final Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            String triId = alertWrapper.tri;
            triId = String.isEmpty(triId) ? alertWrapper.triAutoparts : triId;
            triId = String.isEmpty(triId) ? alertWrapper.triGeneric : triId;
            triId = String.isEmpty(triId) ? alertWrapper.triMultiSector : triId;
            message.setUseSignature(false);
            message.setBccSender(false);
            message.setSaveAsActivity(false);
            message.toAddresses = new List<String>{toolkitRecordsMap.get(alertWrapper.toolkitId)};
            message.setTemplateID(template.Id);
            String body = template.HtmlValue;
            if (alertWrapper.emailType == 'ExpiredTri') {
                body = body.replaceAll('\\{Body\\}', System.Label.cstk.DismissedTriMessage);
                message.subject = System.Label.cstk.TriExpiredAlertName + ' ' + alertWrapper.accountName;
            }else if (alertWrapper.emailType == 'OneWeekWarningTri') {
                body = body.replaceAll('\\{Body\\}', System.Label.cstk.OneWeekWarningTriMessage);
                message.subject = System.Label.cstk.Urgent + ' - ' + System.Label.cstk.TriAlertName + ' ' + alertWrapper.accountName;
            }else if (alertWrapper.emailType == 'OneMonthWarningTri') {
                body = body.replaceAll('\\{Body\\}', System.Label.cstk.OneMonthWarningTriMessage);
                message.subject = System.Label.cstk.TriAlertName + ' ' + alertWrapper.accountName;
            }
            body = body.replaceAll('\\{link\\}', URL.getOrgDomainURL().toExternalForm() + '/lightning/r/' + triId + '/view');
            message.setHtmlBody(body);
            messagesList.add(message);
        }
        CSTK_Utils.sendEmails(messagesList);
    }

   /**
    * @description This method returns a map with the toolkitId and the mails to send
    * @param alertWrapperList
    * @return Map<String, String>
    */
    global static Map<String, String> getTriRecipientEmails(List<cstk.Alert_Wrapper> alertWrapperList) {
        Map<String, String> mailsToolkitIdMap = new Map<String, String>();
        Set<String> toolkitIds = new Set<String>();
        for(cstk.Alert_Wrapper alertWrapper : alertWrapperList){
            toolkitIds.add(alertWrapper.toolkitId);
        }
        final Map<Id, cstk__Toolkit__c> toolkitRecordsMap = new Map<Id,  cstk__Toolkit__c>([SELECT Id, cstk__account_id__r.DES_Country_of_Management__c, cstk__account_id__r.DES_BBVA_Segmentation__c FROM cstk__Toolkit__c WHERE Id =: toolkitIds]);
        final cstk.Json_Selector jsonSelector = new cstk.Json_Selector();
        final List<cstk__ESG_Toolkit_Settings_Json__mdt> triEmails = jsonSelector.selectByObjectName(cstk.Utils.getTriValidatorsStringToFilterByOrg());
        final String triEmailsJson = triEmails[0].cstk__json__c;
        final Map<String, Object> emailsMap = (Map<String, Object>)JSON.deserializeUntyped(triEmailsJson);
        final Map<String, String> segmentationPickList = Util_PickList.getLabelFromApi('Account', 'DES_BBVA_Segmentation__c');
        for(cstk.Alert_Wrapper alertWrapper : alertWrapperList){
            final Boolean isTriMultisector = String.isEmpty(alertWrapper.triMultiSector) ? false : true;
            final cstk__Toolkit__c toolkitRecord = toolkitRecordsMap.get(alertWrapper.toolkitId);
            final String accGeo = toolkitRecord.cstk__account_id__r.DES_Country_of_Management__c;
            final String segmentation = segmentationPickList.get(toolkitRecord.cstk__account_id__r.DES_BBVA_Segmentation__c);
            for (String email : emailsMap.keySet()) {
                final Map<String, Object> segmentGeoMap = (Map<String, Object>)emailsMap.get(email);
                final String geosString = (String)segmentGeoMap.get('geo');
                final List<String> geos = geosString.split(',');
                List<String> segments = new List<String>();
                if (String.isNotBlank(String.valueOf(segmentGeoMap.get('segment')))) {
                    final String segmentsString = (String)segmentGeoMap.get('segment');
                    segments = segmentsString.split(',');
                }
                if ((segments.isEmpty() || segments.contains(segmentation)) && geos.contains(accGeo)) {
                    mailsToolkitIdMap.put(alertWrapper.toolkitId, email);
                }
            }
            if (isTriMultisector && String.isBlank(mailsToolkitIdMap.get(alertWrapper.toolkitId)) && !triEmails[0].Label.contains('sample')) {
                if (segmentation == 'CIB') {
                    mailsToolkitIdMap.put(alertWrapper.toolkitId, 'spain-cib.group@bbva.com');
                } else if (segmentation == 'BEC' || segmentation == 'LOCAL') {
                    mailsToolkitIdMap.put(alertWrapper.toolkitId, 'grupo-validadores-tri-spain-bec.group@bbva.com');
                } else {
                    mailsToolkitIdMap.put(alertWrapper.toolkitId, 'spain-cib.group@bbva.com,grupo-validadores-tri-spain-bec.group@bbva.com');
                }
            } else if (!isTriMultisector && String.isBlank(mailsToolkitIdMap.get(alertWrapper.toolkitId)) && !triEmails[0].Label.contains('sample')) {
                mailsToolkitIdMap.put(alertWrapper.toolkitId, 'spain-cib.group@bbva.com');
            } else if (String.isBlank(mailsToolkitIdMap.get(alertWrapper.toolkitId)) && triEmails[0].Label.contains('sample')) {
                mailsToolkitIdMap.put(alertWrapper.toolkitId, 'gdt_toolkit.group@bbva.com');
            }
        }
        return mailsToolkitIdMap;
    }
}