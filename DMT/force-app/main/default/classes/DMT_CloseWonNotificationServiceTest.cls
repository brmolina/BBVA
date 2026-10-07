/**
 * @description Test class for DMT_CloseWonNotificationService.
 *              Validates that emails are dispatched (Limits.getEmailInvocations) and
 *              inspects their content via the @TestVisible sentEmailsCapture trap.
 *
 *              EmailTemplate is injected via @TestVisible testTemplateOverride, bypassing
 *              the SOQL lookup entirely to avoid failures when the template doesn't exist
 *              in the test org or the DeveloperName collides.
 *
 *              Also validates the WUT survey Platform Event published on Closed Won transitions. The
 *              event is enqueued via DMT_AsyncOrchestrator/DMT_AsyncDispatcher (not published inline -
 *              see DMT_CloseWonNotificationService.publishWutClosedWonSurvey) because the event's
 *              PublishImmediate behavior can't run while this trigger's own record save is still
 *              uncommitted. CIBGLOBALD-4295 - the underlying Queueable executes at Test.stopTest(), and
 *              static state set INSIDE it (e.g. DMT_AsyncDispatcher.publishedWutSurveyEvents) does not
 *              reliably survive to be read by the test method after stopTest() returns - a class's
 *              statics get reinitialized the first time the resuming synchronous code touches it again,
 *              wiping out whatever was set during the async execution. So instead of reading that trap
 *              after stopTest(), these tests verify Limits.getQueueableJobs() (a governor-limit counter,
 *              not a class static, so it isn't subject to the same reset) captured before stopTest() -
 *              proving exactly one async job gets scheduled per transaction, not one per record. The
 *              published event's actual field content (Survey/Modulo/UserIds) is verified separately in
 *              buildSurveyEvent_dmtClosedWon_hasCorrectFields, a direct synchronous call with no async
 *              boundary involved.
 */
@IsTest
private class DMT_CloseWonNotificationServiceTest {

    private static final String TEST_SUBSCRIBER_EMAIL = 'dmt.subscriber.test@example.com';

    // ─── Test Data Setup ──────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        // Non-setup objects
        Account client = new Account(
            Name                      = 'DMT Test Client Notification',
            account_client__c         = 'N',
            Advising__c               = false,
            BBVA_Entity__c            = 'BBVA SA',
            BillingCity               = 'MADRID',
            BillingCountry            = 'ES',
            BillingPostalCode         = '28033',
            BillingState              = 'MADRID',
            BillingStreet             = 'AV GRAN VIA 1',
            CurrencyIsoCode           = 'EUR',
            CIB_Commercial_Prospect__c = 'Commercial'
        );
        insert client;

        // Test user subscriptions for all notification types
        insert new List<DMT_NotificationSubscription__c>{
            new DMT_NotificationSubscription__c(
                User__c   = UserInfo.getUserId(),
                Client__c = client.Id,
                Type__c   = 'Closed_Won'
            ),
            new DMT_NotificationSubscription__c(
                User__c   = UserInfo.getUserId(),
                Client__c = client.Id,
                Type__c   = 'Lines_Opportunities_review'
            ),
            new DMT_NotificationSubscription__c(
                User__c   = UserInfo.getUserId(),
                Client__c = client.Id,
                Type__c   = 'Task_Assigned'
            )
        };

        // Dummy records just to obtain valid Ids for the Draft/Opp tests
        insert new DMT_Line__c(Client__c = client.Id);

        insert new Opportunity(
            Name      = 'DMT Test Opp Dummy',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = client.Id
        );
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static Account getClient() {
        return [SELECT Id FROM Account WHERE Name = 'DMT Test Client Notification' LIMIT 1];
    }

    private static Id getLineId() {
        return [SELECT Id FROM DMT_Line__c LIMIT 1].Id;
    }

    private static Id getOppId() {
        return [SELECT Id FROM Opportunity WHERE Name = 'DMT Test Opp Dummy' LIMIT 1].Id;
    }

    private static Id getOtherUserId() {
        return [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true LIMIT 1].Id;
    }


    /** Injects a dummy EmailTemplate into the service, removing the dependency on SOQL. */
    private static void injectTemplate() {
        DMT_CloseWonNotificationService.testTemplateOverride = new EmailTemplate();
    }

    /** Injects a known subscriber email, removing the dependency on the subscriptions SOQL. */
    private static void injectSubscribers() {
        DMT_CloseWonNotificationService.testSubscriberEmails = new List<String>{ TEST_SUBSCRIBER_EMAIL };
    }

