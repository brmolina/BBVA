/**********************************************************************************
* @author       Global Desktop
* @date         19/05/2020
* @description  Test class for Visit_Management_Team_Helper
**********************************************************************************/
@isTest
public with sharing class Visit_Management_Team_Test {
  /*
  * @author Global Desktop
  * @description test1
  */
  @isTest
  public static void test1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account iAccount = utilTestClass.createClient();
    insert iAccount;

    final Opportunity iOpportunity = utilTestClass.createOpportunity(iAccount);
    insert iOpportunity;

    final pith__Pitch__c iPitch = new pith__Pitch__c();
    iPitch.pith__participant_id__c = iAccount.Id;
    iPitch.pith__solution_category_name__c = 'GTB';
    iPitch.pith__solution_name_path_desc__c = 'Cash Management';
    insert iPitch;

    final dwp_kitv__Visit__c iVisit = utilTestClass.createVisit(iAccount, iOpportunity);
    insert iVisit;

    Test.StartTest();
      dwp_kitv__Visit_Topic__c iVisitTopic = new dwp_kitv__Visit_Topic__c();
        iVisitTopic.dwp_kitv__visit_id__c = iVisit.Id;
        iVisitTopic.pith__pitch_visit_topic_id__c = iPitch.id;
        iVisitTopic.dwp_kitv__topic_desc__c = 'VISIT TOPIC TEST';
      insert iVisitTopic;

      final String iProfile = utilTestClass.createProfile();
      final User iUser = utilTestClass.createUser(iProfile);
      iUser.Email = 'testalertuser@test.com';
      insert iUser;

      dwp_kitv__Visit_Management_Team__c iVisitMT = new dwp_kitv__Visit_Management_Team__c();
      iVisitMT.dwp_kitv__visit_id__c = iVisit.Id;
      iVisitMT.dwp_kitv__user_id__c = iUser.Id;
      insert iVisitMT;
      delete iVisitMT;

      System.assertNotEquals(iAccount,null);
    Test.StopTest();
  }
}