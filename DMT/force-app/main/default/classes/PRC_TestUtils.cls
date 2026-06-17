/** ********************************************************************************
* @author
* @date         20/04/2020
* @description  Clase que crea los registros necesarios para los test de las clases de la funcionalidad Pricing
* @Revision
********************************************************************************* */
@SuppressWarnings('sf:CommentedOutCode,sf:CommentRequired,sf:FinalFieldCouldBeStatic')
@isTest
public class PRC_TestUtils {
    private DES_UtilTestClass utils;
    public Account acc {get;set;}
    public Opportunity opp {get;set;}
    public Product2 prod {get;set;}
    public PricebookEntry pbe {get;set;}
    public OpportunityLineItem oli {get;set;}
    public PRC_Pricing_Detail__c pd{get;set;}
    public PRC_Mitigant__c mitigant {get;set;}
    public PRC_PFS_Response priceFullResponse {get;set;}
    public PRC_PFS_Scenario selectedPrice {get;set;}
    public String amortization_csv_str {get;set;}
    private final String eur = 'EUR';
    private final String economicCapital = 'ECONOMIC_CAPITAL';
    /**
     * priceAmortData
     */
    public PRC_Price_Amortization_Data__c priceAmortData {get;set;}

    public PRC_TestUtils() {
        this.utils = new DES_UtilTestClass();
        this.loadOpportunity();
        this.loadcustomsettings();
        this.loadPFSResponseAndScenario();
        this.loadPRCAmortizationCsv();
        this.loadPriceAmortizationData();
    }
	public void loadOpportunity() {
        final Account acc = this.utils.createClient();
        acc.DES_Structure_Type__c = Label.DES_STR_TYPE_Subsidiary;
        acc.g_customer_id__c = 'Test';
        insert acc;
        this.acc = acc;

        final Product2 prod = this.utils.createProduct(LABEL.DES_Corporate_Loans);
        prod.DES_External_ID__c = 'Corporate Loans';
        insert prod; this.prod = prod;
        System.debug('prod : '+prod);

        final PricebookEntry  pbe = this.utils.createPricebookEntry(prod);
        insert pbe; this.pbe = pbe;

        final Opportunity opp = this.utils.createOpportunity(acc);
        Test.startTest();
        insert opp; this.opp = opp;
		
        OpportunityLineItem oli;
        oli = this.utils.createOppLineItem(opp, prod, pbe);
        //oli.solution_classification_desc__c = 'Corporate Loans';
        //oli.solution_name_path_desc__c = '';
        //oli.PRC_Pricing_Form_Edited_NEW__c = true;
        insert oli;   this.oli = oli;
        System.debug('oli des product name : '+oli.DES_Product_Name__c);

        this.pd = new PRC_Pricing_Detail__c();
        this.pd.opportunity_start_date__c = Date.today();
        this.pd.gf_non_accrual_comission_per__c = 12;
        this.pd.gf_accrual_per__c = 13;
        this.pd.PRC_Opportunity__c = this.opp.Id;
        this.pd.business_area_desc__c = 'GTB';
        this.pd.gf_operation_term_number__c = 'true';
        insert this.pd;
		Test.stopTest();
        this.mitigant = new PRC_Mitigant__c();
        this.mitigant.Pricing_Detail__c = this.pd.Id;
        this.mitigant.gf_warranty_type__c = 'Collateral';
        this.mitigant.gf_subwarranty_name__c = 'CASH';
        this.mitigant.gf_providing_warranty_ent_id__c = this.acc.g_customer_id__c;
        this.mitigant.gf_offer_warranty_country_type__c = 'AR';
        this.mitigant.gf_cty_rqst_wrrnty_risk_per__c = 34;
        this.mitigant.gf_mit_rk_rqst_warranty_per__c = 56;
        this.mitigant.gf_expir_wrrnty_operation_name__c = 'LESS_THAN_DEAL_MATURITY';
        this.mitigant.gf_end_guarantee_date__c = Date.today();
        this.mitigant.gf_gtr_debtor_group_ind_type__c = 'No';
        this.mitigant.gf_cvr_rk_cty_wrrnty_ind_type__c = 'Yes';
        this.mitigant.gf_oppy_mit_dif_ccy_ind_type__c = 'No';
        this.mitigant.gf_exprt_cr_eur_agncy_ind_type__c = 'Yes';
        this.mitigant.gf_mitigating_comment_desc__c = 'Test';
        this.mitigant.gf_external_rating_agncy_type__c = 'AAA';
        this.mitigant.gf_warranty_ptt_rating_type__c = 'AAA';
        this.mitigant.DES_Client_Mitigant__c = this.acc.Id;
        insert this.mitigant;
    }

