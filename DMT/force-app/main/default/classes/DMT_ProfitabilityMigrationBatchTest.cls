@IsTest
private class DMT_ProfitabilityMigrationBatchTest {

    @testSetup
    static void setupData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        OpportunityLineItem oli = DMT_Test_DataFactory.generateOpportunityLineItem(opp);
        oli.gf_group_priority_opportunity_id__c = '01';
        update oli;

        String jsonPassport = '{' +
            '"data": {' +
                '"features": [' +
                    '{' +
                        '"name": "Profitability Engine",' +
                        '"profitability": {' +
                            '"results": [' +
                                '{' +
                                    '"allInDb": 11.111111,' +
                                    '"allInFb": 22.222222,' +
                                    '"economicEad": 1000.12,' +
                                    '"regulatoryEad": 2000.23,' +
                                    '"regulatoryCapital": 3000.34,' +
                                    '"economicCapital": 4000.45,' +
                                    '"franchiseDeal": 5000.56,' +
                                    '"bdiEco": 6000.67,' +
                                    '"bdiReg": 7000.78,' +
                                    '"rorc": 0.1111,' +
                                    '"raroec": 0.2222,' +
                                    '"economicApr": 8000.89,' +
                                    '"regulatoryApr": 9000.91,' +
                                    '"rorcProspected": 0.3333,' +
                                    '"clientRorc": 0.4444' +
                                '},' +
                                '{' +
                                    '"productId": "01",' +
                                    '"isLine": true,' +
                                    '"allInDb": 2.111111,' +
                                    '"allInFb": 2.222222,' +
                                    '"economicEad": 2100.12,' +
                                    '"regulatoryEad": 2200.23,' +
                                    '"regulatoryCapital": 2300.34,' +
                                    '"economicCapital": 2400.45,' +
                                    '"franchiseDeal": 2500.56,' +
                                    '"bdiEco": 2600.67,' +
                                    '"bdiReg": 2700.78,' +
                                    '"rorc": 0.1212,' +
                                    '"raroec": 0.1313,' +
                                    '"economicApr": 2800.89,' +
                                    '"regulatoryApr": 2900.91,' +
                                    '"rorcProspected": 0.1414' +
                                '}' +
                            ']' +
                        '}' +
                    '}' +
                ']' +
            '}' +
        '}';

        insert new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = jsonPassport
        );
    }

    @IsTest
    static void testBatchMigrationSuccessfully() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];

        Test.startTest();
        Database.executeBatch(new DMT_ProfitabilityMigrationBatch(), 1);
        Test.stopTest();

        Opportunity refreshedOpp = [
            SELECT DMT_Allin_Drawn__c, DMT_Global_Expected_RORC__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        OpportunityLineItem refreshedOli = [
            SELECT DMT_Allin_Drawn__c, DMT_RORC__c
            FROM OpportunityLineItem
            WHERE Id = :oli.Id
        ];

        System.assertEquals(11.111111, refreshedOpp.DMT_Allin_Drawn__c);
        System.assertEquals(0.4444, refreshedOpp.DMT_Global_Expected_RORC__c);
        System.assertEquals(2.111111, refreshedOli.DMT_Allin_Drawn__c);
        System.assertEquals(0.1212, refreshedOli.DMT_RORC__c);
    }
}