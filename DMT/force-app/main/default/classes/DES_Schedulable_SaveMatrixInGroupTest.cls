@isTest
public class DES_Schedulable_SaveMatrixInGroupTest {

    @isTest
    public static void DES_Schedulable_SaveMatrixInGroup(){
        Test.startTest();
        String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_SaveMatrixInGroup()); 
        Test.stopTest();
    }

}