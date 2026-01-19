@isTest
private class DES_Batch_Delete_BookingTest{
       
    @isTest
    static void testTrigger(){
        
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
      	
        system.runAs(userTest){
        	Account acc = testClass.createClient();
            insert acc;
        	String paisEspana = 'ESPAÑA';
			List<DES_Booking__c> listBooking = new List<DES_Booking__c>();
            //Funcion createBooking(Account acc, String country, String region, Double revenues, String type, String year)
            DES_Booking__c boo1 = testClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2017');
            listBooking.add(boo1);
            DES_Booking__c boo2 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'GM', '2018');
            listBooking.add(boo2);
            DES_Booking__c boo3 = testClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'IBF', '2017');
            listBooking.add(boo3);
            insert listBooking;
            
        	Id batchInstanceId = Database.executeBatch(new DES_Batch_Delete_Booking(), 10000);
        }
    }

}