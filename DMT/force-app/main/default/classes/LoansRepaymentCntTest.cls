/************************************************************************************
*   @author: GlobalDesktop - APC
*   @method LoansRepaymentCntTest
*   @Description:  LoansRepaymentCnt - Tests


*   @Versions:
        v1 - 2019/06/10 - Initial version
***********************************************************************************/
@isTest
public with sharing class LoansRepaymentCntTest {
    /* Instancia de utilTestClass */
    private static DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    /* constante de accGroup.Name utilizada */
    private final static String NAME = 'Grupo_Loans_ES';
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

        //Loans
        Final List<Loans_Repayment__c> lstLoans = createLoans(accGroup.Id, 4, 'EUR');
        insert lstLoans;
    }
    /*
        Auxiliar method to create several Loans
    */
	private static List<Loans_Repayment__c> createLoans(Id accountId, Decimal years, String curIsoCode) {
        Final List<Loans_Repayment__c> lstLoans = new List<Loans_Repayment__c>();
        for(Integer aux = 0; aux < years; aux++) {
            Loans_Repayment__c loanAF;
            loanAF = new Loans_Repayment__c();
            loanAF.participant_id__c = accountId;
            loanAF.gf_settlement_date__c = STARTERYEAR + aux;
            loanAF.solution_classification_desc__c = 'Asset Finance';
            loanAF.bbva_repayment_amount__c = 40000 + STARTERYEAR;
            loanAF.synd_loan_amortization_amount__c = 50000 + STARTERYEAR;
            loanAF.unrepayment_capital_amount__c = 60000 + STARTERYEAR;
            loanAF.country_name__c = 'ES';
            loanAF.applied_fees_amount__c = 500;
            loanAF.gf_nominal_interest_amount__c = 200;
			loanAF.gf_loan_fund_cost_amount__c = 1000;
            loanAF.CurrencyIsoCode = curIsoCode;
            lstLoans.add(loanAF);
            
            loanAF = new Loans_Repayment__c();
            loanAF.participant_id__c = accountId;
            loanAF.gf_settlement_date__c = STARTERYEAR + aux;
            loanAF.solution_classification_desc__c = 'Asset Finance';
            loanAF.bbva_repayment_amount__c = null;
            loanAF.synd_loan_amortization_amount__c = null;
            loanAF.unrepayment_capital_amount__c = null;
            loanAF.country_name__c = 'ES';
            loanAF.applied_fees_amount__c = null;
            loanAF.gf_nominal_interest_amount__c = null;
			loanAF.gf_loan_fund_cost_amount__c = null;
            loanAF.CurrencyIsoCode = curIsoCode;
            lstLoans.add(loanAF);

            loanAF = new Loans_Repayment__c();
            loanAF.participant_id__c = accountId;
            loanAF.gf_settlement_date__c = STARTERYEAR + aux;
            loanAF.solution_classification_desc__c = 'Asset Finance';
            loanAF.bbva_repayment_amount__c = null;
            loanAF.country_name__c = 'ES';
            loanAF.CurrencyIsoCode = curIsoCode;
            lstLoans.add(loanAF);
          
            Final Loans_Repayment__c loanPF = loanAF.clone(false, false, false, false);
            loanPF.solution_classification_desc__c = 'Project Finance';
            lstLoans.add(loanPF);

            Final Loans_Repayment__c loanCF = loanAF.clone(false, false, false, false);
            loanCF.solution_classification_desc__c = 'Corporate Facilities';
            lstLoans.add(loanCF);

            Final Loans_Repayment__c loanLF = loanAF.clone(false, false, false, false);
            loanLF.solution_classification_desc__c = 'Leveraged Finance';
            lstLoans.add(loanLF);
        }
        return lstLoans;
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @method loansAF
    *   @Description:  Caso 1 - Asset Finance

    *   @Versions:
            v1 - 2019/06/13 - Initial version
    */
	@isTest
	public static void loansAF() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        final String result = LoansRepaymentCnt.getData(acc.Id, 'Asset Finance');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso AF response ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @method loansPF
    *   @Description:  Caso 1 - Project Finance

    *   @Versions:
            v1 - 2019/06/13 - Initial version
    */
	@isTest
	public static void loansPF() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        final String result = LoansRepaymentCnt.getData(acc.Id, 'Project Finance');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso PF response ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @method loansCF
    *   @Description:  Caso 3 - Corporate Facilities

    *   @Versions:
            v1 - 2019/06/13 - Initial version
    */
	@isTest
	public static void loansCF() {
        Final LoansRepaymentCnt instanceLoans = LoansRepaymentCnt.getInstance();
        System.debug(instanceLoans);
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        final String result = LoansRepaymentCnt.getData(acc.Id, 'Corporate Facilities');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso CF response ok');
    	Test.stopTest();
    }
    /**
    *   @author: GlobalDesktop - APC
    *   @method loansLF 
    *   @Description:  Caso 4 - Leveraged Finance

    *   @Versions:
            v1 - 2019/06/13 - Initial version
    */
	@isTest
	public static void loansLF() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        final String result = LoansRepaymentCnt.getData(acc.Id, 'Leveraged Finance');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso LF response ok');
    	Test.stopTest();
    }
    /**
*   @author: GlobalDesktop - APC
*   @method getTable
*   @Description:  Caso 5 - details table

*   @Versions:
        v1 - 2019/06/13 - Initial version
*/
	@isTest
	public static void getTable() {
        final Account acc = [SELECT Id FROM Account WHERE Name = :NAME LIMIT 1];

        Test.startTest();
        final String result = LoansRepaymentCnt.getRowsData(acc.Id, 'Leveraged Finance');
		Boolean response = false;
        if(result != null) {
            response = true;
        }
        System.assert(response, 'caso table response ok');
    	Test.stopTest();
    }
}