/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Test de la case VisitsComNextVisitsByFamilyContTestmercialActivityController
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Testeo de la clase NextVisitsByFamilyContTest
**********************************************************************************/
@isTest
public class NextVisitsByFamilyContTest {
	/**
	* @author Global Desktop
	* @description Testeo de la clase
	*/
  	@isTest
  	public static void NextVisitsByFamilyCont() {
	    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
	   
	    final Account acc1 = utilTestClass.createClient();
	    insert acc1;
	
	    final dwp_kitv__Visit__c vis1 =  utilTestClass.createVisit(acc1, null);
	    vis1.dwp_kitv__solution_name_path_desc__c = 'GTB';
	    insert vis1;
	    
	    Test.StartTest();
	    final String resRelVisits = NextVisitsByFamilyCont.getRelatedVisits('2',acc1.Id, 'GTB', 'Todos');
	    final List<NextVisitsByFamilyCont.WrapperClass> resListRelVisits = (List<NextVisitsByFamilyCont.WrapperClass>)JSON.deserialize(resRelVisits, List<NextVisitsByFamilyCont.WrapperClass>.class);
	    System.assertEquals('VISIT TEST', resListRelVisits[0].visName);
	
	    Test.StopTest();
  }
}