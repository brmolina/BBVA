@IsTest
private with sharing class DMT_ExtractOpportunityByClientMapperTest {
    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'DMT Test Client',
            g_customer_id__c = 'CUST-001',
            DES_Group_Code__c = 'GRP-001'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'DMT Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            RecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId()
        );
        insert opp;
        DMT_Test_DataFactory.generateTestTreasuryLines();

    }


    @IsTest
    static void extractReturnsExpectedContract() {
        Account testAcc = [SELECT Id, g_customer_id__c, DES_Group_Code__c FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Object> result = DMT_ExtractOpportunityByClientMapper.extract(
            new Map<String, Object>{
                'originId' => testAcc.Id,
                'ClientId' => testAcc.g_customer_id__c,
                'groupCode' => testAcc.DES_Group_Code__c,
                'filteredLine' => '',
                'statusLine' => ''
            }
        );
        Test.stopTest();

        Assert.isNotNull(result, 'Result map must be returned');
        Assert.isTrue(result.containsKey('line'), 'Result must include line key');
        Assert.isTrue(result.containsKey('lineFil'), 'Result must include lineFil key');
        Assert.isTrue(result.containsKey('opp'), 'Result must include opp key');
        Assert.isTrue(result.containsKey('countType'), 'Result must include countType key');
        Assert.isTrue(result.containsKey('colLine'), 'Result must include colLine key');
        Assert.isTrue(result.containsKey('colOpp'), 'Result must include colOpp key');

        List<Object> opportunities = (List<Object>) result.get('opp');
        Assert.areEqual(1, opportunities.size(), 'Expected one opportunity in response');
        Assert.isTrue(((Map<String, Object>) opportunities[0]).containsKey('hasAccessOpp'),
            'Opportunity rows must include the effective access flag');

        List<Object> lines = (List<Object>) result.get('line');
        Assert.isFalse(lines.isEmpty(), 'Expected treasury lines in response');
        Assert.isTrue(((Map<String, Object>) lines[0]).containsKey('hasAccessLine'),
            'Line rows must include the effective access flag');
    }

    @IsTest
    static void callableActionExtractReturnsOutputMap() {
        Account testAcc = [SELECT Id FROM Account LIMIT 1];

        DMT_ExtractOpportunityByClientMapper mapper = new DMT_ExtractOpportunityByClientMapper();
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>{ 'originId' => testAcc.Id },
            'output' => new Map<String, Object>()
        };

        Test.startTest();
        Object callResult = mapper.call('extractOpportunityByClient', args);
        Test.stopTest();

        Map<String, Object> output = (Map<String, Object>) callResult;
        Assert.isTrue(output.containsKey('line'), 'Callable output must include line key');
        Assert.isTrue(output.containsKey('opp'), 'Callable output must include opp key');
        DMT_Line__c newLine = [SELECT Id,Name,Client__c,Product__c,Status__c,Booking_Geography__c,Start_Date__c,End_Date__c,DvP_Amount__c,DvP_Currency__c,FD_Amount__c,FD_Currency__c,Client_Type__c,Line_Details__c,Line_Id__c,Closed__c FROM DMT_Line__c LIMIT 1];
        DMT_ExtractOpportunityByClientMapper.toLineMap(newLine);
    }
}