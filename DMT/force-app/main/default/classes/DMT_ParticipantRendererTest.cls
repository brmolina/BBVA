/**
 * CIBGLOBALD-4117: dedicated coverage for Participants' tracking methods (getTrackedFieldsByObject /
 * getChildSections), kept separate from DMT_ViewController_Test so this component's deploy is
 * self-contained - see DMT_ApprovalProcessDataRendererTest's header for the same reasoning.
 */
@IsTest
private class DMT_ParticipantRendererTest {

    private static Id sanctionRtId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction').getRecordTypeId();
    }

    private static Id treasuryRtId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();
    }

    private static Id otherRtId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
    }

    private static Id oppRtId() {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
    }

    @IsTest
    static void testGetTrackedFieldsByObjectReturnsTeamMemberFieldsForSanction() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Participants', new DMT_Line__c(RecordTypeId = sanctionRtId()));

        Assert.isTrue(fieldsByObject.containsKey('DMT_TeamMember__c'), 'Sanction Participants must track DMT_TeamMember__c fields.');
        Set<String> fields = new Set<String>(fieldsByObject.get('DMT_TeamMember__c'));
        Assert.isTrue(fields.contains('Full_Name_User__c'), 'Full_Name_User__c backs the Participant column.');
        Assert.isTrue(fields.contains('AccessLevel__c'), 'AccessLevel__c backs the Access Level column.');
    }

    @IsTest
    static void testGetTrackedFieldsByObjectReturnsTeamMemberFieldsForOpportunity() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Participants', new Opportunity(RecordTypeId = oppRtId()));

        Assert.isTrue(fieldsByObject.containsKey('DMT_TeamMember__c'), 'Opportunity Participants must track DMT_TeamMember__c fields.');
        Set<String> fields = new Set<String>(fieldsByObject.get('DMT_TeamMember__c'));
        Assert.isTrue(fields.contains('Full_Name_User__c'), 'Full_Name_User__c backs the Participant column.');
        Assert.isTrue(fields.contains('AccessLevel__c'), 'AccessLevel__c backs the Access Level column.');
    }

    @IsTest
    static void testGetChildSectionsUsesLineLookupForSanction() {
        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = DMT_RendererFactory.getChildSections('Participants', new DMT_Line__c(RecordTypeId = sanctionRtId()));

        Assert.areEqual(1, sections.size(), 'Sanction Participants must declare exactly one child section.');
        Assert.areEqual('participantList', sections[0].snapshotSectionKey);
        Assert.areEqual('DMT_TeamMember__c', sections[0].childObjectApiName);
        Assert.areEqual('Line__c', sections[0].childLookupField, 'A Sanction Line must look up team members by Line__c, not Opportunity__c.');
        Assert.areEqual('Id', sections[0].parentValueField);
        Assert.isNotNull(sections[0].orderBy, 'participantList sets orderBy for deterministic output.');
    }

    @IsTest
    static void testGetChildSectionsUsesOpportunityLookupForOpportunity() {
        List<DMT_ApprovalChangeStep_Helper.ChildSection> sections = DMT_RendererFactory.getChildSections('Participants', new Opportunity(RecordTypeId = oppRtId()));

        Assert.areEqual(1, sections.size(), 'Opportunity Participants must declare exactly one child section.');
        Assert.areEqual('participantList', sections[0].snapshotSectionKey);
        Assert.areEqual('DMT_TeamMember__c', sections[0].childObjectApiName);
        Assert.areEqual('Opportunity__c', sections[0].childLookupField, 'A DMT_Opportunity record must look up team members by Opportunity__c, not Line__c.');
    }

    @IsTest
    static void testTreasuryAndOtherProductsRemainUnwiredForParticipants() {
        // DMT_ParticipantRenderer only wires DMT_DefaultParticipantRenderer for Sanction and
        // DMT_Opportunity (see its own header) - Treasury/OtherProducts Lines have no Participants
        // renderer at all, matching renderHtml's own behavior, so tracking must stay empty for them
        // too rather than throwing or guessing a lookup field.
        Assert.isTrue(DMT_RendererFactory.getTrackedFieldsByObject('Participants', new DMT_Line__c(RecordTypeId = treasuryRtId())).isEmpty(), 'Treasury must not track Participants fields.');
        Assert.isTrue(DMT_RendererFactory.getChildSections('Participants', new DMT_Line__c(RecordTypeId = treasuryRtId())).isEmpty(), 'Treasury must not declare a Participants child section.');
        Assert.isTrue(DMT_RendererFactory.getTrackedFieldsByObject('Participants', new DMT_Line__c(RecordTypeId = otherRtId())).isEmpty(), 'OtherProducts must not track Participants fields.');
        Assert.isTrue(DMT_RendererFactory.getChildSections('Participants', new DMT_Line__c(RecordTypeId = otherRtId())).isEmpty(), 'OtherProducts must not declare a Participants child section.');
    }

    @IsTest
    static void testGetTrackedFieldsFlatContractIsEmpty() {
        // Participants has no fields of its own on the Line/Opportunity record - everything lives on
        // the child DMT_TeamMember__c rows, so the flat getTrackedFields() contract is correctly
        // empty (DMT_ParticipantRenderer implements only the multi-object interface).
        Assert.isTrue(DMT_RendererFactory.getTrackedFields('Participants', new DMT_Line__c(RecordTypeId = sanctionRtId())).isEmpty(), 'Participants has no record-level fields to track.');
    }

    @IsTest
    static void testDelegatorRenderHtmlRoutesToDefaultRendererForSanctionAndOpportunity() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = sanctionRtId();
        data.participantList = new List<DMT_TeamMember__c>{
            (DMT_TeamMember__c) JSON.deserialize('{"AccessLevel__c":"Edit","Full_Name_User__c":"Test User"}', DMT_TeamMember__c.class)
        };
        String sanctionHtml = new DMT_ParticipantRenderer().renderHtml(data);
        Assert.isTrue(sanctionHtml.contains('Test User'), 'Sanction must route to DMT_DefaultParticipantRenderer and render the participant.');

        data.recordTypeId = oppRtId();
        String oppHtml = new DMT_ParticipantRenderer().renderHtml(data);
        Assert.isTrue(oppHtml.contains('Test User'), 'DMT_Opportunity must route to DMT_DefaultParticipantRenderer and render the participant.');
    }

    @IsTest
    static void testDelegatorRenderHtmlReturnsErrorForUnwiredRecordType() {
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.recordTypeId = treasuryRtId();
        String html = new DMT_ParticipantRenderer().renderHtml(data);
        Assert.isTrue(html.contains('Error'), 'Treasury has no Participants renderer wired - must return an error message, not throw.');

        String nullDataHtml = new DMT_ParticipantRenderer().renderHtml(null);
        Assert.isTrue(nullDataHtml.contains('Error'), 'Null data must return an error message.');
    }
}