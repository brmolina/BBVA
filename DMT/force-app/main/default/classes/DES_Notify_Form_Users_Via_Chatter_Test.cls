/**
*
* @author Global Desktop
*/
@isTest
public class DES_Notify_Form_Users_Via_Chatter_Test {
    /**
     * Test method for notificacionIndividual function
     */
    @isTest(SeeAllData=true) //NOSONAR
    public static void notifyFormUsers() {
        // Datos necesarios
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final List<User> userList = new List<User>();
        final String profileTest = utilTestClass.createProfile();
        final User userTest1 = utilTestClass.createUser(profileTest, '1@email.com');
        userTest1.DES_Disable_Chatter__c = false;
        userTest1.IsActive = true;
        userList.add(userTest1);
        final User userTest2 = utilTestClass.createUser(profileTest, '2@email.com');
        userTest2.DES_Disable_Chatter__c = false;
        userTest2.IsActive = true;
        userList.add(userTest2);
        insert userList;
        final Account acc = utilTestClass.createClient();
        insert acc;
        final Opportunity opportunityTest = utilTestClass.createOpportunity(acc);
        insert opportunityTest;
        final Inside_information_form__c form = new Inside_information_form__c();
        //form.Opportunity__c = opportunityTest.Id;
        final List<DES_Notify_Form_Users_Via_Chatter.ChatterCompliance> lstChttrCmplnc = new List<DES_Notify_Form_Users_Via_Chatter.ChatterCompliance>();
        final DES_Notify_Form_Users_Via_Chatter.ChatterCompliance chttrCmplncElmnt = new DES_Notify_Form_Users_Via_Chatter.ChatterCompliance();
        chttrCmplncElmnt.form = form;
        chttrCmplncElmnt.userList = userList;
        lstChttrCmplnc.add(chttrCmplncElmnt);
        //Test
        Test.startTest();
        DES_Notify_Form_Users_Via_Chatter.notificacionIndividual(lstChttrCmplnc);
        Test.stopTest();
		System.assertNotEquals(null, form);
    }
}