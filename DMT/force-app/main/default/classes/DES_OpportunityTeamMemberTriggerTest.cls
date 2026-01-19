@isTest
private class DES_OpportunityTeamMemberTriggerTest{

	@isTest
    public static void testTrigger(){
        //Datos necesarios
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest = utilTestClass.createUser(profileTest);   
        insert userTest;
        CIB_User_Org__c userOrgTest = utilTestClass.createCustomSetting();
        insert userOrgTest;
        
        //Test
        Test.startTest();
        Account acc = utilTestClass.createClient();
        insert acc;
        Opportunity opportunityTest = utilTestClass.createOpportunity(acc);
        insert opportunityTest;
        OpportunityTeamMember oppTeamMemberTest = utilTestClass.oppTeamMember(opportunityTest,userTest);       
        oppTeamMemberTest.TeamMemberRole = 'Product Specialist';     
        system.debug('>>>>> oppTeamMemberTest : ' + oppTeamMemberTest);   
        insert oppTeamMemberTest;
        delete oppTeamMemberTest;
        Test.stopTest();
    }

}