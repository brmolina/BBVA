/**
*
* @author Global Desktop
*/
@isTest
public with sharing class Batch_UpdateInboundVisit_Test {
    /**
     * Test method for Batch_UpdateOwnerVisitTeam
     */
    @isTest
    public static void testUpdateInboundVisit() {
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

        dwp_kitv__Visit__c iVisit = iUtilClass.createVisit(iAccount, iOpportunity);
        insert iVisit;

        Test.startTest();
            final Batch_UpdateInboundVisit iBatch = new Batch_UpdateInboundVisit();
            Database.executeBatch(iBatch, 1);
        Test.stopTest();

        iVisit = [SELECT Id,
                    visit_type__c
                FROM dwp_kitv__Visit__c
                LIMIT 1];
        System.assertEquals('Inbound', iVisit.visit_type__c, 'The visit is not inbound');
    }
}