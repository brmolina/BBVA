@isTest
public class DES_BatchOppTMInMigrationOppTest {
    
    @isTest
    public static void DES_BatchOppTMInMigrationOppTest(){
        
        
         DES_UtilTestClass testClass = new DES_UtilTestClass();
        Profile prof = [select Id FROM Profile WHERE Name = 'Desktop Integration' LIMIT 1];
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(prof.Id);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Account acc = testClass.createClient();
        	insert acc;
        	list<Opportunity> oppList = new list<Opportunity>();
            Opportunity opp = testClass.createOpportunity(acc); 
            opp.StageName = LABEL.DES_Proposal; 
            opp.OwnerId = userTest.Id;
            opp.DES_Countries__c = 'BE;AR';
            oppList.add(opp);
            //insert opp;
            Opportunity opp2 = testClass.createOpportunity(acc); 
            opp2.StageName = LABEL.DES_Draft;
            opp2.createdBy = userTest;
            opp2.DES_Countries__c = 'BE;AR';
            oppList.add(opp2);
            insert oppList;
            list<DES_BBVA_Management_team__c> oppTeamList = new list<DES_BBVA_Management_team__c>();
            DES_BBVA_Management_team__c oppTeam1 = testClass.createBBVAManagementTeamMember(userTest,acc);
            oppTeam1.DES_Member_Role__c = Label.DES_ROLE_LOCAL_BANKER;
            oppTeam1.DES_Local_Banker_Country__c = 'AR';
            oppTeamList.add(oppTeam1);
            //insert oppTeam1;
            DES_BBVA_Management_team__c oppTeam2 = testClass.createBBVAManagementTeamMember(userTest,acc);
            oppTeamList.add(oppTeam2);
            Final DES_BBVA_Management_team__c oppTeam3 = testClass.createBBVAManagementTeamMember(userTest,acc);
            oppTeamList.add(oppTeam3);
            insert oppTeamList;
        	Test.startTest();
            Id batchInstanceId = Database.executeBatch(new DES_BatchOppTeamMembersInMigrationOpp(), 1);	
            system.assertNotEquals(oppTeam1,null,'Correcto');	
            Test.stopTest();
        }
    }
}