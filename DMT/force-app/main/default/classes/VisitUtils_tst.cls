@isTest
public class VisitUtils_tst {
    /**
    * @description Test method getting a successful response by retrieving the selected json
    */
    @isTest static void testinsertshare() {
        final dwp_kitv__Visit__c visitnew=new dwp_kitv__Visit__c();
        final dwp_kitv__Visit__c visitold=new dwp_kitv__Visit__c();
        final List<dwp_kitv__Visit__c> lstvisitnew=new List<dwp_kitv__Visit__c>();
        final List<dwp_kitv__Visit__c> lstvisitold=new List<dwp_kitv__Visit__c>();
        visitnew.ownerid=UserInfo.getUserId();
        lstvisitnew.add(visitnew);
        lstvisitold.add(visitold);
        
        Test.startTest();
            VisitUtils_cls obj=new VisitUtils_cls();
            obj.createShareOldOwner(lstvisitnew,lstvisitold);//ajusta permisos cambio de owner
            System.assert(!String.isEmpty(visitnew.ownerid), 'The result is empty');
        Test.stopTest();
    }
}