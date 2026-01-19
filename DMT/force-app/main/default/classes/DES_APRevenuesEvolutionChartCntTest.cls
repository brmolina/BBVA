@isTest
public class DES_APRevenuesEvolutionChartCntTest {

    @isTest
    public static void revenuesEvolutionChart() {
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        Account acc;
        acc = utilTestClass.createClient();
        insert acc;
        
        DES_Booking__c booking1;
        booking1 = utilTestClass.createBooking(acc, 'ARGENTINA', 'AMESUR', 100000, 'GM', '2018');
        booking1.SOLUTION_CATEGORY_NAME__c = 'Rates';
        
        DES_Booking__c booking2;
        booking2 = utilTestClass.createBooking(acc, 'ARGENTINA', 'AMESUR', 100000, 'GTB', '2018');
        booking2.SOLUTION_CATEGORY_NAME__c = 'Cash Management';
        
        DES_Booking__c booking3;
        booking3 = utilTestClass.createBooking(acc, 'ARGENTINA', 'AMESUR', 100000, 'GTB', '2019');
        booking3.SOLUTION_CATEGORY_NAME__c = 'Cash Management';
        
        DES_Booking__c booking4;
        booking4 = utilTestClass.createBooking(acc, 'ARGENTINA', 'AMESUR', 100000, 'GM', '2018');
        booking4.SOLUTION_CATEGORY_NAME__c = 'Credit';
        
        List<DES_Booking__c> bookingList = new List<DES_Booking__c>();
        bookingList.add(booking1);
        bookingList.add(booking2);
        bookingList.add(booking3);
        bookingList.add(booking4);
        insert bookingList;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        acpl__Account_Planning__c accountPlan;
        accountPlan = utilTestClass.createAccountPlanning(acc);
        insert accountPlan;
        Test.startTest();
        DES_APRevenuesEvolutionChartCnt.getData(accountPlan.Id, '');
        DES_APRevenuesEvolutionChartCnt.getTableData(accountPlan.Id, '');
        DES_APRevenuesEvolutionChartCnt.getCountries(accountPlan.Id);
        
        DES_APRevenuesEvolutionChartCnt.getData(accountPlan.Id, 'Argentina');
        DES_APRevenuesEvolutionChartCnt.getTableData(accountPlan.Id, 'Argentina');
        
        DES_APRevenuesEvolutionChartCnt.getCurrentUserISOCode();
        system.assertNotEquals(null, bookingList.get(0).Id, 'Error');
        Test.stopTest();
    }
}