@isTest
public class DES_Visit_Contact_NewPackage_TriggerTest {
	@isTest
	public static void DES_Visit_Contact_NewPackage_TriggerTest() {
		
		DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
		String profileTest = utilTestClass.createProfile();
		User userTest1 = utilTestClass.createUser(profileTest);
		insert userTest1;
		CIB_User_Org__c userSettings = utilTestClass.createCustomSetting();
		insert userSettings;
		system.runAs(userTest1){
			
			Test.startTest();
			Account acc = utilTestClass.createClient();
			insert acc;
			
			Contact contact = utilTestClass.createContact(acc);
			insert contact;
			dwp_kitv__visit__c visit = utilTestClass.createVisit(Acc, null);
			insert visit;
			dwp_kitv__Visit_Contact__c visitContact = utilTestClass.visitContact(contact, visit);
			insert visitContact;		
				
			Test.stopTest();
			
		}
		
	}

	/*
	* Test method for mainContactNew
	*/
	@isTest
	public static void mainContactNewTest() {
		final DES_UtilTestClass util = new DES_UtilTestClass();
		final Account acc = util.createClient();
		insert acc;
		final dwp_kitv__Visit__c visit = util.createVisit(acc, null);
		insert visit;
		final Contact con = util.createContact(acc);
		insert con;
		final Contact con1 = util.createContact(acc);
		con1.Email = 'aaaaa' + con1.Email;
		insert con1;
		final Contact con2 = util.createContact(acc);
		con2.Email = 'bbaaaa' + con2.Email;
		insert con2;
		Test.startTest();
		final dwp_kitv__Visit_Contact__c visitContact = util.visitContact(con, visit);
		visitContact.dwp_kitv__Main_contact__c = true;
		insert visitContact;
		final dwp_kitv__Visit_Contact__c visitContact1 = util.visitContact(con1, visit);
		visitContact1.dwp_kitv__Main_contact__c = true;
		insert visitContact1;
		final dwp_kitv__Visit_Contact__c visitContact2 = util.visitContact(con2, visit);
		visitContact2.dwp_kitv__Main_contact__c = false;
		insert visitContact2;
		final dwp_kitv__Visit_Contact__c visitConAux = [SELECT Id, dwp_kitv__Main_contact__c
			FROM dwp_kitv__Visit_Contact__c
			WHERE dwp_kitv__Send_minutes__c = 'To' LIMIT 1];
		system.assert(visitConAux.dwp_kitv__Main_contact__c, 'maincontact');
		Test.stopTest();
	}
}