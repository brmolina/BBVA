@isTest
public class DES_Login_HomeNotificationControllerTest{

    @isTest
    public static void DES_Login_HomeNotificationControllerTest(){
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        String profileId = utilTestClass.createProfile();

        User u = utilTestClass.createUser(profileId);
        u.DES_First_Login_After_Revenues_Update__c = true;
        u.DES_First_Login_After_Historic_Update__c = true;
        insert u;

        User newu = utilTestClass.createUser(profileId);
        newu.DES_First_Login_After_Revenues_Update__c = false;
        newu.DES_First_Login_After_Historic_Update__c = false;
        insert newu;
        final set<Id> udIds =new Set<Id>{u.Id, newu.Id};

        Test.startTest();

        Account acc = utilTestClass.createClient();
        acc.DES_RAR_EVA_RORC_Update_Engloba__c = '20180531';
        acc.DES_Previous_RAR_EVA_RORC_Update_Engloba__c = '20180331';
        insert acc;

        DES_Booking__c b = utilTestClass.createBooking(acc,'FRANCIA','R.EUROPA',2000,'GTB','2017');
        insert b;

        DES_Historic_RAR_EVA_RORC__c h = new DES_Historic_RAR_EVA_RORC__c();
        h.DES_Client__c = acc.Id;
        insert h;

        DES_Login_Home_Notification_Controller.returnIsFirstLogin(u.Id);
        DES_Login_Home_Notification_Controller.returnIsFirstLogin(newu.Id);
        DES_Login_Home_Notification_Controller.returnIsFirstLoginHistoric(u.Id);
        DES_Login_Home_Notification_Controller.returnDateUpdate();
        DES_Login_Home_Notification_Controller.returnDateHistoricUpdate();
        System.assertEquals(2, [SELECT count() FROM User WHERE (DES_First_Login_After_Revenues_Update__c = false AND DES_First_Login_After_Historic_Update__c = false AND Id IN : udIds)], 2);
        Test.stopTest();
    }

}