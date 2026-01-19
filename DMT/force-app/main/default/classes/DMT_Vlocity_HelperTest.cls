@isTest
private class DMT_Vlocity_HelperTest {

@isTest
    static void testIsNotEmpty() {
        System.assertEquals(false, DMT_Vlocity_Helper.isNotEmpty('{}'),'Are not equals');
        System.assertEquals(true, DMT_Vlocity_Helper.isNotEmpty('Test'),'Are not equals');
        System.assertEquals(false, DMT_Vlocity_Helper.isNotEmpty(null),'Are not equals');
    }
}