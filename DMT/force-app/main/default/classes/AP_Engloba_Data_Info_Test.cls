/***********************************************************************************************
Name:            AP_EventNotificationBatch_Test
Description:     Test Class for AP_Engloba_Data_Info

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            02/12/2019      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class AP_Engloba_Data_Info_Test {

    /*
    * @author       Global Desktop
    * @Description  AP_Engloba_Data_InfoTest
    */
  @isTest
    public static void AP_Engloba_Data_InfoTest() {
        
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;
        
        DES_Booking__c booking;
        booking = utilTestClass.createBooking(acc, 'ARGENTINA', 'AMESUR', 100000, 'GM', '2018');
        booking.SOLUTION_CATEGORY_NAME__c = 'Rates';
        insert booking;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;

        
        acpl__Account_Planning__c accountPlan;
        accountPlan = utilTestClass.createAccountPlanning(acc);
        insert accountPlan;
        
        Test.startTest();
        AP_Engloba_Data_Info.getEnglobaData(accountPlan.Id);
        system.assertEquals('Rates', booking.SOLUTION_CATEGORY_NAME__c, 'Error');
        Test.stopTest();        
    }
}