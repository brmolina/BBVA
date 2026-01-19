/***********************************************************************************************
Name:            DES_Booking_Batch_Handler_Test
Description:     Test Class for DES_Booking_Batch_Handler, its schedulable and handler

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            24/03/2020      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class DES_Booking_Batch_Handler_Test {
	@isTest
    static void BookingTest() {
        test.startTest();
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        Final List<Account> accs = new list<Account>();
        String paisEspana = 'ESPAÑA';
        Final Account acc = utils.createClient();
        accs.add(acc);
        insert accs;
        Final DES_Booking__c book = utils.createBooking(acc, paisEspana, paisEspana, 125.12, 'GM', '2020');
        insert book;
        DES_Booking_Batch_Handler.alternativeTopCountries(accs);
        System.assertNotEquals(book, Null, 'Hay respuesta');
        test.stopTest();
    }
}