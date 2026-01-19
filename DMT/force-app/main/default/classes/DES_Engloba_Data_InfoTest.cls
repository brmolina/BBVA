@isTest
public class DES_Engloba_Data_InfoTest {
	
	@isTest
    public static void DES_Engloba_Data_InfoTest() {
        
        DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        String profileTest = utilTestClass.createProfile();
        User userTest1 = utilTestClass.createUser(profileTest);
       	insert userTest1;
        CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
        insert userSettings;
        Account acc = utilTestClass.createClient();
        insert acc;
        String paisEspana = 'ESPAÑA';
       	DES_Booking__c book1 = utilTestClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2018');
       	insert book1;
        system.runAs(userTest1){
        	Test.startTest();
        	
        	String englobaInfo = DES_Engloba_Data_Info.getEnglobaData();
        	Test.stopTest();
        	
        }
        
    }
}