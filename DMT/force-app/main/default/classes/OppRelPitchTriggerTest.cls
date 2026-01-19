/*
* @author Global Desktop
* @description Test del trigger OppRelPitchTrigger
*/
@isTest
public class OppRelPitchTriggerTest {

  /*
  * @author Global Desktop
  * @description Testeo del trigger OppRelPitchTrigger
  */
  @isTest
  public static void OppRelPitchTest() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account acc1 = utilTestClass.createClient();
    insert acc1;
    final Opportunity opp1 = utilTestClass.createOpportunity(acc1);
    insert opp1;
    final pith__Pitch__c pitchTest = new pith__Pitch__c();
    pitchTest.pith__participant_id__c = acc1.Id;
    pitchTest.pith__solution_category_name__c = 'GTB';
    pitchTest.pith__solution_name_path_desc__c = 'Cash Management';
    insert pitchTest;
    final pith__Related_opportunity_pitch__c relOppPitch = new pith__Related_opportunity_pitch__c();
    relOppPitch.pith__opportunity_pitch_id__c = opp1.Id;
    relOppPitch.pith__pitch_opportunity_id__c = pitchTest.Id;
    insert relOppPitch;
    Test.StartTest();
      final String profileUsr = utilTestClass.createProfile();
      final User usr = utilTestClass.createUser(profileUsr);
      usr.Email = 'testalertuser@test.com';
      insert usr;

      DES_Opportunity_Management_member__c iOpportunityMM = new DES_Opportunity_Management_member__c();
      iOpportunityMM.DES_Opportunity__c = opp1.Id;

      iOpportunityMM.DES_User__c = usr.Id;
      insert iOpportunityMM;
      delete iOpportunityMM;
      System.assertNotEquals(acc1,null);
    Test.StopTest();
  }

}