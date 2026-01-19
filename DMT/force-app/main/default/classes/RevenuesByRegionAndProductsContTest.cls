/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Clase de test de RevenuesByRegionAndProductsCont
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2019      Global Desktop    Clase de test de RevenuesByRegionAndProductsCont
**********************************************************************************/
@isTest
public class RevenuesByRegionAndProductsContTest {
	
	/*
	* @author Global Desktop
	* @description Method de testeo de la clase RevenuesByRegionAndProductsCont
	*/
    @isTest
    public static void revenuesByRegionAndProductsCont() {
        
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
            
        final Account acc1 = utilTestClass.createClient();
        insert acc1;
        
        final String year = String.valueOf(Date.today().year());
        final Integer thisMonthInt = Integer.valueOf(Date.today().month());
        final String month = String.valueOf(thisMonthInt);
        
        final List <DES_Booking__c> bookList = new List <DES_Booking__c>();
        final DES_Booking__c book1 = utilTestClass.createBooking(acc1, 'HOLDING', 'HOLDING', 15000, 'GM', year);
        book1.SOLUTION_CATEGORY_NAME__c = 'Debt Capital Markets';
        book1.Month_type__c = month;
        book1.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book1);
        final DES_Booking__c book2 = utilTestClass.createBooking(acc1, 'ITALIA', 'R.EUROPA', 20400, 'GM', year); 
        book2.SOLUTION_CATEGORY_NAME__c = 'Equity';
        book2.Month_type__c = month;
        book2.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book2);  
        final DES_Booking__c book3 = utilTestClass.createBooking(acc1, 'TURQUIA', 'TURQUIA', 2100, 'GM', year); 
        book3.SOLUTION_CATEGORY_NAME__c = 'FX';
        book3.Month_type__c = month;
        book3.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book3);  
        final DES_Booking__c book4 = utilTestClass.createBooking(acc1, 'ARGENTINA', 'AMESUR', 3000, 'GM', year); 
        book4.SOLUTION_CATEGORY_NAME__c = 'Rates';
        book4.Month_type__c = month;
        book4.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book4);
        final DES_Booking__c book5 = utilTestClass.createBooking(acc1, 'JAPON', 'ASIA', 4200, 'GM', year); 
        book5.SOLUTION_CATEGORY_NAME__c = 'Credit';
        book5.Month_type__c = month;
        book5.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book5);  
        final DES_Booking__c book6 = utilTestClass.createBooking(acc1, 'EEUU', 'EEUU', 1500, 'GM', year); 
        book6.SOLUTION_CATEGORY_NAME__c = 'Debt Capital Markets';
        book6.Month_type__c = month;
        book6.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book6);  
        final DES_Booking__c book7 = utilTestClass.createBooking(acc1, 'ESPAÑA', 'ESPAÑA', 20400, 'GM', year); 
        book7.SOLUTION_CATEGORY_NAME__c = 'Equity';
        book7.Month_type__c = month;
        book7.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book7);  
        final DES_Booking__c book8 = utilTestClass.createBooking(acc1, 'MEXICO', 'MEXICO', 2100, 'GM', year); 
        book8.SOLUTION_CATEGORY_NAME__c = 'FX';
        book8.Month_type__c = month;
        book8.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book8);  
        final DES_Booking__c book9 = utilTestClass.createBooking(acc1, 'AUSTRALIA', 'RESTO', 3000, 'GM', year); 
        book9.SOLUTION_CATEGORY_NAME__c = 'Rates';
        book9.Month_type__c = month;
        book9.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book9);
        final DES_Booking__c book10 = utilTestClass.createBooking(acc1, 'COLOMBIA', 'RESTO LATAM', 4200, 'GM', year); 
        book10.SOLUTION_CATEGORY_NAME__c = 'Credit';
        book10.Month_type__c = month;
        book10.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book10);  
        final DES_Booking__c book100 = utilTestClass.createBooking(acc1, 'ITALIA', 'R.EUROPA', 30000, 'CF', year); 
        book100.SOLUTION_CATEGORY_NAME__c = 'Equity Capital Markets';
        book100.Month_type__c = month;
        book100.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book100);  
        insert bookList; 
        
        Test.StartTest();
            
        final String resgetData = RevenuesByRegionAndProductsCont.getData(acc1.Id, 'GM');
        System.assertEquals('HOLDING', book1.DES_Country__c, 'Assert Message');
         
        final String resEnglobaDate = RevenuesByRegionAndProductsCont.getEnglobaDate();
        system.debug(resEnglobaDate);
        
        final String resgetRowsData = RevenuesByRegionAndProductsCont.getRowsData(acc1.Id, 'GM');
        final List<RevenuesByRegionAndProductsCont.WrapperClass> reslistRowsData = (List<RevenuesByRegionAndProductsCont.WrapperClass>)JSON.deserialize(resgetRowsData, List<RevenuesByRegionAndProductsCont.WrapperClass>.class);                
		system.debug(reslistRowsData);
		
        Test.StopTest();
    }

}