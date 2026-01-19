/**********************************************************************************
* @author       Global Desktop
* @date         30/06/2018
* @description  Clase controladora de apoyo para triggers en procesos configuración de productos con/sin tramos en oportunidades
* @Revision
06/05/2019 Añadidos methods y lógica relativa para productos con tramos; y cambios en configuración productos CL, LBOs y PFL
01/07/2019 Añadidos methods y lógica relativa para resto de productos; Refactorización
**********************************************************************************/
public with sharing class DES_relatedProductsTriggerHandler { //NOSONAR
    
    private static final CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    
    /* Variable para diferenciar subproducto TB Guarantees en producto Working Capital */
    private static final String TB_GUARANTEES = 'TB Guarantees';
    
    /* Variable para diferenciar subproducto Credit Accounts en producto Working Capital */
    private static final String CREDIT_ACCOUNTS = 'Credit Accounts';
    
    /* Variable para diferenciar subproducto Bilateral Loans en producto Working Capital */
    private static final String BILATERAL = 'Bilateral Loans';
    
    /* Variable para diferenciar subproducto Renting en producto Working Capital */
    private static final String RENTING = 'Renting';
    
    /* Variable para diferenciar subproducto Leasing en producto Working Capital */
    private static final String LEASING = 'Leasing';
    
    /* Variable para diferenciar subproducto SCF - Factoring en producto Working Capital */
    private static final String FACTORING = 'SCF - Factoring';
    
    /* Variable para diferenciar subproducto SCF - Reverse factoring en producto Working Capital */
    private static final String REVERSE = 'SCF - Reverse factoring';
    
    /* Variable para diferenciar subproducto Issuance of Import LC en producto Transaction Trade Finance */
    private static final String ISSUE_IMPORT = 'Issuance of Import LC';
    
    /* Variable para diferenciar subproducto Import LC with Beneficiary Financing en producto Transaction Trade Finance */
    private static final String BENEF_FINANCE = 'Import LC with Beneficiary Financing';
    
    /* Variable para diferenciar subproducto LC Confirmation and Discount en producto Transaction Trade Finance */
    private static final String CONFIRM_DISC = 'LC Confirmation and Discount';
    
    /* Variable para diferenciar subproducto LC Confirmation and Post-financing en producto Transaction Trade Finance */
    private static final String CONFIRM_POST = 'LC Confirmation and Post-financing';
    
    /* Variable para diferenciar subproducto LC Silent Confirmation en producto Transaction Trade Finance */
    private static final String LC_SILENT_CONFIRM = 'LC Silent Confirmation';
    
    /* Variable para diferenciar subproducto LC Confirmation en producto Transaction Trade Finance */
    private static final String LC_CONFIRMATION = 'LC Confirmation';
    
    /* Variable para diferenciar subproducto Silent Guarantee Issuance & Financing en producto Transaction Trade Finance */
    private static final String SILENT_GUA_FIN = 'Silent Guarantee Issuance & Financing';
    
    /* Variable para diferenciar subproducto Accounts en producto Client Resources */
    private static final String SUBPROD_ACCOUNTS = 'Accounts';
    
    /* Variable para diferenciar subproducto Accounts en producto Client Resources */
    private static final String SUBPROD_FIEM = 'FIEM';
    
    /* Variable para diferenciar subproducto Accounts en producto Client Resources */
    private static final String SUBPROD_ECAG = 'ECA Guarantee';
    
    /* Variable para diferenciar producto Channels en producto Cash Management */
    private static final String PROD_CHANNELS = 'Channels';
    
    /** Constante con la opcion 'Mandatory sell down' del picklist underwriting_agreement_type__c */
    private static final String UW_MSD = 'Mandatory sell down';
    
    /** Constante con la opcion 'Deal not materialised' del picklist underwriting_agreement_type__c */
    private static final String UW_DNM = 'Deal not materialised';
    
    /** Constante con la opcion 'Yes' del picklist underwriting_agreement_type__c */
    private static final String UW_YES = 'Yes';
    
    /** Constante con la opcion 'No' del picklist underwriting_agreement_type__c */
    private static final String UW_NO = 'No';
    
    /** Constante con la opcion 'Best Efforts' del picklist underwriting_agreement_type__c */
    private static final String UW_BE = 'Best Efforts';
    
    
    /*
    * Constructor de instancia sin argumentos
    **/
    private DES_relatedProductsTriggerHandler() {
        System.debug('DES_relatedProductsTriggerHandler');
    }
    
    /*
    *   @author Global Desktop
    **/
    public static void setClosedDate(List<Opportunity> triggerNew) {//NOSONAR
        for(Opportunity opp : triggerNew) {
            if((opp.StageName == Label.DES_Closed_Won || opp.StageName == Label.DES_Closed_Lose) && opp.DES_Date_Won_Lost__c == null) {
                opp.DES_Date_Won_Lost__c = Date.today();
            }
        }
    }
    
    /*
    * Lanza el proceso de autorelleno de campos según producto
    *
    * @input   Map<Id,OpportunityLineItem> cmplxItemsNew   -   mapa ollis con campos a autorellenar(Opportuniy Product)
    * @input   Map<Id,OpportunityLineItem> cmplxItemsOld   -   mapa ollis antiguos (Opportuniy Product)
    *
    *
    **/
    public static void checkAutoFillFields(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld) { //NOSONAR
        final Map<Id,fprd__GBL_Product_version__c> mapPVersions =
        new Map<Id,fprd__GBL_Product_version__c>([SELECT fprd__Version_number__c FROM fprd__GBL_Product_version__c LIMIT 50000]);
        for (OpportunityLineItem olli : mapOppliNew.values()) {
            if(!userSettings.CIB_Is_Admin__c) {
                final fprd__GBL_Product_version__c pVersion = mapPVersions.get(olli.fprd__GBL_Product_version__c);
                final Set<String> manualProducts = new Set<String>{Label.DES_Equity,Label.DES_FX,Label.DES_Credit,Label.DES_Rates};
                final Set<String> gfProducts = new Set<String>{Label.DES_Corporate_Loans,Label.DES_Leverage_Buyout_LBOs,Label.DES_Project_Finance_Lending,Label.DES_Project_Finance_Advisory,Label.DES_FI_capital_Solutions,Label.DES_Rating_Advisory,Label.DES_Liability_Management};
                final Set<String> cfProducts = new Set<String>{Label.DES_Equity_Capital_Markets,Label.DES_Mergers_Acquisitions};
                
                //Si el producto no es multitranche y tiene campos autoinformados, se resetea su Potential Revenues y se lanza el proceso
                // Siempre que su product version sea 2 (corresponde a oportunidad 2.0)
                final Boolean hasTranche = olli.multi_tranche_type__c == Label.DES_YES;
                final Boolean isOppVer2 = pVersion != null && pVersion.fprd__Version_number__c == 2;
                if(hasTranche) {
                    return;
                } else if(pVersion != null && pVersion.fprd__Version_number__c == 1 //WC en Opp 1.0
                && olli.solution_classification_desc__c == Label.DES_Working_Capital && olli.DES_Risk_Fee_Next_12_Months__c != null
                && olli.syndicated_loan_drawn_amount__c != null) {
                    olli.pre_endrs_fee_next_12m_amount__c = (olli.DES_Risk_Fee_Next_12_Months__c/10000) * olli.syndicated_loan_drawn_amount__c;
                } else if(isOppVer2 && manualProducts.contains(olli.solution_classification_desc__c)) { //Pot. Revenues manuales opp 2.0
                    olli.fee_next_12m_amount__c = olli.pre_oppy_revenue_next_12m_amount__c;
                } else if(isOppVer2) { //Resto productos en opp 2.0 relleno automatico
                    olli.pre_oppy_revenue_next_12m_amount__c = 0;
                    if(gfProducts.contains(olli.solution_classification_desc__c)) {
                        olli = checkAutoFillGF(olli);
                    } else if(cfProducts.contains(olli.solution_classification_desc__c)) {
                        olli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(olli.pre_oppy_revenue_next_12m_amount__c,olli.fee_next_12m_amount__c);
                        olli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(olli.pre_oppy_revenue_next_12m_amount__c,olli.retainer_fee_12m_amount__c);
                    } else {
                        olli = checkFieldsByFamily(olli);
                    }
                }
            }
        }
    }
    
    /*
    * Rellena campos autoinformados si estos no se van a rellenar con valores de tramo
    *
    * @input   OpportunityLineItem olli             -   olli a checkear (Opportuniy Product)
    * @return  OpportunityLineItem newValuesOlli    -   olli con nuevos valores calculados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem checkFieldsByFamily(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        
        if(newValuesOlli.solution_classification_desc__c == Label.DES_Debt_Capital_Markets) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Cash_Management || newValuesOlli.solution_classification_desc__c == Label.DES_Client_Resources) {
            newValuesOlli = checkAutoFillGTB1(newValuesOlli);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Securities_Services || newValuesOlli.solution_classification_desc__c == Label.DES_Working_Capital
        || newValuesOlli.solution_classification_desc__c == Label.DES_Structure_Trade_Finance || newValuesOlli.solution_classification_desc__c == Label.DES_Transaction_Trade_Finance) {
            newValuesOlli = checkAutoFillGTB2(newValuesOlli);
        }
        
        return newValuesOlli;
    }
    
    /*
    * Rellena campos autoinformados si estos no se van a rellenar con valores de tramo para familia productos GF
    *
    * @input   OpportunityLineItem olli             -   olli a checkear (Opportuniy Product)
    * @return  OpportunityLineItem newValuesOlli    -   olli con nuevos valores calculados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem checkAutoFillGF(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        
        if(newValuesOlli.solution_classification_desc__c == Label.DES_Corporate_Loans) {
            newValuesOlli = fillAutoFields(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
            
            //newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.gf_upfront_undwr_fees_amount__c); //MAXMIX4-3058
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.gf_own_undwr_mk_rsk_fee_amount__c); //MAXMIX4-3058
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c -= newValuesOlli.gf_est_fee_cust_sycr_amount__c; //MAXMIX4-3058
            
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Leverage_Buyout_LBOs) {
            newValuesOlli = fillAutoFields(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
            
            //newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.gf_upfront_undwr_fees_amount__c); //MAXMIX4-3058
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.gf_own_undwr_mk_rsk_fee_amount__c); //MAXMIX4-3058
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c -= newValuesOlli.gf_est_fee_cust_sycr_amount__c; //MAXMIX4-3058
            
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Project_Finance_Lending) {
            newValuesOlli = fillAutoFields(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
            
            
            //newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.gf_upfront_undwr_fees_amount__c); //MAXMIX4-3058
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.gf_own_undwr_mk_rsk_fee_amount__c); //MAXMIX4-3058
            
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c -= newValuesOlli.gf_est_fee_cust_sycr_amount__c; //MAXMIX4-3058
            
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Project_Finance_Advisory) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.retainer_fee_12m_amount__c);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Liability_Management) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = newValuesOlli.fee_next_12m_amount__c;
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Rating_Advisory) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = newValuesOlli.fee_next_12m_amount__c;
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_FI_capital_Solutions) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = newValuesOlli.fee_next_12m_amount__c;
        }
        
        return newValuesOlli;
    }
    
    /*
    * Rellena campos autoinformados si estos no se van a rellenar con valores de tramo para familia productos GTB
    *
    * @input   OpportunityLineItem olli             -   olli a checkear (Opportuniy Product)
    * @return  OpportunityLineItem olli             -   olli con nuevos valores calculados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem checkAutoFillGTB1(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        
        if(newValuesOlli.solution_classification_desc__c == Label.DES_Cash_Management && newValuesOlli.subproduct_name__c == PROD_CHANNELS) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.opening_fee_amount__c);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Cash_Management) {
            newValuesOlli = fillFeesN12M(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli = fillIncomeRelatedAverageBalance(newValuesOlli);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Client_Resources ) {
            newValuesOlli = autoFillClientResources(newValuesOlli);
        }
        
        return olli;
    }
    
    /*
    * Calcula campo "Estimated Incomes Related to Average Balance Next 12 Months" para producto Cash Management
    *
    * @input   OpportunityLineItem olli             -   olli a checkear (Opportuniy Product)
    * @return  OpportunityLineItem olli             -   olli con nuevos valores calculados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem fillIncomeRelatedAverageBalance(OpportunityLineItem olli) {
        if(olli.DES_Funding_Transfer_Price__c!=null && olli.avg_balance_annual_amount__c!=null) {  //NOSONAR
            olli.bbva_est_incm_next_12m_amount__c = (olli.DES_Funding_Transfer_Price__c/100) * olli.avg_balance_annual_amount__c;
            olli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(olli.pre_oppy_revenue_next_12m_amount__c,olli.bbva_est_incm_next_12m_amount__c);
        } else {
            olli.bbva_est_incm_next_12m_amount__c = 0;
        }
        
        return olli;
    }
    
    /*
    * Rellena campos autoinformados si estos no se van a rellenar con valores de tramo para producto GTB - Client Resources
    *
    * @input   OpportunityLineItem olli             -   olli a checkear (Opportuniy Product)
    * @return  OpportunityLineItem olli             -   olli con nuevos valores calculados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem autoFillClientResources(OpportunityLineItem olli) {
        if(olli.solution_name_path_desc__c == SUBPROD_ACCOUNTS && olli.pre_net_margin_next_12m_per__c!=null && olli.avg_balance_annual_amount__c != null) {
            olli.loan_tenor_month_desc__c = 0;
            olli.deal_total_amount__c = 0;
            olli.pre_net_margin_next_12m_amount__c = (olli.pre_net_margin_next_12m_per__c/10000) * olli.avg_balance_annual_amount__c;
        } else if(olli.pre_net_margin_next_12m_per__c!=null && olli.loan_tenor_month_desc__c != null && olli.deal_total_amount__c != null) { //NOSONAR
            olli.avg_balance_annual_amount__c = 0;
            olli.pre_net_margin_next_12m_amount__c = (olli.pre_net_margin_next_12m_per__c/10000) * olli.deal_total_amount__c * (olli.loan_tenor_month_desc__c/12);
        } else {
            olli.pre_net_margin_next_12m_amount__c = 0;
        }
        olli.pre_oppy_revenue_next_12m_amount__c = olli.pre_net_margin_next_12m_amount__c;
        olli.fee_next_12m_amount__c = olli.pre_oppy_revenue_next_12m_amount__c;
        
        return olli;
    }
    
    /*
    * Rellena campos autoinformados si estos no se van a rellenar con valores de tramo para familia productos GTB
    *
    * @input   OpportunityLineItem olli             -   olli a checkear (Opportuniy Product)
    * @return  OpportunityLineItem newValuesOlli    -   olli con nuevos valores calculados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem checkAutoFillGTB2(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        
        if(newValuesOlli.solution_classification_desc__c == Label.DES_Securities_Services) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(olli.pre_oppy_revenue_next_12m_amount__c,olli.fee_next_12m_amount__c);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Working_Capital) {
            newValuesOlli = fillWorkingCapitalFields(newValuesOlli);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Structure_Trade_Finance) {
            newValuesOlli = fillStructureTradeFields(newValuesOlli);
        } else if(newValuesOlli.solution_classification_desc__c == Label.DES_Transaction_Trade_Finance) {
            newValuesOlli = fillTransactionTradeFields(newValuesOlli);
        }
        
        return newValuesOlli;
    }
    
    /*
    * Rellena campos autoinformados de producto GTB - Structured Trade Finance
    *
    * @input   OpportunityLineItem olli   -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campos informados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem fillStructureTradeFields(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        
        newValuesOlli = fillAutoFields(newValuesOlli);
        if(newValuesOlli.solution_name_path_desc__c == SUBPROD_FIEM) {
            newValuesOlli.DES_Risk_Fee_Next_12_Months__c = 0;
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.opening_fee_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.periodic_fee_amount__c);
        } else if(newValuesOlli.solution_name_path_desc__c == SUBPROD_ECAG) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli = fillRiskFeeAmount(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_endrs_fee_next_12m_amount__c);
        } else {
            newValuesOlli.DES_Risk_Fee_Next_12_Months__c = 0;
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
        }
        
        return newValuesOlli;
    }
    
    /*
    * Rellena campos de fórmula si estos no se van a rellenar con valores de tramo (Deferred/Non-Deferred amount y Fees Next 12 Months)
    *
    * @input   OpportunityLineItem olli   -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campos informados (Opportuniy Product)
    *
    **/
    private static OpportunityLineItem fillFeesN12M(OpportunityLineItem olli) { //NOSONAR
        Boolean fromFillAuto = olli.deferred_fee_per__c != null && olli.opening_fee_amount__c!=null && olli.loan_tenor_month_desc__c != null && olli.loan_tenor_month_desc__c != 0; //NOSONAR
        
        if(olli.solution_classification_desc__c == Label.DES_Cash_Management && olli.unit_price_with_tax_amount__c!=null && olli.opportunity_sold_prdt_number__c!=null
        && olli.unit_price_with_tax_amount__c!=0 && olli.opportunity_sold_prdt_number__c!=0) {
            olli.DES_Price_Percent__c = 0;
            olli.DES_Volume_in_Amounts__c = 0;
            olli.fee_next_12m_amount__c = olli.unit_price_with_tax_amount__c * olli.opportunity_sold_prdt_number__c;
        } else if(olli.solution_classification_desc__c == Label.DES_Cash_Management && olli.DES_Price_Percent__c!=null && olli.DES_Volume_in_Amounts__c!=null
        && olli.DES_Price_Percent__c!=0 && olli.DES_Volume_in_Amounts__c!=0) {
            olli.unit_price_with_tax_amount__c = 0;
            olli.opportunity_sold_prdt_number__c = 0;
            olli.fee_next_12m_amount__c = (olli.DES_Price_Percent__c/100) * olli.DES_Volume_in_Amounts__c;
        } else if(fromFillAuto) {
            olli.deferred_fee_amount__c = (olli.opening_fee_amount__c * (olli.deferred_fee_per__c/100)) / (olli.loan_tenor_month_desc__c/12);
            olli.no_deferred_fee_amount__c = olli.opening_fee_amount__c * ((100-olli.deferred_fee_per__c)/100);
            olli.fee_next_12m_amount__c = olli.deferred_fee_amount__c + olli.no_deferred_fee_amount__c;
            olli.fee_next_12m_amount__c = sumIfNotNull(olli.fee_next_12m_amount__c,olli.periodic_fee_amount__c);
            olli.fee_next_12m_amount__c = sumIfNotNull(olli.fee_next_12m_amount__c,olli.underwriting_fee_amount__c);
        } else {
            olli.deferred_fee_amount__c = 0;
            olli.no_deferred_fee_amount__c = 0;
            olli.fee_next_12m_amount__c = 0;
        }
        
        return olli;
    }
    
    /*
    * Rellena campos de fórmula si estos no se van a rellenar con valores de tramo (Annual Commitment Fee N12M y Margin Net of Funding Cost)
    *
    * @input   OpportunityLineItem olli   -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campos informados (Opportuniy Product)
    *
    **/
    private static OpportunityLineItem fillAverageDrawnFields(OpportunityLineItem olli) {
        if(olli.undrawn_fee_next_12m_per__c == null || olli.credit_undrawn_next_12m_per__c == null || olli.syndicated_loan_drawn_amount__c == null) {
            olli.undrawn_fee_next_12m_amount__c = 0;
        } else {
            olli.undrawn_fee_next_12m_amount__c = olli.syndicated_loan_drawn_amount__c * (olli.credit_undrawn_next_12m_per__c/100) * (olli.undrawn_fee_next_12m_per__c/10000);
        }
        
        if(olli.pre_net_margin_next_12m_per__c == null || olli.credit_drawn_next_12m_per__c == null || olli.syndicated_loan_drawn_amount__c == null) {
            olli.pre_net_margin_next_12m_amount__c = 0;
        } else {
            olli.pre_net_margin_next_12m_amount__c = (olli.pre_net_margin_next_12m_per__c/10000) * olli.syndicated_loan_drawn_amount__c * (olli.credit_drawn_next_12m_per__c/100);
        }
        
        return olli;
    }
    
    /*
    * Rellena campos autoinformados de producto GTB - Working Capital
    *
    * @input   OpportunityLineItem olli   -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campos informados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem fillWorkingCapitalFields(OpportunityLineItem olli) { //NOSONAR
        OpportunityLineItem newValuesOlli = olli;
        newValuesOlli.opening_fee_amount__c = 0;
        newValuesOlli.fee_next_12m_amount__c = 0;
        newValuesOlli.pre_endrs_fee_next_12m_amount__c = 0;
        newValuesOlli.pre_net_margin_next_12m_amount__c = 0;
        newValuesOlli.undrawn_fee_next_12m_amount__c = 0;
        
        //newValuesOlli.syndicated_loan_drawn_amount__c!=null && newValuesOlli.opening_fee_per__c!=null
        if(newValuesOlli.opening_fee_per__c==null || newValuesOlli.opening_fee_per__c== 0) {
            newValuesOlli.opening_fee_amount__c = 0;
        } else {
            final set<String> validUWType = new Set<String> {UW_DNM, UW_MSD, UW_BE};
            if(validUWType.contains(newValuesOlli.underwriting_agreement_type__c)) {
                if(newValuesOlli.gf_synd_fnl_primry_allc_amount__c==null) {
                    newValuesOlli.opening_fee_amount__c = 0;
                } else {
                    newValuesOlli.opening_fee_amount__c = newValuesOlli.gf_synd_fnl_primry_allc_amount__c * (newValuesOlli.opening_fee_per__c/10000);
                } 
            } else if(newValuesOlli.underwriting_agreement_type__c == UW_YES) {
                if(newValuesOlli.bbva_prtcp_tranche_amount__c==null) {
                    newValuesOlli.opening_fee_amount__c = 0;
                } else {
                    newValuesOlli.opening_fee_amount__c = newValuesOlli.bbva_prtcp_tranche_amount__c * (newValuesOlli.opening_fee_per__c/10000);
                }
            } else if(newValuesOlli.underwriting_agreement_type__c == UW_NO) {
                if(newValuesOlli.syndicated_loan_drawn_amount__c==null) {
                    newValuesOlli.opening_fee_amount__c = 0;
                } else {
                    newValuesOlli.opening_fee_amount__c = (newValuesOlli.opening_fee_per__c/10000) * newValuesOlli.syndicated_loan_drawn_amount__c;            
                }
            }
            newValuesOlli.fee_next_12m_amount__c =  newValuesOlli.opening_fee_amount__c;
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.fee_next_12m_amount__c);
        }
        
        if(newValuesOlli.solution_name_path_desc__c == TB_GUARANTEES && newValuesOlli.DES_Risk_Fee_Next_12_Months__c != null && newValuesOlli.syndicated_loan_drawn_amount__c != null) {
            newValuesOlli.opening_fee_per__c = 0;
            newValuesOlli.undrawn_fee_next_12m_per__c = 0;
            newValuesOlli.pre_gross_margin_next_12m_per__c = 0;
            newValuesOlli.credit_drawn_next_12m_per__c = 0;
            newValuesOlli.funding_cost_per__c = 0;
            newValuesOlli = fillRiskFeeAmount(newValuesOlli);
            if(newValuesOlli.loan_tenor_month_desc__c != null) {
                newValuesOlli.pre_oppy_revenue_next_12m_amount__c = newValuesOlli.pre_endrs_fee_next_12m_amount__c * newValuesOlli.loan_tenor_month_desc__c/12;
            }
        } else if(newValuesOlli.solution_name_path_desc__c == CREDIT_ACCOUNTS) {
            newValuesOlli.DES_Risk_Fee_Next_12_Months__c = 0;
            newValuesOlli = fillAverageDrawnFields(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
        } else if((newValuesOlli.solution_name_path_desc__c == BILATERAL || newValuesOlli.solution_name_path_desc__c == FACTORING || newValuesOlli.solution_name_path_desc__c == REVERSE)
        && newValuesOlli.pre_net_margin_next_12m_amount__c != null && newValuesOlli.loan_tenor_month_desc__c != null) {
            newValuesOlli.undrawn_fee_next_12m_per__c = 0;
            newValuesOlli.DES_Risk_Fee_Next_12_Months__c = 0;
            newValuesOlli.credit_drawn_next_12m_per__c = 100;
            newValuesOlli = fillAverageDrawnFields(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c += newValuesOlli.pre_net_margin_next_12m_amount__c * newValuesOlli.loan_tenor_month_desc__c/12;
        } else if(newValuesOlli.solution_name_path_desc__c == RENTING || newValuesOlli.solution_name_path_desc__c == LEASING) {
            newValuesOlli.undrawn_fee_next_12m_per__c = 0;
            newValuesOlli.DES_Risk_Fee_Next_12_Months__c = 0;
            newValuesOlli.credit_drawn_next_12m_per__c = 100;
            newValuesOlli = fillAverageDrawnFields(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
        }
        
        return newValuesOlli;
    }
    
    /*
    * Rellena campos autoinformados de producto GTB - Transaction Trade Finance
    *
    * @input   OpportunityLineItem olli            -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem newValuesOlli   -   olli con campos informados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem fillTransactionTradeFields(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        
        newValuesOlli = fillAutoFields(newValuesOlli);
        newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.deferred_fee_amount__c);
        newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.no_deferred_fee_amount__c);
        
        final Set<String> listTTFProds = new Set<String>{Label.DES_Prod_Trade_Loans,Label.DES_Prod_Factoring,Label.DES_Prod_Forfaiting,Label.DES_Prod_SCF};
        if(listTTFProds.contains(newValuesOlli.subproduct_name__c)) {
            newValuesOlli.DES_Risk_Fee_Next_12_Months__c = 0;
            newValuesOlli.pre_endrs_fee_next_12m_amount__c = 0;
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            newValuesOlli.fee_next_12m_amount__c = newValuesOlli.pre_oppy_revenue_next_12m_amount__c;
        } else if(newValuesOlli.subproduct_name__c == Label.DES_Prod_Guarantees_SBLCs) {
            newValuesOlli.undrawn_fee_next_12m_per__c = 0;
            newValuesOlli.undrawn_fee_next_12m_amount__c = 0;
            newValuesOlli = fillRiskFeeAmount(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_endrs_fee_next_12m_amount__c);
            if(newValuesOlli.solution_name_path_desc__c == SILENT_GUA_FIN) {
                newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            } else {
                newValuesOlli.pre_gross_margin_next_12m_per__c = 0;
                newValuesOlli.credit_drawn_next_12m_per__c = 0;
                newValuesOlli.funding_cost_per__c = 0;
                newValuesOlli.pre_net_margin_next_12m_amount__c = 0;
            }
            newValuesOlli.fee_next_12m_amount__c = newValuesOlli.pre_oppy_revenue_next_12m_amount__c;
        } else if(newValuesOlli.subproduct_name__c == Label.DES_Prod_Letter_of_Credit) {
            newValuesOlli = fillLetterOfCreditTTF(newValuesOlli);
        }
        
        return newValuesOlli;
    }
    
    /*
    * Rellena campos autoinformados de producto GTB - TTF - Letter of Credit
    *
    * @input   OpportunityLineItem olli   -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campos informados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem fillLetterOfCreditTTF(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        final Set<String> listLoCSub1 = new Set<String>{BENEF_FINANCE,CONFIRM_DISC,CONFIRM_POST};
        final Set<String> listLoCSub2 = new Set<String>{LC_SILENT_CONFIRM,LC_CONFIRMATION,ISSUE_IMPORT}; //NOSONAR si no dice potentially unused por else if
        
        if(listLoCSub1.contains(newValuesOlli.solution_name_path_desc__c)) {
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            newValuesOlli = fillRiskFeeAmount(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_endrs_fee_next_12m_amount__c);
            newValuesOlli.fee_next_12m_amount__c = newValuesOlli.pre_oppy_revenue_next_12m_amount__c;
        } else if(listLoCSub2.contains(newValuesOlli.solution_name_path_desc__c)) {
            newValuesOlli.pre_gross_margin_next_12m_per__c = 0;
            newValuesOlli.credit_drawn_next_12m_per__c = 0;
            newValuesOlli.funding_cost_per__c = 0;
            newValuesOlli.pre_net_margin_next_12m_amount__c = 0;
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
            newValuesOlli = fillRiskFeeAmount(newValuesOlli);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_endrs_fee_next_12m_amount__c);
            newValuesOlli.fee_next_12m_amount__c = newValuesOlli.pre_oppy_revenue_next_12m_amount__c;
        } else {
            newValuesOlli.DES_Risk_Fee_Next_12_Months__c = 0;
            newValuesOlli.pre_endrs_fee_next_12m_amount__c = 0;
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.undrawn_fee_next_12m_amount__c);
            newValuesOlli.pre_oppy_revenue_next_12m_amount__c = sumIfNotNull(newValuesOlli.pre_oppy_revenue_next_12m_amount__c,newValuesOlli.pre_net_margin_next_12m_amount__c);
            newValuesOlli.fee_next_12m_amount__c = newValuesOlli.pre_oppy_revenue_next_12m_amount__c;
        }
        
        return newValuesOlli;
    }
    
    /*
    * Rellena campos autoinformados si estos no se van a rellenar con valores de tramo
    *
    * @input   OpportunityLineItem olli   -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campos informados (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem fillAutoFields(OpportunityLineItem olli) {
        OpportunityLineItem newValuesOlli = olli;
        
        if(newValuesOlli.operation_underwriting_per__c == null || newValuesOlli.bbva_prtcp_tranche_amount__c == null) { //MAXMIX4-3058 underwriting_amount__c=> bbva_prtcp_tranche_amount__c
            newValuesOlli.underwriting_fee_amount__c = 0;
        } else {
            newValuesOlli.underwriting_fee_amount__c = (newValuesOlli.operation_underwriting_per__c/10000) * newValuesOlli.bbva_prtcp_tranche_amount__c; //MAXMIX4-3058 underwriting_amount__c=> bbva_prtcp_tranche_amount__c
        }
        
        if(newValuesOlli.opening_fee_per__c == null) {
            newValuesOlli.opening_fee_amount__c = 0;
        } else {
            final set<String> validUWType = new Set<String> {UW_DNM, UW_MSD, UW_BE};
            if(validUWType.contains(newValuesOlli.underwriting_agreement_type__c)) {
                if(newValuesOlli.gf_synd_fnl_primry_allc_amount__c==null) {
                    newValuesOlli.opening_fee_amount__c = 0;
                } else {
                    newValuesOlli.opening_fee_amount__c = newValuesOlli.gf_synd_fnl_primry_allc_amount__c * (newValuesOlli.opening_fee_per__c/10000);
                } 
            } else if(newValuesOlli.underwriting_agreement_type__c == UW_YES) {
                if(newValuesOlli.bbva_prtcp_tranche_amount__c==null) {
                    newValuesOlli.opening_fee_amount__c = 0;
                } else {
                    newValuesOlli.opening_fee_amount__c = newValuesOlli.bbva_prtcp_tranche_amount__c * (newValuesOlli.opening_fee_per__c/10000);
                }
            } else if(newValuesOlli.underwriting_agreement_type__c == UW_NO) {
                if(newValuesOlli.syndicated_loan_drawn_amount__c==null) {
                    newValuesOlli.opening_fee_amount__c = 0;
                } else {
                    newValuesOlli.opening_fee_amount__c = (newValuesOlli.opening_fee_per__c/10000) * newValuesOlli.syndicated_loan_drawn_amount__c;            
                }
            }
        }
        
        newValuesOlli = fillAverageDrawnFields(newValuesOlli);
        newValuesOlli = fillFeesN12M(newValuesOlli);
        
        return newValuesOlli;
    }
    
    /*
    * Rellena el campo Risk Fee Next 12 Months (amount in units) para los productos WC, STF y TTF
    *
    * @input   OpportunityLineItem olli   -   olli con campo a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campo informado (Opportuniy Product)
    *
    *
    **/
    private static OpportunityLineItem fillRiskFeeAmount(OpportunityLineItem olli) {
        if(olli.DES_Risk_Fee_Next_12_Months__c == null || olli.syndicated_loan_drawn_amount__c == null) {
            olli.pre_endrs_fee_next_12m_amount__c = 0;
        } else {
            olli.pre_endrs_fee_next_12m_amount__c = (olli.DES_Risk_Fee_Next_12_Months__c/10000) * olli.syndicated_loan_drawn_amount__c;
        }
        
        return olli;
    }
    
    /*
    *  Funcion que inserta los nuevos productos con el Stage Draft Opp
    *
    * @input   List<OpportunityLineItem> itemsNew   -   items a setear Opp Stage (Trigger.new)
    *
    **/
    public static void insertWithDraftStage(List<OpportunityLineItem> itemsNew) {
        for (OpportunityLineItem olli : itemsNew) {
            //olli.opportunity_stage_type__c = olli.Opportunity.StageName;
            final Set<String> prodsDeferr = new Set<String>{Label.DES_Corporate_Loans,Label.DES_Leverage_Buyout_LBOs,Label.DES_Project_Finance_Lending};
            if(olli.multi_tranche_type__c == Label.DES_No && prodsDeferr.contains(olli.solution_classification_desc__c)) {
                olli = fillDeferredFees(olli);
            }
        }
    }
    
    /*
    * Rellena campo Deferred Fees (%) en funcion del perfil de usuario
    *
    * @input   OpportunityLineItem olli   -   olli con campos a informar (Opportuniy Product)
    * @return  OpportunityLineItem olli   -   olli con campos informados (Opportuniy Product)
    *
    *
    **/
    public static OpportunityLineItem fillDeferredFees(OpportunityLineItem olli) {
        if(olli.deferred_fee_per__c == null) {
            if(olli.user_profile_id__c == ('BBVA Desktop GTB Business Development') || olli.user_profile_id__c == ('BBVA Desktop GTB Standard')) {
                olli.deferred_fee_per__c = 100;
            } else {
                olli.deferred_fee_per__c = 50;
            }
        }
        
        return olli;
    }
    
    /*
    * Suma una pareja de valores si el valor a añadir no es nulo
    *
    * @input   Decimal valueField   -   valor actual en campo olli (Valor Opportuniy Product)
    * @input   Decimal valueToAdd   -   valor a sumar en campo olli (Valor Opportuniy Product)
    * @return  Decimal finalValue   -   valor calculado a guardar en campo olli (Opportuniy Product)
    *
    *
    **/
    public static Decimal sumIfNotNull(Decimal valueField, Decimal valueToAdd) {
        Decimal finalValue;
        
        if(valueField==null) {
            finalValue = 0;
        } else {
            finalValue = valueField;
        }
        
        if(valueToAdd!=null) {
            finalValue += valueToAdd;
        }
        
        return finalValue;
    }
    
    /*
    * Rellena campo productos asociados a la Oportunidad en Oportunidad
    *
    * @input   List<OpportunityLineItem> triggerNew
    *
    *
    **/
    public static void fillOppPrducts(List<OpportunityLineItem> triggerNew) {
        Set<Id> idOppLine;
        idOppLine = new Set<Id>();
        Set<Id> idOpp;
        idOpp = new Set<Id>();
        for(OpportunityLineItem oppLine : triggerNew) {
            idOpp.add(oppLine.OpportunityId);
            idOppLine.add(oppLine.Id);
        }
        List<Opportunity> lstOppUpd;
        lstOppUpd = new List<Opportunity>();
        system.debug('---------------------->'+idOppLine);
        final List<OpportunityLineItem> lstOppLine = [SELECT id, Name, Opportunity.gf_opportunity_product_desc__c , Product2.Name FROM OpportunityLineItem WHERE id = :idOppLine];
        system.debug('---------------------->'+lstOppLine);
        List<Opportunity> lstOpp;
        lstOpp =  [SELECT id, Name, gf_opportunity_product_desc__c  FROM Opportunity WHERE id = :idOpp];
        lstOppUpd = fillOppProductsHelper(lstOppLine, lstOppUpd, lstOpp);
        system.debug('lstOppUpd---------------------->'+lstOppUpd);
        update lstOppUpd;
    }
    
    /*
    * Helper del met0d0 fillOppProductsHelper
    *
    * @input   List<OpportunityLineItem> lstOppLine, List<Opportunity> lstOppUpd, List<Opportunity> lstOpp
    * @output  List<Opportunity> lstOppUpd
    *
    **/
    public static List<Opportunity> fillOppProductsHelper(List<OpportunityLineItem> lstOppLine,List<Opportunity> lstOppUpd, List<Opportunity> lstOpp) {
        for(OpportunityLineItem oppLine : lstOppLine) {
            system.debug('---------------------->'+oppLine);
            if(String.isEmpty(oppLine.Opportunity.gf_opportunity_product_desc__c )) {
                system.debug('ENTRO AL PRIMER IF---------------------->');
                system.debug('oppLine.Product2.Name---------------------->'+oppLine.Product2.Name);
                oppLine.Opportunity.gf_opportunity_product_desc__c  = oppLine.Product2.Name;
                system.debug('lstOppUpd1---------------------->'+lstOppUpd);
                lstOppUpd.add(new Opportunity(id = oppLine.OpportunityId, gf_opportunity_product_desc__c  = oppLine.Opportunity.gf_opportunity_product_desc__c ));
                system.debug('lstOppUpd2---------------------->'+lstOppUpd);
                system.debug('oppLine.Opportunity.gf_opportunity_product_desc__c ---------------------->'+oppLine.Opportunity.gf_opportunity_product_desc__c );
            } else {
                system.debug('ENTRO AL PRIMER ELSE---------------------->');
                if(!oppLine.Opportunity.gf_opportunity_product_desc__c .contains(oppLine.Product2.Name)) {
                    oppLine.Opportunity.gf_opportunity_product_desc__c  += ','+oppLine.Product2.Name;
                    for(Opportunity opp :lstOpp) {
                        if(opp.id == oppLine.OpportunityId) {
                            opp.gf_opportunity_product_desc__c  = oppLine.Opportunity.gf_opportunity_product_desc__c ;
                            if(!lstOppUpd.isEmpty()) {
                                final List<Opportunity> lstOppClon = lstOppUpd.clone();
                                for(Opportunity oppUp : lstOppClon) {
                                    if(oppUp.id == opp.id) {
                                        lstOppUpd.remove(lstOppUpd.indexOf(oppUp));
                                    }
                                }
                            }
                            system.debug('lstOppUpd3---------------------->'+lstOppUpd);
                            lstOppUpd.add(opp);
                            system.debug('lstOppUpd4---------------------->'+lstOppUpd);
                        }
                    }
                    system.debug('ENTRO AL IF en el else---------------------->');
                    system.debug('gf_opportunity_product_desc__c ---------------------->'+oppLine.Opportunity.gf_opportunity_product_desc__c );
                }
            }
        }
        return lstOppUpd;
    }
    /*
    * Modifica campo productos asociados a la Oportunidad en Oportunidad
    *
    * @input   List<OpportunityLineItem> triggerOld
    *
    *
    **/
    public static void deleteOppPrducts(List<OpportunityLineItem> triggerOld) {
        Set<Id> idOpp;
        idOpp = new Set<Id>();
        for(OpportunityLineItem oppLine : triggerOld) {
            idOpp.add(oppLine.OpportunityId);
        }
        List<Opportunity> lstOpp;
        lstOpp = [SELECT id, Name, gf_opportunity_product_desc__c , (SELECT id, Name, OpportunityId, Product2.Name FROM OpportunityLineItems) FROM Opportunity WHERE id = :idOpp and recordType.DeveloperName != 'DMT_Opportunity'];
        List<Opportunity> lstOppUpd;
        lstOppUpd = new List<Opportunity>();
        system.debug('lstOpp---------------------->'+lstOpp);
        system.debug('idOpp---------------------->'+idOpp);
        for(Opportunity opp : lstOpp) {
            system.debug('------------------------->'+JSON.serialize(opp));
            opp.gf_opportunity_product_desc__c  = null; //NOSONAR
            for(OpportunityLineItem oppLine : opp.OpportunityLineItems) {
                system.debug('------------------------->'+JSON.serialize(oppLine));
                if(String.isEmpty(opp.gf_opportunity_product_desc__c )) {
                    opp.gf_opportunity_product_desc__c  = oppLine.Product2.Name;
                } else {
                    if(!opp.gf_opportunity_product_desc__c .contains(oppLine.Product2.Name)) {
                        opp.gf_opportunity_product_desc__c  += ','+oppLine.Product2.Name;
                    }
                }
            }
            lstOppUpd.add(opp);
        }
        if(lstOppUpd.size() > 0){
            update(lstOppUpd);
        }  
    }
    
    /*
    * Lanza el proceso de autorelleno de campo "%Underwriting oportunidad"
    *
    * @input   Map<Id,OpportunityLineItem> mapOppliNew   -   mapa olis con campos a autorellenar(Opportuniy Product)
    * @input   Map<Id,OpportunityLineItem> mapOppliOld   -   mapa olis antiguos (Opportuniy Product)
    **/
    public static void fillBbvaParticipationPer(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld) { //NOSONAR
        final set<String> validUWType = new Set<String>{UW_DNM, UW_MSD, UW_BE};
        
        for (OpportunityLineItem oli : mapOppliNew.values()) {
            if(validUWType.contains(oli.underwriting_agreement_type__c)){
                oli.bbva_participation_per__c = 100;
            } else if(oli.underwriting_agreement_type__c == UW_YES) {
                final OpportunityLineItem oldOli = mapOppliOld.get(oli.Id);
                final Boolean newIsNotManual = oldOli.bbva_participation_per__c == oli.bbva_participation_per__c;
                final Boolean oldWasFormula = (oldOli.bbva_participation_per__c == BbvaParticipationPerFormula(oldOli));
                final Boolean oliNotSet = (oli.bbva_participation_per__c == null || oli.bbva_participation_per__c == 0);
                final Boolean agreementToYes = oldOli.underwriting_agreement_type__c != UW_YES;
                
                if((newIsNotManual && oldWasFormula) || agreementToYes || oliNotSet) {
                    oli.bbva_participation_per__c = BbvaParticipationPerFormula(oli);
                }
            }
        }
    }
    
    /*
    * Lanza el proceso de autorelleno de campo "%Underwriting oportunidad"
    *
    * @input   List<OpportunityLineItem> triggerNew
    **/
    public static void fillBbvaParticipationPer(List<OpportunityLineItem> triggerNew) { //NOSONAR
        final set<String> validUWType = new Set<String>{UW_DNM, UW_MSD, UW_BE};
        for (OpportunityLineItem oli : triggerNew) {
            if(validUWType.contains(oli.underwriting_agreement_type__c)) {
                oli.bbva_participation_per__c = 100;
            } else if(oli.underwriting_agreement_type__c == UW_YES && (oli.bbva_participation_per__c == null || oli.bbva_participation_per__c == 0)) {
                oli.bbva_participation_per__c = BbvaParticipationPerFormula(oli);
            } 
        }
    }
    
    private static Decimal BbvaParticipationPerFormula(OpportunityLineItem oli) {
        final Boolean notValidValues = (oli.bbva_prtcp_tranche_amount__c == null || oli.deal_total_amount__c == null || oli.deal_total_amount__c < 1);
        return notValidValues ? 0 : (oli.bbva_prtcp_tranche_amount__c / oli.deal_total_amount__c) * 100; 
    }
    
    /*
    * Lanza el proceso de autorelleno de campo "Amount to be sold (amount in units)"
    * MAXMIX4-4100
    * @input   Map<Id,OpportunityLineItem> mapOppliNew   -   mapa olis con campos a autorellenar(Opportuniy Product)
    * @input   Map<Id,OpportunityLineItem> mapOppliOld   -   mapa olis antiguos (Opportuniy Product)
    **/
    public static void fillAmountToBeSold(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld) { //NOSONAR
        final set<String> validUWType = new Set<String>{UW_DNM, UW_MSD, UW_BE, UW_YES};
        
        for (OpportunityLineItem oli : mapOppliNew.values()) {
            if(validUWType.contains(oli.underwriting_agreement_type__c)) {
                final OpportunityLineItem oldOli = mapOppliOld.get(oli.Id);
                final Boolean newIsNotManual = oldOli.underwriting_amount__c == oli.underwriting_amount__c;
                final Boolean oldWasFormula = (oldOli.underwriting_amount__c == amountToBeSoldFormula(oldOli));
                final Boolean oliNotSet = (oli.underwriting_amount__c == null || oli.underwriting_amount__c == 0);
                final Boolean agreementChanged = oldOli.underwriting_agreement_type__c != oli.underwriting_agreement_type__c;
                
                if((newIsNotManual && oldWasFormula) || agreementChanged || oliNotSet) {
                    oli.underwriting_amount__c = amountToBeSoldFormula(oli);
                }
            }
        }
    }
    
    /*
    * Lanza el proceso de autorelleno de campo "Amount to be sold (amount in units)"
    * MAXMIX4-4100
    * @input   List<OpportunityLineItem> triggerNew
    **/
    public static void fillAmountToBeSold(List<OpportunityLineItem> triggerNew) { //NOSONAR
        final set<String> validUWType = new Set<String>{UW_DNM, UW_MSD, UW_BE, UW_YES};
        for (OpportunityLineItem oli : triggerNew) {
            if(validUWType.contains(oli.underwriting_agreement_type__c) && (oli.underwriting_amount__c == null || oli.underwriting_amount__c == 0)) {
                oli.underwriting_amount__c = amountToBeSoldFormula(oli);
            } 
        }
    }
    /* Formula de autorelleno de campo "Amount to be sold (amount in units)"
    * MAXMIX4-4100
    * 
    * */
    private static Decimal amountToBeSoldFormula(OpportunityLineItem oli) { //
        final set<String> validUWType = new Set<String>{UW_DNM, UW_MSD, UW_BE};
        Decimal output = 0;
        if(validUWType.contains(oli.underwriting_agreement_type__c)) {
            final Boolean validValues = !((oli.gf_synd_fnl_primry_allc_amount__c == null || oli.gf_synd_fnl_primry_allc_amount__c < 1) || (oli.syndicated_loan_drawn_amount__c == null || oli.syndicated_loan_drawn_amount__c < 1) || oli.gf_synd_fnl_primry_allc_amount__c - oli.syndicated_loan_drawn_amount__c < 0);
            if(validValues) {
                output = oli.gf_synd_fnl_primry_allc_amount__c - oli.syndicated_loan_drawn_amount__c; 
            }
        } else if(oli.underwriting_agreement_type__c == UW_YES) {
            final Boolean validValues = !((oli.bbva_prtcp_tranche_amount__c == null || oli.bbva_prtcp_tranche_amount__c < 1) || (oli.syndicated_loan_drawn_amount__c == null || oli.syndicated_loan_drawn_amount__c < 1)  || oli.bbva_prtcp_tranche_amount__c - oli.syndicated_loan_drawn_amount__c < 0);
            if(validValues) {
                output = (oli.bbva_prtcp_tranche_amount__c - oli.syndicated_loan_drawn_amount__c); 
            }
        }
        return output;
    }
    
    /*
    * Lanza el proceso de autorelleno de campo "%Underwriting oportunidad"
    * MAXMIX4-4097
    * @input   Map<Id,OpportunityLineItem> mapOppliNew   -   mapa olis con campos a autorellenar(Opportuniy Product)
    * @input   Map<Id,OpportunityLineItem> mapOppliOld   -   mapa olis antiguos (Opportuniy Product)
    **/
    public static void fillFinalAllocation(Map<Id,OpportunityLineItem> mapOppliNew, Map<Id,OpportunityLineItem> mapOppliOld) { //NOSONAR
        final set<String> validUWType = new Set<String>{UW_DNM, UW_MSD, UW_BE};
        for (OpportunityLineItem oli : mapOppliNew.values()) {           
            if(validUWType.contains(oli.underwriting_agreement_type__c) && 
            oli.gf_synd_fnl_primry_allc_amount__c == null) {
                if(oli.bbva_prtcp_tranche_amount__c == null) {
                    oli.gf_synd_fnl_primry_allc_amount__c = 0;                    
                } else {
                    oli.gf_synd_fnl_primry_allc_amount__c = oli.bbva_prtcp_tranche_amount__c;
                }
            }
        }
    }
}