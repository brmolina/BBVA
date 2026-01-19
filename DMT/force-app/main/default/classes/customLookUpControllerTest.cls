@isTest
private class customLookUpControllerTest {

    @isTest
    static void customLookUpControllerTest(){
        // Datos necesarios
        customLookUpController testClass = new customLookUpController();
        DES_UtilTestClass utilsTestClass = new DES_UtilTestClass();
        String profile = utilsTestClass.createProfile();
        User user = utilsTestClass.createUser(profile);
        insert user; 
        List < sObject > returnList1 = new List < sObject > (); 
        List < sObject > returnList2 = new List < sObject > ();
        List < sObject > returnList3 = new List < sObject > ();
        List < sObject > returnList4 = new List < sObject > ();
        List < sObject > returnList5 = new List < sObject > ();
        
        // Test
        Test.startTest();
            returnList1 = customLookUpController.fetchLookUpValues('User', 'User','', true, true, 'FirstName','');
            returnList2 = customLookUpController.fetchLookUpValues('Product', 'Product2','IBF', true, false, 'Name','');
            returnList3 = customLookUpController.fetchLookUpValues('Opportunity', 'Opportunity','', false, true, 'Name','');
            returnList4 = customLookUpController.fetchLookUpValues('User', 'User','', false, true, 'FirstName','');
            returnList5 = customLookUpController.fetchLookUpValues('Product', 'Product2','IBF', false, false, 'Name','');
            System.debug(returnList1);
            boolean assert = false;
            if (returnList1.size() > 0) {
                assert = true;
            }
            System.assertEquals(assert, true);
        Test.stopTest();
    }

}