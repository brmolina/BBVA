/** ********************************************************************************
* @author       JSS
* @date         07/05/2020
* @description  Clase para testear los métodos de la clase de utilidades PRCPricingUtils y las clases de request/response que no se testean con el resto test indirectamente.
* @Revision
********************************************************************************* */
@isTest
@SuppressWarnings('sf:ExcessiveMethodLength')
public class PRCPricingUtils_TEST {
    public static testmethod void test01() {
         //INSERT DATA NEEDED
         PRC_TestUtils utils = new PRC_TestUtils();
         String resp = PrcPriceMatrixBrowser_Ctrl.callWsRegisterAmiweb((String) utils.opp.Id, utils.priceFullResponse, utils.selectedPrice);

         //START TEST
         
		// PRC_PFS_Operation_Mitigant class
		final PRC_PFS_Operation_Mitigant mit = new PRC_PFS_Operation_Mitigant();
		mit.mitigantType = '';
		mit.commercialRisk = 1;
		mit.countryRisk = 1;
		mit.maturityType = '';
		mit.maturityDate =  Datetime.now();
		mit.isCountryRiskCoverage = true;
		mit.belongsSameGroup = true;
		mit.isInLocalCurrency = true;
		mit.description = '';
		mit.isEuropeanExportCreditAgency = true;

		final PRC_PFS_Operation_Mitigant.rating rating = new PRC_PFS_Operation_Mitigant.rating();
		rating.shortScaleValue = '';
		rating.longScaleValue = '';
		final PRC_PFS_Operation_Mitigant.guarantor guarantor = new PRC_PFS_Operation_Mitigant.guarantor();
		guarantor.Id = '';
		guarantor.rating = rating;
		mit.guarantor = guarantor;

		mit.id = 'id';

		// PRC_PFS_Operation_Amortization class
		final PRC_PFS_Operation_Amortization amort = new PRC_PFS_Operation_Amortization();
		amort.installments = new list<PRC_PFS_Operation_Amortization.installment>();
		amort.margin = new PRC_PFS_Operation_Amortization.margin();
		amort.notional = new PRC_PFS_Operation_Amortization.notional();
		PRC_PFS_Operation_Amortization.installment ins = new PRC_PFS_Operation_Amortization.installment();
		ins = new PRC_PFS_Operation_Amortization.installment(Datetime.now(),
								amort.margin,
								amort.notional,
								new PRC_PFS_Operation_Amortization.fee(),
								new PRC_PFS_Operation_Amortization.rating(),
								1,
								'');
		ins.fee = new PRC_PFS_Operation_Amortization.fee(0, 1);

		// PRC_PFS_Scenario class
		final PRC_PFS_Scenario scen = new PRC_PFS_Scenario();
		scen.axis = new list<PRC_PFS_Scenario.axis>();
		PRC_PFS_Scenario.axis ax = new PRC_PFS_Scenario.axis();
			ax.id = '';
			ax.value = 1;
		scen.term = new PRC_PFS_Scenario.term();
			scen.term.unit = '';
			scen.term.value = 1;
		scen.fundingCostInCash = new PRC_PFS_Scenario.fundingCostInCash();
			scen.fundingCostInCash.amount = 1;
			scen.fundingCostInCash.currenc_y = '';
		scen.regulatoryFundingDuration = new PRC_PFS_Scenario.regulatoryFundingDuration();
			scen.regulatoryFundingDuration.unit = '';
			scen.regulatoryFundingDuration.value = 1;
		scen.operations = new list<PRC_PFS_Scenario.operation>();
		PRC_PFS_Scenario.operation op = new PRC_PFS_Scenario.operation();
			//op.currencyFactor = 1;
			//op.countryRating = '';
			//op.regulatoryExpectedLoss = 1;
			//op.netFundingCostInCash = 1;
			//op.fundingDuration = 1;
		scen.costToIncome = new PRC_PFS_Scenario.costToIncome();
		scen.costToIncome.amount = 1;
		scen.costToIncome.currenc_y = '';
		scen.sensitivities = new list<PRC_PFS_Scenario.sensitivity>();
		PRC_PFS_Scenario.sensitivity sense = new PRC_PFS_Scenario.sensitivity();
			sense.fixedsum = new PRC_PFS_Scenario.fixedsum();
			sense.fixedsum.amount = 1;
			sense.fixedsum.currenc_y = '';
		scen.results = new List<PRC_PFS_Scenario.result>();
		PRC_PFS_Scenario.result res = new PRC_PFS_Scenario.result();
			res.name = new List<PRC_PFS_Scenario.exchangerate>();
			PRC_PFS_Scenario.exchangerate exchan = new PRC_PFS_Scenario.exchangerate();
			exchan.ratio = 1;

		// PRC_PFS_Response class
		final PRC_PFS_Response respon = new PRC_PFS_Response();
		respon.data = new PRC_PFS_Response.data();
		respon.data.engineWorksWith = new PRC_PFS_Response.responsebody();
		respon.data.engineWorksWith.engineWorksWithType = '';
		respon.data.engineWorksWith.investmentBankingProposalId = '';
		respon.data.engineWorksWith.hasCalculationMatched = true;
		respon.data.engineWorksWith.id = '';
		respon.data.engineWorksWith.valueDate = Datetime.now();
		respon.data.engineWorksWith.scenario = new PRC_PFS_Scenario();
        respon.data.engineWorksWith.status = new PRC_PFS_Response.status();
        respon.data.engineWorksWith.status.id = '';
        respon.data.engineWorksWith.matrices = new List<PRC_PFS_Matrix>();
		respon.data.engineWorksWith.crossSellAmounts = new List<PRC_PFS_Response.crossSellAmount>();
        PRC_PFS_Response.crossSellAmount csa = new PRC_PFS_Response.crossSellAmount();
		respon.data.engineWorksWith.participant = new PRC_PFS_Participant();
		respon.data.engineWorksWith.webPricingcode = '';
		respon.data.engineWorksWith.currenc_y = 'EUR';
		respon.data.engineWorksWith.scenarios = new List<PRC_PFS_Scenario>();
		final PRC_PFS_Response.originationBranch originationBranch = new PRC_PFS_Response.originationBranch();
		originationBranch.id='id';
		respon.data.engineWorksWith.originationBranch = originationBranch;



		// PRCPricingUtils class
		final PRCPricingUtils pricingLogic = PRCPricingUtils.getInstance();
		final String service1 = pricingLogic.getServiceRegisterAmiweb();
		final String service2 = pricingLogic.getServiceRegisterWorkflow();
		final String service3 = pricingLogic.getServiceStatusWorkflow();
		delete utils.oli;
		delete utils.opp;


         //ASSERTS
         System.assertNotEquals('',service1);
         System.assertNotEquals('',service2);
         System.assertNotEquals('',service3);
     }

}