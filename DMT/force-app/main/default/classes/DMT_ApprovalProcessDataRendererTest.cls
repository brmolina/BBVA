/**
 * CIBGLOBALD-4117: dedicated coverage for the Approval Process Data tracking methods (getTrackedFields /
 * getTrackedFieldsByObject / getChildSections), kept separate from DMT_ViewController_Test so this
 * component's deploy is self-contained and never depends on that file (which carries substantial
 * unrelated drift and is deployed on its own schedule).
 */
@isTest
private class DMT_ApprovalProcessDataRendererTest {

    @isTest
    static void testGetTrackedFieldsApprovalProcessDataTreasury() {
        Id treasuryRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();

        Test.startTest();
        List<String> trackedFields = DMT_RendererFactory.getTrackedFields('Approval Process Data', new DMT_Line__c(RecordTypeId = treasuryRtId));
        Test.stopTest();

        Set<String> expected = new Set<String>{
            'DMT_Booking_Unit_Risk_Analyst__r.Name', 'DMT_GlobalBanker__c',
            'DMT_Approver__r.Name', 'DMT_ApproverGlobalBanker__r.Name', 'DMT_Client_Use__c'
        };
        Assert.areEqual(expected, new Set<String>(trackedFields),
            'Treasury Approval Process Data must track exactly what it renders - Comments/Additional Restrictions belong to OtherProducts only.');
    }

    @isTest
    static void testGetTrackedFieldsApprovalProcessDataOther() {
        Id otherRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();

        Test.startTest();
        List<String> trackedFields = DMT_RendererFactory.getTrackedFields('Approval Process Data', new DMT_Line__c(RecordTypeId = otherRtId));
        Test.stopTest();

        Set<String> expected = new Set<String>{
            'DMT_GlobalBanker__c', 'DMT_Approver__r.Name', 'DMT_ApproverGlobalBanker__r.Name',
            'DMT_Booking_Unit_Risk_Analyst__r.Name', 'DMT_Comments__c', 'DMT_Additional_Restrictions__c'
        };
        Assert.areEqual(expected, new Set<String>(trackedFields),
            'OtherProducts Approval Process Data must track exactly what it renders - Client Use belongs to TreasurySettlement only.');
    }

    @isTest
    static void testGetTrackedFieldsApprovalProcessDataOpportunityTracksSppiAndFinancialSponsors() {
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();

        Test.startTest();
        // Most fields this tab reads live on DMT_Opportunity_Client__c or one of its three child
        // objects (see getTrackedFieldsByObject/getChildSections below), but these four are editable
        // directly on Opportunity (SPPI TEST section, dmt_OppApproversInfoForm) - found via a
        // field-drift audit, see DMT_OppApprovalProcessDataRenderer's own getTrackedFields comment.
        List<String> trackedFields = DMT_RendererFactory.getTrackedFields('Approval Process Data', new Opportunity(RecordTypeId = oppRtId));
        Test.stopTest();

        Assert.areEqual(
            new Set<String>{'DMT_SPPI_Status__c', 'DMT_SPPI_User__c', 'DMT_SPPI_File_Uploaded__c', 'DMT_Financial_Sponsors__c'},
            new Set<String>(trackedFields),
            'Approval Process Data must track its four Opportunity-native fields.'
        );
    }

