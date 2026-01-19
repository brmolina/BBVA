@isTest
public class DES_Override_NewButton_ControllerTest {
	
	@isTest
	public static void DES_Override_NewButton_ControllerTest() {
		
		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
		//system.runAs(){
			Test.startTest();
        	
        	String domain = DES_Override_NewButton_Controller.getDomain();
        	Id idListView = DES_Override_NewButton_Controller.getOppsListViews();
        	String idListView2 = DES_Override_NewButton_Controller.getClientListViews();
        	
			Test.stopTest();
			
		//}
		
	}
}