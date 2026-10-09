@IsTest
private class DMT_DmlUtilsTest {

    @IsTest
    static void testInsertUpdateDeleteMany() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');

        Test.startTest();
        DMT_DmlUtils.insertMany(new List<SObject>{ c }, 'insertCase');
        c.Status = 'In Progress';
        DMT_DmlUtils.updateMany(new List<SObject>{ c }, 'updateCase');
        Task t = new Task(WhatId = c.Id, Subject = 'T', Status = 'Not Started', ActivityDate = Date.today());
        DMT_DmlUtils.insertMany(new List<SObject>{ t }, 'insertTask');
        DMT_DmlUtils.deleteMany(new List<SObject>{ t }, 'deleteTask');
        Test.stopTest();

        Assert.areEqual('In Progress', [SELECT Status FROM Case WHERE Id = :c.Id].Status);
        Assert.areEqual(0, [SELECT COUNT() FROM Task WHERE Id = :t.Id]);
    }

    @IsTest
    static void testNoOpOnNullOrEmptyLists() {
        Test.startTest();
        DMT_DmlUtils.insertMany(null, 'op');
        DMT_DmlUtils.insertMany(new List<SObject>(), 'op');
        DMT_DmlUtils.updateMany(null, 'op');
        DMT_DmlUtils.updateMany(new List<SObject>(), 'op');
        DMT_DmlUtils.deleteMany(null, 'op');
        DMT_DmlUtils.deleteMany(new List<SObject>(), 'op');
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown for null/empty lists.');
    }

    @IsTest
    static void testWithIdOnlyFiltersRecordsWithoutId() {
        Case withId = new Case(Id = '500000000000001AAA');
        Case withoutId = new Case();

        Test.startTest();
        List<SObject> filtered = DMT_DmlUtils.withIdOnly(new List<SObject>{ withId, withoutId, null });
        Test.stopTest();

        Assert.areEqual(1, filtered.size());
        Assert.areEqual(withId.Id, filtered[0].Id);
    }

    @IsTest
    static void testUpdateManyPropagatesDmlExceptionOnFailure() {
        Case c = new Case(DMT_Passport_Sanction__c = 'approval');
        insert c;
        Case deleted = new Case(Id = c.Id);
        delete c;

        Boolean threw = false;
        Test.startTest();
        try {
            DMT_DmlUtils.updateMany(new List<SObject>{ deleted }, 'testOperation');
        } catch (DmlException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'A failed DML row (updating an already-deleted record) must throw.');
    }
}