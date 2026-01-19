@isTest
public class DES_CustomReportLastUpdOppsTest {
	/*
	 *	esta clase de test ya no aplica, ya que este componente no se utiliza ( se sustituye por el report estandar de cristina)
	 *
	 *
	**/
	@isTest
    public static void DES_CustomReportLastUpdOppsTest() {
        
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
       	DES_CustomReportLastUpdOpps customRLUO = new DES_CustomReportLastUpdOpps();
        system.runAs(userTest1){
        	
        	Test.startTest();
        	
        	String currISOCode = DES_CustomReportLastUpdOpps.getCurrentUserISOCode();
        	String dataChart = DES_CustomReportLastUpdOpps.getData('GM', '2');        	
        	Test.stopTest();
        	
        }
        
    }
}