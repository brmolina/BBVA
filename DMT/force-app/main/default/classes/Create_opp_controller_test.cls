/**
 * @author Global Desktop
 */
@isTest
public class Create_opp_controller_test {
  /*
   * Test method for getRecordTypeId functions
   */
    @isTest
    public static void testController() {
        final String rtId = Create_opp_controller.getRecordTypeId('Opportunity', Label.DES_RT_ACC_Draft_Opportunity);
        system.assertNotEquals(null, rtId, 'Not null');
    }

   /*
   * Test method for getRecordTypeId functions
   */
    @isTest
    public static void testController4() {
        final String rtId = Create_opp_controller.getRecordTypeId('DES_Opportunity_Management_member__c', Label.RT_OPP_TEAM_MEMBER_INSIDE_INFO);
        system.assertNotEquals(null, rtId, 'Not null');
    }

    /*
     * Test method for getInstance functions
     */
    @isTest
    public static void testController1() {
        final Create_opp_controller instance = Create_opp_controller.getInstance();
        system.assertNotEquals(null, instance, 'msg');
    }


   /*
    * Test method for complianceQuestions functions
    */
    @isTest
    public static void testController2() {
        final Map<String,String> preguntas = Create_opp_controller.complianceQuestions();
        system.assertNotEquals(null, preguntas, 'nessage');
    }

    /*
   * Test method for getRecordTypeId functions
   */
    @isTest
    public static void testController3() {
        try {
            final String rtId1 = Create_opp_controller.getRecordTypeId('DES_Opportunity_Management_member__c' , 'Test');
            system.assertEquals(null, rtId1, 'Null');
        } catch(Exception e) {
            system.debug(e.getMessage());
        }
    }
}