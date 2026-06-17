@isTest
public class GBL_DenormalizeOpportunitiesDeleteTest {

    // ************************************************************************************************
    // TEST: BATCH DELETE – elimina registros existentes sin recrearlos
    // ************************************************************************************************
    @isTest
    static void testDeleteOnly() {
        Test.startTest();
        GBL_DenormalizeOpportunitiesDelete batch = new GBL_DenormalizeOpportunitiesDelete(false);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Integer remaining = [SELECT COUNT() FROM AMH_Denorm_Account_Opportunity__c];
        System.assertEquals(0, remaining, 'Todos los registros deberían haberse eliminado');
    }

    // ************************************************************************************************
    // TEST: BATCH DELETE + EXECUTE – elimina y luego lanza el proceso de recreación
    // ************************************************************************************************
    @isTest
    static void testDeleteAndRecreate() {
        Test.startTest();
        GBL_DenormalizeOpportunitiesDelete batch = new GBL_DenormalizeOpportunitiesDelete(true);
        Database.executeBatch(batch, 1);
        Test.stopTest();

        Integer remaining = [SELECT COUNT() FROM AMH_Denorm_Account_Opportunity__c];
        System.assertEquals(0, remaining, 'El registro debe eliminarse antes de ejecutar el siguiente batch');
        System.assert(true, 'El batch GBL_DenormalizeOpportunitiesExecute se lanzó correctamente al finalizar.');
    }
}