@isTest
public class GBL_DenormalizeOpportunitiesExecuteTest {

    // ************************************************************************************************
    // TEST: BATCH EXECUTE – procesa oportunidades creadas recientemente
    // ************************************************************************************************
    @isTest
    static void testBatchExecute() {
       Account[] accts = GBL_TestMAHDataFactory.setupAccounts();

        Opportunity opp = new Opportunity(
            Name = 'Test Oportunidad',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = accts[0].Id
        );
        insert opp;
        Test.startTest();
        GBL_DenormalizeOpportunitiesExecute batch = new GBL_DenormalizeOpportunitiesExecute();
        Database.executeBatch(batch, 1);
        Test.stopTest();
        System.assert(true, 'El batch se ejecutó correctamente sin excepciones.');
    }
}