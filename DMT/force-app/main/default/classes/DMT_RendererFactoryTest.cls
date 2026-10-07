@IsTest
public class DMT_RendererFactoryTest {

    private static Id treasuryRTId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();
    }

    private static Id otherProductsRTId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();
    }

    private static Id sanctionRTId() {
        return Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction').getRecordTypeId();
    }

    private static Id dmtOpportunityRTId() {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
    }

    // CIBGLOBALD-4117: getTrackedFields/getTrackedFieldsByObject/getChildSections take the full
    // record (not just its RecordTypeId) so a renderer can branch on any of its own fields - these
    // helpers build the minimal record each test needs.
    private static DMT_Line__c treasuryLine() {
        return new DMT_Line__c(RecordTypeId = treasuryRTId());
    }

    private static DMT_Line__c otherProductsLine() {
        return new DMT_Line__c(RecordTypeId = otherProductsRTId());
    }

    private static DMT_Line__c sanctionLine() {
        return new DMT_Line__c(RecordTypeId = sanctionRTId());
    }

    private static Opportunity dmtOpportunity() {
        return new Opportunity(RecordTypeId = dmtOpportunityRTId());
    }

    @IsTest
    static void testGetTrackedFieldsByObjectForClientOnTreasuryReturnsBothObjects() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Client', treasuryLine());
        Assert.isTrue(fieldsByObject.containsKey('DMT_Line__c'), 'Treasury Client must include DMT_Line__c fields.');
        Assert.isTrue(fieldsByObject.containsKey('Custom_Association_Client__c'), 'Treasury Client must include Custom_Association_Client__c fields.');
    }

    @IsTest
    static void testGetTrackedFieldsByObjectForClientOnOtherProductsReturnsBothObjects() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Client', otherProductsLine());
        Assert.isTrue(fieldsByObject.containsKey('DMT_Line__c'), 'OtherProducts Client must include DMT_Line__c fields.');
        Assert.isTrue(fieldsByObject.containsKey('Custom_Association_Client__c'), 'OtherProducts Client must include Custom_Association_Client__c fields.');
    }

    @IsTest
    static void testGetTrackedFieldsByObjectForClientOnSanctionReturnsEmpty() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Client', sanctionLine());
        Assert.isTrue(fieldsByObject.isEmpty(), 'Sanction Client is not tracked - DMT_LineSanctionClientRenderer does not implement DMT_MultiObjectFieldTrackableRenderer.');
    }

    @IsTest
    static void testGetTrackedFieldsByObjectForClientOnOpportunityReturnsBothObjects() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Client', dmtOpportunity());
        Assert.isTrue(fieldsByObject.containsKey('DMT_Opportunity_Client__c'), 'Opportunity Client must track its DMT_Opportunity_Client__c child fields.');
        Assert.isTrue(fieldsByObject.containsKey('Opportunity'), 'Opportunity Client must track DMT_Threshold_Type__c on the Opportunity itself.');

        Set<String> oppFields = new Set<String>(fieldsByObject.get('Opportunity'));
        Assert.areEqual(new Set<String>{ 'DMT_Threshold_Type__c' }, oppFields, 'Only DMT_Threshold_Type__c lives on the Opportunity record itself.');

        Set<String> clientFields = new Set<String>(fieldsByObject.get('DMT_Opportunity_Client__c'));
        // Present in the renderer/LWC but absent from DMT_Campos_componente_Refact__c - gaps that
        // renderer-based tracking closes.
        for (String f : new List<String>{ 'DMT_Scoring__c', 'DMT_Industry__c', 'DMT_Leveraged_Lending__c', 'DMT_CAMN__c', 'DMT_Sector_Head__c', 'DMT_Guarantor_Name_Fiscal_ID__c' }) {
            Assert.isTrue(clientFields.contains(f), f + ' is displayed by the renderer and must now be tracked.');
        }
        // Only built inside the Fin Inst Counterpart branch, so they can only come from the
        // explicit additions in getTrackedFieldsByObject().
        for (String f : new List<String>{ 'SCRA__c', 'AVC_Check__c', 'European_Bank_Check__c' }) {
            Assert.isTrue(clientFields.contains(f), f + ' must be tracked regardless of the Counterpart branch.');
        }
        // Account fields are deliberately excluded - they live on the parent Account and the
        // trigger-side gate cannot see parent relationships.
        Assert.isFalse(clientFields.contains('DES_ID_Fiscal__c'), 'Account fields must not be tracked.');
        Assert.isFalse(fieldsByObject.containsKey('Account'), 'Account must not appear as a tracked object.');
    }

    @IsTest
    static void testGetTrackedFieldsByObjectForUnknownComponentReturnsEmpty() {
        Map<String, List<String>> fieldsByObject = DMT_RendererFactory.getTrackedFieldsByObject('Not A Real Component', treasuryLine());
        Assert.isTrue(fieldsByObject.isEmpty(), 'Unknown component must return an empty map, not throw.');
    }

    // CIBGLOBALD-4117: there is deliberately no separate "is this component/record type tracked"
    // list anywhere - callers (DMT_ApprovalChangeStep_Handler.updateTaskWithStatus,
    // DMT_Line_Helper.restartApprovalTasksOnLineResubmission) decide purely from whether these
    // two methods return anything for a given (component, recordType) pair. These tests guard
    // that emptiness signal directly, for every combination those callers rely on.
    @IsTest
    static void testGetTrackedFieldsForClientOnTreasuryAndOtherProductsIsNonEmpty() {
        Assert.isFalse(DMT_RendererFactory.getTrackedFields('Client', treasuryLine()).isEmpty(), 'Client must return DMT_Line__c-native fields for Treasury.');
        Assert.isFalse(DMT_RendererFactory.getTrackedFields('Client', otherProductsLine()).isEmpty(), 'Client must return DMT_Line__c-native fields for OtherProducts.');
    }

    @IsTest
    static void testGetTrackedFieldsForClientOnSanctionIsEmpty() {
        Assert.isTrue(DMT_RendererFactory.getTrackedFields('Client', sanctionLine()).isEmpty(), 'Client is not tracked for Sanction - its renderer implements neither tracking interface.');
    }

    @IsTest
    static void testGetTrackedFieldsForClientOnOpportunityReturnsOpportunityNativeFieldsOnly() {
        // The flat getTrackedFields() feeds the record-level comparison, so it must return only
        // fields that live on the Opportunity itself. The DMT_Opportunity_Client__c child fields
        // reach the comparison through DMT_SnapshotChildComparator instead.
        Set<String> f = new Set<String>(DMT_RendererFactory.getTrackedFields('Client', dmtOpportunity()));
        Assert.areEqual(new Set<String>{ 'DMT_Threshold_Type__c' }, f, 'Only the Opportunity-native field belongs in the flat tracked list.');
    }

    @IsTest
    static void testGetTrackedFieldsForLineInfoAndOpportunityInfoIsNonEmptyForEveryRecordType() {
        // Regression guard: these two components are tracked across every record type they're used
        // with, so callers never need to fall back to DMT_Campos_componente_Refact__c for them.
        Assert.isFalse(DMT_RendererFactory.getTrackedFields('Line Info', treasuryLine()).isEmpty(), 'Line Info is tracked - Treasury.');
        Assert.isFalse(DMT_RendererFactory.getTrackedFields('Line Info', sanctionLine()).isEmpty(), 'Line Info is tracked - Sanction too, regardless of record type.');
        Assert.isFalse(DMT_RendererFactory.getTrackedFields('Opportunity Info', dmtOpportunity()).isEmpty(), 'Opportunity Info is tracked.');
    }

    @IsTest
    static void testGetTrackedFieldsForUnknownComponentIsEmpty() {
        Assert.isTrue(DMT_RendererFactory.getTrackedFields('Not A Real Component', treasuryLine()).isEmpty(), 'Unknown component must return an empty list, not throw.');
    }
}