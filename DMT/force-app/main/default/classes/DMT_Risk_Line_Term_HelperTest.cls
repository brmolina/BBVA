@isTest
public class DMT_Risk_Line_Term_HelperTest {

    @TestSetup
    static void makeData(){
        DMT_Test_DataFactory.generateTestTreasuryLines();
    }

    @isTest
    static void testUpdateLastModifiedByHuman() {
        DMT_Risk_Line_Term__c riskLineTerm = [SELECT Id, Name, DMT_Init_Term__c FROM DMT_Risk_Line_Term__c WHERE Name LIKE '%rsk line term 1' LIMIT 1];

        Test.startTest();
        riskLineTerm.DMT_Init_Term__c = '1';
        update riskLineTerm;
        Test.stopTest();

        riskLineTerm = [SELECT Last_Modified_By_Human__c FROM DMT_Risk_Line_Term__c WHERE Id = :riskLineTerm.Id];
        Assert.isNotNull(riskLineTerm.Last_Modified_By_Human__c, 'Last Modified By Human should not be null');
    }
}