    public OpportunityLineItem createOpportunityLineItem() {
        final OpportunityLineItem oli = this.utils.createOppLineItem(this.opp, this.prod, this.pbe);
        return oli;
    }
    public void loadcustomsettings() {
        final iaso__GBL_Rest_Services_Url__c cs =  new iaso__GBL_Rest_Services_Url__c();
        cs.Name = 'PRCCalculateMatrix_INT';
        cs.iaso__Blocked_Service__c = FALSE;
        cs.iaso__Cache_Partition__c = 'iaso.ServicesPartition';
        cs.iaso__Enable_Log__c = TRUE;
        cs.iaso__Timeout__c = 20000;
        cs.iaso__Url__c = 'https://ei-asoexternos.grupobbva.com/ESCD/risk-investment-banking-profitabilities/v0/risk-profitability-calculations';
        cs.iaso__isCacheInOrg__c = TRUE;
        cs.iaso__useEnqueueMethod__c = FALSE;
        insert cs;
    }

    public void loadPFSResponseAndScenario() {
        //Response
        this.priceFullResponse = new PRC_PFS_Response();
        this.priceFullResponse.data = new PRC_PFS_Response.data();
        this.priceFullResponse.data.id = 'fullResponse_001';

        this.priceFullResponse.data.engineWorksWith = new PRC_PFS_Response.responsebody();
        this.priceFullResponse.data.engineWorksWith.operations = new List<PRC_PFS_Operation>();
        PRC_PFS_Operation oper = new PRC_PFS_Operation();
            oper.amortization = new PRC_PFS_Operation_Amortization();
            oper.amortization.notional.onBalance = 1212;
            oper.amortization.margin.onBalance = 1212;
                        /* Obsoletoen V3.0
            oper.fees = new list<PRC_PFS_Operation.operationfee>();
            PRC_PFS_Operation.operationfee operFee1 = new PRC_PFS_Operation.operationfee();
            operFee1.id = 'NON_ACCRUAL';
            operFee1.value = 1100;
            PRC_PFS_Operation.operationfee operFee2 = new PRC_PFS_Operation.operationfee();
            operFee2.id = 'ACCRUAL';
            operFee2.value = 2200;
        oper.fees.add(operFee1);
        oper.fees.add(operFee2);
        */
        this.priceFullResponse.data.engineWorksWith.operations.add(oper);

        //Scenario
        this.selectedPrice = new PRC_PFS_Scenario();
        this.selectedPrice.id = 'scenario_001';
        this.selectedPrice.funds = new List<PRC_PFS_Scenario.fund>();
            PRC_PFS_Scenario.fund fu = new PRC_PFS_Scenario.fund();
            fu.onBalance = 111;
            fu.offBalance = 222;
        this.selectedPrice.funds.add(fu);


        final PRC_PFS_Scenario.margin scenariomargin = new PRC_PFS_Scenario.margin();
        scenariomargin.onBalance = 5;
        scenariomargin.offBalance = 19;
        final PRC_PFS_Scenario.fee scenariofee = new PRC_PFS_Scenario.fee(5,19);
        final PRC_PFS_Scenario.operation scenarioOperation = new PRC_PFS_Scenario.operation();
        scenarioOperation.margin = scenariomargin;
        scenarioOperation.fee = scenariofee;
        this.selectedPrice.operations = new List<PRC_PFS_Scenario.operation>();
        this.selectedPrice.operations.add(scenarioOperation);


        this.selectedPrice.profitabilityMetrics = new List<PRC_PFS_Scenario.profitabilityMetric>();
            PRC_PFS_Scenario.profitabilityMetric pm1 = new PRC_PFS_Scenario.profitabilityMetric();
            pm1.id = 'RAROEC_WITH_FUNDING';
            pm1.deal = 33;
            pm1.dealFirstTwelveMonths = 34;
            pm1.total = 35;
            pm1.totalFirstTwelveMonths = 36;
            PRC_PFS_Scenario.profitabilityMetric pm2 = new PRC_PFS_Scenario.profitabilityMetric();
            pm2.id = 'RAROEC_WITHOUT_FUNDING';
            pm2.deal = 33;
            PRC_PFS_Scenario.profitabilityMetric pm3 = new PRC_PFS_Scenario.profitabilityMetric();
            pm3.id = 'RORC_WITH_FUNDING';
            pm3.deal = 33;
            pm3.dealFirstTwelveMonths = 34;
            PRC_PFS_Scenario.profitabilityMetric pm4 = new PRC_PFS_Scenario.profitabilityMetric();
            pm4.id = 'RORC_WITHOUT_FUNDING';
            pm4.deal = 33;
        this.selectedPrice.profitabilityMetrics.add(pm1);
        this.selectedPrice.profitabilityMetrics.add(pm2);
        this.selectedPrice.profitabilityMetrics.add(pm3);
        this.selectedPrice.profitabilityMetrics.add(pm4);

        this.selectedPrice.sensitivities = new List<PRC_PFS_Scenario.sensitivity>();
            PRC_PFS_Scenario.sensitivity sensi1 = new PRC_PFS_Scenario.sensitivity();
            sensi1.id = 'SENSITIVITY';
            sensi1.margin = new PRC_PFS_Scenario.margin();
            sensi1.margin.onBalance = 44;
            sensi1.margin.offBalance = 44;

            PRC_PFS_Scenario.sensitivity sensi2 = new PRC_PFS_Scenario.sensitivity();
            sensi2.id = 'SENSITIVITY_END_OF_YEAR';
            sensi2.margin = new PRC_PFS_Scenario.margin();
            sensi2.margin.onBalance = 44;
            sensi2.margin.offBalance = 44;
        this.selectedPrice.sensitivities.add(sensi1);
        this.selectedPrice.sensitivities.add(sensi2);

        this.selectedPrice.allIn = new PRC_PFS_Scenario.allIn();
        this.selectedPrice.allIn.onBalance = 55;
        this.selectedPrice.allIn.offBalance = 55;

        this.selectedPrice.incomes = new list<PRC_PFS_Scenario.income>();
        PRC_PFS_Scenario.income inc = new PRC_PFS_Scenario.income();
            inc.id = 'DEAL_END_OF_YEAR';
            inc.amount = 66;
            inc.currenc_y = eur;
        this.selectedPrice.incomes.add(inc);

        this.selectedPrice.exposuresAtDefault = new list<PRC_PFS_Scenario.exposuresAtDefault>();
        PRC_PFS_Scenario.exposuresAtDefault ead = new PRC_PFS_Scenario.exposuresAtDefault();
            ead.model = 'ECONOMICAL';
            ead.amount = 77;
            ead.currenc_y = eur;
        this.selectedPrice.exposuresAtDefault.add(ead);

        this.selectedPrice.maxBalance = 888;
        this.selectedPrice.averageLifeInYears = 888;

        this.selectedPrice.creditRisks = new list<PRC_PFS_Scenario.creditRisk>();
        PRC_PFS_Scenario.creditRisk cr = new PRC_PFS_Scenario.creditRisk();
            cr.id = 'CREDIT_RISK';
            cr.amounts = new list<PRC_PFS_Scenario.amount>();
                PRC_PFS_Scenario.amount amo1 = new PRC_PFS_Scenario.amount();
                amo1.id = 'EXPECTED_LOSS';
                amo1.amount = 7770;
                PRC_PFS_Scenario.amount amo2 = new PRC_PFS_Scenario.amount();
                amo2.id = economicCapital;
                amo2.amount = 7771;
            cr.amounts.add(amo1);
            cr.amounts.add(amo2);
        this.selectedPrice.creditRisks.add(cr);

        this.selectedPrice.averageLossGivenDefault = 91;
        this.selectedPrice.equivalentRating = 'equivalentRating';

        this.selectedPrice.currencyFactor = 1;
        this.selectedPrice.regulatoryExpectedLoss = 1;
        this.selectedPrice.netFundingCostInCash = 1;
        this.selectedPrice.fundingDuration = 1;

        final PRC_PFS_Scenario.maximumBalance maximumBalance = new PRC_PFS_Scenario.maximumBalance();
        maximumBalance.amount = 1;
        maximumBalance.currenc_y = eur;
        this.selectedPrice.maximumBalance = maximumBalance;

        final PRC_PFS_Scenario.netProfit netProfit = new PRC_PFS_Scenario.netProfit();
        netProfit.amount = 1;
        netProfit.currenc_y = eur;
        this.selectedPrice.netProfit = netProfit;

        final List<PRC_PFS_Scenario.amounts> amountsList = new List<PRC_PFS_Scenario.amounts>();
        final PRC_PFS_Scenario.amounts amountEconomic = new PRC_PFS_Scenario.amounts();
        amountEconomic.amount = 1;
        amountEconomic.currenc_y = eur;
        amountEconomic.id = economicCapital;

        final PRC_PFS_Scenario.amounts amountsRegulatory = new PRC_PFS_Scenario.amounts();
        amountsRegulatory.amount = 1;
        amountsRegulatory.currenc_y = eur;
        amountsRegulatory.id = 'REGULATORY_CAPITAL';

        amountsList.add(amountEconomic);
        amountsList.add(amountsRegulatory);

        final PRC_PFS_Scenario.operationalRisks operationalRisks = new PRC_PFS_Scenario.operationalRisks();
        operationalRisks.amounts = amountsList;

        // Scenario Results
        this.selectedPrice.results = new list<PRC_PFS_Scenario.result> ();
        PRC_PFS_Scenario.result result1 = new PRC_PFS_Scenario.result();
            result1.interest = new PRC_PFS_Scenario.interest();
            result1.interest.amount = 1111;
            result1.resultType = 'ANNUAL';
            result1.year = 2020;
            result1.offerRate = 11111;
            result1.operationalRisk = 11113;
            result1.taxes = 11114;
            result1.amounts = new List<PRC_PFS_Scenario.amount>();
                PRC_PFS_Scenario.amount r1_am1 = new PRC_PFS_Scenario.amount();
                    r1_am1.id = 'FUNDING_COST';
                    r1_am1.amount = 1111;
                PRC_PFS_Scenario.amount r1_am2 = new PRC_PFS_Scenario.amount();
                    r1_am2.id = 'ACCRUAL_FEES';
                    r1_am2.amount = 1112;
                PRC_PFS_Scenario.amount r1_am3 = new PRC_PFS_Scenario.amount();
                    r1_am3.id = 'UPFRONT_FEES';
                    r1_am3.amount = 1113;
                PRC_PFS_Scenario.amount r1_am4 = new PRC_PFS_Scenario.amount();
                    r1_am4.id = economicCapital;
                    r1_am4.amount = 1114;
                PRC_PFS_Scenario.amount r1_am5 = new PRC_PFS_Scenario.amount();
                    r1_am5.id = 'EXPECTED_LOSS';
                    r1_am5.amount = 1115;
                PRC_PFS_Scenario.amount r1_am6 = new PRC_PFS_Scenario.amount();
                    r1_am6.id = 'EXPECTED_LOSS_FOR_RORC';
                    r1_am6.amount = 1116;
                PRC_PFS_Scenario.amount r1_am7 = new PRC_PFS_Scenario.amount();
                    r1_am7.id = 'OPEX_VALUE';
                    r1_am7.amount = 1117;
                PRC_PFS_Scenario.amount r1_am8 = new PRC_PFS_Scenario.amount();
                    r1_am8.id = 'EXPOSURE_AT_DEFAULT';
                    r1_am8.amount = 1118;
                    r1_am8.currenc_y = eur;
            result1.amounts.add(r1_am1);
            result1.amounts.add(r1_am2);
            result1.amounts.add(r1_am3);
            result1.amounts.add(r1_am4);
            result1.amounts.add(r1_am5);
            result1.amounts.add(r1_am6);
            result1.amounts.add(r1_am7);
            result1.amounts.add(r1_am8);
            result1.timeGap = 1;

            List<PRC_PFS_Scenario.riskWeightedAssests> riskWAList = new List<PRC_PFS_Scenario.riskWeightedAssests>();

            final PRC_PFS_Scenario.riskWeightedAssests rwa = new PRC_PFS_Scenario.riskWeightedAssests();
            rwa.amount = 1;
            rwa.currenc_y = eur;
            rwa.id = 'REGULATORY_BY_CREDIT_RISK';
            riskWAList.add(rwa);

            result1.riskWeightedAssests = riskWAList;

        PRC_PFS_Scenario.result result2 = new PRC_PFS_Scenario.result();
            result2.interest = new PRC_PFS_Scenario.interest();
            result2.interest.amount = 1111;
            result2.interest.currenc_y = eur;
            result2.resultType = 'ACCUMULATED';
            result2.year = 2020;
            result2.offerRate = 11111;
            result2.operationalRisk = 11113;
            result2.taxes = 11114;
            result2.amounts = new List<PRC_PFS_Scenario.amount>();
                PRC_PFS_Scenario.amount r2_am1 = new PRC_PFS_Scenario.amount();
                    r2_am1.id = 'FUNDING_COST';
                    r2_am1.amount = 1111;
                PRC_PFS_Scenario.amount r2_am2 = new PRC_PFS_Scenario.amount();
                    r2_am2.id = 'ACCRUAL_FEES';
                    r2_am2.amount = 1112;
                PRC_PFS_Scenario.amount r2_am3 = new PRC_PFS_Scenario.amount();
                    r2_am3.id = 'UPFRONT_FEES';
                    r2_am3.amount = 1113;
                PRC_PFS_Scenario.amount r2_am4 = new PRC_PFS_Scenario.amount();
                    r2_am4.id = economicCapital;
                    r2_am4.amount = 1114;
                PRC_PFS_Scenario.amount r2_am5 = new PRC_PFS_Scenario.amount();
                    r2_am5.id = 'EXPECTED_LOSS';
                    r2_am5.amount = 1115;
                PRC_PFS_Scenario.amount r2_am6 = new PRC_PFS_Scenario.amount();
                    r2_am6.id = 'EXPECTED_LOSS_FOR_RORC';
                    r2_am6.amount = 1116;
                PRC_PFS_Scenario.amount r2_am7 = new PRC_PFS_Scenario.amount();
                    r2_am7.id = 'OPEX_VALUE';
                    r2_am7.amount = 1117;
                PRC_PFS_Scenario.amount r2_am8 = new PRC_PFS_Scenario.amount();
                    r2_am8.id = 'EXPOSURE_AT_DEFAULT';
                    r2_am8.amount = 1118;
                    r2_am8.currenc_y = eur;
            result2.amounts.add(r2_am1);
            result2.amounts.add(r2_am2);
            result2.amounts.add(r2_am3);
            result2.amounts.add(r2_am4);
            result2.amounts.add(r2_am5);
            result2.amounts.add(r2_am6);
            result2.amounts.add(r2_am7);
            result2.amounts.add(r2_am8);

        this.selectedPrice.results.add(result1);
        this.selectedPrice.results.add(result2);
    }

    public void loadPRCAmortizationCsv() {
        this.amortization_csv_str = 'Fecha;NominalDB;NominalFB;SpreadDB;SpreadFB;Comision' + '\r\n' + '3/31/2020;71058.38;178941.62;162.5;50;110' + '\r\n' + '4/31/2020;71058.38;178941.62;162.5;50;90';
    }

    /**
    * @description
    * @author Global Desktop | 03-08-2021
    **/
    public void loadPriceAmortizationData() {
        priceAmortData = new PRC_Price_Amortization_Data__c();
        priceAmortData.PRC_Opportunity__c = opp.Id;
        insert priceAmortData;
    }


}