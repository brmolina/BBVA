/*
* @author Global Desktop
* @description Test de la clase VisitLast12MonthsQuartersCnt
*/
@isTest
public class VisitLast12MonthsQuartersCntTest {
	
	/*
	* @author Global Desktop
	* @description Method que testea la clase
	*/
    @isTest
    public static void visitLast12MonthsQuartersCnt() {
                      
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        Boolean devuelveJSON = false;

        final Account acc1 = utilTestClass.createClient();
        insert acc1;
        
        final List <dwp_kitv__Visit__c> visitList = new List <dwp_kitv__Visit__c>();
        final dwp_kitv__Visit__c visit1 = utilTestClass.createVisit(acc1, null);
        visit1.dwp_kitv__solution_name_path_desc__c = 'GTB;GM';
        visitList.add(visit1);
        final dwp_kitv__Visit__c visit2 = utilTestClass.createVisit(acc1, null);
        visit2.dwp_kitv__visit_start_date__c = Date.today().addMonths(-3);
        visit2.dwp_kitv__solution_name_path_desc__c = 'IBF';
        visitList.add(visit2);
        final dwp_kitv__Visit__c visit3 = utilTestClass.createVisit(acc1, null);
        visit3.dwp_kitv__visit_start_date__c = Date.today().addMonths(-6);
        visit3.dwp_kitv__solution_name_path_desc__c = 'GCC';
        visitList.add(visit3);  
        final dwp_kitv__Visit__c visit4 = utilTestClass.createVisit(acc1, null);
        visit4.dwp_kitv__visit_start_date__c = Date.today().addMonths(-9);
        visit4.dwp_kitv__solution_name_path_desc__c = 'GTB';
        visitList.add(visit4);
        insert visitList;  
        
        Test.StartTest();
            
        final String resgetData = VisitLast12MonthsQuartersCnt.getData(acc1.Id);
        final Map<String, Map<String, Integer>> resMapStage = (Map<String, Map<String, Integer>>)JSON.deserialize(resgetData, Map<String, Map<String, Integer>>.class);
        system.debug(resMapStage);
        final String resGetOppProducts = VisitLast12MonthsQuartersCnt.getOppProducts(acc1.Id);
        final List<VisitLast12MonthsQuartersCnt.WrapperClass> listOppProd = (List<VisitLast12MonthsQuartersCnt.WrapperClass>)JSON.deserialize(resGetOppProducts, List<VisitLast12MonthsQuartersCnt.WrapperClass>.class);               
        if(listOppProd != null) {
            devuelveJSON = true;
        }
        System.assertEquals(devuelveJSON, true, 'assert Message');

        Test.StopTest();
    }
    
}