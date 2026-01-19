@isTest
public class insertShareOpportunityTest { 
    @isTest
    public static void testMethod1() {
            test.startTest();
            OpportunityShare obj=new OpportunityShare();
            List<OpportunityShare> lstOppShare=new List<OpportunityShare>();
            lstOppShare.add(obj);
            ID jobID = System.enqueueJob(new insertShareOpportunity(lstOppShare));
            test.stopTest();
            system.assertNotEquals(jobID, null);
    }
    
    @isTest
    public static void testMethod2() {
        test.startTest();
        OpportunityShare obj;
        List<OpportunityShare> lstOppShare=new List<OpportunityShare>();
        for(Integer i=0;i<10000;i++) {
            obj=new OpportunityShare();
            lstOppShare.add(obj);
            
        }   
        test.stopTest();
        ID jobID = System.enqueueJob(new insertShareOpportunity(lstOppShare));
        system.assertNotEquals(jobID, null);
    }
}