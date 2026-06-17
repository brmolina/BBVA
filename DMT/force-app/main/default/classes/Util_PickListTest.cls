@isTest
private class Util_PickListTest{

    @isTest
    static void testTrigger(){

        DES_UtilTestClass testClass = new DES_UtilTestClass();

        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        Account client;
        client= testClass.createClient();
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;

        system.runAs(userTest){
            Map<String, String> mapAPILabel = Util_PickList.getLabelFromAPI('Opportunity','StageName');
            String apiName = Util_PickList.getAPIFromLabel('Opportunity', 'StageName', 'NotFoundStage'); // --
            Map <String, String> mapOptions;
            mapOptions = Util_PickList.getselectOptions(userTest, 'almd__alert_notification_type__c', client.id);

            System.debug(mapOptions);

            System.assertEquals(apiName, null);
            System.assertEquals(mapAPILabel.get('Proposal'), 'Proposal');
        }

    }

}