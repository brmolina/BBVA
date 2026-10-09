/**
 * CIBGLOBALD-4117: dedicated coverage for DMT_SnapshotChildComparator, kept separate so this fix's
 * deploy is self-contained. Exercises a cross-object ChildSection (childLookupField containing a
 * dot, e.g. 'DMT_Risk_Line_Term__r.DMT_Line__c') end to end via real DML and a real query - this is
 * exactly the path that regressed: SObject.get(String) cannot resolve a dotted relationship path as
 * one string, so queryLiveRows() threw "Invalid field X for Y" for every cross-object section
 * (currencyProvisions/warranties on Products, opportunityTenor/opportunityMitigant/
 * opportunityUnderlying on Opportunity Products) - silently aborting the whole restart check for
 * any record with one of these sections, caught by the caller's own try/catch and never surfaced.
 * Found live-testing Participants against a real Opportunity resubmission.
 */
@IsTest
private class DMT_SnapshotChildComparatorTest {

    @IsTest
    static void testHasChangesDetectsAChangeThroughACrossObjectChildSection() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = new DMT_Risk_Line_Term__c(DMT_Line__c = line.Id, CurrencyIsoCode = 'EUR');
        insert risk;
        DMT_Warranty__c warranty = new DMT_Warranty__c(DMT_Risk_Line_Term__c = risk.Id, Name = 'Original Warranty');
        insert warranty;

        DMT_Line__c queriedLine = [SELECT Id, RecordTypeId, Custom_Association__c FROM DMT_Line__c WHERE Id = :line.Id];
        Map<Id, SObject> recordsById = new Map<Id, SObject>{ queriedLine.Id => queriedLine };

        Test.startTest();
        DMT_SnapshotChildComparator comparator = DMT_SnapshotChildComparator.forRecords(recordsById);
        Test.stopTest();

        Assert.isNotNull(comparator, 'OtherProducts declares the warranties ChildSection (cross-object, dotted childLookupField) - a comparator must be built.');

        // Frozen snapshot shows a different Warranty Name than what is live now - this must be
        // detected as a change without the query itself throwing SObjectException.
        Map<String, Object> frozenWarranties = new Map<String, Object>{
            (String) warranty.Id => new Map<String, Object>{ 'Name' => 'A Different Warranty Name' }
        };
        Map<String, Object> snapshotJson = new Map<String, Object>{ 'warranties' => frozenWarranties };

        Boolean changed = comparator.hasChanges(queriedLine.Id, snapshotJson);
        Assert.isTrue(changed, 'A live Warranty.Name differing from the frozen value must be detected through the cross-object lookup.');
    }

    @IsTest
    static void testHasChangesReturnsFalseWhenCrossObjectRowsMatch() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = new DMT_Risk_Line_Term__c(DMT_Line__c = line.Id, CurrencyIsoCode = 'EUR');
        insert risk;
        DMT_Warranty__c warranty = new DMT_Warranty__c(DMT_Risk_Line_Term__c = risk.Id);
        insert warranty;
        // Name is an auto-number field on DMT_Warranty__c, not settable via DML - read back the
        // real generated value instead of assuming a literal one persisted.
        warranty = [SELECT Id, Name FROM DMT_Warranty__c WHERE Id = :warranty.Id];

        DMT_Line__c queriedLine = [SELECT Id, RecordTypeId, Custom_Association__c FROM DMT_Line__c WHERE Id = :line.Id];
        Map<Id, SObject> recordsById = new Map<Id, SObject>{ queriedLine.Id => queriedLine };

        DMT_SnapshotChildComparator comparator = DMT_SnapshotChildComparator.forRecords(recordsById);

        Map<String, Object> frozenWarranties = new Map<String, Object>{
            (String) warranty.Id => new Map<String, Object>{ 'Name' => warranty.Name }
        };
        Map<String, Object> snapshotJson = new Map<String, Object>{ 'warranties' => frozenWarranties };

        Boolean changed = comparator.hasChanges(queriedLine.Id, snapshotJson);
        Assert.isFalse(changed, 'Identical frozen and live Warranty rows must not be flagged as changed.');
    }
}