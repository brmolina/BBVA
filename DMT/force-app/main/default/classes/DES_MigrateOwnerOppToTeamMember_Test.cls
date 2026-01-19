/**
*
* @author Global Desktop
*/
@isTest
public class DES_MigrateOwnerOppToTeamMember_Test {
    /**
     * Test method for DES_MigrateOwnerOppToTeamMember_Batch
     */
    @isTest
    public static void testMigrateOwner() {
        final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();
        final Account iAccount = iUtilClass.createClient();
        insert iAccount;

        final String profile = iUtilClass.createProfile();
        final User iUser = iUtilClass.createUser(profile);
        insert iUser;

        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;

        List<DES_Opportunity_Management_member__c> listOppMember = new List<DES_Opportunity_Management_member__c>();
        for(DES_Opportunity_Management_member__c iOppMember : [SELECT Id,
                                                                DES_Owner__c
                                                            FROM DES_Opportunity_Management_member__c
                                                            WHERE DES_Opportunity__c = :iOpportunity.Id]) {
            iOppMember.DES_Owner__c = false;
            listOppMember.add(iOppMember);
        }
        update listOppMember;

        final DES_Opportunity_Management_member__c iOppMember = new DES_Opportunity_Management_member__c(
            DES_Opportunity__c = iOpportunity.Id,
            DES_User__c = iUser.Id,
            DES_Owner__c = true,
            Name = iUser.Name);
        insert iOppMember;

        Test.startTest();
            final DES_MigrateOwnerOppToTeamMember_Batch iBatch = new DES_MigrateOwnerOppToTeamMember_Batch('SELECT Id FROM Opportunity');
            Database.executeBatch(iBatch, 1);
        Test.stopTest();

        listOppMember = [SELECT Id,
                            DES_Owner__c
                        FROM DES_Opportunity_Management_member__c
                        WHERE DES_Opportunity__c = :iOpportunity.Id
                            AND DES_Owner__c = true];

        System.assertEquals(1, listOppMember.size(), 'There is more than one owner for the opportunity or none');
    }

    /**
     * Test method for DES_MigrateOwnerOppToTeamMember_Batch
     */
    @isTest
    public static void testMigrateOwnerDeleted() {
        final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();
        final Account iAccount = iUtilClass.createClient();
        insert iAccount;

        final String profile = iUtilClass.createProfile();
        final User iUser = iUtilClass.createUser(profile);
        insert iUser;

        final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
        insert iOpportunity;

        List<DES_Opportunity_Management_member__c> listOppMember = new List<DES_Opportunity_Management_member__c>();
        for(DES_Opportunity_Management_member__c iOppMember : [SELECT Id,
                                                                DES_Owner__c
                                                            FROM DES_Opportunity_Management_member__c
                                                            WHERE DES_Opportunity__c = :iOpportunity.Id]) {
            iOppMember.DES_Owner__c = false;
            listOppMember.add(iOppMember);
        }
        delete listOppMember;

        Test.startTest();
            final DES_MigrateOwnerOppToTeamMember_Batch iBatch = new DES_MigrateOwnerOppToTeamMember_Batch('SELECT Id FROM Opportunity');
            Database.executeBatch(iBatch, 1);
        Test.stopTest();

        listOppMember = [SELECT Id,
                            DES_Owner__c
                        FROM DES_Opportunity_Management_member__c
                        WHERE DES_Opportunity__c = :iOpportunity.Id
                            AND DES_Owner__c = true];

        System.assertEquals(1, listOppMember.size(), 'There is more than one owner for the opportunity or none');
    }
}