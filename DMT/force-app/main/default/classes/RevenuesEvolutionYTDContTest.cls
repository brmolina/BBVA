/*****************************************************************************************
Name:            VisitsByRegionAndProductsYTDcnt
Description:     Apex Test de la clase RevenuesEvolutionYTDCont

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------
0.1            14/11/2018      Global Desktop    Apex Test de la clase RevenuesEvolutionYTDCont
*****************************************************************************************/
@isTest
public class RevenuesEvolutionYTDContTest {
	
	/**
	* @author Global Desktop
	* @description Method para testear RevenuesEvolutionYTDCont
	*/
    @isTest
    public static void RevenuesEvolutionYTDCont() {
        
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
            
        Account acc1 = utilTestClass.createClient();
        insert acc1;
        
        final String thisYear = String.valueOf(Date.today().year());
        final Integer lastYearInt = (Integer.valueOf(Date.today().year()))-1;
        final String lastYear = String.valueOf(lastYearInt);
        final Integer thisMonthInt = Integer.valueOf(Date.today().month());
        final String thisMonth = String.valueOf(thisMonthInt);
        final Integer twoMonthsLatInt = Integer.valueOf(Date.today().month())+2;
        final String twoMonthsLat = String.valueOf(twoMonthsLatInt);
        
        final List <DES_Booking__c> bookList = new List <DES_Booking__c>();
        final DES_Booking__c book1 = utilTestClass.createBooking(acc1, 'HOLDING', 'HOLDING', 15000, 'GTB', thisYear);
        book1.SOLUTION_CATEGORY_NAME__c = 'Client Resources';
        book1.Month_type__c = thisMonth;
        book1.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book1);
        final DES_Booking__c book2 = utilTestClass.createBooking(acc1, 'ITALIA', 'R.EUROPA', 20400, 'CF', thisYear); 
        book2.SOLUTION_CATEGORY_NAME__c = 'Equity Capital Markets';
        book2.Month_type__c = thisMonth;
        book2.DES_Engloba_Load_Helper__c = '0';
        bookList.add(book2);  
        final DES_Booking__c book3 = utilTestClass.createBooking(acc1, 'ITALIA', 'R.EUROPA', 30000, 'CF', lastYear); 
        book3.SOLUTION_CATEGORY_NAME__c = 'Equity Capital Markets';
        book3.Month_type__c = thisMonth;
        book3.DES_Engloba_Load_Helper__c = '1';
        bookList.add(book3);  
        final DES_Booking__c book4 = utilTestClass.createBooking(acc1, 'ITALIA', 'R.EUROPA', 30000, 'CF', lastYear); 
        book4.SOLUTION_CATEGORY_NAME__c = 'Equity Capital Markets';
        book4.Month_type__c = twoMonthsLat;
        book4.DES_Engloba_Load_Helper__c = '1';
        bookList.add(book4);  
        insert bookList;      
        
        Test.StartTest();
            
        final String resgetData = RevenuesEvolutionYTDCont.getData(acc1.Id);
        final Map<String, Map<String, Double>> resmapYear = (Map<String, Map<String, Double>>)JSON.deserialize(resgetData, Map<String, Map<String, Double>>.class);
        System.assertEquals(30000.0, resmapYear.get(lastYear).get('CF'), 'Assert Message');
        System.assertEquals(15000.0, resmapYear.get(thisYear).get('GTB'), 'Assert Message');

        final String resgetBookProducts = RevenuesEvolutionYTDCont.getBookingProd(acc1.Id);
        final List<RevenuesEvolutionYTDCont.WrapperClass> reslistBookProducts = (List<RevenuesEvolutionYTDCont.WrapperClass>)JSON.deserialize(resgetBookProducts, List<RevenuesEvolutionYTDCont.WrapperClass>.class);                
        System.assertEquals('Client Resources', reslistBookProducts[0].prodName);
        System.assertEquals(thisMonth, reslistBookProducts[1].month);  
        System.assertEquals(lastYear, reslistBookProducts[2].year);  
        
        final String resUserInfo = RevenuesEvolutionYTDCont.getCurrentUserISOCode();
        system.debug(resUserInfo);
        //System.assertEquals('EUR',resUserInfo);

        Test.StopTest();
    }

}