/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_TabSetChecker_Corp_Test
* @author      marcos.gimeno.tech@bbva.com
* @date        05-04-2024
*
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Test class for Arc_Gen_TabSetChecker_Corp
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         marcos.gimeno.tech@bbva.com
* 05-04-2024   Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_Gen_TabSetChecker_Corp_Test {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test setup
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        05-04-2024
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        final List<User> testUsers = [SELECT Id,gf_user_operation_ambit_name__c FROM User WHERE Profile.Name = 'BBVA Standard User' AND IsActive = TRUE AND gf_user_operation_ambit_name__c = 'CIB - R3 - CIB Europe'];
        User testUser;

        if (testUsers.isEmpty()){
            testUser = arce.Arc_UtilitiesToTest_tst.crearUsuario('Test User', 'System Administrator', null);
            insert testUser;
        } else {
            testUser = testUsers[0];
        }

        final List<PermissionSet> testPsets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN :Arc_Gen_TabSetChecker_Corp.REQUIRED_PS
        ];
        
        final Set<Id> psetIds = new Set<Id>();
        for (PermissionSet pset : testPsets) {
            psetIds.add(pset.Id);
        }

        final List<PermissionSetAssignment> psetAssigns = [
            SELECT Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id
            AND PermissionSetId IN :psetIds
        ];

        final Set<Id> psetAssignIds = new Set<Id>();
        for (PermissionSetAssignment psetAssign : psetAssigns) {
            psetAssignIds.add(psetAssign.PermissionSetId);
        }

        final List<PermissionSetAssignment> testPsetAssigns = new List<PermissionSetAssignment>();
        for (PermissionSet pset : testPsets) {
            if (!psetAssignIds.contains(pset.Id)) {
                final PermissionSetAssignment psetAssign = new PermissionSetAssignment();
                psetAssign.AssigneeId = testUser.Id;
                psetAssign.PermissionSetId = pset.Id;
                testPsetAssigns.add(psetAssign);
            }
        }

        if (!testPsetAssigns.isEmpty()) {
            insert testPsetAssigns;
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Test hasPermissions method
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        05-04-2024
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testHasPermissions() {
        final List<User> testUsers = [SELECT Id,gf_user_operation_ambit_name__c FROM User WHERE Profile.Name = 'BBVA Standard User' AND IsActive = TRUE AND gf_user_operation_ambit_name__c = 'CIB - R3 - CIB Europe'];
        User testUser;

        if (testUsers.isEmpty()){
            testUser = [SELECT Id FROM User WHERE Name = 'Test User' AND Profile.Name = 'System Administrator' LIMIT 1];
        } else {
            testUser = testUsers[0];
        }
        
        final Id fakeId = arce.Arc_UtilitiesToTest_tst.generateFakeId(arce__Account_has_Analysis__c.sObjectType, '1');

        System.runAs(testUser) {
            final Arc_Gen_TabSetChecker_Corp checker = new Arc_Gen_TabSetChecker_Corp();
            final Boolean result = checker.hasPermissions(fakeId);

            System.assertEquals(true, result, 'Expected the user to have permissions');
        }
    }
}