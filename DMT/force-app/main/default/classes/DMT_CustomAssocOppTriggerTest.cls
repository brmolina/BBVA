/**
 * @description Tests for DMT_CustomAssocOppTrigger: when the multiholder Main Borrower changes
 * (g_customer_id__c on Custom_Association_Opportunity__c), the previously captured data is
 * transferred to the newly selected Main Borrower Opportunity Client, while client-identity fields
 * are preserved.
 */
@isTest
public with sharing class DMT_CustomAssocOppTriggerTest {

    private static final String ALPHA_A = 'ES0182000000001';
    private static final String ALPHA_B = 'ES0182000000002';
    private static final String ALPHA_C = 'ES0182000000003';

    @TestSetup
    static void makeData() {
        TriggerBypass.setBypass();

        Id oppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Main Borrower Transfer',
            StageName = 'Draft',
            CloseDate = Date.today().addDays(30),
            RecordTypeId = oppRtId
        );
        insert opp;

        // Original Main Borrower (A) carries the business data; B and C are the other holders.
        DMT_Opportunity_Client__c clientA = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Alpha_Code_Client__c = ALPHA_A,
            g_customer_id__c = ALPHA_A,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N',
            g_upd_lmscl_internal_ratg_type__c = '-A',
            Revenues_Last_Year_number__c = 14,
            EBITDA_Last_Year_number__c = 7
        );
        DMT_Opportunity_Client__c clientB = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Alpha_Code_Client__c = ALPHA_B,
            g_customer_id__c = ALPHA_B,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        DMT_Opportunity_Client__c clientC = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = opp.Id,
            Alpha_Code_Client__c = ALPHA_C,
            g_customer_id__c = ALPHA_C,
            Counterpart__c = 'Corporates',
            DMT_Sector__c = 'N'
        );
        insert new List<DMT_Opportunity_Client__c>{ clientA, clientB, clientC };

        insert new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = ALPHA_A,
            gf_customer_group_id__c = 'GRP-' + opp.Id
        );

        TriggerBypass.removeBypass();
    }

    @isTest
    static void testTransferOnMainBorrowerChange() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Custom_Association_Opportunity__c assoc = [
            SELECT Id, g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];

        Test.startTest();
        // Change Main Borrower from A to B
        assoc.g_customer_id__c = ALPHA_B;
        update assoc;
        Test.stopTest();

        DMT_Opportunity_Client__c newMain = [
            SELECT Alpha_Code_Client__c, g_customer_id__c, Revenues_Last_Year_number__c,
                   EBITDA_Last_Year_number__c, g_upd_lmscl_internal_ratg_type__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opp.Id AND Alpha_Code_Client__c = :ALPHA_B
            LIMIT 1
        ];

        // Business / approval data transferred from the previous Main Borrower (A)
        Assert.areEqual(14, newMain.Revenues_Last_Year_number__c, 'Revenues should be transferred to the new Main Borrower');
        Assert.areEqual(7, newMain.EBITDA_Last_Year_number__c, 'EBITDA should be transferred to the new Main Borrower');
        Assert.areEqual('-A', newMain.g_upd_lmscl_internal_ratg_type__c, 'Internal rating should be transferred');

        // Identity fields preserved on the new Main Borrower
        Assert.areEqual(ALPHA_B, newMain.Alpha_Code_Client__c, 'Alpha Code must NOT be overwritten');
        Assert.areEqual(ALPHA_B, newMain.g_customer_id__c, 'Customer id must NOT be overwritten');
    }

    @isTest
    static void testNoTransferWhenMainBorrowerUnchanged() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Custom_Association_Opportunity__c assoc = [
            SELECT Id, gf_origin_application_type__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];

        Test.startTest();
        // Update an unrelated field; the Main Borrower (g_customer_id__c) stays the same
        assoc.gf_origin_application_type__c = '05';
        update assoc;
        Test.stopTest();

        DMT_Opportunity_Client__c clientB = [
            SELECT Revenues_Last_Year_number__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opp.Id AND Alpha_Code_Client__c = :ALPHA_B
            LIMIT 1
        ];
        Assert.areEqual(null, clientB.Revenues_Last_Year_number__c,
            'No transfer should happen when the Main Borrower is unchanged');
    }

    @isTest
    static void testTriggerBypassSkipsTransfer() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Custom_Association_Opportunity__c assoc = [
            SELECT Id, g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];

        Test.startTest();
        // With the bypass active the trigger returns early and performs no transfer.
        TriggerBypass.setBypass();
        assoc.g_customer_id__c = ALPHA_B;
        update assoc;
        TriggerBypass.removeBypass();
        Test.stopTest();

        DMT_Opportunity_Client__c clientB = [
            SELECT Revenues_Last_Year_number__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opp.Id AND Alpha_Code_Client__c = :ALPHA_B
            LIMIT 1
        ];
        Assert.areEqual(null, clientB.Revenues_Last_Year_number__c,
            'Bypassed trigger must not transfer data');
    }

    @isTest
    static void testAfterInsertSyncsMainHolderName() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Account mainHolder = new Account(Name = 'Sync Main Holder Account', g_customer_id__c = 'SYNC_ALPHA_MH');
        insert mainHolder;

        Test.startTest();
        insert new Custom_Association_Opportunity__c(
            Opportunity__c = opp.Id,
            g_customer_id__c = 'SYNC_ALPHA_MH'
        );
        Test.stopTest();

        Opportunity result = [SELECT DMT_Main_Holder_Name__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Sync Main Holder Account', result.DMT_Main_Holder_Name__c,
            'Inserting the Multiholder association should populate the Main Holder Name');
    }

    @isTest
    static void testAfterDeleteRevertsMainHolderNameToAccountFallback() {
        Opportunity opp = [SELECT Id, Account.Name FROM Opportunity LIMIT 1];
        Custom_Association_Opportunity__c assoc = [
            SELECT Id
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];

        Test.startTest();
        delete assoc;
        Test.stopTest();

        Opportunity result = [SELECT DMT_Main_Holder_Name__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual(opp.Account?.Name, result.DMT_Main_Holder_Name__c,
            'Deleting the last Multiholder association should revert the Main Holder Name to the Opportunity\'s own Account');
    }
}