@isTest
public class Account_Without_SharingTest {

   
@isTest
public static void method1(){
      DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc = utilTestClass.createClient();
        insert acc;
        final Opportunity opp = utilTestClass.createOpportunity(acc);
        opp.DES_Expected_Probability__c = 20;
        insert opp;
	    final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm = new dwp_acmh__Denorm_Account_Opportunity__c ();
	    oppDenorm.dwp_acmh__AccountId__c = acc.Id;
	    oppDenorm.dwp_acmh__OpportunityId__c = opp.Id;
	    insert oppDenorm;

    Test.startTest();
    Map<Id,Account> relatedAccMap=new Map<Id,Account>(); 
    relatedAccMap.put(acc.id,acc);
    List<dwp_acmh__Denorm_Account_Opportunity__c> lstDenorm=new List<dwp_acmh__Denorm_Account_Opportunity__c>();
    lstDenorm.add(oppDenorm);
    Account_Without_Sharing.manageIsDeleting(relatedAccMap, lstDenorm);
    Test.stopTest();
    system.assertNotEquals(oppDenorm, null);
}
}