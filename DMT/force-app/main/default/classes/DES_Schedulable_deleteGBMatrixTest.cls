@isTest
public class DES_Schedulable_deleteGBMatrixTest{

    @isTest
    public static void DES_Schedulable_deleteGBMatrixTest(){
    Test.startTest();  
    DES_Group_Subsidiary_Matrix__c matrix = new DES_Group_Subsidiary_Matrix__c();
    insert matrix;
    String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_deleteGBMatrix ()); 

    System.assertNotEquals(jobId, null);
    Test.stopTest();  
    }


}