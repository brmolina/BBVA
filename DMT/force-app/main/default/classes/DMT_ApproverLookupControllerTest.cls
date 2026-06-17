@isTest
private without sharing class DMT_ApproverLookupControllerTest {

    private static final String ENTIFIC_ES = 'ES';
    private static final String ENTIFIC_MX = 'MX';

    @testSetup
    static void setupData() {
        // Tipos de approver
        DMT_Approver_Type__c riskType = new DMT_Approver_Type__c(
            Name = 'Risk',
            DMT_External_Id__c = '32'
        );
        DMT_Approver_Type__c globalBankerType = new DMT_Approver_Type__c(
            Name = 'Global Banker',
            DMT_External_Id__c = '42'
        );
        insert new List<DMT_Approver_Type__c>{ riskType, globalBankerType };

        // Approvers activos válidos para búsquedas
        DMT_Approver__c riskApproverByName = new DMT_Approver__c(
            Name = 'Alpha Risk Team',
            DMT_ApproverType__c = riskType.Id,
            DMT_Is_Active__c = true,
            DMT_Entific__c = ENTIFIC_ES,
            DMT_External_Id__c = '11',
            DMT_Approver_Code__c = '11'
        );

        DMT_Approver__c riskApproverByMember = new DMT_Approver__c(
            Name = 'Beta Review Committee',
            DMT_ApproverType__c = riskType.Id,
            DMT_Is_Active__c = true,
            DMT_Entific__c = ENTIFIC_ES,
            DMT_External_Id__c = '22',
            DMT_Approver_Code__c = '22'
        );

        DMT_Approver__c gbApprover = new DMT_Approver__c(
            Name = 'Global Banker Team',
            DMT_ApproverType__c = globalBankerType.Id,
            DMT_Is_Active__c = true,
            DMT_Entific__c = ENTIFIC_ES,
            DMT_External_Id__c = '33',
            DMT_Approver_Code__c = '33'
        );

        // No debería salir por estar inactivo
        DMT_Approver__c inactiveApprover = new DMT_Approver__c(
            Name = 'Inactive Risk Team',
            DMT_ApproverType__c = riskType.Id,
            DMT_Is_Active__c = false,
            DMT_Entific__c = ENTIFIC_ES,
            DMT_External_Id__c = '44',
            DMT_Approver_Code__c = '44'
        );

        // No debería salir por distinta entific
        DMT_Approver__c differentEntificApprover = new DMT_Approver__c(
            Name = 'Other Country Risk Team',
            DMT_ApproverType__c = riskType.Id,
            DMT_Is_Active__c = true,
            DMT_Entific__c = ENTIFIC_MX,
            DMT_External_Id__c = '55',
            DMT_Approver_Code__c = '55'
        );

        insert new List<DMT_Approver__c>{
            riskApproverByName,
            riskApproverByMember,
            gbApprover,
            inactiveApprover,
            differentEntificApprover
        };

        // Miembros
        Id currentUserId = UserInfo.getUserId();

        insert new List<DMT_Approver_Member__c>{
            new DMT_Approver_Member__c(
                Name = 'Member Alpha',
                DMT_Approver__c = riskApproverByName.Id,
                DMT_User__c = currentUserId
            ),
            new DMT_Approver_Member__c(
                Name = 'Member Beta',
                DMT_Approver__c = riskApproverByMember.Id,
                DMT_User__c = currentUserId
            ),
            new DMT_Approver_Member__c(
                Name = 'Member GB',
                DMT_Approver__c = gbApprover.Id,
                DMT_User__c = currentUserId
            )
        };
    }

    @IsTest
    static void testSearchApprovers_ByApproverName_RiskField() {
        Test.startTest();
        List<DMT_ApproverLookupController.LookupResult> results =
            DMT_ApproverLookupController.searchApprovers(
                'Alpha',
                10,
                null,
                ENTIFIC_ES,
                'DMT_Approver__c'
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Debe devolver un approver por nombre');
        System.assertEquals('Alpha Risk Team', results[0].name);
        System.assertEquals('Risk', results[0].subtitle);
        System.assertEquals(ENTIFIC_ES, results[0].entific);
        System.assertEquals('standard:people', results[0].icon);
        System.assertNotEquals(null, results[0].members);
        System.assertEquals(1, results[0].members.size(), 'Debe traer miembros relacionados');
        System.assertEquals('Member Alpha', results[0].members[0].name);
    }

    @IsTest
    static void testSearchApprovers_ByMemberUserName() {
        User currentUser = [
            SELECT Id, Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        String searchTerm = currentUser.Name.length() >= 2
            ? currentUser.Name.substring(0, 2)
            : currentUser.Name;

        Test.startTest();
        List<DMT_ApproverLookupController.LookupResult> results =
            DMT_ApproverLookupController.searchApprovers(
                searchTerm,
                10,
                null,
                ENTIFIC_ES,
                'DMT_Booking_Unit_Risk_Analyst__c'
            );
        Test.stopTest();

        System.assert(results.size() > 0, 'Debe encontrar approvers por nombre del usuario miembro');

        Boolean foundAlpha = false;
        Boolean foundBeta = false;

        for (DMT_ApproverLookupController.LookupResult result : results) {
            if (result.name == 'Alpha Risk Team') {
                foundAlpha = true;
            }
            if (result.name == 'Beta Review Committee') {
                foundBeta = true;
            }
        }

        System.assertEquals(true, foundAlpha, 'Debe incluir Alpha Risk Team');
        System.assertEquals(true, foundBeta, 'Debe incluir Beta Review Committee');
    }

    @IsTest
    static void testSearchApprovers_GlobalBankerField() {
        Test.startTest();
        List<DMT_ApproverLookupController.LookupResult> results =
            DMT_ApproverLookupController.searchApprovers(
                'Global',
                10,
                null,
                ENTIFIC_ES,
                'DMT_ApproverGlobalBanker__c'
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Global Banker Team', results[0].name);
        System.assertEquals('Global Banker', results[0].subtitle);
    }

    @IsTest
    static void testSearchApprovers_SearchTermTooShort() {
        Test.startTest();
        List<DMT_ApproverLookupController.LookupResult> results =
            DMT_ApproverLookupController.searchApprovers(
                'A',
                10,
                null,
                ENTIFIC_ES,
                'DMT_Approver__c'
            );
        Test.stopTest();

        System.assertEquals(0, results.size(), 'No debe buscar con menos de 2 caracteres');
    }

    @IsTest
    static void testGetApproverById() {
        DMT_Approver__c approver = [
            SELECT Id, Name
            FROM DMT_Approver__c
            WHERE Name = 'Alpha Risk Team'
            LIMIT 1
        ];

        Test.startTest();
        DMT_ApproverLookupController.LookupResult result =
            DMT_ApproverLookupController.getApproverById(approver.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(approver.Id, result.id);
        System.assertEquals('Alpha Risk Team', result.name);
        System.assertEquals('Risk', result.subtitle);
        System.assertEquals(ENTIFIC_ES, result.entific);
        System.assertEquals(1, result.members.size());
        System.assertEquals('Member Alpha', result.members[0].name);
    }

    @IsTest
    static void testGetApproverById_Null() {
        Test.startTest();
        DMT_ApproverLookupController.LookupResult result =
            DMT_ApproverLookupController.getApproverById(null);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @IsTest
    static void testGetRecentApprovers() {
        Test.startTest();
        List<DMT_ApproverLookupController.LookupResult> results =
            DMT_ApproverLookupController.getRecentApprovers(3);
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Debe devolver los N approvers solicitados');

        for (DMT_ApproverLookupController.LookupResult result : results) {
            System.assertNotEquals(null, result.id);
            System.assertNotEquals(null, result.name);
        }
    }
}