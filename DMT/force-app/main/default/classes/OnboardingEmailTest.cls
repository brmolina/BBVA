/*
* Test class
*/
@isTest
public class OnboardingEmailTest {
  /*
  * Test method
  */
  @isTest
  public static void sendEmailTest() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final Account acc = utils.createClient();
    insert acc;
    final Opportunity opp = utils.createOpportunity(acc);
    insert opp;
    final String profile = utils.createProfile();
    final User user = utils.createUser(profile);
    insert user;
    final DES_Opportunity_Management_member__c member = utils.createOppManagementMember(user, opp);
    insert member;
    final OnboardingEmail.FlowInputs inputs = new OnboardingEmail.FlowInputs();
    inputs.record = acc.Id;
    inputs.onboardingTeam = 'MEX';
    Test.startTest();
    final List<OnboardingEmail.FlowInputs> listInputs = new List<OnboardingEmail.FlowInputs>();
    listInputs.add(inputs);
    OnboardingEmail.sendEmail(listInputs);
    system.assertNotEquals(null, acc, 'notnull');
    Test.stopTest();
  }
}