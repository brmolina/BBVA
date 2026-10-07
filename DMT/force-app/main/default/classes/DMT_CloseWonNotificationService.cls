/**
 * @description Service class that sends email notifications to subscribed users when
 *              a DMT_Line__c or an Opportunity associated to a client reaches "Closed Won" status.
 *              Triggered from DMT_Line_TriggerHandler and Opportunity.trigger after-update contexts.
 */
public without sharing class DMT_CloseWonNotificationService {

    // Email template developer names per notification type
    private static final String TEMPLATE_CLOSE_WON_LINE = 'Line_Approvers_Closed_Won_Notification';
    private static final String TEMPLATE_CLOSE_WON_OPP  = 'Opp_Approvers_Closed_Won_Notification';
    private static final String TEMPLATE_REVIEW_LINE    = 'Line_Back_To_Draft_Notification';
    private static final String TEMPLATE_CLOSE_LOST_LINE = 'Line_Approvers_Closed_Lost_Notification';
    private static final String TEMPLATE_CLOSE_LOST_OPP  = 'Opp_Approvers_Closed_Lost_Notification';
    private static final String TEMPLATE_REVIEW_OPP     = 'Opp_Back_To_Draft_Notification';
    private static final String TEMPLATE_TASK_LINE      = 'DMT_Task_assigned_Line';
    private static final String TEMPLATE_TASK_OPP       = 'DMT_Task_assigned_Opp';

    private static final String SENDER_DISPLAY_NAME     = 'Global Desktop Notification';
    private static final String CLOSE_WON_TYPE          = 'Closed_Won';
    private static final String CLOSE_LOST_TYPE         = 'Closed_Lost';
    private static final String REVIEW_TYPE             = 'Lines_Opportunities_review';
    private static final String TASK_ASSIGNED_TYPE      = 'Task_Assigned';
    private static final Set<String> READ_WRITE_LEVELS   = new Set<String>{ 'Edit', 'All' };

    // WUT survey Platform Event parameters for the Closed Won trigger
    private static final String WUT_SURVEY_NAME         = 'DMTWUT';
    private static final String WUT_MODULE_NAME         = 'Deal Management';

    // Captures emails sent in test context (validation point 3)
    @TestVisible private static List<Messaging.SingleEmailMessage> sentEmailsCapture = new List<Messaging.SingleEmailMessage>();
    // Allows injecting an EmailTemplate in tests without depending on SOQL (avoids failures from a missing template)
    @TestVisible private static EmailTemplate testTemplateOverride = null;
    // Allows injecting subscriber emails in tests without depending on SOQL
    @TestVisible private static List<String> testSubscriberEmails = null;

    @TestVisible private static Set<String> alreadyNotified = new Set<String>();

    // ─── Public entry points ──────────────────────────────────────────────────

    /**
     * @description Sends Close Won notifications for DMT_Line__c records that have just
     *              transitioned to Status__c = 'Closed' AND DMT_Status_Completed__c = 'Closed Won'.
     * @param newLines  Trigger.new list of DMT_Line__c.
     * @param oldMap    Trigger.oldMap for the same records.
     */
    public static void sendCloseWonLineNotifications(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMap) {
        sendClosedLineNotifications(newLines, oldMap, 'Closed Won', CLOSE_WON_TYPE, TEMPLATE_CLOSE_WON_LINE);
    }

    public static void sendCloseLostLineNotifications(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMap) {
        sendClosedLineNotifications(newLines, oldMap, 'Closed Lost', CLOSE_LOST_TYPE, TEMPLATE_CLOSE_LOST_LINE);
    }

    private static void sendClosedLineNotifications(
        List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMap,
        String closedResult, String subscriptionType, String templateName
    ) {
        if (newLines == null || newLines.isEmpty()) {
            return;
        }

        List<DMT_Line__c> triggered = new List<DMT_Line__c>();
        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = oldMap.get(line.Id);
            Boolean isNowClosed    = line.Status__c == 'Closed' && line.DMT_Status_Completed__c == closedResult; 
            Boolean wasNotClosed   = oldLine == null
                || !(oldLine.Status__c == 'Closed' && oldLine.DMT_Status_Completed__c == closedResult); 
            if (isNowClosed && wasNotClosed && line.Client__c != null
                && alreadyNotified.add(String.valueOf(line.Id) + ':' + subscriptionType)) { // evita duplicados
                triggered.add(line);
            }
        }
        if (triggered.isEmpty()) {
            return;
        }

        if (subscriptionType == CLOSE_WON_TYPE) { // la encuesta WUT solo aplica a Closed Won
            publishWutClosedWonSurvey();
        }

        Set<Id> clientIds = new Set<Id>();
        for (DMT_Line__c line : triggered) {
            clientIds.add(line.Client__c);
        }

        Map<Id, List<SubscriberInfo>> subsByClient = getSubscribersByAccount(clientIds, subscriptionType); 
        if (subsByClient.isEmpty()) {
            return;
        }

        // Use Line-specific Close Won template
        EmailTemplate template = getTemplate(templateName); 
        if (template == null) {
            return;
        }
        Id orgWideEmailId = getOrgWideEmailId();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (DMT_Line__c line : triggered) {
            List<SubscriberInfo> subscribers = subsByClient.get(line.Client__c);
            if (subscribers == null) {
                continue;
            }
            //  Filter to only owner and Approval participants (subscribed) of this line or its parent opportunity
            List<SubscriberInfo> authorizedSubscribers = filterSubscribersForLineApprovalParticipants(subscribers, line);
            for (SubscriberInfo sub : authorizedSubscribers) {
                Messaging.SingleEmailMessage mail = buildEmail(template, sub.userId, sub.email, line.Id, orgWideEmailId);
                if (mail != null) {
                    emails.add(mail);
                }
            }
        }
        dispatchEmails(emails);
    }

    /**
     * @description Sends Close Won/Lost notifications for Opportunity records that have just
     *              transitioned to StageName = 'Closed Won'/'Closed Lost'
     * @param newOpps  Trigger.new list of Opportunity.
     * @param oldMap   Trigger.oldMap for the same records.
     */
    public static void sendCloseWonOppNotifications(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
    // punto de entrada Closed Won (Opportunities)
        sendClosedOppNotifications(newOpps, oldMap, 'Closed Won', CLOSE_WON_TYPE, TEMPLATE_CLOSE_WON_OPP);
    }

    // punto de entrada Closed Lost (Opportunities)
    public static void sendCloseLostOppNotifications(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        sendClosedOppNotifications(newOpps, oldMap, 'Closed Lost', CLOSE_LOST_TYPE, TEMPLATE_CLOSE_LOST_OPP);
    }

    //  cuerpo original de sendCloseWonOppNotifications, parametrizado por etapa, tipo y plantilla
    private static void sendClosedOppNotifications(
        List<Opportunity> newOpps, Map<Id, Opportunity> oldMap,
        String closedStage, String subscriptionType, String templateName
    ) {
        if (newOpps == null || newOpps.isEmpty()) {
            return;
        }

        List<Opportunity> triggered = new List<Opportunity>();
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean isNowClosedWon  = opp.StageName == closedStage; 
            Boolean wasNotClosedWon = oldOpp == null || oldOpp.StageName != closedStage; 
            if (isNowClosedWon && wasNotClosedWon && opp.AccountId != null
                && alreadyNotified.add(String.valueOf(opp.Id) + ':' + subscriptionType)) { //evita duplicados
                triggered.add(opp);
            }
        }
        if (triggered.isEmpty()) {
            return;
        }

        if (subscriptionType == CLOSE_WON_TYPE) { //  la encuesta WUT solo aplica a Closed Won
            publishWutClosedWonSurvey();
        }

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : triggered) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, List<SubscriberInfo>> subsByAccount = getSubscribersByAccount(accountIds, subscriptionType); 
        if (subsByAccount.isEmpty()) {
            return;
        }

        // Use Opportunity-specific Close Won template
        EmailTemplate template = getTemplate(templateName); 
        if (template == null) {
            return;
        }
        Id orgWideEmailId = getOrgWideEmailId();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : triggered) {
            List<SubscriberInfo> subscribers = subsByAccount.get(opp.AccountId);
            if (subscribers == null) {
                continue;
            }
            //  Filter to only owner and Approval participants (subscribed)
            List<SubscriberInfo> authorizedSubscribers = filterSubscribersForOpportunityApprovalParticipants(subscribers, opp);
            for (SubscriberInfo sub : authorizedSubscribers) {
                Messaging.SingleEmailMessage mail = buildEmail(template, sub.userId, sub.email, opp.Id, orgWideEmailId);
                if (mail != null) {
                    emails.add(mail);
                }
            }
        }
        dispatchEmails(emails);
    }

    /**
     * @description Sends Draft notifications for DMT_Line__c records that have just
     *              transitioned to Status__c = 'Draft'.
     * @param newLines  Trigger.new list of DMT_Line__c.
     * @param oldMap    Trigger.oldMap for the same records.
     */
    public static void sendDraftLineNotifications(List<DMT_Line__c> newLines, Map<Id, DMT_Line__c> oldMap) {
        if (newLines == null || newLines.isEmpty()) {
            return;
        }

        List<DMT_Line__c> triggered = new List<DMT_Line__c>();
        for (DMT_Line__c line : newLines) {
            DMT_Line__c oldLine = oldMap.get(line.Id);
            Boolean isNowDraft  = line.Status__c == 'Draft';
            Boolean wasNotDraft = oldLine == null || oldLine.Status__c != 'Draft';
            Boolean isBackToProposal = line.Status__c == 'Proposal' && oldLine != null && oldLine.Status__c == 'Approval';
            if (((isNowDraft && wasNotDraft) || isBackToProposal) && line.Client__c != null
                && alreadyNotified.add(String.valueOf(line.Id) + ':' + REVIEW_TYPE)) {
                triggered.add(line);
            }
        }
        if (triggered.isEmpty()) {
            return;
        }

        Set<Id> clientIds = new Set<Id>();
        for (DMT_Line__c line : triggered) {
            clientIds.add(line.Client__c);
        }

        Map<Id, List<SubscriberInfo>> subsByClient = getSubscribersByAccount(clientIds, REVIEW_TYPE);
        if (subsByClient.isEmpty()) {
            return;
        }

        // Use Line-specific Review template
        EmailTemplate template = getTemplate(TEMPLATE_REVIEW_LINE);
        if (template == null) {
            return;
        }
        Id orgWideEmailId = getOrgWideEmailId();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (DMT_Line__c line : triggered) {
            List<SubscriberInfo> subscribers = subsByClient.get(line.Client__c);
            if (subscribers == null) {
                continue;
            }
            // Filter to only owners and participants of this line or its parent opportunity
            List<SubscriberInfo> authorizedSubscribers = filterSubscribersForLine(subscribers, line, true);
            for (SubscriberInfo sub : authorizedSubscribers) {
                Messaging.SingleEmailMessage mail = buildEmail(template, sub.userId, sub.email, line.Id, orgWideEmailId);
                if (mail != null) {
                    emails.add(mail);
                }
            }
        }
        dispatchEmails(emails);
    }

    /**
     * @description Sends Draft notifications for Opportunity records that have just
     *              transitioned to StageName = 'Draft'.
     * @param newOpps  Trigger.new list of Opportunity.
     * @param oldMap   Trigger.oldMap for the same records.
     */
    public static void sendDraftOppNotifications(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        if (newOpps == null || newOpps.isEmpty()) {
            return;
        }

        List<Opportunity> triggered = new List<Opportunity>();
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean isNowDraft  = opp.StageName == 'Draft';
            Boolean wasNotDraft = oldOpp == null || oldOpp.StageName != 'Draft';
            Boolean isBackToProposal = opp.StageName == 'Proposal' && oldOpp != null && oldOpp.StageName == 'Approval';
            if (((isNowDraft && wasNotDraft) || isBackToProposal) && opp.AccountId != null
                && alreadyNotified.add(String.valueOf(opp.Id) + ':' + REVIEW_TYPE)) {
                triggered.add(opp);
            }
        }
        if (triggered.isEmpty()) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : triggered) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, List<SubscriberInfo>> subsByAccount = getSubscribersByAccount(accountIds, REVIEW_TYPE);
        if (subsByAccount.isEmpty()) {
            return;
        }

        // Use Opportunity-specific Review template
        EmailTemplate template = getTemplate(TEMPLATE_REVIEW_OPP);
        if (template == null) {
            return;
        }
        Id orgWideEmailId = getOrgWideEmailId();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : triggered) {
            List<SubscriberInfo> subscribers = subsByAccount.get(opp.AccountId);
            if (subscribers == null) {
                continue;
            }
            //  Filter to only owner and Approval participants (subscribed)
            List<SubscriberInfo> authorizedSubscribers = filterSubscribersForOpportunity(subscribers, opp, true);
            for (SubscriberInfo sub : authorizedSubscribers) {
                Messaging.SingleEmailMessage mail = buildEmail(template, sub.userId, sub.email, opp.Id, orgWideEmailId);
                if (mail != null) {
                    emails.add(mail);
                }
            }
        }
        dispatchEmails(emails);
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private class SubscriberInfo {
        public Id     userId;
        public String email;

        public SubscriberInfo(Id userId, String email) {
            this.userId = userId;
            this.email  = email;
        }
    }

    private static Map<Id, List<SubscriberInfo>> getSubscribersByAccount(Set<Id> accountIds, String subscriptionType) {
        if (Test.isRunningTest() && testSubscriberEmails != null) {
            Map<Id, List<SubscriberInfo>> testResult = new Map<Id, List<SubscriberInfo>>();
            for (Id acctId : accountIds) {
                List<SubscriberInfo> subs = new List<SubscriberInfo>();
                for (String email : testSubscriberEmails) {
                    subs.add(new SubscriberInfo(UserInfo.getUserId(), email));
                }
                testResult.put(acctId, subs);
            }
            return testResult;
        }
        Map<Id, List<SubscriberInfo>> result = new Map<Id, List<SubscriberInfo>>();
        Set<String> addedUserByAccount = new Set<String>();

        // No WITH USER_MODE: this runs from trigger context (system mode).
        // WITH USER_MODE would silently return 0 rows if the running user lacks CRUD on the object.
        // Query includes both account-specific subscriptions and global subscriptions (Client__c = NULL)
        List<DMT_NotificationSubscription__c> subs = [
            SELECT User__c, User__r.Email, Client__c
            FROM DMT_NotificationSubscription__c
            WHERE (Client__c IN :accountIds OR Client__c = NULL)
              AND Type__c = :subscriptionType
              AND User__r.IsActive = true
        ];

        for (DMT_NotificationSubscription__c sub : subs) {
            if (String.isBlank(sub.User__r.Email)) {
                continue;
            }
            
            // If subscription is global (Client__c = NULL), add subscriber to ALL accounts
            if (sub.Client__c == NULL) {
                for (Id accountId : accountIds) {
                    if (!addedUserByAccount.add(String.valueOf(accountId) + ':' + sub.User__c)) { 
                        continue;
                    }
                    if (!result.containsKey(accountId)) {
                        result.put(accountId, new List<SubscriberInfo>());
                    }
                    result.get(accountId).add(new SubscriberInfo(sub.User__c, sub.User__r.Email));
                }
            } else {
                // If subscription is account-specific, add subscriber only to that account
                if (!addedUserByAccount.add(String.valueOf(sub.Client__c) + ':' + sub.User__c)) { 
                    continue;
                }
                if (!result.containsKey(sub.Client__c)) {
                    result.put(sub.Client__c, new List<SubscriberInfo>());
                }
                result.get(sub.Client__c).add(new SubscriberInfo(sub.User__c, sub.User__r.Email));
            }
        }
        return result;
    }

    private static Messaging.SingleEmailMessage buildEmail(
        EmailTemplate template,
        Id            userId,
        String        recipientEmail,
        Id            recordId,
        Id            orgWideEmailId
    ) {
        String subject;
        String htmlBody;

        try {
            Messaging.SingleEmailMessage rendered =
                Messaging.renderStoredEmailTemplate(template.Id, userId, recordId);
            subject  = rendered != null ? rendered.getSubject()  : null;
            htmlBody = rendered != null ? rendered.getHtmlBody() : null;
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'DMT_CloseWonNotificationService: template render failed — ' + ex.getMessage());
        }

        if (String.isBlank(subject)) {
            subject = 'Closed Won Notification';
        }
        if (String.isBlank(htmlBody)) {
            htmlBody = '<p>A record linked to your client has reached <strong>Closed Won</strong> status.</p>'
                + '<p>Record ID: ' + String.valueOf(recordId) + '</p>';
        }

        if (String.isBlank(recipientEmail)) {
            return null;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mail.setToAddresses(new List<String>{ recipientEmail });
        mail.setSaveAsActivity(false);
        mail.setBccSender(false);
        if (orgWideEmailId != null) {
            mail.setOrgWideEmailAddressId(orgWideEmailId);
        }
        return mail;
    }

    /**
     * @description CIBGLOBALD-4295 - Enqueues a single WUT survey Platform Event publish for a Closed
     *              Won transition batch, via the existing DMT_AsyncOrchestrator/DMT_AsyncDispatcher
     *              framework (same one this trigger already uses for Passport/Snapshot work) rather
     *              than publishing inline or via a standalone Queueable: it shares the same "one
     *              Queueable per transaction" budget instead of competing with it, and the framework
     *              already falls back to Batch when that budget is used up elsewhere in the same
     *              transaction. Deferring to async (instead of inline EventBus.publish) is required
     *              because the event's publish behavior is PublishImmediately, which Salesforce refuses
     *              while this trigger's own record save is still uncommitted in the same transaction -
     *              confirmed via a controlled test (disabling the inline EventBus.publish call made all
     *              9 previously-failing email assertions pass, isolating it as the cause).
     *              One event per transaction, not one per record: the event payload carries no record
     *              reference, so publishing per-record would just inflate the downstream usage/fatigue
     *              counter for what is really one user action.
     *              CIBGLOBALD-4295 - enqueue()/flush() are wrapped in try/catch: enqueue() itself can't
     *              throw, but flush() can (Database.executeBatch/System.enqueueJob can fail synchronously
     *              on governor-limit or async-context restrictions) - async deferral protects the actual
     *              EventBus.publish from the uncommitted-DML restriction, but does nothing to protect this
     *              scheduling call itself from throwing and aborting the caller before it ever reaches the
     *              subscriber/email logic below. A dropped try/catch here was the direct cause of a real
     *              regression (9 email assertions failing) when this method was first switched to the
     *              orchestrator pattern.
     */
    private static void publishWutClosedWonSurvey() {
        try {
            DMT_AsyncOrchestrator.enqueue(new DMT_WutSurveyPayload(
                WUT_SURVEY_NAME, WUT_MODULE_NAME, String.valueOf(UserInfo.getUserId())
            ));
            DMT_AsyncOrchestrator.flush();
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'WUT survey enqueue/flush failed — '
                + ex.getTypeName() + ': ' + ex.getMessage());
        }
    }

    private static void dispatchEmails(List<Messaging.SingleEmailMessage> emails) {
        if (emails.isEmpty()) {
            return;
        }
        if (Test.isRunningTest()) {
            sentEmailsCapture.addAll(emails);
        }
        try {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Messaging.SendEmailError err : results[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'DMT_CloseWonNotificationService email[' + i + '] error: ' + err.getMessage());
                    }
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'DMT_CloseWonNotificationService.dispatchEmails error: ' + ex.getMessage());
        }
    }

    private static EmailTemplate getTemplate(String templateDeveloperName) {
        if (Test.isRunningTest() && testTemplateOverride != null) {
            return testTemplateOverride;
        }
        if (String.isBlank(templateDeveloperName)) {
            return null;
        }
        List<EmailTemplate> templates = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = :templateDeveloperName
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'DMT_CloseWonNotificationService: email template not found: ' + templateDeveloperName);
            return null;
        }
        return templates[0];
    }

    private static Id getOrgWideEmailId() {
        List<OrgWideEmailAddress> addresses = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE DisplayName = :SENDER_DISPLAY_NAME
            LIMIT 1
        ];
        return addresses.isEmpty() ? null : addresses[0].Id;
    }

    // ─── Owner/Participant validation ─────────────────────────────────────────

    /**
     * @description Filters a list of subscribers to only include those who are either:
     *              - Owner of the DMT_Line__c record, OR
     *              - Participant (DMT_TeamMember__c) of the line or its parent Opportunity.
     * @param subscribers List of SubscriberInfo to filter.
     * @param line        The DMT_Line__c record to check access against.
     * @return Filtered list containing only authorized subscribers.
     */
    @TestVisible
    private static List<SubscriberInfo> filterSubscribersForLine(List<SubscriberInfo> subscribers, DMT_Line__c line) {
        return filterSubscribersForLine(subscribers, line, false); 
    }

    private static List<SubscriberInfo> filterSubscribersForLine(List<SubscriberInfo> subscribers, DMT_Line__c line, Boolean requireReadWrite) {
        if (subscribers == null || subscribers.isEmpty() || line == null) {
            return new List<SubscriberInfo>();
        }

        Set<Id> subscriberUserIds = new Set<Id>();
        for (SubscriberInfo sub : subscribers) {
            subscriberUserIds.add(sub.userId);
        }

        Set<Id> authorizedUserIds = new Set<Id>();

        // Check if subscriber is the owner of the line
        if (line.OwnerId != null && subscriberUserIds.contains(line.OwnerId)) {
            authorizedUserIds.add(line.OwnerId);
        }

        // Check if subscriber is a participant of the line or its parent opportunity
        List<DMT_TeamMember__c> teamMembers = [
            SELECT User__c, AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE User__c IN :subscriberUserIds
              AND (Line__c = :line.Id OR Opportunity__c = :line.DMT_Opportunity__c)
        ];

        for (DMT_TeamMember__c tm : teamMembers) {
            if (requireReadWrite && !READ_WRITE_LEVELS.contains(tm.AccessLevel__c)) { 
                continue;
            }
            authorizedUserIds.add(tm.User__c);
        }

        List<SubscriberInfo> filtered = new List<SubscriberInfo>();
        for (SubscriberInfo sub : subscribers) {
            if (authorizedUserIds.contains(sub.userId)) {
                filtered.add(sub);
            }
        }
        return filtered;
    }

    /**
     * @description Filters a list of subscribers to only include those who are either:
     *              - Owner of the Opportunity record, OR
     *              - Participant (DMT_TeamMember__c) of the opportunity.
     * @param subscribers List of SubscriberInfo to filter.
     * @param opp         The Opportunity record to check access against.
     * @return Filtered list containing only authorized subscribers.
     */
    @TestVisible
    private static List<SubscriberInfo> filterSubscribersForOpportunity(List<SubscriberInfo> subscribers, Opportunity opp) {
        return filterSubscribersForOpportunity(subscribers, opp, false); 
    }

    
    private static List<SubscriberInfo> filterSubscribersForOpportunity(List<SubscriberInfo> subscribers, Opportunity opp, Boolean requireReadWrite) {
        if (subscribers == null || subscribers.isEmpty() || opp == null) {
            return new List<SubscriberInfo>();
        }

        Set<Id> subscriberUserIds = new Set<Id>();
        for (SubscriberInfo sub : subscribers) {
            subscriberUserIds.add(sub.userId);
        }

        Set<Id> authorizedUserIds = new Set<Id>();

        // Check if subscriber is the owner of the opportunity
        if (opp.OwnerId != null && subscriberUserIds.contains(opp.OwnerId)) {
            authorizedUserIds.add(opp.OwnerId);
        }

        // Check if subscriber is a participant of the opportunity
        List<DMT_TeamMember__c> teamMembers = [
            SELECT User__c, AccessLevel__c
            FROM DMT_TeamMember__c
            WHERE User__c IN :subscriberUserIds
              AND Opportunity__c = :opp.Id
        ]; // se recupera AccessLevel__c
        for (DMT_TeamMember__c tm : teamMembers) {
            if (requireReadWrite && !READ_WRITE_LEVELS.contains(tm.AccessLevel__c)) { 
                continue;
            }
            authorizedUserIds.add(tm.User__c);
        }

        List<SubscriberInfo> filtered = new List<SubscriberInfo>();
        for (SubscriberInfo sub : subscribers) {
            if (authorizedUserIds.contains(sub.userId)) {
                filtered.add(sub);
            }
        }
        return filtered;
    }

    /**
     * @description Filters a list of subscribers to only include those who are either:
     *              - Owner of the DMT_Line__c record, OR
     *              - A user who completed a Task on the approval process for this line.
     *              Reuses the legacy recipient logic from DMT_SendEmailSelectTeamMember.
     * @param subscribers List of SubscriberInfo to filter.
     * @param line        The DMT_Line__c record to check access against.
     * @return Filtered list containing only authorized subscribers.
     */
    @TestVisible
    private static List<SubscriberInfo> filterSubscribersForLineApprovalParticipants(List<SubscriberInfo> subscribers, DMT_Line__c line) {
        if (subscribers == null || subscribers.isEmpty() || line == null) {
            return new List<SubscriberInfo>();
        }

        Set<Id> authorizedUserIds = DMT_SendEmailSelectTeamMember.getRecipientEmails(line.Id, DMT_Line__c.SObjectType, true).keySet();

        List<SubscriberInfo> filtered = new List<SubscriberInfo>();
        for (SubscriberInfo sub : subscribers) {
            if (authorizedUserIds.contains(sub.userId)) {
                filtered.add(sub);
            }
        }
        return filtered;
    }

    /**
     * @description Filters a list of subscribers to only include those who are either:
     *              - Owner of the Opportunity record, OR
     *              - A user who completed a Task on the approval process for this opportunity.
     *              Reuses the legacy recipient logic from DMT_SendEmailSelectTeamMember.
     * @param subscribers List of SubscriberInfo to filter.
     * @param opp         The Opportunity record to check access against.
     * @return Filtered list containing only authorized subscribers.
     */
    @TestVisible
    private static List<SubscriberInfo> filterSubscribersForOpportunityApprovalParticipants(List<SubscriberInfo> subscribers, Opportunity opp) {
        if (subscribers == null || subscribers.isEmpty() || opp == null) {
            return new List<SubscriberInfo>();
        }

        Set<Id> authorizedUserIds = DMT_SendEmailSelectTeamMember.getRecipientEmails(opp.Id, Opportunity.SObjectType, true).keySet();

        List<SubscriberInfo> filtered = new List<SubscriberInfo>();
        for (SubscriberInfo sub : subscribers) {
            if (authorizedUserIds.contains(sub.userId)) {
                filtered.add(sub);
            }
        }
        return filtered;
    }

    // ─── Task Assigned Notifications ──────────────────────────────────────────

    /**
     * @description Sends Task Assigned notifications for DMT_Line__c related Tasks.
     *              Sends to users who:
     *              1. Are members of the Group (queue) that owns the Task
     *              2. Have the Task_Assigned subscription enabled for the client
     *              3. Are owner or participant of the line
     * @param newTasks  List of newly created Tasks with RecordType DMT_Step_Approval.
     */
    public static void sendTaskAssignedLineNotifications(List<Task> newTasks) {
        if (newTasks == null || newTasks.isEmpty()) {
            return;
        }

        // Filter tasks related to Cases and collect Group IDs
        Set<Id> caseIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        for (Task t : newTasks) {
            if (t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')) {
                caseIds.add(t.WhatId);
            }
            if (t.OwnerId != null && String.valueOf(t.OwnerId).startsWith('00G')) {
                groupIds.add(t.OwnerId);
            }
        }
        if (caseIds.isEmpty() || groupIds.isEmpty()) {
            return;
        }

        // Get Cases with their related Lines
        Map<Id, Case> casesWithLines = new Map<Id, Case>([
            SELECT Id, DMT_Line__c, DMT_Line__r.Client__c, DMT_Line__r.OwnerId, DMT_Line__r.DMT_Opportunity__c
            FROM Case
            WHERE Id IN :caseIds
              AND DMT_Line__c != null
        ]);
        if (casesWithLines.isEmpty()) {
            return;
        }

        // Get Group Members (users in the queue)
        Map<Id, Set<Id>> userIdsByGroupId = getGroupMembers(groupIds);

        // Get client IDs for subscription lookup
        Set<Id> clientIds = new Set<Id>();
        for (Case c : casesWithLines.values()) {
            if (c.DMT_Line__r.Client__c != null) {
                clientIds.add(c.DMT_Line__r.Client__c);
            }
        }

        Map<Id, List<SubscriberInfo>> subsByClient = getSubscribersByAccount(clientIds, TASK_ASSIGNED_TYPE);
        if (subsByClient.isEmpty()) {
            return;
        }

        EmailTemplate template = getTemplate(TEMPLATE_TASK_LINE);
        if (template == null) {
            return;
        }
        Id orgWideEmailId = getOrgWideEmailId();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Task t : newTasks) {
            Case relatedCase = casesWithLines.get(t.WhatId);
            if (relatedCase == null || relatedCase.DMT_Line__c == null) {
                continue;
            }

            Set<Id> groupMemberUserIds = userIdsByGroupId.get(t.OwnerId);
            if (groupMemberUserIds == null || groupMemberUserIds.isEmpty()) {
                continue;
            }

            Id clientId = relatedCase.DMT_Line__r.Client__c;
            List<SubscriberInfo> subscribers = subsByClient.get(clientId);
            if (subscribers == null) {
                continue;
            }

            for (SubscriberInfo sub : subscribers) {
                if (!groupMemberUserIds.contains(sub.userId)) {
                    continue;
                }
                if (isOwnerOrParticipantOfLine(sub.userId, relatedCase.DMT_Line__c, relatedCase.DMT_Line__r.OwnerId, relatedCase.DMT_Line__r.DMT_Opportunity__c)) {
                    Messaging.SingleEmailMessage mail = buildEmail(template, sub.userId, sub.email, relatedCase.DMT_Line__c, orgWideEmailId);
                    if (mail != null) {
                        emails.add(mail);
                    }
                }
            }
        }
        dispatchEmails(emails);
    }

    /**
     * @description Sends Task Assigned notifications for Opportunity related Tasks.
     *              Sends to users who:
     *              1. Are members of the Group (queue) that owns the Task
     *              2. Have the Task_Assigned subscription enabled for the client
     *              3. Are owner or participant of the opportunity
     * @param newTasks  List of newly created Tasks with RecordType DMT_Step_Approval.
     */
    public static void sendTaskAssignedOppNotifications(List<Task> newTasks) {
        if (newTasks == null || newTasks.isEmpty()) {
            return;
        }

        Set<Id> caseIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        for (Task t : newTasks) {
            if (t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')) {
                caseIds.add(t.WhatId);
            }
            if (t.OwnerId != null && String.valueOf(t.OwnerId).startsWith('00G')) {
                groupIds.add(t.OwnerId);
            }
        }
        if (caseIds.isEmpty() || groupIds.isEmpty()) {
            return;
        }

        // Get Cases with Opportunities (no Line)
        Map<Id, Case> casesWithOpps = new Map<Id, Case>([
            SELECT Id, opportunity_id__c, opportunity_id__r.AccountId, opportunity_id__r.OwnerId
            FROM Case
            WHERE Id IN :caseIds
              AND opportunity_id__c != null
              AND DMT_Line__c = null
        ]);
        if (casesWithOpps.isEmpty()) {
            return;
        }

        Map<Id, Set<Id>> userIdsByGroupId = getGroupMembers(groupIds);

        Set<Id> accountIds = new Set<Id>();
        for (Case c : casesWithOpps.values()) {
            if (c.opportunity_id__r.AccountId != null) {
                accountIds.add(c.opportunity_id__r.AccountId);
            }
        }

        Map<Id, List<SubscriberInfo>> subsByAccount = getSubscribersByAccount(accountIds, TASK_ASSIGNED_TYPE);
        if (subsByAccount.isEmpty()) {
            return;
        }

        EmailTemplate template = getTemplate(TEMPLATE_TASK_OPP);
        if (template == null) {
            return;
        }
        Id orgWideEmailId = getOrgWideEmailId();

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Task t : newTasks) {
            Case relatedCase = casesWithOpps.get(t.WhatId);
            if (relatedCase == null || relatedCase.opportunity_id__c == null) {
                continue;
            }

            Set<Id> groupMemberUserIds = userIdsByGroupId.get(t.OwnerId);
            if (groupMemberUserIds == null || groupMemberUserIds.isEmpty()) {
                continue;
            }

            Id accountId = relatedCase.opportunity_id__r.AccountId;
            List<SubscriberInfo> subscribers = subsByAccount.get(accountId);
            if (subscribers == null) {
                continue;
            }

            for (SubscriberInfo sub : subscribers) {
                if (!groupMemberUserIds.contains(sub.userId)) {
                    continue;
                }
                if (isOwnerOrParticipantOfOpp(sub.userId, relatedCase.opportunity_id__c, relatedCase.opportunity_id__r.OwnerId)) {
                    Messaging.SingleEmailMessage mail = buildEmail(template, sub.userId, sub.email, relatedCase.opportunity_id__c, orgWideEmailId);
                    if (mail != null) {
                        emails.add(mail);
                    }
                }
            }
        }
        dispatchEmails(emails);
    }

    /**
     * @description Gets user members of the specified groups.
     */
    private static Map<Id, Set<Id>> getGroupMembers(Set<Id> groupIds) {
        Map<Id, Set<Id>> userIdsByGroupId = new Map<Id, Set<Id>>();
        for (GroupMember gm : [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :groupIds]) {
            if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                if (!userIdsByGroupId.containsKey(gm.GroupId)) {
                    userIdsByGroupId.put(gm.GroupId, new Set<Id>());
                }
                userIdsByGroupId.get(gm.GroupId).add(gm.UserOrGroupId);
            }
        }
        return userIdsByGroupId;
    }

    /**
     * @description Checks if a user is owner or participant of a DMT_Line__c.
     */
    private static Boolean isOwnerOrParticipantOfLine(Id userId, Id lineId, Id lineOwnerId, Id opportunityId) {
        if (userId == lineOwnerId) {
            return true;
        }
        List<DMT_TeamMember__c> teamMembers = [
            SELECT Id
            FROM DMT_TeamMember__c
            WHERE User__c = :userId
              AND (Line__c = :lineId OR Opportunity__c = :opportunityId)
            LIMIT 1
        ];
        return !teamMembers.isEmpty();
    }

    /**
     * @description Checks if a user is owner or participant of an Opportunity.
     */
    private static Boolean isOwnerOrParticipantOfOpp(Id userId, Id opportunityId, Id oppOwnerId) {
        if (userId == oppOwnerId) {
            return true;
        }
        List<DMT_TeamMember__c> teamMembers = [
            SELECT Id
            FROM DMT_TeamMember__c
            WHERE User__c = :userId
              AND Opportunity__c = :opportunityId
            LIMIT 1
        ];
        return !teamMembers.isEmpty();
    }
}