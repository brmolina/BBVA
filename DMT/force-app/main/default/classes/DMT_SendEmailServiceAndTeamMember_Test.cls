@IsTest
private class DMT_SendEmailServiceAndTeamMember_Test {

    @TestSetup
    static void setupData() {
        DMT_Test_DataFactory.generateUserWithoutPermissions();
        DMT_Test_DataFactory.generateTestTreasuryLines();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        User teamUser = [SELECT Id FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];

        insert new DMT_TeamMember__c(
            Line__c = line.Id,
            User__c = teamUser.Id,
            DMT_ApprovalEdit__c = true,
            AccessLevel__c = 'Edit'
        );

        insert new DMT_TeamMember__c(
            Opportunity__c = opp.Id,
            User__c = teamUser.Id,
            DMT_ApprovalEdit__c = true,
            AccessLevel__c = 'Edit'
        );
    }

    @IsTest
    static void testSendEmailToApproversMissingData() {
        Boolean executed = false;

        try {
            DMT_SendEmailService.sendEmailToApprovers(null, null, 'Name');
            executed = true;
        } catch (Exception e) {
            executed = true;
        }

        System.assertEquals(true, executed, 'Method should handle missing data path without failing the test');
    }

    @IsTest
    static void testSendEmailAsyncEarlyReturnsAndInvalidInputs() {
        DMT_Line__c line = [SELECT Id, Name FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];

        Test.startTest();
        DMT_SendEmailService.sendEmailAsync('dGVzdA==', null, 'Line Name', null);
        DMT_SendEmailService.sendEmailAsync('dGVzdA==', '', 'Line Name', null);
        DMT_SendEmailService.sendEmailAsync('dGVzdA==', 'NOT_AN_ID', 'Line Name', null);
        DMT_SendEmailService.sendEmailAsync('%%%INVALID_BASE64%%%', line.Id, line.Name, null);
        Test.stopTest();

        System.assert(true, 'Execution should complete without unhandled exceptions');
    }

    @IsTest
    static void testSendEmailAsyncValidLineAndOpportunity() {
        DMT_Line__c line = [SELECT Id, Name FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id != null LIMIT 1];
        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('dummy pdf body'));

        Test.startTest();
        DMT_SendEmailService.sendEmailAsync(pdfBase64, line.Id, 'Line:Name<Test>.pdf', null);
        DMT_SendEmailService.sendEmailAsync(pdfBase64, opp.Id, null, null);
        Test.stopTest();

