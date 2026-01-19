@isTest
public class DES_Schedulable_AllWeeksTest {
    
    @isTest
    public static void DES_Schedulable_AllWeeks(){
    	DES_UtilTestClass testClass = new DES_UtilTestClass();
        
        String idProfile = testClass.createProfile();
        User userTest = testClass.createUser(idProfile);
        insert userTest;
        CIB_User_Org__c userSettings = testClass.createCustomSetting();
        insert userSettings;
        
        Account acc = testClass.createClient();
        insert acc;
        String paisEspana = 'ESPAÑA';
        String paisAlemania = 'ALEMANIA';
        String regionREuropa = 'R.EUROPA';
        List<DES_Booking__c> listBooking = new List<DES_Booking__c>();
        //Funcion createBooking(Account acc, String country, String region, Double revenues, String type, String year)
        DES_Booking__c boo1 = testClass.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2017');
        listBooking.add(boo1);
        DES_Booking__c boo2 = testClass.createBooking(acc, paisEspana, paisEspana, 12.06, 'GM', '2018');
        listBooking.add(boo2);
        DES_Booking__c boo3 = testClass.createBooking(acc, paisEspana, paisEspana, 13.24, 'IBF', '2017');
        listBooking.add(boo3);
        DES_Booking__c boo4 = testClass.createBooking(acc, paisEspana, paisEspana, 129.16, 'IBF', '2018');
        listBooking.add(boo4);
        DES_Booking__c boo5 = testClass.createBooking(acc, paisEspana, paisEspana, 45.82, 'GM', '2017');
        listBooking.add(boo5);
        DES_Booking__c boo6 = testClass.createBooking(acc, paisEspana, paisEspana, 496.02, 'GTB', '2018');
        listBooking.add(boo6);
        DES_Booking__c boo7 = testClass.createBooking(acc, paisAlemania, regionREuropa, 87.05, 'GM', '2017');
        listBooking.add(boo7);
        DES_Booking__c boo8 = testClass.createBooking(acc, paisAlemania, regionREuropa, 61.06, 'GM', '2018');
        listBooking.add(boo8);
        DES_Booking__c boo9 = testClass.createBooking(acc, paisAlemania, regionREuropa, 12.14, 'CF', '2017');
        listBooking.add(boo9);
        DES_Booking__c boo10 = testClass.createBooking(acc, paisAlemania, regionREuropa, 14.16, 'CF', '2018');
        listBooking.add(boo10);
        DES_Booking__c boo11 = testClass.createBooking(acc, paisAlemania, regionREuropa, 21.05, 'GM', '2017');
        listBooking.add(boo11);
        DES_Booking__c boo12 = testClass.createBooking(acc, paisAlemania, regionREuropa, 421.00, 'GTB', '2018');
        listBooking.add(boo12);
        DES_Booking__c boo13 = testClass.createBooking(acc, paisAlemania, regionREuropa, 421.00, 'GTB', '2017');
        listBooking.add(boo13);
        DES_Booking__c boo14 = testClass.createBooking(acc, paisAlemania, regionREuropa, 421.00, 'CO', '2018');
        listBooking.add(boo14);
        DES_Booking__c boo15 = testClass.createBooking(acc, paisAlemania, regionREuropa, 127.00, 'CO', '2017');
        listBooking.add(boo15);
        DES_Booking__c boo16 = testClass.createBooking(acc, paisAlemania, regionREuropa, 421.00, 'GL', '2018');
        listBooking.add(boo16);
        DES_Booking__c boo17 = testClass.createBooking(acc, paisAlemania, regionREuropa, 127.00, 'GL', '2017');
        listBooking.add(boo17);
        DES_Booking__c boo18 = testClass.createBooking(acc, paisAlemania, regionREuropa, 421.00, 'GM', '2016');
        listBooking.add(boo18);
        DES_Booking__c boo19 = testClass.createBooking(acc, paisAlemania, regionREuropa, 127.00, 'GTB', '2016');
        listBooking.add(boo19);

        insert listBooking;
        delete listBooking;
        for(DES_Booking__c book : listBooking){
        	book.Id = null;
        }
        insert listBooking;
		Test.startTest();
		String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_AllWeeks()); 
		Test.stopTest();
    }
    
}