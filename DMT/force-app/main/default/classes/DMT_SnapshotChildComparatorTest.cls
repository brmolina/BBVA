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

    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();

    @IsTest
    static void testHasChangesDetectsAChangeThroughACrossObjectChildSection() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = DMT_UTIL.createRiskLineTermRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => line.Id,
                DMT_Risk_Line_Term__c.CurrencyIsoCode => 'EUR'
            }
        );

        DMT_Warranty__c warranty = DMT_UTIL.createWarrantyRecord(
            risk.Id,
            new Map<Schema.SObjectField, Object>{
                DMT_Warranty__c.Name => 'Original Warranty'
            }
        );

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

        Boolean changed = comparator.hasChanges(queriedLine.Id, snapshotJson, null); // CIBGLOBALD-4811, CIBGLOBALD-4870
        Assert.isTrue(changed, 'A live Warranty.Name differing from the frozen value must be detected through the cross-object lookup.');
        Assert.areEqual(1, comparator.changedComponents(queriedLine.Id, snapshotJson, null).size(), 'The component of the changed section is named'); // CIBGLOBALD-4811
        // CIBGLOBALD-4811 - only the task's components count: warranties belong to Products.
        Assert.areEqual(new List<String>{ 'Products' }, comparator.changedComponents(queriedLine.Id, snapshotJson, new List<String>{ 'Products', 'Line Info' }), 'The changed section is named by the task component that tracks it');
        Assert.isFalse(comparator.hasChanges(queriedLine.Id, snapshotJson, new List<String>{ 'Line Info' }), 'A section of a component the task did not freeze is not compared'); // CIBGLOBALD-4870
        Assert.isNull(DMT_SnapshotChildComparator.forRecords(recordsById, new List<String>{ 'Line Info' }), 'No child section is queried when the task components have none'); // CIBGLOBALD-4870
    }

    @IsTest
    static void testHasChangesReturnsFalseWhenCrossObjectRowsMatch() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = DMT_UTIL.createRiskLineTermRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => line.Id,
                DMT_Risk_Line_Term__c.CurrencyIsoCode => 'EUR'
            }
        );

        DMT_Warranty__c warranty = DMT_UTIL.createWarrantyRecord(risk.Id);
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

        Boolean changed = comparator.hasChanges(queriedLine.Id, snapshotJson, null); // CIBGLOBALD-4811, CIBGLOBALD-4870
        Assert.isFalse(changed, 'Identical frozen and live Warranty rows must not be flagged as changed.');
        Assert.isTrue(comparator.changedComponents(queriedLine.Id, snapshotJson, null).isEmpty(), 'No component is named when the rows match'); // CIBGLOBALD-4811
    }

    // CIBGLOBALD-4811 - an unsaved value on a live row is compared as if it were saved; rows of
    // another object are ignored.
    @IsTest
    static void testApplyUnsavedRowsComparesTheUnsavedValue() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = DMT_UTIL.createRiskLineTermRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => line.Id,
                DMT_Risk_Line_Term__c.CurrencyIsoCode => 'EUR'
            }
        );
        DMT_Warranty__c warranty = DMT_UTIL.createWarrantyRecord(risk.Id);
        warranty = [SELECT Id, Name FROM DMT_Warranty__c WHERE Id = :warranty.Id];

        DMT_Line__c queriedLine = [SELECT Id, RecordTypeId, Custom_Association__c FROM DMT_Line__c WHERE Id = :line.Id];
        Map<String, Object> snapshotJson = new Map<String, Object>{
            'warranties' => new Map<String, Object>{ (String) warranty.Id => new Map<String, Object>{ 'Name' => warranty.Name } }
        };

        Test.startTest();
        DMT_SnapshotChildComparator otherObject = DMT_SnapshotChildComparator.forRecords(new Map<Id, SObject>{ queriedLine.Id => queriedLine });
        otherObject.applyUnsavedRows(queriedLine.Id, new List<Map<String, Object>>{
            new Map<String, Object>{ 'objectApiName' => 'DMT_Line__c', 'rowId' => (String) warranty.Id, 'values' => new Map<String, Object>{ 'Name' => 'Unsaved' } }
        });
        DMT_SnapshotChildComparator sameObject = DMT_SnapshotChildComparator.forRecords(new Map<Id, SObject>{ queriedLine.Id => queriedLine });
        sameObject.applyUnsavedRows(queriedLine.Id, new List<Map<String, Object>>{
            new Map<String, Object>{ 'objectApiName' => 'DMT_Warranty__c', 'rowId' => (String) warranty.Id, 'values' => new Map<String, Object>{ 'Name' => 'Unsaved' } }
        });
        Test.stopTest();

        Assert.isFalse(otherObject.hasChanges(queriedLine.Id, snapshotJson, null), 'A row of another object leaves the warranties section as stored');
        Assert.isTrue(sameObject.hasChanges(queriedLine.Id, snapshotJson, null), 'The unsaved Warranty Name differs from the frozen one');
        Assert.areEqual(warranty.Name, [SELECT Name FROM DMT_Warranty__c WHERE Id = :warranty.Id].Name, 'Nothing is saved');
    }

    // CIBGLOBALD-4811 - a row the save inserts or deletes changes the row count of the section.
    @IsTest
    static void testApplyUnsavedRowsAddedAndDeletedRowsAreChanges() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Risk_Line_Term__c risk = DMT_UTIL.createRiskLineTermRecord(
            new Map<Schema.SObjectField, Object>{
                DMT_Risk_Line_Term__c.DMT_Line__c => line.Id,
                DMT_Risk_Line_Term__c.CurrencyIsoCode => 'EUR'
            }
        );
        DMT_Warranty__c warranty = DMT_UTIL.createWarrantyRecord(risk.Id);
        warranty = [SELECT Id, Name FROM DMT_Warranty__c WHERE Id = :warranty.Id];

        DMT_Line__c queriedLine = [SELECT Id, RecordTypeId, Custom_Association__c FROM DMT_Line__c WHERE Id = :line.Id];
        Map<String, Object> snapshotJson = new Map<String, Object>{
            'warranties' => new Map<String, Object>{ (String) warranty.Id => new Map<String, Object>{ 'Name' => warranty.Name } }
        };

        Test.startTest();
        DMT_SnapshotChildComparator added = DMT_SnapshotChildComparator.forRecords(new Map<Id, SObject>{ queriedLine.Id => queriedLine });
        added.applyUnsavedRows(queriedLine.Id, new List<Map<String, Object>>{
            new Map<String, Object>{ 'objectApiName' => 'DMT_Warranty__c', 'values' => new Map<String, Object>{ 'Name' => 'New warranty' } }
        });
        DMT_SnapshotChildComparator deleted = DMT_SnapshotChildComparator.forRecords(new Map<Id, SObject>{ queriedLine.Id => queriedLine });
        deleted.applyUnsavedRows(queriedLine.Id, new List<Map<String, Object>>{
            new Map<String, Object>{ 'objectApiName' => 'DMT_Warranty__c', 'rowId' => (String) warranty.Id, 'deleted' => true }
        });
        Test.stopTest();

        Assert.isTrue(added.hasChanges(queriedLine.Id, snapshotJson, null), 'A row the save inserts is a change');
        Assert.isTrue(deleted.hasChanges(queriedLine.Id, snapshotJson, null), 'A row the save deletes is a change');
    }
}