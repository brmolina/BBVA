/**
*
* @author Global Desktop
*/
@isTest
public with sharing class Batch_UpdateOwnerVisitTeam_Test {
    /**
     * Test method for Batch_UpdateOwnerVisitTeam
     */
    @isTest
    public static void testMigrateOwner() {
        final dwp_kitv__Visit_validations_acc_cs__c customSetting = new dwp_kitv__Visit_validations_acc_cs__c(
            dwp_kitv__bypass__c = true,
            dwp_kitv__create_Owner_in_Team_management__c = true,
            dwp_kitv__days_to_create__c = 365,
            dwp_kitv__Remember_visits__c = false,
            dwp_kitv__User_Team_Member__c = true
        );

        insert customSetting;

        final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();
        final Account iAccount = iUtilClass.createClient();
        insert iAccount;

        final String profile = iUtilClass.createProfile();
        final User iUser = iUtilClass.createUser(profile);
        insert iUser;
        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;
		Test.startTest();

        final dwp_kitv__Visit__c iVisit = iUtilClass.createVisit(iAccount, iOpportunity);
        insert iVisit;

        List<dwp_kitv__Visit_Management_Team__c> listVisitMember = [SELECT Id
                                                                    FROM dwp_kitv__Visit_Management_Team__c
                                                                    WHERE dwp_kitv__visit_id__c = :iVisit.Id];
        delete listVisitMember;
            //final Batch_UpdateOwnerVisitTeam iBatch = new Batch_UpdateOwnerVisitTeam();
            Database.executeBatch(new Batch_UpdateOwnerVisitTeam(), 1);
        Test.stopTest();

        listVisitMember = [SELECT Id
                        FROM dwp_kitv__Visit_Management_Team__c
                        WHERE dwp_kitv__visit_id__c = :iVisit.Id];

        System.assertEquals(1, listVisitMember.size(), 'There is more than one owner for the opportunity or none');
    }
}