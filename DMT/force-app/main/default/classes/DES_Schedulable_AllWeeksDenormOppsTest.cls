@isTest
public class DES_Schedulable_AllWeeksDenormOppsTest {

    @isTest
    public static void DES_Schedulable_AllWeeksDenormOppsTest(){
        Test.startTest();
        String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_AllWeeksDenormOpps()); 
        Test.stopTest();    
    }


}