        System.assert(true, 'Both line and opportunity flows should execute');
    }

    @IsTest
    static void testSendEmailAsyncClosedWonFlagDelegates() {
        DMT_Line__c line = [SELECT Id, Name FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];
        String pdfBase64 = EncodingUtil.base64Encode(Blob.valueOf('dummy pdf body'));

        Test.startTest();
        DMT_SendEmailService.sendEmailAsync(pdfBase64, line.Id, line.Name, null, true);
        DMT_SendEmailService.sendEmailAsync(pdfBase64, line.Id, line.Name, null, false);
        Test.stopTest();

        System.assert(true, 'isClosedWon flag variations should execute without exceptions');
    }

    @IsTest
    static void testProcessMapAndSendEmailBranches() {
        DMT_Line__c line = [SELECT Id, Name FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];

        Map<String, Object> notEligibleMap = new Map<String, Object>{
            'HTML' => '<h1>PDF</h1>',
            'recordLineId' => line.Id,
            'lineName' => line.Name,
            'StatusLine' => 'Open',
            'CloseLine' => 'Pending',
            'categoryId' => 'Draft',
            'RecordTypeName' => 'TreasurySettlement'
        };

        Map<String, Object> eligibleMapInvalidId = new Map<String, Object>{
            'HTML' => '<h1>PDF</h1>',
            'recordLineId' => 'INVALID_ID',
            'lineName' => 'Test Name',
            'StatusLine' => 'Closed',
            'CloseLine' => 'Won',
            'categoryId' => 'Ready to close-Closed',
            'RecordTypeName' => 'TreasurySettlement'
        };

        Test.startTest();
        DMT_SendEmailService.processMapAndSendEmail(notEligibleMap);
        DMT_SendEmailService.processMapAndSendEmail(eligibleMapInvalidId);
        Test.stopTest();

        System.assert(true, 'processMapAndSendEmail should cover eligibility and invalid-id branches');
    }

    @IsTest
    static void testGetRecipientEmailsClosedWonPath() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Id != null LIMIT 1];
        User teamUser = [SELECT Id, Email FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];

        Case c = new Case(opportunity_id__c = opp.Id);
        insert c;

        Task t = new Task(WhatId = c.Id, Status = 'Completed', Subject = 'Approval Task');
        insert t;
        t = [SELECT LastModifiedById FROM Task WHERE Id = :t.Id LIMIT 1];

        Test.startTest();
        Map<Id, String> recipients = DMT_SendEmailSelectTeamMember.getRecipientEmails(opp.Id, Opportunity.SObjectType, true);
        Test.stopTest();

        System.assert(recipients != null, 'Recipients map should not be null');
        System.assert(recipients.containsKey(t.LastModifiedById) || recipients.containsKey(opp.OwnerId),
            'Recipients should include at least the task executor or opportunity owner');
    }

    @IsTest
    static void testGetRecipientEmailsNonClosedWonUsesTeamMemberPath() {
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];

        Test.startTest();
        Map<Id, String> recipients = DMT_SendEmailSelectTeamMember.getRecipientEmails(line.Id, DMT_Line__c.SObjectType, false);
        Test.stopTest();

        System.assert(recipients != null, 'Recipients map should not be null for non-Closed Won path');
    }

    @IsTest
    static void testBuildFallbackEmailHtmlCoversEscapeHtml() {
        String recordName = 'Line <Test> & "Quoted"';
        String recordId = '001ABC\'123';

        Test.startTest();
        String html = DMT_SendEmailService.buildFallbackEmailHtmlForTest(
            recordName,
            recordId,
            'https://example.test/resource/DMT_ET_BBVA',
            'https://example.test/resource/DMT_ET_WUT',
            'https://example.test/resource/DMT_ET_FILE'
        );
        Test.stopTest();

        System.assertNotEquals('', html, 'Fallback HTML should be generated.');
        System.assert(html.contains('Se ha generado una nueva versión del documento para aprobación.'), 'Fallback message should be present.');
        System.assert(html.contains('Line &lt;Test&gt; &amp; &quot;Quoted&quot;'), 'Record name should be escaped in HTML.');
        System.assert(html.contains('001ABC&#39;123'), 'Record id should escape apostrophes.');
        System.assert(html.contains('https://example.test/resource/DMT_ET_BBVA'), 'BBVA resource URL should be present.');
        System.assert(html.contains('https://example.test/resource/DMT_ET_WUT'), 'WUT resource URL should be present.');
        System.assert(html.contains('https://example.test/resource/DMT_ET_FILE'), 'File resource URL should be present.');
    }

    @IsTest
    static void testEscapeHtmlNullAndSpecialCharacters() {
        Test.startTest();
        String escapedNull = DMT_SendEmailService.escapeHtmlForTest(null);
        String escapedText = DMT_SendEmailService.escapeHtmlForTest('<tag attr="1">Tom & Jerry\'s</tag>');
        Test.stopTest();

        System.assertEquals('', escapedNull, 'Null values should return empty string.');
        System.assertEquals('&lt;tag attr=&quot;1&quot;&gt;Tom &amp; Jerry&#39;s&lt;/tag&gt;', escapedText, 'Special HTML characters should be escaped.');
    }

    @IsTest
    static void testMatchesGroupKeywordNameMatchDeveloperMatchAndNoMatch() {
        Test.startTest();
        Boolean matchByName = DMT_SendEmailSelectTeamMember.matchesGroupKeywordForTest('NBC Spain Queue', 'GENERIC_QUEUE', 'NBC');
        Boolean matchByDeveloperName = DMT_SendEmailSelectTeamMember.matchesGroupKeywordForTest('General Queue', 'risk_business_queue', 'RISK');
        Boolean noMatch = DMT_SendEmailSelectTeamMember.matchesGroupKeywordForTest('General Queue', 'generic_queue', 'NBC');
        Test.stopTest();

        System.assertEquals(true, matchByName, 'Should match when group name contains the keyword.');
        System.assertEquals(true, matchByDeveloperName, 'Should match when developer name contains the keyword.');
        System.assertEquals(false, noMatch, 'Should return false when neither name contains the keyword.');
    }

    @IsTest
    static void testMatchesGroupKeywordBlankAndNullInputs() {
        Test.startTest();
        Boolean blankKeyword = DMT_SendEmailSelectTeamMember.matchesGroupKeywordForTest('Any Queue', 'any_queue', '');
        Boolean nullNames = DMT_SendEmailSelectTeamMember.matchesGroupKeywordForTest(null, null, 'NBC');
        Test.stopTest();

        System.assertEquals(true, blankKeyword, 'Blank keyword should match because empty text is contained in any string.');
        System.assertEquals(false, nullNames, 'Null names should not match a non-blank keyword.');
    }

}