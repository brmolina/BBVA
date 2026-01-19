/***********************************************************************************************
Name:            DES_MigrateOppliFieldsForOppVersion2
Description:     Batch class to migrate data for opportunity 2.0 fields (in opportunity product)
Test Class:      DES_MigrateOppliFieldsForOppVersion2Test

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            19/09/2019                     Class creation

***********************************************************************************************/
@SupressWarnings('all')
public class DES_MigrateOppliFieldsForOppVersion2 implements Database.Batchable<sObject>, Database.Stateful { //NOSONAR
    /**
     * Mapa campos opportunitylineitem
     */
    Map<String, Schema.SObjectField> fieldMap;

    /**
     * Product version literal 1
     */
     private static final Integer ONE = 1;

    /**
     * Deal Volume - Deal Amount en DCM,ECM,M&A
     */
     private static final List<String> DEAL_VOLUME = new List<String>{Label.DES_Debt_Capital_Markets,Label.DES_Equity_Capital_Markets,Label.DES_Mergers_Acquisitions};

     /**
     * Total Debt Size - Deal Amount en PFA,PFL
     */
     private static final List<String> TDEBTSIZE = new List<String>{Label.DES_Project_Finance_Advisory,Label.DES_Project_Finance_Lending};

     /**
     * Global Deal Amount - Deal Amount en CL,LBOs
     */
     private static final List<String> GDEALAMOUNT = new List<String>{Label.DES_Corporate_Loans,Label.DES_Leverage_Buyout_LBOs};

     /**
     * BBVA Final Hold - BBVA Final Take en CL,LBOs,PFL
     */
     private static final List<String> FINALHOLD = new List<String>{Label.DES_Corporate_Loans,Label.DES_Leverage_Buyout_LBOs,Label.DES_Project_Finance_Lending};

     /**
     * (Old) NBC Comments - NBC Comments en WC,STF,PFL,CL,LBOs,TTF
     */
     private static final List<String> OLDNBCCOMM = new List<String>{Label.DES_Corporate_Loans,Label.DES_Leverage_Buyout_LBOs,Label.DES_Project_Finance_Lending
                                                                    ,Label.DES_Structure_Trade_Finance,Label.DES_Working_Capital,Label.DES_Transaction_Trade_Finance};

    /**
    * Territorial - Regional en Rates,Equity,FX,STF
    */
    private static final List<String> TERRITORIAL = new List<String>{Label.DES_Rates,Label.DES_Equity,Label.DES_FX,Label.DES_Structure_Trade_Finance};




    /**
     * Map product versions
     */
    Map<Id, fprd__GBL_Product_version__c> mapProductVersion {
        get {
            if(mapProductVersion == null) {
                mapProductVersion = new Map<Id, fprd__GBL_Product_version__c>();
                for(fprd__GBL_Product_version__c iProductVersion : [SELECT Id, fprd__Version_number__c
                                                                    FROM fprd__GBL_Product_version__c LIMIT 50000]) {
                    mapProductVersion.put(iProductVersion.Id, iProductVersion);
                }
            }
            return mapProductVersion;
        } set;
    }

    /**
     * Constructor
     */
    public DES_MigrateOppliFieldsForOppVersion2() {
        this.fieldMap = OpportunityLineItem.sObjectType.getDescribe().fields.getMap();
    }

