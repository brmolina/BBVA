/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class GDT_Block_Studies_Controller_Test {

    @isTest
    static void testGetTableData() {
        Account grupo = new Account(Name = 'Test Group');
        insert grupo;

        // Crear propuesta vinculada al grupo
        arce__SP2_Proposal__c proposal = new arce__SP2_Proposal__c(
            arce__main_group__c = grupo.Id,
            arce__Stage__c = '1',
            arce__SanctSanctionDate_Fin__c = Date.today(),
            arce__proposalExternalID__c = 'PR99992536'
        );
        insert proposal;

        Test.startTest();
        List<Map<String, Object>> result = GDT_Block_Studies_Proposal_Controller.getTableData(grupo.Id);
        Test.stopTest();

        // Asserts
        System.assertNotEquals(null, result, 'El resultado no debe ser null');
    }
}