    private static Group createTaskQueue(String developerName) {
        Group queue = new Group(
            Name = developerName,
            Type = 'Queue',
            DeveloperName = developerName
        );
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            insert queue;
            insert new QueueSobject(QueueId = queue.Id, SObjectType = 'Task');
            insert new GroupMember(GroupId = queue.Id, UserOrGroupId = UserInfo.getUserId());
        }
        return queue;
    }

    // ─── sendCloseWonLineNotifications ───────────────────────────────────────

    @IsTest
    static void sendCloseWonLineNotifications_transitionTriggersEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Insert with Status__c='Closed' + Closed__c='Won' so the DMT_Status_Completed__c
        // formula field is calculated by the platform (it can't be assigned directly)
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = client.Id
        );
        insert line;
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        // oldLine in memory: previous state without the formula → DMT_Status_Completed__c=null → wasNotClosed=true
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): triggering our async WUT survey job during
        // stopTest() resets DMT_CloseWonNotificationService's static state once execution resumes, so
        // sentEmailsCapture must be read now, not after stopTest().
        List<Messaging.SingleEmailMessage> capturedEmails = DMT_CloseWonNotificationService.sentEmailsCapture;
        // CIBGLOBALD-4295 - also captured before Test.stopTest(): a governor-limit counter, not a class
        // static, so it isn't subject to the same reset - proves exactly one async job was scheduled for
        // the WUT survey publish (see buildSurveyEvent_dmtClosedWon_hasCorrectFields for content
        // verification, which can't reliably be read back after the async boundary - see that test's
        // comment for why).
        Integer queueableJobsScheduled = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(1, capturedEmails.size(),
            'Debe capturarse 1 email para la transición a Closed Won (línea)');
        Assert.areEqual(
            TEST_SUBSCRIBER_EMAIL,
            capturedEmails[0].getToAddresses()[0],
            'El destinatario debe ser el usuario suscrito'
        );

        Assert.areEqual(1, queueableJobsScheduled,
            'A Closed Won line transition must schedule exactly one WUT survey publish job');
    }

    @IsTest
    static void sendCloseWonLineNotifications_noTransition_noEmail() {
        // Template not injected: the service returns early at triggered.isEmpty() before reaching it
        Account client = getClient();

        // Same record passed as both new and old: it was already Closed Won → no transition
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = client.Id
        );
        insert line;
        DMT_Line__c lineRecord = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                                  FROM DMT_Line__c WHERE Id = :line.Id];

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ lineRecord },
            new Map<Id, DMT_Line__c>{ lineRecord.Id => lineRecord }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(), same reasoning as the transition tests, even
        // though no reset actually occurs here (no async job runs since no transition happened) - kept
        // consistent so this doesn't rely on that coincidence.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Integer queueableJobsScheduled = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(0, capturedEmailCount,
            'Sin transición no debe capturarse ningún email');
        Assert.areEqual(0, queueableJobsScheduled,
            'No transition must not schedule any WUT survey publish job');
    }

    @IsTest
    static void sendCloseWonLineNotifications_noSubscription_noEmail() {
        injectTemplate();

        // Client with no subscriptions
        Account otherClient = new Account(Name = 'DMT No Sub Client');
        insert otherClient;

        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = otherClient.Id
        );
        insert line;
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Sin suscripción no debe capturarse ningún email');
    }

    @IsTest
    static void sendCloseWonLineNotifications_emptyList_noEmail() {
        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>(),
            new Map<Id, DMT_Line__c>()
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Lista vacía no debe generar emails');
    }

    @IsTest
    static void sendCloseLostLineNotifications_transitionTriggersEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Insert with Status__c='Closed' + Closed__c='Lost' so the DMT_Status_Completed__c
        // formula field is calculated by the platform (it can't be assigned directly)
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Lost',
            Client__c = client.Id
        );
        insert line;
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseLostLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        // Captured before Test.stopTest() to stay consistent with the Closed Won tests,
        // even though Closed Lost schedules no async job
        List<Messaging.SingleEmailMessage> capturedEmails = DMT_CloseWonNotificationService.sentEmailsCapture;
        Integer queueableJobsScheduled = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(1, capturedEmails.size(),
            'Debe capturarse 1 email para la transición a Closed Lost (línea)');
        Assert.areEqual(
            TEST_SUBSCRIBER_EMAIL,
            capturedEmails[0].getToAddresses()[0],
            'El destinatario debe ser el usuario suscrito'
        );

        Assert.areEqual(0, queueableJobsScheduled,
            'Closed Lost no debe programar la encuesta WUT (solo aplica a Closed Won)');
    }

    // ─── sendCloseWonOppNotifications ─────────────────────────────────────────

    @IsTest
    static void sendCloseWonOppNotifications_transitionTriggersEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();
        Id oppId       = getOppId();

        // Query full record to include OwnerId for owner/participant filter
        Opportunity dbOpp = [SELECT Id, StageName, AccountId, OwnerId FROM Opportunity WHERE Id = :oppId];
        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Closed Won', AccountId = client.Id, OwnerId = dbOpp.OwnerId);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Prospecting', AccountId = client.Id, OwnerId = dbOpp.OwnerId);

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        List<Messaging.SingleEmailMessage> capturedEmails = DMT_CloseWonNotificationService.sentEmailsCapture;
        Integer queueableJobsScheduled = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(1, capturedEmails.size(),
            'Debe capturarse 1 email para la transición a Closed Won (opp)');
        Assert.areEqual(TEST_SUBSCRIBER_EMAIL,
            capturedEmails[0].getToAddresses()[0]);

        Assert.areEqual(1, queueableJobsScheduled,
            'A Closed Won opportunity transition must schedule exactly one WUT survey publish job');
    }

    // ─── WUT survey event content (direct, synchronous - no async boundary) ──

    /**
     * CIBGLOBALD-4295 - Verifies the actual field content of the WUT survey Platform Event built for
     * the DMT Closed Won trigger. Calls DES_cls_BotonNoteBookLm.buildSurveyEvent directly rather than
     * going through the async publish path: that path's result can't be reliably read back after
     * Test.stopTest() (see the class-level comment), so content verification is split out here as a
     * plain synchronous call with no async boundary involved.
     */
    @IsTest
    static void buildSurveyEvent_dmtClosedWon_hasCorrectFields() {
        Id closingUserId = UserInfo.getUserId();

        Test.startTest();
        DES_pe_SurveyNotification__e evt = DES_cls_BotonNoteBookLm.buildSurveyEvent(
            'DMTWUT', 'Deal Management', String.valueOf(closingUserId)
        );
        Test.stopTest();

        Assert.areEqual('DMTWUT', evt.DES_fld_Survey__c, 'Survey must be DMTWUT for the DMT Closed Won trigger');
        Assert.areEqual('Deal Management', evt.DES_fld_Modulo__c, 'Modulo must be the fixed Deal Management value');
        Assert.areEqual(String.valueOf(closingUserId), evt.DES_fld_UserIds__c, 'UserIds must be the closing user');
    }

    @IsTest
    static void sendCloseWonOppNotifications_alreadyClosedWon_noEmail() {
        // Template not injected: the service returns early at triggered.isEmpty() before reaching it
        Account client = getClient();
        Id oppId       = getOppId();

        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Closed Won', AccountId = client.Id);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Closed Won', AccountId = client.Id);

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Sin transición Opp no debe capturarse ningún email');
    }

    @IsTest
    static void sendCloseLostOppNotifications_transitionTriggersEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();
        Id oppId       = getOppId();

        // Query full record to include OwnerId for owner/participant filter
        Opportunity dbOpp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :oppId];
        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Closed Lost', AccountId = client.Id, OwnerId = dbOpp.OwnerId);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Prospecting', AccountId = client.Id, OwnerId = dbOpp.OwnerId);

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseLostOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        // Captured before Test.stopTest(): see sendCloseLostLineNotifications_transitionTriggersEmail.
        List<Messaging.SingleEmailMessage> capturedEmails = DMT_CloseWonNotificationService.sentEmailsCapture;
        Integer queueableJobsScheduled = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(1, capturedEmails.size(),
            'Debe capturarse 1 email para la transición a Closed Lost (opp)');
        Assert.areEqual(TEST_SUBSCRIBER_EMAIL,
            capturedEmails[0].getToAddresses()[0]);

        Assert.areEqual(0, queueableJobsScheduled,
            'Closed Lost no debe programar la encuesta WUT (solo aplica a Closed Won)');
    }

    // ─── sendDraftLineNotifications ───────────────────────────────────────────

    @IsTest
    static void sendDraftLineNotifications_transitionTriggersEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();
        Id lineId      = getLineId();

        // Query full record to include OwnerId and Opportunity__c for owner/participant filter
        DMT_Line__c dbLine = [SELECT Id, OwnerId, DMT_Opportunity__c FROM DMT_Line__c WHERE Id = :lineId];
        DMT_Line__c newLine = new DMT_Line__c(Id = lineId, Status__c = 'Draft', Client__c = client.Id, OwnerId = dbLine.OwnerId, DMT_Opportunity__c = dbLine.DMT_Opportunity__c);
        DMT_Line__c oldLine = new DMT_Line__c(Id = lineId, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ lineId => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(1, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Debe capturarse 1 email para la transición a Draft (línea)');
        Assert.areEqual(TEST_SUBSCRIBER_EMAIL,
            DMT_CloseWonNotificationService.sentEmailsCapture[0].getToAddresses()[0]);
    }

    @IsTest
    static void sendDraftLineNotifications_alreadyDraft_noEmail() {
        // Template not injected: the service returns early at triggered.isEmpty() before reaching it
        Account client = getClient();
        Id lineId      = getLineId();

        DMT_Line__c newLine = new DMT_Line__c(Id = lineId, Status__c = 'Draft', Client__c = client.Id);
        DMT_Line__c oldLine = new DMT_Line__c(Id = lineId, Status__c = 'Draft');

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ lineId => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Sin transición a Draft no debe capturarse ningún email');
    }

    // ─── sendDraftOppNotifications ────────────────────────────────────────────

    @IsTest
    static void sendDraftOppNotifications_transitionTriggersEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();
        Id oppId       = getOppId();

        // Query full record to include OwnerId for owner/participant filter
        Opportunity dbOpp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :oppId];
        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Draft', AccountId = client.Id, OwnerId = dbOpp.OwnerId);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Prospecting', AccountId = client.Id, OwnerId = dbOpp.OwnerId);

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(1, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Debe capturarse 1 email para la transición a Draft (opp)');
        Assert.areEqual(TEST_SUBSCRIBER_EMAIL,
            DMT_CloseWonNotificationService.sentEmailsCapture[0].getToAddresses()[0]);
    }

    @IsTest
    static void sendDraftOppNotifications_approvalToProposal_triggersEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();
        Id oppId       = getOppId();

        // Query full record to include OwnerId for owner/participant filter
        Opportunity dbOpp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :oppId];
        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Proposal', AccountId = client.Id, OwnerId = dbOpp.OwnerId);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Approval', AccountId = client.Id, OwnerId = dbOpp.OwnerId);

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(1, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Debe capturarse 1 email para el retorno Approval → Proposal (opp)');
        Assert.areEqual(TEST_SUBSCRIBER_EMAIL,
            DMT_CloseWonNotificationService.sentEmailsCapture[0].getToAddresses()[0]);
    }

    // ─── Owner/Participant Filter Tests ───────────────────────────────────────

    @IsTest
    static void filterSubscribersForLine_ownerReceivesEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Create line owned by the current test user
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = client.Id
        );
        insert line;
        
        // Query full record to ensure OwnerId is included
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Test.stopTest();

        // Test user is owner → should receive email
        Assert.areEqual(1, capturedEmailCount,
            'Owner debe recibir email');
    }

    @IsTest
    static void filterSubscribersForLine_participantReceivesEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Create opportunity first
        Opportunity opp = new Opportunity(
            Name      = 'DMT Test Opp Participant',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = client.Id
        );
        insert opp;

        // Create line with different owner (system assigns current user anyway, so we'll test participant)
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = client.Id,
            DMT_Opportunity__c = opp.Id
        );
        insert line;

        // Create DMT_TeamMember for current user on the line
        insert new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = UserInfo.getUserId(),
            AccessLevel__c = 'Read'
        );
        
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Test.stopTest();

        // Test user is participant via DMT_TeamMember → should receive email
        Assert.areEqual(1, capturedEmailCount,
            'Participant de línea debe recibir email');
    }

    @IsTest
    static void filterSubscribersForLine_oppParticipantReceivesLineEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Create opportunity
        Opportunity opp = new Opportunity(
            Name      = 'DMT Test Opp Parent Participant',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = client.Id
        );
        insert opp;
        insert new DMT_TeamMember__c(
            Opportunity__c = opp.Id,
            User__c = UserInfo.getUserId(),
            AccessLevel__c = 'Read'
        );
        // Create the line linked to the opportunity
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = client.Id,
            DMT_Opportunity__c = opp.Id
        );
        insert line;
        
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Test.stopTest();

        Assert.areEqual(1, capturedEmailCount,
            'Participant de oportunidad padre debe recibir email de línea hija');
    }

    @IsTest
    static void filterSubscribersForOpportunity_participantReceivesEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Create opportunity
        Opportunity opp = new Opportunity(
            Name      = 'DMT Test Opp Participant Direct',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = client.Id
        );
        insert opp;

        // Create DMT_TeamMember for current user on the opportunity
        insert new DMT_TeamMember__c(
            Opportunity__c = opp.Id,
            User__c = UserInfo.getUserId(),
            AccessLevel__c = 'Read'
        );

        Opportunity newOpp = [SELECT Id, StageName, AccountId, OwnerId FROM Opportunity WHERE Id = :opp.Id];
        newOpp.StageName = 'Closed Won';
        Opportunity oldOpp = new Opportunity(
            Id = opp.Id,
            StageName = 'Prospecting',
            AccountId = client.Id,
            OwnerId = newOpp.OwnerId
        );

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Test.stopTest();

        // Test user is participant via DMT_TeamMember → should receive email
        Assert.areEqual(1, capturedEmailCount,
            'Participant de oportunidad debe recibir email');
    }

    @IsTest
    static void filterSubscribersForLine_readOnlyParticipant_noDraftEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Draft',
            Client__c = client.Id
        );
        insert line;

        // Current user is a Read-only participant of the line
        insert new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = UserInfo.getUserId(),
            AccessLevel__c = 'Read'
        );

        DMT_Line__c newLine = [SELECT Id, Status__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        // Owned by another user so the current user is authorized only as participant
        newLine.OwnerId = getOtherUserId();
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Participant con acceso Read no debe recibir el aviso de back to draft');
    }

    // ─── Additional Edge Case Tests for sendCloseWonOppNotifications ──────────

    @IsTest
    static void sendCloseWonOppNotifications_emptyList_noEmail() {
        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonOppNotifications(
            new List<Opportunity>(),
            new Map<Id, Opportunity>()
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Lista vacía no debe generar emails');
    }

    @IsTest
    static void sendCloseWonOppNotifications_noSubscription_noEmail() {
        injectTemplate();

        // Account with no subscriptions
        Account otherClient = new Account(Name = 'DMT No Sub Client Opp');
        insert otherClient;

        Opportunity opp = new Opportunity(
            Name      = 'DMT Test No Sub Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = otherClient.Id
        );
        insert opp;

        Opportunity newOpp = [SELECT Id, StageName, AccountId, OwnerId FROM Opportunity WHERE Id = :opp.Id];
        newOpp.StageName = 'Closed Won';
        Opportunity oldOpp = new Opportunity(Id = opp.Id, StageName = 'Prospecting', AccountId = otherClient.Id, OwnerId = newOpp.OwnerId);

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Sin suscripción Opp no debe capturarse ningún email');
    }

    // ─── Additional Edge Case Tests for sendDraftLineNotifications ────────────

    @IsTest
    static void sendDraftLineNotifications_emptyList_noEmail() {
        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftLineNotifications(
            new List<DMT_Line__c>(),
            new Map<Id, DMT_Line__c>()
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Lista vacía de líneas Draft no debe generar emails');
    }

    @IsTest
    static void sendDraftLineNotifications_noSubscription_noEmail() {
        injectTemplate();

        // Account with no subscriptions of type 'Lines_Opportunities_review'
        Account otherClient = new Account(Name = 'DMT No Review Sub Client');
        insert otherClient;

        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Draft',
            Client__c = otherClient.Id
        );
        insert line;

        DMT_Line__c newLine = [SELECT Id, Status__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Sin suscripción Review no debe capturarse email');
    }

    // ─── Additional Edge Case Tests for sendDraftOppNotifications ─────────────

    @IsTest
    static void sendDraftOppNotifications_emptyList_noEmail() {
        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftOppNotifications(
            new List<Opportunity>(),
            new Map<Id, Opportunity>()
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Lista vacía de Opp Draft no debe generar emails');
    }

    @IsTest
    static void sendDraftOppNotifications_alreadyDraft_noEmail() {
        Account client = getClient();
        Id oppId       = getOppId();

        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Draft', AccountId = client.Id);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Draft', AccountId = client.Id);

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Sin transición a Draft Opp no debe capturarse ningún email');
    }

    @IsTest
    static void sendDraftOppNotifications_noSubscription_noEmail() {
        injectTemplate();

        // Account with no subscriptions of type 'Lines_Opportunities_review'
        Account otherClient = new Account(Name = 'DMT No Review Sub Client Opp');
        insert otherClient;

        Opportunity opp = new Opportunity(
            Name      = 'DMT Test No Review Sub Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = otherClient.Id
        );
        insert opp;

        Opportunity newOpp = [SELECT Id, StageName, AccountId, OwnerId FROM Opportunity WHERE Id = :opp.Id];
        newOpp.StageName = 'Draft';
        Opportunity oldOpp = new Opportunity(Id = opp.Id, StageName = 'Prospecting', AccountId = otherClient.Id, OwnerId = newOpp.OwnerId);

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ opp.Id => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Sin suscripción Review no debe capturarse email Opp');
    }

    // ─── sendTaskAssignedLineNotifications Tests ──────────────────────────────

    @IsTest
    static void sendTaskAssignedLineNotifications_emptyList_noEmail() {
        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedLineNotifications(new List<Task>());
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Lista vacía de Tasks no debe generar emails');
    }

    @IsTest
    static void sendTaskAssignedLineNotifications_queueOwner_authorizedSubscriberReceivesEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();
        Group queue = createTaskQueue('DMT_LINE_TASK_QUEUE_TEST');

        DMT_Line__c line = new DMT_Line__c(Status__c = 'Draft', Client__c = client.Id);
        insert line;
        Case relatedCase = new Case(Subject = 'DMT Queue Line Case', DMT_Line__c = line.Id);
        insert relatedCase;
        Task task = new Task(Subject = 'DMT Queue Line Task', WhatId = relatedCase.Id, OwnerId = queue.Id);
        insert task;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedLineNotifications(new List<Task>{ task });
        Test.stopTest();

        Assert.areEqual(1, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'El miembro autorizado de la Queue debe recibir el email de línea');
    }

    @IsTest
    static void sendTaskAssignedLineNotifications_withCaseAndLine_coversPath() {
        // This test covers the path with a Case that has a Line, but the Task has a User owner (not a Queue)
        // Therefore it returns early at groupIds.isEmpty() → covers that return statement
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Draft',
            Client__c = client.Id
        );
        insert line;

        Case c = new Case(
            Subject = 'DMT Test Case Task Line',
            DMT_Line__c = line.Id
        );
        insert c;

        // Task with User owner (not a Queue) → groupIds will be empty → early return
        Task t = new Task(
            Subject = 'Test Task Line User Owner',
            WhatId = c.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert t;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedLineNotifications(new List<Task>{ t });
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Task con User owner (no Queue) no debe generar email');
    }

    @IsTest
    static void sendTaskAssignedLineNotifications_caseWithoutLine_noEmail() {
        // Case without DMT_Line__c → casesWithLines is empty
        Case c = new Case(
            Subject = 'DMT Test Case No Line'
        );
        insert c;

        Task t = new Task(
            Subject = 'Test Task No Line',
            WhatId = c.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert t;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedLineNotifications(new List<Task>{ t });
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Task de Case sin Line no debe generar email');
    }

    @IsTest
    static void sendTaskAssignedLineNotifications_noCaseWhatId_noEmail() {
        // Task with WhatId that isn't a Case → not processed
        Account client = getClient();

        Task t = new Task(
            Subject = 'Test Task No Case',
            WhatId = client.Id,  // Account, not Case
            OwnerId = UserInfo.getUserId()
        );
        insert t;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedLineNotifications(new List<Task>{ t });
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Task sin Case WhatId no debe generar email');
    }

    // ─── sendTaskAssignedOppNotifications Tests ───────────────────────────────

    @IsTest
    static void sendTaskAssignedOppNotifications_emptyList_noEmail() {
        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedOppNotifications(new List<Task>());
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Lista vacía de Tasks Opp no debe generar emails');
    }

    @IsTest
    static void sendTaskAssignedOppNotifications_queueOwner_authorizedSubscriberReceivesEmail() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();
        Group queue = createTaskQueue('DMT_OPP_TASK_QUEUE_TEST');

        Opportunity opp = new Opportunity(
            Name = 'DMT Queue Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = client.Id
        );
        insert opp;
        Case relatedCase = new Case(Subject = 'DMT Queue Opp Case', opportunity_id__c = opp.Id);
        insert relatedCase;
        Task task = new Task(Subject = 'DMT Queue Opp Task', WhatId = relatedCase.Id, OwnerId = queue.Id);
        insert task;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedOppNotifications(new List<Task>{ task });
        Test.stopTest();

        Assert.areEqual(1, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'El miembro autorizado de la Queue debe recibir el email de oportunidad');
    }

    @IsTest
    static void sendTaskAssignedOppNotifications_withCaseAndOpp_coversPath() {
        // This test covers the path with a Case that has an Opp, but the Task has a User owner (not a Queue)
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        Opportunity opp = new Opportunity(
            Name      = 'DMT Test Opp Task User',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = client.Id
        );
        insert opp;

        Case c = new Case(
            Subject = 'DMT Test Case Opp Task User',
            opportunity_id__c = opp.Id
        );
        insert c;

        Task t = new Task(
            Subject = 'Test Task Opp User Owner',
            WhatId = c.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert t;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedOppNotifications(new List<Task>{ t });
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Task con User owner (no Queue) no debe generar email');
    }

    @IsTest
    static void sendTaskAssignedOppNotifications_caseWithoutOpp_noEmail() {
        // Case without opportunity_id__c → casesWithOpps is empty
        Case c = new Case(
            Subject = 'DMT Test Case No Opp'
        );
        insert c;

        Task t = new Task(
            Subject = 'Test Task No Opp',
            WhatId = c.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert t;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedOppNotifications(new List<Task>{ t });
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Task de Case sin Opp no debe generar email');
    }

    @IsTest
    static void sendTaskAssignedOppNotifications_caseWithLineAndOpp_noEmail() {
        // Case with DMT_Line__c → does NOT enter sendTaskAssignedOppNotifications (filtered by DMT_Line__c = null)
        Account client = getClient();
        
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Draft',
            Client__c = client.Id
        );
        insert line;

        Opportunity opp = new Opportunity(
            Name      = 'DMT Test Opp With Line',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = client.Id
        );
        insert opp;

        // Case with BOTH: Line and Opp → must be excluded from sendTaskAssignedOppNotifications
        Case c = new Case(
            Subject = 'DMT Test Case With Line And Opp',
            DMT_Line__c = line.Id,
            opportunity_id__c = opp.Id
        );
        insert c;

        Task t = new Task(
            Subject = 'Test Task With Line And Opp',
            WhatId = c.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert t;

        Test.startTest();
        DMT_CloseWonNotificationService.sendTaskAssignedOppNotifications(new List<Task>{ t });
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Case con Line no debe procesarse en sendTaskAssignedOppNotifications');
    }

    // ─── Filter Methods Edge Cases (tested via public methods) ──────────────

    // ─── Global Subscription Tests (Client__c = NULL) ─────────────────────────

    @IsTest
    static void sendCloseWonLineNotifications_globalSubscription_triggersEmail() {
        injectTemplate();
        
        // Create a global subscription (Client__c = null)
        DMT_CloseWonNotificationService.testSubscriberEmails = new List<String>{ TEST_SUBSCRIBER_EMAIL };
        
        Account client = getClient();

        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = client.Id
        );
        insert line;
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Test.stopTest();

        Assert.areEqual(1, capturedEmailCount,
            'Suscripción global debe recibir email');
    }

    @IsTest
    static void sendCloseWonLineNotifications_globalAndClientSubscription_singleEmail() {
        injectTemplate();
        // Subscribers NOT injected: this test exercises the real subscription query, where the
        // running user has a client-specific subscription (from makeData) and also a global one
        insert new DMT_NotificationSubscription__c(
            User__c   = UserInfo.getUserId(),
            Client__c = null,
            Type__c   = 'Closed_Won'
        );
        Account client = getClient();

        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = client.Id
        );
        insert line;
        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Test.stopTest();

        Assert.areEqual(1, capturedEmailCount,
            'Un usuario con suscripción global y por cliente debe recibir un solo email');
    }

    // ─── Multiple Records Tests ───────────────────────────────────────────────

    @IsTest
    static void sendCloseWonLineNotifications_multipleLines_multipleEmails() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Create multiple lines
        List<DMT_Line__c> lines = new List<DMT_Line__c>();
        for (Integer i = 0; i < 3; i++) {
            lines.add(new DMT_Line__c(
                Status__c = 'Closed',
                Closed__c = 'Won',
                Client__c = client.Id
            ));
        }
        insert lines;

        List<DMT_Line__c> newLines = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                                      FROM DMT_Line__c WHERE Id IN :lines];
        Map<Id, DMT_Line__c> oldMap = new Map<Id, DMT_Line__c>();
        for (DMT_Line__c line : newLines) {
            oldMap.put(line.Id, new DMT_Line__c(Id = line.Id, Status__c = 'Active'));
        }

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(newLines, oldMap);
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Integer queueableJobsScheduled = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(3, capturedEmailCount,
            'Múltiples líneas deben generar múltiples emails');
        Assert.areEqual(1, queueableJobsScheduled,
            'Multiple lines closed in the same transaction must schedule only one WUT survey publish job, not one per line');
    }

    @IsTest
    static void sendCloseWonOppNotifications_multipleOpps_multipleEmails() {
        injectTemplate();
        injectSubscribers();
        Account client = getClient();

        // Create multiple opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 2; i++) {
            opps.add(new Opportunity(
                Name      = 'DMT Test Multi Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                AccountId = client.Id
            ));
        }
        insert opps;

        List<Opportunity> newOpps = [SELECT Id, StageName, AccountId, OwnerId FROM Opportunity WHERE Id IN :opps];
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        for (Opportunity opp : newOpps) {
            opp.StageName = 'Closed Won';
            oldMap.put(opp.Id, new Opportunity(Id = opp.Id, StageName = 'Prospecting', AccountId = client.Id, OwnerId = opp.OwnerId));
        }

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonOppNotifications(newOpps, oldMap);
        // CIBGLOBALD-4295 - captured before Test.stopTest(): see sendCloseWonLineNotifications_transitionTriggersEmail.
        Integer capturedEmailCount = DMT_CloseWonNotificationService.sentEmailsCapture.size();
        Integer queueableJobsScheduled = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(2, capturedEmailCount,
            'Múltiples opps deben generar múltiples emails');
        Assert.areEqual(1, queueableJobsScheduled,
            'Multiple opportunities closed in the same transaction must schedule only one WUT survey publish job, not one per opportunity');
    }

    // ─── Null AccountId/ClientId Tests ────────────────────────────────────────

    @IsTest
    static void sendCloseWonLineNotifications_nullClientId_noEmail() {
        injectTemplate();
        injectSubscribers();

        // Line with no Client__c
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Closed',
            Closed__c = 'Won',
            Client__c = null
        );
        insert line;

        DMT_Line__c newLine = [SELECT Id, Status__c, DMT_Status_Completed__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Línea sin Client__c no debe generar email');
    }

    @IsTest
    static void sendCloseWonOppNotifications_nullAccountId_noEmail() {
        injectTemplate();
        injectSubscribers();
        Id oppId = getOppId();

        // Opp with no AccountId
        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Closed Won', AccountId = null);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Prospecting', AccountId = null);

        Test.startTest();
        DMT_CloseWonNotificationService.sendCloseWonOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Opp sin AccountId no debe generar email');
    }

    @IsTest
    static void sendDraftLineNotifications_nullClientId_noEmail() {
        injectTemplate();
        injectSubscribers();

        // Line with no Client__c
        DMT_Line__c line = new DMT_Line__c(
            Status__c = 'Draft',
            Client__c = null
        );
        insert line;

        DMT_Line__c newLine = [SELECT Id, Status__c, Client__c, OwnerId, DMT_Opportunity__c
                               FROM DMT_Line__c WHERE Id = :line.Id];
        DMT_Line__c oldLine = new DMT_Line__c(Id = newLine.Id, Status__c = 'Active');

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftLineNotifications(
            new List<DMT_Line__c>{ newLine },
            new Map<Id, DMT_Line__c>{ newLine.Id => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Línea Draft sin Client__c no debe generar email');
    }

    @IsTest
    static void sendDraftOppNotifications_nullAccountId_noEmail() {
        injectTemplate();
        injectSubscribers();
        Id oppId = getOppId();

        // Opp with no AccountId
        Opportunity newOpp = new Opportunity(Id = oppId, StageName = 'Draft', AccountId = null);
        Opportunity oldOpp = new Opportunity(Id = oppId, StageName = 'Prospecting', AccountId = null);

        Test.startTest();
        DMT_CloseWonNotificationService.sendDraftOppNotifications(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ oppId => oldOpp }
        );
        Test.stopTest();

        Assert.areEqual(0, DMT_CloseWonNotificationService.sentEmailsCapture.size(),
            'Opp Draft sin AccountId no debe generar email');
    }
}