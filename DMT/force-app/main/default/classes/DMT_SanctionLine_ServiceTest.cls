/**
 * CIBGLOBALD-4374 - Tests of DMT_SanctionLine_Service. Test data comes from DMT_Test_DataFactory.
 * The line code callout is answered by the integration service mock (DMT_HPG_Utils.getMock).
 */
@IsTest
private class DMT_SanctionLine_ServiceTest {

    private static Opportunity createOpportunity(String structureType) {
        Account account = DMT_Test_DataFactory.generateAccount(
            new Map<Schema.SObjectField, Object>{ Account.DES_Structure_Type__c => structureType }
        );
        return DMT_Test_DataFactory.generateOpportunityForAccount(account.Id);
    }

    @IsTest
    static void approvalLineName_replacesTheOpportunityWordInBothLanguages() {
        Assert.areEqual('Approval Alpha', DMT_SanctionLine_Service.approvalLineName('Opportunity Alpha'), 'English');
        Assert.areEqual('Approval Alpha', DMT_SanctionLine_Service.approvalLineName('Oportunidad Alpha'), 'Spanish');
        Assert.isNull(DMT_SanctionLine_Service.approvalLineName(null), 'Null stays null');
    }

    @IsTest
    static void createFromOpportunity_nullIdReturnsNull() {
        Assert.isNull(DMT_SanctionLine_Service.createFromOpportunity(null), 'Nothing to create without an Opportunity');
    }

    @IsTest
    static void createFromOpportunity_reusesTheExistingSanctionLineAndLinksTheOpportunity() {
        Opportunity opp = createOpportunity('Group');
        DMT_Line__c existing = DMT_Test_DataFactory.generateSanctionLine(opp.AccountId, opp.Id, '00977');

        Test.startTest();
        Id lineId = DMT_SanctionLine_Service.createFromOpportunity(opp.Id);
        Test.stopTest();

        Assert.areEqual(existing.Id, lineId, 'The existing Sanction Line is returned');
        Assert.areEqual(1, [SELECT COUNT() FROM DMT_Line__c WHERE DMT_Opportunity__c = :opp.Id], 'No second Line is created');
        Assert.areEqual(existing.Id, [SELECT DMT_Sanction__c FROM Opportunity WHERE Id = :opp.Id].DMT_Sanction__c, 'The Opportunity points at the Sanction Line');
    }

    @IsTest
    static void createFromOpportunity_clientWithoutMultiholderCreatesTheLineAndReturnsNoId() {
        Opportunity opp = createOpportunity('Group');

        Test.startTest();
        Id lineId = DMT_SanctionLine_Service.createFromOpportunity(opp.Id);
        Test.stopTest();

        // Same observable behavior as the flow it replaces: the Line exists, nothing else is created.
        Assert.isNull(lineId, 'No Line Id is returned');
        List<DMT_Line__c> created = [SELECT Id, Status__c, Name, Line_Id__c FROM DMT_Line__c WHERE DMT_Opportunity__c = :opp.Id];
        Assert.areEqual(1, created.size(), 'One approval Line');
        Assert.areEqual(DMT_Constants.APPROVAL, created[0].Status__c, 'The Line is created in Approval');
        Assert.isNotNull(created[0].Line_Id__c, 'The external code comes from the integration service');
    }

    @IsTest
    static void createFromOpportunity_subsidiaryCreatesLinePassportAndLinksTheOpportunity() {
        Opportunity opp = createOpportunity('Subsidiary');

        Test.startTest();
        Id lineId = DMT_SanctionLine_Service.createFromOpportunity(opp.Id);
        Test.stopTest();

        Assert.isNotNull(lineId, 'A Subsidiary client always gets the Sanction Line back');
        DMT_Line__c line = [SELECT Status__c, DMT_Opportunity__c, Start_Date__c, End_Date__c FROM DMT_Line__c WHERE Id = :lineId];
        Assert.areEqual(DMT_Constants.APPROVAL, line.Status__c, 'Approval Line');
        Assert.areEqual(opp.Id, line.DMT_Opportunity__c, 'Related to the Opportunity');
        Assert.areEqual(line.Start_Date__c.addMonths(3), line.End_Date__c, 'Three months of life');
        Assert.areEqual(1, [SELECT COUNT() FROM Passport__c WHERE DMT_Line__c = :lineId], 'The Line Passport is created');
        Assert.areEqual(lineId, [SELECT DMT_Sanction__c FROM Opportunity WHERE Id = :opp.Id].DMT_Sanction__c, 'The Opportunity is linked');
    }

    @IsTest
    static void createFromOpportunity_multiholderCreatesAssociationAndClients() {
        Opportunity opp = createOpportunity('Group');
        Custom_Association_Opportunity__c association = DMT_Test_DataFactory.generateCustomAssociationOpportunity(
            opp.Id,
            new Map<Schema.SObjectField, Object>{
                Custom_Association_Opportunity__c.gf_customer_group_id__c => 'ESCD25LIN00006610ES',
                Custom_Association_Opportunity__c.g_group_id__c => 'TestGroupId',
                Custom_Association_Opportunity__c.g_customer_id__c => 'TestCustomerId'
            }
        );
        DMT_Test_DataFactory.generateCustomAssociationClientOpportunity(
            association.Id,
            opp.AccountId,
            new Map<Schema.SObjectField, Object>{
                DMT_Custom_Association_ClientOpportunity__c.DMT_g_customer_id__c => 'TestClientId'
            }
        );

        Test.startTest();
        Id lineId = DMT_SanctionLine_Service.createFromOpportunity(opp.Id);
        Test.stopTest();

        Assert.isNotNull(lineId, 'A Multiholder Opportunity returns the Sanction Line');
        DMT_Line__c line = [SELECT Custom_Association__c FROM DMT_Line__c WHERE Id = :lineId];
        Assert.isNotNull(line.Custom_Association__c, 'The Line points at the new association');
        Assert.areEqual(1, [SELECT COUNT() FROM Custom_Association_Client__c WHERE Custom_Association__c = :line.Custom_Association__c],
            'One association client per Opportunity holder');
    }
}
