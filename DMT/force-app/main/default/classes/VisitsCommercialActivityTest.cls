/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Test de la case VisitsCommercialActivityController
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Testeo de la clase VisitsCommercialActivityController
**********************************************************************************/
@isTest
public class VisitsCommercialActivityTest {
	
	/**
	* @author Global Desktop
	* @description Testeo de la clase
	*/
    @isTest
    public static void visitsCommercialActivityController() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final Account acc1 = utilTestClass.createClient();
        insert acc1;
        final List <dwp_kitv__Visit__c> visitsIns = new  List <dwp_kitv__Visit__c>();
        final dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(acc1, null);
        visitsIns.add(visit1);
        final dwp_kitv__Visit__c visit2 = utilTestClass.createVisit(acc1, null);
        visitsIns.add(visit2);
        visit2.dwp_kitv__visit_start_date__c = date.newinstance(2017, 2, 17);
        final dwp_kitv__Visit__c visit3 = utilTestClass.createVisit(acc1, null);
        visitsIns.add(visit3);
        insert visitsIns;

        Test.StartTest();
        String res = VisitsCommercialActivityController.getVisitInfo(acc1.Id, 'Spain');
        res = VisitsCommercialActivityController.getVisitInfo(acc1.Id, 'Todos');
        List<VisitsCommercialActivityController.wrapperClass> listres; //NOSONAR
        listres = (List<VisitsCommercialActivityController.wrapperClass>)JSON.deserialize(res, List<VisitsCommercialActivityController.wrapperClass>.class); //NOSONAR
        System.assertEquals(visit3.dwp_kitv__account_id__c, acc1.Id, 'System assert message');
        Test.StopTest();
    }
}