    @isTest
    static void testGetTrackedFieldsByObjectApprovalProcessDataOpportunity() {
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();

        Test.startTest();
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Approval Process Data', new Opportunity(RecordTypeId = oppRtId));
        Test.stopTest();

        Assert.isTrue(fieldsByObject.containsKey('DMT_Opportunity_Client__c'), 'Scalar fields (Main Characteristics, Risk, Tiering, Sustainable Finance, Other Aspects, Client Profitability, Client Info) all live on DMT_Opportunity_Client__c.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Opportunity_Client__c')).contains('DMT_History_Deal__c'), 'A field from buildHtmlMainCharacteristics should be present.');
        Assert.isTrue(new Set<String>(fieldsByObject.get('DMT_Opportunity_Client__c')).contains('DMT_Applicable_Jurisdiction__c'), 'A field from buildHtmlOtherAspects should be present.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Opportunity_Business_Plan__c'), 'Basic Financials and Business Plan rows both live on DMT_Opportunity_Business_Plan__c.');
        Set<String> bpFields = new Set<String>(fieldsByObject.get('DMT_Opportunity_Business_Plan__c'));
        Assert.isTrue(bpFields.contains('DMT_Revenues_number__c'), 'A Basic Financials field should be present.');
        Assert.isTrue(bpFields.contains('Current_FY_GTF_amount__c'), 'A Business Plan per-geography field should be present.');
        Assert.isTrue(bpFields.contains('DMT_Xsell_Cost_to_Income__c'), 'A GLOBAL-record-only qualitative field should be present.');

        Assert.isTrue(fieldsByObject.containsKey('DMT_Global_Structure__c'), 'Global Structure of the Deal reads DMT_Global_Structure__c rows.');
        Assert.isTrue(fieldsByObject.containsKey('DMT_Banking_Pool_Structure__c'), 'Banking Pool Structure reads DMT_Banking_Pool_Structure__c rows.');
    }

    // Happy-path renderHtml coverage, matching the existing DMT_OtherLineInfoRendererTest pattern:
    // build LineDataWrapper.line directly in memory (no DML needed - relationship fields are
    // simply null on a fresh SObject, which buildRenderFields()'s safe navigation handles).
    @isTest
    static void testRenderHtmlTreasuryHappyPath() {
        DMT_TreasuryApprovalProcessDataRenderer renderer = new DMT_TreasuryApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // DMT_GlobalBanker__c is a formula field, not settable directly - Client_Use__c is plain text.
        data.line = new DMT_Line__c(Name = 'TestLine001', DMT_Client_Use__c = 'Test use');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('APPROVAL PROCESS DATA'), 'Happy path must render the header.');
        Assert.isTrue(result.contains('Test use'), 'DMT_Client_Use__c must render.');
        Assert.isTrue(!result.contains('Error:'), 'Happy path must not produce an error div.');
    }

    @isTest
    static void testRenderHtmlOtherHappyPath() {
        DMT_OtherApprovalProcessDataRenderer renderer = new DMT_OtherApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // DMT_GlobalBanker__c is a formula field, not settable directly - Comments/Additional
        // Restrictions are plain text.
        data.line = new DMT_Line__c(Name = 'TestLine001', DMT_Comments__c = 'Test comments', DMT_Additional_Restrictions__c = 'Test restrictions');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Approval Process Data'), 'Happy path must render the header.');
        Assert.isTrue(result.contains('Test comments'), 'DMT_Comments__c must render.');
        Assert.isTrue(result.contains('Test restrictions'), 'DMT_Additional_Restrictions__c must render.');
        Assert.isTrue(!result.contains('Error:'), 'Happy path must not produce an error div.');
    }

    @isTest
    static void testRenderHtmlDelegatorNullData() {
        DMT_ApprovalProcessDataRenderer renderer = new DMT_ApprovalProcessDataRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Error'), 'Null data must return the guard error message.');
    }

    @isTest
    static void testRenderHtmlDelegatorInvalidRecordType() {
        DMT_ApprovalProcessDataRenderer renderer = new DMT_ApprovalProcessDataRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = null;
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Error'), 'An unrecognized record type must return the guard error message.');
    }

    @isTest
    static void testGetChildSectionsApprovalProcessDataOpportunity() {
        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();

        Test.startTest();
        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = DMT_RendererFactory.getChildSections('Approval Process Data', new Opportunity(RecordTypeId = oppRtId));
        Test.stopTest();

        Map<String, DMT_ApprovalChangeStep_Helper.ChildSection> byKey = new Map<String, DMT_ApprovalChangeStep_Helper.ChildSection>();
        for (DMT_ApprovalChangeStep_Helper.ChildSection s : sections) {
            byKey.put(s.snapshotSectionKey, s);
        }
        Assert.areEqual(4, sections.size(), 'Approval Process Data declares opportunityClient, opportunityBusinessPlan, opportunityGlobalStructure and opportunityBankingPoolStructure.');
        Assert.isTrue(byKey.containsKey('opportunityClient'), 'Must declare the same section key as the Client component, so their fields union instead of one overwriting the other.');
        Assert.areEqual('DMT_Opportunity_Client__c', byKey.get('opportunityClient').childObjectApiName);
        Assert.areEqual('DMT_MDE_Opportunity__c', byKey.get('opportunityClient').childLookupField, 'Must match the lookup Client\'s own ChildSection declares for this same object/section.');
        Assert.areEqual('DMT_Opportunity_Business_Plan__c', byKey.get('opportunityBusinessPlan').childObjectApiName);
        Assert.areEqual('DMT_Global_Structure__c', byKey.get('opportunityGlobalStructure').childObjectApiName);
        Assert.areEqual('DMT_Banking_Pool_Structure__c', byKey.get('opportunityBankingPoolStructure').childObjectApiName);
        for (String key : new List<String>{ 'opportunityBusinessPlan', 'opportunityGlobalStructure', 'opportunityBankingPoolStructure' }) {
            Assert.areEqual('Id', byKey.get(key).parentValueField, key + ' hangs directly off the Opportunity.');
            Assert.areEqual('DMT_Opportunity__c', byKey.get(key).childLookupField, key + ' uses the DMT_Opportunity__c lookup on the child.');
        }
    }
}