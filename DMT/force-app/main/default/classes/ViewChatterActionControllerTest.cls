@isTest
private class ViewChatterActionControllerTest {

    @isTest
    static void testGetChatterContextWithNullRecordId() {
        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(null);
        Test.stopTest();

        System.assertEquals(null, context.feedRecordId);
        System.assertEquals(false, context.showLineFeed);
        System.assertEquals(false, context.showOpportunityFeed);
        System.assertEquals('Live Chatter', context.widgetTitle);
    }

    @isTest
    static void testGetChatterContextForOpportunity() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(opp.Id);
        Test.stopTest();

        System.assertEquals(opp.Id, context.feedRecordId);
        System.assertEquals(true, context.showLineFeed);
        System.assertEquals(false, context.showOpportunityFeed);
        System.assertEquals('Opportunity Chatter', context.widgetTitle);
    }

    @isTest
    static void testGetChatterContextForCaseFlagO() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, UserInfo.getUserId());

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(c.Id);
        Test.stopTest();

        System.assertEquals(opp.Id, context.feedRecordId);
        System.assertEquals(true, context.showLineFeed);
        System.assertEquals('Opportunity Chatter', context.widgetTitle);
    }

    @isTest
    static void testGetChatterContextForCaseFlagL() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        Case c = DMT_Test_DataFactory.generateCase(line.Id, null, UserInfo.getUserId());

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(c.Id);
        Test.stopTest();

        System.assertEquals(line.Id, context.feedRecordId);
        System.assertEquals(true, context.showLineFeed);
        System.assertEquals('Line Chatter', context.widgetTitle);
    }

    @isTest
    static void testGetChatterContextForCaseFallbackOpportunity() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, UserInfo.getUserId());

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(c.Id);
        Test.stopTest();

        System.assertEquals(opp.Id, context.feedRecordId);
        System.assertEquals(true, context.showLineFeed);
        System.assertEquals('Opportunity Chatter', context.widgetTitle);
    }

    @isTest
    static void testGetChatterContextForCaseFallbackCase() {
        Case c = DMT_Test_DataFactory.generateCase(null, null, UserInfo.getUserId());

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(c.Id);
        Test.stopTest();

        System.assertEquals(c.Id, context.feedRecordId);
        System.assertEquals(true, context.showLineFeed);
        System.assertEquals('Case Chatter', context.widgetTitle);
    }

    @isTest
    static void testGetChatterContextForLineWithOpTemplate() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();

        Map<String, Schema.SObjectField> lineFields = Schema.SObjectType.DMT_Line__c.fields.getMap();
        DMT_Line__c lineToUpdate = new DMT_Line__c(Id = line.Id);

        if (lineFields.containsKey('opportunity_id__c')) {
            lineToUpdate.put('opportunity_id__c', opp.Id);
        } else if (lineFields.containsKey('Opportunity__c')) {
            lineToUpdate.put('Opportunity__c', opp.Id);
        }

        update lineToUpdate;

        DMT_Line__c lineFromDb = [
            SELECT DMT_line_template_type__c
            FROM DMT_Line__c
            WHERE Id = :line.Id
            LIMIT 1
        ];

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(line.Id);
        Test.stopTest();

        System.assertEquals(line.Id, context.feedRecordId);
        System.assertEquals(true, context.showLineFeed);
        System.assertEquals('Line Chatter', context.widgetTitle);

        if ((lineFields.containsKey('opportunity_id__c') || lineFields.containsKey('Opportunity__c'))
            && lineFromDb.DMT_line_template_type__c == 'OP') {
            System.assertEquals(true, context.showOpportunityFeed);
            System.assertEquals(opp.Id, context.opportunityFeedRecordId);
        } else {
            System.assertEquals(false, context.showOpportunityFeed);
        }
    }

    @isTest
    static void testGetChatterContextForLineWithoutOpTemplate() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(line.Id);
        Test.stopTest();

        System.assertEquals(line.Id, context.feedRecordId);
        System.assertEquals(true, context.showLineFeed);
        System.assertEquals(false, context.showOpportunityFeed);
        System.assertEquals('Line Chatter', context.widgetTitle);
    }

    @isTest
    static void testGetChatterContextForUnsupportedObject() {
        Account acc = DMT_Test_DataFactory.generateAccount();

        Test.startTest();
        ViewChatterActionController.ChatterContext context =
            ViewChatterActionController.getChatterContext(acc.Id);
        Test.stopTest();

        System.assertEquals(acc.Id, context.feedRecordId);
        System.assertEquals(false, context.showLineFeed);
        System.assertEquals(false, context.showOpportunityFeed);
        System.assertEquals('Live Chatter', context.widgetTitle);
    }
}