    /**
     * Implementation of the start method of the Database.Batchable interface
     */
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator('SELECT Id,DES_Comments__c FROM Opportunity');
    }

    /**
     * Implementation of the execute method of the Database.Batchable interface
     */
    public void execute(Database.BatchableContext batchableContext, List<SObject> records) { //NOSONAR
        List<Opportunity> listOpp = new List<Opportunity>();
        listOpp = (List<Opportunity>) records;
        //final Map<Id,Opportunity> mapOpp = new Map<Id,Opportunity>(listOpp);
        final Savepoint iSavePoint = Database.setSavepoint();

        try {
            final List<String> fieldNames = new List<String>();
            fieldNames.addAll(this.fieldMap.keySet());

            final String allFields = String.join(fieldNames, ',').replaceAll('totalprice,', '');

            final List<OpportunityLineItem> liAllOlli = Database.query('SELECT ' + allFields + ' FROM OpportunityLineItem WHERE OpportunityId IN :listOpp');

            //final List<Opportunity> liOppyUpdt = new List<Opportunity>();
            //Opportunity oppy;
            String numericString;

            final List<OpportunityLineItem> liOlliUpdt = new List<OpportunityLineItem>();

            for(OpportunityLineItem olli : liAllOlli) {
                final fprd__GBL_Product_Version__c pVersion = mapProductVersion.get(olli.fprd__GBL_Product_version__c);
                // Si el product version corresponde a Opportunity 1.0 se realiza la migración
                // if(pVersion.fprd__Version_number__c == ONE) {
                    if(olli.DES_Pricing_Committee_Approval_BEC__c != null) {
                        olli.oppy_pricing_cmtee_rspse_type__c = olli.DES_Pricing_Committee_Approval_BEC__c;

                    }

                    if(olli.DES_Borrower_and_or_Operation_Name__c != null) {
                        olli.participant_name__c = olli.DES_Borrower_and_or_Operation_Name__c;

                    }

                    if(olli.DES_Seller__c != null) {
                        olli.seller_advance_payment_name__c = olli.DES_Seller__c;

                    }

                    if(olli.DES_Potential_Revenue__c != null) {
                        olli.pre_oppy_revenue_next_12m_amount__c = olli.DES_Potential_Revenue__c;

                    }

                    if(olli.DES_Tenor_Months__c != null) {
                        olli.loan_tenor_month_desc__c = olli.DES_Tenor_Months__c;

                    }

                    if(olli.DES_BBVA_Commitment__c != null) {
                        olli.bbva_prtcp_tranche_amount__c = olli.DES_BBVA_Commitment__c;

                    }

                    if(olli.DES_Cost_of_Funding__c != null) {
                        olli.funding_cost_per__c = olli.DES_Cost_of_Funding__c;

                    }

                    if(olli.DES_Counterpart_Name__c != null) {
                        olli.counterparty_name__c = olli.DES_Counterpart_Name__c;

                    }

                    if(olli.DES_Underwriting_Approval_Date__c != null) {
                        olli.oppy_undwr_cmtee_approval_date__c = olli.DES_Underwriting_Approval_Date__c;

                    }

                    if(olli.DES_Underwriting_Committee_Approval__c != null) {
                        olli.oppy_undwr_cmtee_rspse_type__c = olli.DES_Underwriting_Committee_Approval__c;

                    }

                    if(olli.DES_NBC_Approval_Date__c == null) {
                        if(olli.DES_NBC_PreApproval_BIBEC_Date__c != null) {
                            olli.opportunity_nbc_recm_date__c = olli.DES_NBC_PreApproval_BIBEC_Date__c;

                        }
                    } else if(olli.DES_NBC_PreApproval_BIBEC_Date__c == null) {
                        if(olli.DES_NBC_Approval_Date__c != null) {
                            olli.opportunity_nbc_recm_date__c = olli.DES_NBC_Approval_Date__c;

                        }
                    }

                    if(olli.DES_NBC_Approval__c == null) {
                        if(olli.DES_NBC_Approval_or_PreApproval_BIBEC__c != null) {
                            olli.opportunity_nbc_recm_ind_type__c = olli.DES_NBC_Approval_or_PreApproval_BIBEC__c;

                        }
                    } else if(olli.DES_NBC_Approval_or_PreApproval_BIBEC__c == null) {
                        if(olli.DES_NBC_Approval__c != null) {
                            olli.opportunity_nbc_recm_ind_type__c = olli.DES_NBC_Approval__c;

                        }
                    }

                    if(OLDNBCCOMM.contains(olli.solution_classification_desc__c)) {
                        if(olli.DES_NBC_Comments__c != null) {
                            olli.opportunity_nbc_comments_desc__c = olli.DES_NBC_Comments__c;

                        }
                    } else if(olli.NBC_Comments__c != null) {
                        if(olli.NBC_Comments__c != null) {
                            olli.opportunity_nbc_comments_desc__c = olli.NBC_Comments__c;

                        }
                    }

                    if(olli.DES_Subproduct__c != null) {
                        olli.solution_name_path_desc__c = olli.DES_Subproduct__c;

                    }

                    if(olli.DES_BIBEC_Banker__c != null) {
                        olli.classification_cib_banker_type__c = olli.DES_BIBEC_Banker__c;

                    }

                    if(olli.DES_Product__c != null) {
                        olli.subproduct_name__c = olli.DES_Product__c;

                    }

                    if(olli.DES_Opportunity_Stage__c != null) {
                        olli.opportunity_stage_type__c = olli.DES_Opportunity_Stage__c;

                    }

                    if(olli.DES_Mandate_Date__c != null) {
                        olli.oppy_substage_mandate_date__c = olli.DES_Mandate_Date__c;

                    }

                    if(olli.DES_Risk_Approval_Date__c != null) {
                        olli.risk_committee_approval_date__c = olli.DES_Risk_Approval_Date__c;

                    }

                    if(olli.DES_BBVA_Participant_Banks__c != null) {
                        olli.bbva_struc_trd_finc_bank_name__c = olli.DES_BBVA_Participant_Banks__c;

                    }

                    if(olli.DES_Country_Distribution_Area__c != null) {
                        olli.filial_country_distribution_id__c = olli.DES_Country_Distribution_Area__c;

                    }

                    if(olli.DES_Risks_Holder__c != null) {
                        olli.risk_holder_entity_name__c = olli.DES_Risks_Holder__c;

                    }

                    if(olli.DES_RFP__c != null) {
                        olli.proposal_requested_ind_type__c = olli.DES_RFP__c;

                    }

                    if(olli.DES_Average_Annual_Balance__c != null) {
                        olli.avg_balance_annual_amount__c = olli.DES_Average_Annual_Balance__c;

                    }

                    if(olli.DES_BBVA_Role__c != null) {
                        olli.entity_role_type__c = olli.DES_BBVA_Role__c;

                    }

                    if(olli.DES_Asset_Type_Level_3__c != null) {
                        olli.oppy_asset_level_3_name__c = olli.DES_Asset_Type_Level_3__c;

                    }

                    if(olli.DES_Implementation__c != null) {
                        olli.gf_product_conn_impl_ind_type__c = olli.DES_Implementation__c;

                    }

                    if(olli.DES_Importer__c != null) {
                        olli.importing_company_name__c = olli.DES_Importer__c;

                    }

                    if(olli.DES_Compliance_Approval__c != null) {
                        olli.cplc_cmtee_approval_ind_type__c = olli.DES_Compliance_Approval__c;

                    }

                    if(olli.DES_Pricing_Approval_Date_BEC_Clients__c != null) {
                        olli.oppy_pricing_cmtee_aprvl_date__c = olli.DES_Pricing_Approval_Date_BEC_Clients__c;

                    }

                    if(olli.DES_Origination_Country__c != null) {
                        olli.origin_country_name__c = olli.DES_Origination_Country__c;

                    }

                    if(olli.DES_Purpose__c != null) {
                        olli.loan_purpose_desc__c = olli.DES_Purpose__c;

                    }

                    if(olli.DES_Signature_Date__c != null) {
                        olli.signing_date__c = olli.DES_Signature_Date__c;

                    }

                    if(olli.DES_Underwriting_fee__c == null) {
                        if(olli.DES_Syndication_Fee__c != null) {
                            olli.operation_underwriting_per__c = olli.DES_Syndication_Fee__c;

                        }
                    } else {
                        if(olli.DES_Underwriting_fee__c != null) {
                            olli.operation_underwriting_per__c = olli.DES_Underwriting_fee__c;

                        }
                    }

                    if(olli.Booking_type__c != null) {
                        olli.product_scope_type__c = olli.Booking_type__c;

                    }

                    if(olli.DES_Asset_Type_Level_2__c != null) {
                        olli.oppy_asset_level_2_name__c = olli.DES_Asset_Type_Level_2__c;

                    }

                    if(olli.DES_Beneficiary__c != null) {
                        olli.beneficiary_entity_name__c = olli.DES_Beneficiary__c;

                    }

                    if(olli.DES_Sell_Down_Commitment_Date__c != null) {
                        olli.oppy_product_ctrct_comt_date__c = olli.DES_Sell_Down_Commitment_Date__c;

                    }

                    if(olli.DES_Asset_Type_Level_1__c != null) {
                        olli.oppy_asset_level_1_name__c = olli.DES_Asset_Type_Level_1__c;

                    }

                    if(olli.DES_Distribution_Area__c != null) {
                        olli.oppy_product_offer_area_name__c = olli.DES_Distribution_Area__c;

                    }

                    if(olli.DES_Target_Country__c != null) {
                        olli.oppy_target_country_name__c = olli.DES_Target_Country__c;

                    }

                    if(olli.DES_Matfil__c != null) {
                        olli.benefit_sharing_agree_ind_type__c = olli.DES_Matfil__c;

                    }

                    if(olli.DES_Platform__c != null) {
                        olli.trd_finc_tran_cnfrm_pltfm_name__c = olli.DES_Platform__c;

                    }

                    if(olli.DES_Beneficiary_Bank__c != null) {
                        olli.beneficiary_entity_id__c = olli.DES_Beneficiary_Bank__c;

                    }

                    if(olli.DES_Valued_portfolio__c != null) {
                        olli.current_value_portfolio_amount__c = olli.DES_Valued_portfolio__c;

                    }


                    if(olli.DES_Exporter_Country__c != null) {
                        olli.multn_acqn_export_country_name__c = olli.DES_Exporter_Country__c;

                    }

                    if(olli.DES_Buyer__c != null) {
                        olli.gf_company_adv_payment_name__c = olli.DES_Buyer__c;

                    }

                    if(olli.DES_Exporter__c != null) {
                        olli.exporting_company_name__c = olli.DES_Exporter__c;

                    }

                    if(olli.DES_Issuing_Bank__c != null) {
                        olli.issuing_entity_name__c = olli.DES_Issuing_Bank__c;

                    }

                    if(olli.DES_Advising_Bank__c != null) {
                        olli.advising_entity_id__c = olli.DES_Advising_Bank__c;

                    }

                    if(olli.DES_Counterpart_Country__c != null) {
                        olli.counterparty_country_id__c = olli.DES_Counterpart_Country__c;

                    }

                    if(olli.DES_Asset_Country__c != null) {
                        olli.country_name__c = olli.DES_Asset_Country__c;

                    }

                    if(olli.DES_Applicant__c != null) {
                        olli.financial_gntee_applicant_name__c = olli.DES_Applicant__c;

                    }

                    if(olli.DES_Assignor__c != null) {
                        olli.assignor_id__c = olli.DES_Assignor__c;

                    }

                    if(olli.DES_Confirming_Bank__c != null) {
                        olli.confirming_entity_id__c = olli.DES_Confirming_Bank__c;

                    }

                    if(olli.DES_Asset_Allocation_Approval__c != null) {
                        olli.aa_committee_approval_ind_type__c = olli.DES_Asset_Allocation_Approval__c;

                    }

                    if(olli.DES_Debtor__c != null) {
                        olli.customer_debtor_name__c = olli.DES_Debtor__c;

                    }

                    if(olli.DES_Counterparty_Role__c != null) {
                        olli.counterparty_rol_name__c = olli.DES_Counterparty_Role__c;

                    }

                    if(olli.DES_BO_Type__c != null) {
                        olli.opportunity_name__c = olli.DES_BO_Type__c;

                    }

                    if(olli.DES_Maturity_NBC_Date__c != null) {
                        olli.oppy_nbc_rcmndn_maturity_date__c = olli.DES_Maturity_NBC_Date__c;

                    }

                    if(olli.DES_Importer_Country__c != null) {
                        olli.multn_acqn_import_country_name__c = olli.DES_Importer_Country__c;

                    }

                    if(olli.DES_Client_Type__c != null) {
                        olli.customer_type__c = olli.DES_Client_Type__c;

                    }

                    if(olli.DES_Offer_Maturity_ECA__c != null) {
                        olli.gf_eca_offer_expiry_date__c = olli.DES_Offer_Maturity_ECA__c;

                    }

                    if(olli.DES_Guarantor__c != null) {
                        olli.customer_guarantor_entity_id__c = olli.DES_Guarantor__c;

                    }

                    if(olli.DES_Target_Industry__c != null) {
                        olli.oppy_target_industry_name__c = olli.DES_Target_Industry__c;

                    }

                    if(olli.DES_Client_Role__c != null) {
                        olli.participant_role_desc__c = olli.DES_Client_Role__c;

                    }

                    if(olli.DES_Guarantor_Coverage_Mitigant__c != null) {
                        olli.gf_thpty_guarantor_risk_name__c = olli.DES_Guarantor_Coverage_Mitigant__c;

                    }

                    if(olli.DES_COMEX_Specialist__c != null) {
                        olli.ext_trade_cmtee_cr_spclst_name__c = olli.DES_COMEX_Specialist__c;

                    }

                    if(olli.DES_N_Guarantor_Coverage_Mitigant__c != null) {
                        olli.gf_thpty_guarantor_risk_per__c = olli.DES_N_Guarantor_Coverage_Mitigant__c;

                    }

                    if(olli.DES_Risk_Type__c != null) {
                        olli.opportunity_risk_name__c = olli.DES_Risk_Type__c;

                    }

                    if(olli.DES_Fronting_Bank__c != null) {
                        olli.beneficiary_fronting_bank_name__c = olli.DES_Fronting_Bank__c;

                    }

                    if(olli.Security_package__c != null) {
                        olli.deal_guarantee_desc__c = olli.Security_package__c;

                    }
                    if(olli.deal_guarantee_desc__c != null && olli.deal_guarantee_desc__c.equalsIgnoreCase('ECA')) {
                        if(olli.DES_ECA_Name__c != null) {
                            olli.export_credit_agency_name__c = olli.DES_ECA_Name__c;

                        }
                        if(olli.DES_ECA_Cover__c != null) {
                            olli.loan_export_cr_agncy_cntrb_per__c = olli.DES_ECA_Cover__c;

                        }
                    } else if(olli.deal_guarantee_desc__c != null && olli.deal_guarantee_desc__c.equalsIgnoreCase('Private Insurance')) {
                        if(olli.Private_Insurance_Name__c != null) {
                            olli.insurance_company_name__c = olli.Private_Insurance_Name__c;

                        }
                        if(olli.Cover_Private_Insurance__c != null) {
                            olli.insurance_cover_per__c = olli.Cover_Private_Insurance__c;

                        }
                    }

                    if(olli.DES_Tenor__c != null && !olli.DES_Tenor__c.equalsIgnoreCase('')) {
                        String lastStrChar;
                        numericString = '';
                        if(olli.DES_Tenor__c != null) {
                            lastStrChar = olli.DES_Tenor__c.mid(0,1);

                        }
                        if(olli.DES_Tenor__c != null) {
                            final Integer strLength = olli.DES_Tenor__c.length();

                        
                            for(integer i =0;i<strLength;i++) {
                                if(olli.DES_Tenor__c != null) {
                                    final String strChar= olli.DES_Tenor__c.mid(i,1);
    
                                
                                    if((strChar.isNumeric() && !lastStrChar.isAlpha()) || (!lastStrChar.isAlpha() && strChar.equalsIgnoreCase('.'))) {
                                        numericString += strChar;
                                    }
                                    lastStrChar= strChar;
                                }
                            }
                        }
                        olli.opportunity_tenor_years_number__c = Decimal.valueOf(numericString);
                    } else {
                        if(olli.DES_Tenor_Years__c != null) {
                            olli.opportunity_tenor_years_number__c = olli.DES_Tenor_Years__c;

                        }
                    }

                    if(DEAL_VOLUME.contains(olli.solution_classification_desc__c)) {
                        if(olli.DES_Deal_Volume__c != null) {
                            olli.deal_total_amount__c = olli.DES_Deal_Volume__c;

                        }
                    } else if(olli.solution_classification_desc__c == Label.DES_Structure_Trade_Finance) {
                        if(olli.DES_Credit_Amount__c != null) {
                            olli.deal_total_amount__c = olli.DES_Credit_Amount__c;

                        }
                    } else if(TDEBTSIZE.contains(olli.solution_classification_desc__c)) {
                        if(olli.DES_Total_Debt_Size__c != null) {
                            olli.deal_total_amount__c = olli.DES_Total_Debt_Size__c;

                        }
                    } else if(GDEALAMOUNT.contains(olli.solution_classification_desc__c)) {
                        if(olli.DES_Global_Deal_Amount__c != null) {
                            olli.deal_total_amount__c = olli.DES_Global_Deal_Amount__c;

                        }
                    }

                    if(FINALHOLD.contains(olli.solution_classification_desc__c)) {
                        if(olli.DES_BBVA_Final_Hold__c != null) {
                            olli.syndicated_loan_drawn_amount__c = olli.DES_BBVA_Final_Hold__c;

                        }
                    } else if(olli.DES_BBVA_Final_Take__c == null) {
                        if(olli.DES_Amount__c != null) {
                            olli.syndicated_loan_drawn_amount__c = olli.DES_Amount__c;

                        }
                    } else {
                        if(olli.DES_BBVA_Final_Take__c != null) {
                            olli.syndicated_loan_drawn_amount__c = olli.DES_BBVA_Final_Take__c;

                        }
                    }

                    if(olli.solution_classification_desc__c == Label.DES_Equity_Capital_Markets) {
                    if(olli.DES_Retainer_Fees__c != null) {
                        olli.retainer_fee_12m_amount__c = olli.DES_Retainer_Fees__c;

                    }
                    } /*else if(olli.solution_classification_desc__c == Label.DES_Project_Finance_Advisory) {
   olli.DES_Monthly_Retainer_Fee__c != null                     if() {
    olli.retainer_fee_12m_amount__c = olli.DES_Monthly_Retainer_Fee__c;
    
                        }
                    }*/ //NOSONAR

                    if(TERRITORIAL.contains(olli.solution_classification_desc__c)) {
                        if(olli.DES_Territorial__c != null) {
                            olli.regional_area_name__c = olli.DES_Territorial__c;

                        }
                    } else if(olli.DES_Team__c == null) {
                        if(olli.DES_Regional__c != null) {
                            olli.regional_area_name__c = olli.DES_Regional__c;

                        }
                    } else if(olli.DES_Regional__c == null) {
                        if(olli.DES_Team__c != null) {
                            olli.regional_area_name__c = olli.DES_Team__c;

                        }
                    }

                    if(olli.solution_classification_desc__c == Label.DES_Working_Capital) {
                        if(olli.DES_Arrangement_Fee__c != null) {
                            olli.opening_fee_per__c = olli.DES_Arrangement_Fee__c;

                        }
                    } else if (olli.DES_Up_Front_Fees__c != null) {
                        if(olli.DES_Up_Front_Fees__c != null) {
                            olli.opening_fee_per__c = olli.DES_Up_Front_Fees__c;

                        }
                    }

                    if(olli.solution_classification_desc__c == Label.DES_Mergers_Acquisitions) {
                        if(olli.DES_Earned_Retainer_Fees__c != null) {
                            olli.fee_next_12m_amount__c = olli.DES_Earned_Retainer_Fees__c;

                        }
                    } /*else if (olli.solution_classification_desc__c == Label.DES_Project_Finance_Advisory) {
   olli.DES_Success_Fee__c != null                     if() {
    olli.fee_next_12m_amount__c = olli.DES_Success_Fee__c;
    
                        }
                    }*/ //NOSONAR

                    if(olli.DES_Risk_Observations__c != null) {
                        olli.risk_committee_comments_desc__c = olli.DES_Risk_Observations__c;

                    }

                        if(olli.DES_Commitment_Fees__c != null) {
                            olli.undrawn_fee_next_12m_per__c = olli.DES_Commitment_Fees__c;

                        }

                    if(olli.solution_classification_desc__c == Label.DES_Working_Capital && olli.DES_Annual_Risk_Fee__c != null) {
                            if(olli.DES_Annual_Risk_Fee__c != null) {
                                olli.DES_Risk_Fee_Next_12_Months__c = olli.DES_Annual_Risk_Fee__c * 100;

                            }
                        if(olli.syndicated_loan_drawn_amount__c != null) {
                            olli.pre_endrs_fee_next_12m_amount__c = (olli.DES_Risk_Fee_Next_12_Months__c/10000) * olli.syndicated_loan_drawn_amount__c;
                        }
                    }

                    /*if(olli.DES_Relevant_Comments__c != null) {
                        oppy = mapOpp.get(olli.OpportunityId);
   olli.DES_Relevant_Comments__c != null                     if() {
    oppy.DES_Comments__c = olli.DES_Relevant_Comments__c;
    
                        }
                        liOppyUpdt.add(oppy);
                    }*/ //NOSONAR

                    if(olli.DES_Underwriting__c == true) {
                        olli.underwriting_agreement_type__c = Label.DES_YES;
                    } else if(olli.DES_Underwriting__c == false
                    && !olli.underwriting_agreement_type__c.equalsIgnoreCase(Label.DES_YES)) {
                        olli.underwriting_agreement_type__c = 'No';
                    }

                    if(olli.DES_CIB_Client__c != null && olli.DES_CIB_Client__c.equalsIgnoreCase(Label.DES_YES)) {
                        olli.customer_cib_ind_type__c = 'CIB';
                    } else if(olli.DES_CIB_Client__c != null && olli.DES_CIB_Client__c.equalsIgnoreCase('No')) {
                        olli.customer_cib_ind_type__c = 'BEC';
                    }

                    if(olli.solution_classification_desc__c == Label.DES_Transaction_Trade_Finance) {
                        if(olli.DES_Risk_and_Pricing_Approvals__c == true) {
                            olli.risk_committee_aprvl_ind_type__c = Label.DES_YES;
                        } else if(olli.DES_Risk_and_Pricing_Approvals__c == false) {
                            olli.risk_committee_aprvl_ind_type__c = 'No';
                        }
                    } else {
                        if(olli.DES_Risk_Approval__c == true) {
                            olli.risk_committee_aprvl_ind_type__c = Label.DES_YES;
                        } else if(olli.DES_Risk_Approval__c == false) {
                            olli.risk_committee_aprvl_ind_type__c = 'No';
                        }
                    }
                // }
                liOlliUpdt.add(olli);
            }

            //update liOppyUpdt;
            update liOlliUpdt;

        } catch(Exception e) {
            Database.rollback(iSavePoint);
            System.debug('Error DES_MigrateOppliFieldsForOppVersion2: ' + e.getMessage());
        }
    }

    /**
     * Implementation of the finish method of the Database.Batchable interface
     */
    public void finish(Database.BatchableContext batchableContext) {
        System.debug('DES_MigrateOppliFieldsForOppVersion2 finish');
    }
}