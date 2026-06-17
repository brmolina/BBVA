@isTest
private without sharing class DMT_CaseOwnerType_Handler_Test {

    private static String randomToken() {
        // Token alfanumérico válido para DeveloperName de Group
        // (sin puntos, sin underscores, empieza por letra).
        String raw = String.valueOf(Math.abs(Crypto.getRandomLong()));
        return 'X' + raw;
    }

    /**
     * Crea una Queue (Group + QueueSobject para Case) en contexto runAs
     * para evitar Mixed DML al combinar después con inserts de Case.
     */
    private static Group createCaseQueue(String devName) {
        Group g = new Group(
            Name = 'UT Queue ' + devName,
            DeveloperName = devName,
            Type = 'Queue'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert g;
            insert new QueueSobject(QueueId = g.Id, SobjectType = 'Case');
        }
        return g;
    }

    private static DMT_Approver_Type__c createApproverType(String typeName) {
        DMT_Approver_Type__c t = new DMT_Approver_Type__c(
            Name = typeName,
            DMT_External_Id__c = 'UTTYPE' + randomToken()
        );
        insert t;
        return t;
    }

    /**
     * Crea el Approver apuntando al DeveloperName de la cola dada.
     * Si el flow After Trigger DMT_Approver lo sobrescribe, lo restauramos
     * con un update para garantizar la relación.
     */
    private static DMT_Approver__c createApproverForQueue(Id approverTypeId, String groupDevName) {
        String token = randomToken();
        DMT_Approver__c a = new DMT_Approver__c(
            Name = 'UTApprover' + token,
            DMT_External_Id__c = 'UTAPP' + token,
            DMT_Approver_Code__c = 'UTCODE' + token,
            DMT_ApproverType__c = approverTypeId,
            DMT_Group__c = groupDevName
        );
        insert a;

        DMT_Approver__c reloaded = [
            SELECT Id, DMT_Group__c
            FROM DMT_Approver__c
            WHERE Id = :a.Id
            LIMIT 1
        ];
        if (reloaded.DMT_Group__c != groupDevName) {
            reloaded.DMT_Group__c = groupDevName;
            update reloaded;
        }
        return reloaded;
    }

    private static Case createOpportunityCase(Id oppId, Id ownerQueueId, String sanctionValue) {
        Case c = DMT_Test_DataFactory.generateCase(null, oppId, ownerQueueId);
        c.DMT_Passport_Sanction__c = sanctionValue;
        update c;
        return c;
    }

    @isTest
    static void testGetOwnerCaseType_UpdatesDate_WhenBusinessAndPassport() {
        String token = randomToken();
        Group q = createCaseQueue('UTQ' + token);

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Approver_Type__c businessType = createApproverType('Business');
        createApproverForQueue(businessType.Id, q.DeveloperName);
        Case c = createOpportunityCase(opp.Id, q.Id, 'approval');

        Test.startTest();
        DMT_CaseOwnerType_Handler.ResponseWrapper result = DMT_CaseOwnerType_Handler.getOwnerCaseType(c.Id);
        Test.stopTest();

        Opportunity oppAfter = [SELECT DMT_Bussiness_Approved_Date__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(Date.today(), oppAfter.DMT_Bussiness_Approved_Date__c, 'Business approved date must be updated to today.');
        System.assertEquals(true, result.updated, 'Response should indicate update executed.');
    }

    @isTest
    static void testGetOwnerCaseType_DoesNotUpdate_WhenSanctionIsNotAllowed() {
        String token = randomToken();
        Group q = createCaseQueue('UTQ' + token);

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Approver_Type__c businessType = createApproverType('Business');
        createApproverForQueue(businessType.Id, q.DeveloperName);
        Case c = createOpportunityCase(opp.Id, q.Id, 'draft');

        Test.startTest();
        DMT_CaseOwnerType_Handler.ResponseWrapper result = DMT_CaseOwnerType_Handler.getOwnerCaseType(c.Id);
        Test.stopTest();

        Opportunity oppAfter = [SELECT DMT_Bussiness_Approved_Date__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(null, oppAfter.DMT_Bussiness_Approved_Date__c, 'Date must not be updated for non-allowed sanction values.');
        System.assertEquals(false, result.updated, 'Response should not indicate update.');
    }

    @isTest
    static void testGetOwnerCaseType_DoesNotUpdate_WhenApproverTypeIsNotBusiness() {
        String token = randomToken();
        Group q = createCaseQueue('UTQ' + token);

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Approver_Type__c riskType = createApproverType('Risk');
        createApproverForQueue(riskType.Id, q.DeveloperName);
        Case c = createOpportunityCase(opp.Id, q.Id, 'readytoclose');

        Test.startTest();
        DMT_CaseOwnerType_Handler.ResponseWrapper result = DMT_CaseOwnerType_Handler.getOwnerCaseType(c.Id);
        Test.stopTest();

        Opportunity oppAfter = [SELECT DMT_Bussiness_Approved_Date__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(null, oppAfter.DMT_Bussiness_Approved_Date__c, 'Date must not be updated when approver type is not Business.');
        System.assertEquals(false, result.updated, 'Response should not indicate update.');
    }

    @isTest
    static void testCall_InvokesGetOwnerCaseType() {
        String token = randomToken();
        Group q = createCaseQueue('UTQ' + token);

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        DMT_Approver_Type__c businessType = createApproverType('Business');
        createApproverForQueue(businessType.Id, q.DeveloperName);
        Case c = createOpportunityCase(opp.Id, q.Id, 'approval');

        Map<String, Object> input = new Map<String, Object>{ 'caseId' => c.Id };
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => input,
            'output' => output,
            'options' => options
        };

        Test.startTest();
        DMT_CaseOwnerType_Handler handler = new DMT_CaseOwnerType_Handler();
        Object res = handler.call('getOwnerCaseType', args);
        Test.stopTest();

        System.assertNotEquals(null, res, 'call() should return the output map.');


    }

    @isTest
    static void testCall_UnsupportedMethod_Throws() {
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Boolean threw = false;
        Test.startTest();
        try {
            new DMT_CaseOwnerType_Handler().call('notAValidMethod', args);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Unsupported method should throw an exception.');
    }

    @isTest
    static void testGetOwnerCaseType_BlankCaseId_Throws() {
        Boolean threw = false;
        Test.startTest();
        try {
            DMT_CaseOwnerType_Handler.getOwnerCaseType(null);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Blank caseId should throw an exception.');
    }

    @isTest
    static void testGetOwnerCaseType_DoesNotUpdate_WhenOwnerIsNotQueue() {
        // Caso con Owner = User (no Group), debe salir por la condición principal sin actualizar.
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, UserInfo.getUserId());
        c.DMT_Passport_Sanction__c = 'approval';
        update c;

        Test.startTest();
        DMT_CaseOwnerType_Handler.ResponseWrapper result =
            DMT_CaseOwnerType_Handler.getOwnerCaseType(c.Id);
        Test.stopTest();

        Opportunity oppAfter = [SELECT DMT_Bussiness_Approved_Date__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(null, oppAfter.DMT_Bussiness_Approved_Date__c, 'Date must not be updated when owner is not a Queue.');
        System.assertEquals(false, result.updated, 'Response should not indicate update.');
    }
}