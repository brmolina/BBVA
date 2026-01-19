@isTest
private class DES_Simple_Table_Controller_Test {

    @isTest
    static void DES_Simple_Table_Controller_Test(){
        // Datos necesarios
        DES_Simple_Table_Controller testClass = new DES_Simple_Table_Controller();
        DES_UtilTestClass utilsTestClass = new DES_UtilTestClass();
        Account acc = utilsTestClass.createClient();
        insert acc; 
        
        // Test
        Test.startTest();
        acc = DES_Simple_Table_Controller.getAccountData(acc.Id);
        Test.stopTest();
	}
}