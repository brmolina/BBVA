/***********************************************************************************************
Name:            NPS_CompleteTaskController_Test
Description:     Test Class for NPS_CompleteTaskController, its schedulable and handler

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            02/12/2019      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class NPS_CompleteTaskController_Test {
    /**
    * Me0d0 test uno
    */
	@isTest
    public static void NpsTaskTestOne() {
        Final DES_UtilTestClass utils = new DES_UtilTestClass();
        final NPS_CompleteTaskController npes = NPS_CompleteTaskController.getInstance();
        final String profile = utils.createProfile();
        final User user = utils.createUser(profile, 'username@test.comm');
        user.IsActive=true;
        user.DES_Disable_Chatter__c=false;
        insert user;

        final Task successTask = new Task();
        successTask.Subject = 'NPS Wave%';
        successTask.Status='In Progress';
        successTask.OwnerId=user.Id;
        insert successTask;
    	Test.startTest();
        system.assertNotEquals(successTask,null,'Error');
        system.assertNotEquals(npes,null,'Error');
        NPS_CompleteTaskController.haveNPSContacts();
        NPS_CompleteTaskController.completeTask();
    	Test.stopTest();
    }
}