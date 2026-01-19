@isTest
public class DES_Schedulable_AllWeeksAccAlertTest{

    @isTest
    public static void DES_Schedulable_AllWeeksAccAlertTest(){
        Test.startTest();
        String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_AllWeeksAccAlert()); 
        Test.stopTest();    
    }


}