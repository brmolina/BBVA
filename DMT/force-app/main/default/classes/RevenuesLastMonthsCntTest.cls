/************************************************************************************
*   @author: GlobalDesktop - APC
*   @method LoansRepaymentCntTest
*   @Description:  LoansRepaymentCnt - Tests


*   @Versions:
        v1 - 2019/06/10 - Initial version
***********************************************************************************/
@isTest
public with sharing class RevenuesLastMonthsCntTest {

    /* Instancia de utilTestClass */
    private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    /* constante de accGroup.Name utilizada */
    private final static String NAME = 'Grupo_HBook_ES';
    /* constantes */
    Final static Integer STARTERYEAR = 2019;

    /*
        Test Setup: account - loans
    */
    @testSetup
	public static void setupRows() {
        //Accounts
        Final Account accGroup = utilTestClass.createClient();
        	accGroup.Name = NAME;
        	accGroup.DES_BBVA_Segmentation__c = 'B';
        	accGroup.DES_Structure_Type__c = 'Group';
        	accGroup.DES_Country_Client__c = 'ES';
    	insert accGroup;

        //DES_Historic_Booking__c
        Final List<DES_Historic_Booking__c> lstHBooks = createHistoricBookings(accGroup.Id, 4, 'EUR');
        insert lstHBooks;
    }
    /*
        Auxiliar method to create several Loans
    */
	private static List<DES_Historic_Booking__c> createHistoricBookings(Id accountId, Decimal years, String curIsoCode) {
        Final List<DES_Historic_Booking__c> lstHBooks = new List<DES_Historic_Booking__c>();

        for(Integer aux = 1; aux < years + 1; aux++) {
            DES_Historic_Booking__c hbEspWC = new DES_Historic_Booking__c();
            hbEspWC.month_type__c = '12';
            hbEspWC.year_id__c = '19';
            hbEspWC.participant_id__c = accountId;
            hbEspWC.country_id__c = 'ES';
            hbEspWC.region_name__c = 'ESPAÑA';
            hbEspWC.solution_category_desc__c = 'GTB';
            hbEspWC.solution_id_path_desc__c = 'Working Capital';
            hbEspWC.sf_historic_booking_id__c = getExternalIdHB(hbEspWC) + aux;

            hbEspWC = createHistoricBookings1(hbEspWC, aux);
            hbEspWC = createHistoricBookings2(hbEspWC, aux);

            hbEspWC.CurrencyIsoCode = curIsoCode;
            lstHBooks.add(hbEspWC);

            Final DES_Historic_Booking__c hBook02 = hbEspWC.clone(false, false, false, false);
            hBook02.solution_category_desc__c = 'GM';
            hBook02.solution_id_path_desc__c = 'Client Resources';
            hBook02.sf_historic_booking_id__c = getExternalIdHB(hBook02) + aux;
            lstHBooks.add(hBook02);

            Final DES_Historic_Booking__c hBook03= hbEspWC.clone(false, false, false, false);
            hBook03.solution_category_desc__c = 'IBF';
            hBook03.solution_id_path_desc__c = 'Cash Management';
            hBook03.sf_historic_booking_id__c = getExternalIdHB(hBook03) + aux;
            lstHBooks.add(hBook03);

            Final DES_Historic_Booking__c hBook04 = hbEspWC.clone(false, false, false, false);
            hBook04.solution_category_desc__c = 'CF';
            hBook04.solution_id_path_desc__c = 'Securities Services';
            hBook04.sf_historic_booking_id__c = getExternalIdHB(hBook04) + aux;
            lstHBooks.add(hBook04);
        }
        return lstHBooks;
    }

    /*
        Auxiliar method to create several Loans
    */
    private static DES_Historic_Booking__c createHistoricBookings1(DES_Historic_Booking__c historic, Integer aux) {

        DES_Historic_Booking__c hbEspWC;
        hbEspWC = historic;

        hbEspWC.total_gross_margin_jan_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_feb_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_mar_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_apr_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_may_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_jun_py_amount__c = 1000 * (aux);

        hbEspWC.total_gross_margin_jul_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_aug_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_sep_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_oct_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_nov_py_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_dec_py_amount__c = 1000 * (aux);

        hbEspWC.xbrdr_gross_margin_jan_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_feb_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_mar_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_apr_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_may_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_jun_py_amount__c = 1000 * (aux);

        hbEspWC.xbrdr_gross_margin_jul_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_aug_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_sep_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_oct_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_nov_py_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_dec_py_amount__c = 1000 * (aux);

        return hbEspWC;
    }

    /*
        Auxiliar method to create several Loans
    */
    private static DES_Historic_Booking__c createHistoricBookings2(DES_Historic_Booking__c historic, Integer aux) {

        DES_Historic_Booking__c hbEspWC;
        hbEspWC = historic;

        hbEspWC.total_gross_margin_jan_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_feb_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_mar_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_apr_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_may_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_jun_amount__c = 1000 * (aux);

        hbEspWC.total_gross_margin_jul_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_aug_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_sep_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_oct_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_nov_amount__c = 1000 * (aux);
        hbEspWC.total_gross_margin_dec_amount__c = 1000 * (aux);

        hbEspWC.xbrdr_gross_margin_jan_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_feb_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_mar_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_apr_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_may_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_jun_amount__c = 1000 * (aux);

        hbEspWC.xbrdr_gross_margin_jul_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_aug_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_sep_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_oct_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_nov_amount__c = 1000 * (aux);
        hbEspWC.xbrdr_gross_margin_dec_amount__c = 1000 * (aux);

        return hbEspWC;
    }

    /*
        Auxiliar method to populate external ID in the same way it should be inserted by APX
    */
    private static String getExternalIdHB(DES_Historic_Booking__c hbook) {
        return hbook.country_id__c + hbook.country_id__c + hbook.solution_category_desc__c + hbook.solution_id_path_desc__c + hbook.year_id__c + hbook.month_type__c;
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @method hBookGTB
    *   @Description:  Caso 1 - GTB

    *   @Versions:
            v1 - 2019/06/19 - Initial version
    */
	@isTest
	public static void hBookGTB() {
        Final RevenuesLastMonthsCnt instanceHBooks = RevenuesLastMonthsCnt.getInstance();
        System.debug(instanceHBooks);
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        final String result = RevenuesLastMonthsCnt.getData(acc.Id, 'GTB', 24);
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso GTB response ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @method hBookDataTable
    *   @Description:  Caso 2 - DataTable

    *   @Versions:
            v1 - 2019/06/19 - Initial version (getTrigDetail = treegrid (new) || old = getRowsData)
    */
	@isTest
	public static void hBookDataTable() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        final String result = RevenuesLastMonthsCnt.getTrigDetail(acc.Id, 'GM');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso DataTable response ok');
    	Test.stopTest();
    }
}