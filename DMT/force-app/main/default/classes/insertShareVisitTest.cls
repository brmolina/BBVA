@isTest
public with sharing class insertShareVisitTest {
    @isTest
    public static void testMethod1() {
            test.startTest();
            dwp_kitv__Visit__Share obj=new dwp_kitv__Visit__Share();
            List<dwp_kitv__Visit__Share> listvisitSharing=new List<dwp_kitv__Visit__Share>();
            listvisitSharing.add(obj);
            ID jobID = System.enqueueJob(new insertShareVisit(listvisitSharing));
            test.stopTest();
            system.assertNotEquals(jobID, null);
    }
    
    @isTest
    public static void testMethod2() {
        test.startTest();
        dwp_kitv__Visit__Share obj;
        List<dwp_kitv__Visit__Share> listvisitSharing=new List<dwp_kitv__Visit__Share>();
        for(Integer i=0;i<10000;i++) {
            obj=new dwp_kitv__Visit__Share();
            listvisitSharing.add(obj);
            
        }   
        test.stopTest();
        ID jobID = System.enqueueJob(new insertShareVisit(listvisitSharing));
        system.assertNotEquals(jobID, null);
    }
}