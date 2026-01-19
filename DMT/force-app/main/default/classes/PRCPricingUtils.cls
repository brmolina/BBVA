/** ********************************************************************************
* @author       JSS
* @date         21/01/2020
* @description  Clase con los métodos que implementan la lógica necesaria de la funcionalidad Pricing de las oportunidades
* @Revision
********************************************************************************* */
public without sharing class PRCPricingUtils {
    //LOGIC
    /**************** Se quita esa variable porque ya no se utiliza el customMetadata para nada */
        //private Map<String,PRC_Product_List__mdt> prodPricingMap = new Map<String,PRC_Product_List__mdt>();
    /****************/
    private static final String REGISTER_AMIWEB_WS = 'PrcRegisterInAmiweb';
    private static final String REGISTER_WORKFLOW_WS = 'PrcRegisterInWorkflow';
    private static final String STATUS_WORKFLOW_WS = 'PrcGetStatusWorkflow';
    private static final list<Integer> RESPONSE_STATUS_CODE_OK_LIST = new list<Integer>{200,201};
    private static final list<String> PRICING_PRODUCT_FAMILIES_LIST = new list<String>{'GTB','IBF'};
    /**
     * TOTAL_REGULATORY
     */
    private static final String TOTAL_REGULATORY = 'TOTAL_REGULATORY';
    /**
     * REGULATORY_BY_CREDIT_RISK
     */
    private static final String REGULATORY_BY_CR = 'REGULATORY_BY_CREDIT_RISK';
    /**
     * ECONOMIC_BY_CREDIT_RISK
     */
    private static final String ECONOMIC_BY_CR = 'ECONOMIC_BY_CREDIT_RISK';
    /**
     * DEAL_END_OF_YEAR
     */
    private static final String DEAL_END_OF_YEAR = 'DEAL_END_OF_YEAR';
    /**
     * ECONOMICAL
     */
    private static final String ECONOMICAL = 'ECONOMICAL';
    /**
     * CREDIT_RISK
     */
    private static final String CREDIT_RISK = 'CREDIT_RISK';
    /**
     * EXPECTED_LOSS
     */
    private static final String EXPECTED_LOSS = 'EXPECTED_LOSS';
    /**
     * ECONOMIC_CAPITAL
     */
    private static final String ECONOMIC_CAPITAL = 'ECONOMIC_CAPITAL';

    //CONSTRUCTOR
    private PRCPricingUtils() {
    }

    //SINGLETON PATTERN
    private static PRCPricingUtils instance;
    public static PRCPricingUtils getInstance() {
        if (instance == null) {
            instance = new PRCPricingUtils();
        }
        return instance;
    }


// ////////// PUBLIC METHODS ////////// //



    /**
    * @author       JSS
    * @description  Método que devuelve el nombre de la configuración CustomMetadata del servicio de alta en Amiweb
    */
    public String getServiceRegisterAmiweb() {
        return REGISTER_AMIWEB_WS;
    }

    /**
    * @author       JSS
    * @description  Método que devuelve el nombre de la configuración CustomMetadata del servicio de alta en workflow
    */
    public String getServiceRegisterWorkflow() {
        return REGISTER_WORKFLOW_WS;
    }

    /**
    * @author       JSS
    * @description  Método que devuelve el nombre de la configuración CustomMetadata del servicio de consulta de estado workflow
    */
    public String getServiceStatusWorkflow() {
        return STATUS_WORKFLOW_WS;
    }

        /**
    * @author       JSS
    * @description  Método que devuelve la lista de Status Code que son OK en las respuestas de los web services
    */
    public List<Integer> getResponseStatusCodeOKList() {
        return RESPONSE_STATUS_CODE_OK_LIST;
    }

   /**
    * @author       JSS
    * @description  comprueba si el producto del OppLineItem pasado por parámetro está dentro de la lista de productos definidos en la funcionalidad Pricing
    */
    public Boolean isPricingProduct(OpportunityLineItem oli) {
        Boolean result = false;
        if (PRICING_PRODUCT_FAMILIES_LIST.contains(oli.DES_Product_Family__c)) {
            result = true;
        }

        return result;
    }


    /**
    * @author       JSS
    * @description  lógica que comprueba si para un producto Pricing ya se ha seleccionado un precio de la matriz y debe aparecer el botón de "Price Details"
    */
    public Boolean displayAmiwebButton(Opportunity opp, list <OpportunityLineItem> oliList) {
        if ( oliList.size() == 1 && isPricingProduct(oliList.get(0)) && String.isEmpty(opp.gf_workflow_opportunity_id__c)) {
            return true;
        } else {
            return false;
        }
    }


     /**
    * @author       JSS
    * @description  lógica que comprueba si para un producto Pricing ya se ha seleccionado un precio de la matriz y deben aparecer el resto de secciones dentro de la flexipage
    */
    public Boolean displayPricingSection(Opportunity opp, list <OpportunityLineItem> oliList) {
        if ( oliList.size() == 1 && isPricingProduct(oliList.get(0)) && !String.isEmpty(opp.gf_amiweb_opportunity_id__c) ) {
            return true;
        } else {
            return false;
        }
    }


   /**
    * @author       JSS
    * @description  lógica que comprueba si para un producto Pricing ya se ha seleccionado un precio de la matriz y debe aparecer el botón de "Sent to Workflow" dentro funcionalidad Pricing recibiendo como parametro un objeto OpportunityLineItem
    */
    public Boolean displayWorkflowButton(Opportunity opp, list <OpportunityLineItem> oliList) {
        if ( oliList.size() == 1 && isPricingProduct(oliList.get(0)) && !String.isEmpty(opp.gf_amiweb_opportunity_id__c) && String.isEmpty(opp.gf_workflow_opportunity_id__c)) {
            return true;
        } else {
            return false;
        }
    }

   /**
    * @author       JSS
    * @description  Devuelve la lista de registros del objeto PRC_Profitability_Scenarios__c de una oportunidad
    */
    public List<PRC_Profitability_Scenarios__c> getScenariosListFromOppid(Id OppId) {
        return [select id from PRC_Profitability_Scenarios__c where PRC_Opportunity__c  = :OppId];
    }


   /**
    * @author       JSS
    * @description  Devuelve la lista de registros del objeto PRC_Profitability_Scenarios__c necesario para la tabla de la sección "Profitability under differents scenarios"
    */
    public List<PRC_Profitability_Scenarios__c> getScenarioWithSalesAgreementData(Id OppId) {
        return [select Id, IsDeleted, Name, CurrencyIsoCode, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, gf_nominal_interest_amount__c, gf_loan_fund_cost_amount__c, gf_accrual_fees_amount__c, oppy_upfront_fee_amount__c, gf_reference_index_rate_per__c, economic_capital_amount__c, gf_expected_loss_amount__c, gf_rorc_cpt_el_amount__c, gf_opern_expenditures_amount__c, gf_operational_risk_per__c, ead_amount__c, gf_taxes_amount__c, year_id__c, PRC_Opportunity__c,
                gf_trans_rar_amount__c, gf_rorc_amount__c, gf_econ_regy_result_name__c, gf_sum_rwa_regy_amount__c, gf_capital_regy_amount__c from PRC_Profitability_Scenarios__c where PRC_Opportunity__c  = :OppId AND gf_econ_regy_result_name__c = 'ANNUAL' Order by year_id__c ASC];
    }

   /**
    * @author       JSS
    * @description  Devuelve la lista de registros del objeto PRC_Profitability_Scenarios__c necesario para el gráfico de la sección "Profitability under differents scenarios"
    */
    public List<PRC_Profitability_Scenarios__c> getScenarioWithoutSalesAgreementData(Id OppId) {
        return [Select id, PRC_Opportunity__c, year_id__c, ead_amount__c, gf_trans_rar_amount__c, gf_rorc_amount__c From PRC_Profitability_Scenarios__c where PRC_Opportunity__c  = :OppId AND gf_econ_regy_result_name__c = 'ACCUMULATED' Order by year_id__c ASC];
    }



    /**
    * @author       JSS
    * @description  Método que actualiza la información Pricing de tres objetos: el price selected (OppLineItem), Price profitability, y el amiwebId en Opportunity
    */
    public void saveSelectedPrice(Id oppId, PRC_PFS_Response priceFullResponse, PRC_PFS_Scenario selectedPrice, String amiwebId,String proposalId) {
        savePriceToPricingDetails(oppId, priceFullResponse, selectedPrice);
        saveProfitabilityScenarios (oppId, selectedPrice);
        //saveAmiwebId(oppId,amiwebId,proposalId);
        saveAmiwebId(oppId,'NOAMIWEB','NOAMIWEB');
    }


   /**
    * @author       JSS
    * @description  Guarda en el registro de Profitability Scenario de Salesforce los datos relativos a escenarios de rentabilidad del Price seleccionado
    */
    public void saveWorkflowData(Id oppId, string workflowId, string workflowStatus) {
        System.debug('>>>>>>>>>>>> saveWorkflowData. oppId: ' + oppId);
        // recuperamos el id del OppLI donde queremos guardar los datos
        Opportunity opp = new Opportunity();
        opp.Id = oppId;
        opp.gf_workflow_opportunity_id__c = workflowId;
        opp.gf_workflow_oppy_status_type__c = workflowStatus;

        update opp;
    }


    /**
    * @author       JSS
    * @description  recupera los datos del OppLineItem relacionado con el Id de Opp que recibe como parametro
    */
    public OpportunityLineItem getOppLineItemDataFromOpp(Id oppId) {
        return getOppLineItemListFromOpp(oppId).get(0);
    }




    /**
    * @author       JSS
    * @description  recupera los datos del PriceDetails relacionado con el Id de Opp que recibe como parametro
    */
    public PRC_Pricing_Detail__c getPricingDetailsDataFromOpp(Id oppId) {
        final List<Id> idList = new List<id>{oppId};
        return getPricingDetailsDataFromList(idList).get(0);
    }




    /**
    * @author       JSS
    * @description  devuele un boolean true si se puede eliminar la oportunidad; false si no se puede eliminar (porque ya se ha enviado a Workflow)
    */
    public Boolean pricingOpportunityCanBeDeleted(Opportunity opp) {
        return (String.isEmpty(opp.gf_workflow_opportunity_id__c) ? true : false);
    }


    /**
    * @author       JSS
    * @description  devuele un boolean true si se puede eliminar la oportunidad; false si no se puede eliminar (porque ya se ha enviado a Workflow)
    */
    public Boolean pricingOppLineItemCanBeDeleted(OpportunityLineItem oli) {
        return (String.isEmpty(oli.gf_workflow_opportunity_id__c) ? true : false);
    }



    /**
    * @author       JSS
    * @description  devuele un boolean true si se puede añadir un nuevo oppLineItem porque la oportunidad no está ya avanzada en Pricing; false si no se puede añadir (porque ya se ha rellenado el Pricing form)
    */
    /*
    public Boolean pricingOppLineItemCanBeAdded(OpportunityLineItem oli) {
        return (String.isEmpty(oli.gf_amiweb_opportunity_id__c) ? true : false);
    }*/

    /**
    * @author       JSS
    * @description  devuele un boolean true si es un oppLineItem que ya se ha rellenado con info de Pricing y se ha mandado a amiweb; false si no se ha avanzado (rellenado el Pricing form y seleccionado un precio de la matriz)
    */
    public Boolean oppLineItemHasPricingData(OpportunityLineItem oli) {
        return (String.isEmpty(oli.gf_amiweb_opportunity_id__c) ? false : true);
    }



    /**
    * @author       JSS
    * @description  devuelve el idProposal de la Matriz de la oportunidad que se le pasa como parámetro
    */
    public String getMatrixProposalId(Id oppId) {
        System.debug('>>>>>>>>>>> PRCPricingUtils > getMatrixProposalId > oppId:' + oppId);
        Opportunity result = [Select id, gf_proposal_id__c From Opportunity Where id = :oppId LIMIT 1];
        return (String.isEmpty(result.gf_proposal_id__c) ? '' : result.gf_proposal_id__c);
    }


    /**
    * @author       JSS
    * @description  devuelve la lista de datos de PricingDetail a partir de la lista de PricingDetailId que recibe
    */
    public List<PRC_Pricing_Detail__c> getPricingDetailsDataFromList(List<Id> idList) {
        return getPricingDetailsDataMapByOpp(idList).values();
    }


    /**
    * @author       JSS
    * @description  devuelve la lista de datos de PricingDetail a partir de la lista de OpportunityId que recibe
    */
    public Map<Id,PRC_Pricing_Detail__c> getPricingDetailsDataMapByOpp(List<Id> idList) {
        List<PRC_Pricing_Detail__c> pdList  = [SELECT Id,PRC_Opportunity__c,PRC_Opportunity__r.Account.Industry,
        /* solution_classification_desc__c, solution_name_path_desc__c, DES_Product_Family__c,  */
        branch_name__c, gf_cust_group_rating_type__c, rating_scale_type__c, gf_scope_type__c, agency_rating_value_type__c,
        gf_ope_agency_rating_type__c, gf_fdg_trd_prpsl_rar_tot_per__c,
        gf_nfdg_trd_prpsl_rar_tot_per__c, gf_trd_prpsl_rorc_funding_per__c, gf_eoy_nfdg_trd_prpsl_rorc_per__c,
        opportunity_currency_id__c, gf_pricing_risk_product_name__c, gf_pricing_risk_product_id__c,
        gf_ope_booking_entity_name__c, gf_financing_type_name__c, opportunity_start_date__c, current_expiry_date__c,
        transaction_country_name__c, gf_operation_term_number__c, gf_funding_curve_type__c, lgd_per__c, gf_on_balance_funding_per__c,
        gf_off_balance_funding_per__c, amortization_desc__c, payment_type__c, frequency_type__c, currency_id__c, gf_on_bal_mrgn_gen_amount__c,
        gf_off_bal_mrgn_gen_amount__c, gf_ope_on_balance_margin_per__c, gf_ope_off_balance_margin_per__c, gf_tax_rate_per__c, gf_cost_income_ratio_per__c,
        gf_accrual_per__c, gf_non_accrual_comission_per__c,economic_activity_sector_desc__c, PRC_Opportunity__r.Account.SER_CClient__c,
        business_area_desc__c, gf_ope_cpt_25_pct_red_ind_type__c, PRC_Opportunity__r.AccountId
        FROM PRC_Pricing_Detail__c
        WHERE PRC_Opportunity__c = :idList];

        Map<Id,PRC_Pricing_Detail__c> pdMap = new Map<Id,PRC_Pricing_Detail__c>();
        for (PRC_Pricing_Detail__c pd : pdList) {
            pdMap.put(pd.PRC_Opportunity__c,pd);
        }

        return pdMap;
    }



    /**
    * @author       JSS
    * @description  Método que recupera del body de la httpresponse la descripción del error que devuelve el servicio
    */
    public String getResponseWarningDescription(String respBody) {
        final Map<String,Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(respBody);
        final List<Object> responseList = (List<Object>)responseMap.get('messages');
        final Map<String,Object> responseObject = (Map<String,Object>)responseList.get(0);
        final String msg = (String)responseObject.get('message');
        return msg.replaceAll('#',' - '); // remplazamos el caracter # porque nosotros tambien lo utilizamos como separador
    }



// ////////// PRIVATE METHODS ////////// //


   /**
    * @author       JSS
    * @description  recupera el la lista de OppLineItem relacionado con el Id de Opp que recibe como parametro
    */
    private list<OpportunityLineItem> getOppLineItemListFromOpp(Id oppId) {
        return [SELECT Id,OpportunityId,Opportunity.Account.Industry,solution_classification_desc__c,solution_name_path_desc__c,
               PRC_Pricing_Detail__c, DES_Product_Family__c
        FROM OpportunityLineItem
        WHERE OpportunityId = :oppId];
    }


    /**
    * @author       JSS
    * @description  recupera el ID OppLineItem relacionado con el Id de Opp que recibe como parametro
    */
    private Id getOppLineItemIDFromOpp(Id oppId) {
        list<OpportunityLineItem> oppliList = getOppLineItemListFromOpp(oppid);
        return (oppliList.size() != 1 ? '' : oppliList.get(0).Id);
    }


    /**
    * @author       JSS
    * @description  recupera el ID PricingDetails relacionado con el Id de Opp que recibe como parametro
    */
    private Id getPricingDetailsIDFromOpp(Id oppId) {
        final List<Id> idList = new List<id>{oppId};
        list<PRC_Pricing_Detail__c> pdList = getPricingDetailsDataFromList(idList);
        return (pdList.size() != 1 ? '' : pdList.get(0).Id);
    }



   /**
    * @author       JSS
    * @description  Guarda en el registro de OppLineItem de Salesforce los datos del Price seleccionado
    */
    private void saveAmiwebId(Id oppId, String amiwebId,String proposalId) {
        // rellenamos el id del OppLI donde queremos guardar los datos
        Opportunity opp = new Opportunity();
        opp.Id = oppId;
        opp.gf_amiweb_opportunity_id__c = amiwebId;
        opp.gf_proposal_id__c = proposalId;

        update opp;
    }



   /**
    * @author       JSS
    * @description  Guarda en el registro de PricingDetails de Salesforce los datos del Price seleccionado
    */
    private void savePriceToPricingDetails( Id oppId, PRC_PFS_Response resp, PRC_PFS_Scenario selectedPrice) {
        System.debug('>>>>>>>>>>>> Entrando savePriceToPricingDetails');
        final String priceDetailsId = getPricingDetailsIDFromOpp(oppId);

        // este IF es por seguridad, pero si ha llegado hasta aquí el ID de PricingDetails nunca debería ser vacío
        if (!String.isEmpty(priceDetailsId)) {
            // rellenamos el id del OppLI donde queremos guardar los datos
            PRC_Pricing_Detail__c pdToUpdate = new PRC_Pricing_Detail__c();

            for (PRC_PFS_Scenario.profitabilityMetric pm: selectedPrice.profitabilityMetrics) {
                switch on pm.id {
                    when 'RAROEC_WITH_FUNDING' {
                        pdToUpdate.gf_fdg_trd_prpsl_rar_tot_per__c = pm.deal.setScale(2);
                        pdToUpdate.gf_eoy_fdg_trd_prpsl_rar_per__c = pm.dealFirstTwelveMonths.setScale(2);
                    }
                    when 'RAROEC_WITHOUT_FUNDING' {
                        pdToUpdate.gf_nfdg_trd_prpsl_rar_tot_per__c = pm.deal.setScale(2);
                    }
                    when 'RORC_WITH_FUNDING' {
                        pdToUpdate.gf_trd_prpsl_rorc_funding_per__c = pm.deal.setScale(2);
                        pdToUpdate.gf_eoy_fdg_trd_prpsl_rorc_per__c = pm.dealFirstTwelveMonths.setScale(2);
                    }
                    when 'RORC_WITHOUT_FUNDING' {
                        pdToUpdate.gf_eoy_nfdg_trd_prpsl_rorc_per__c = pm.deal.setScale(2);
                    }
                }

            }

            pdToUpdate = completeScenario(selectedPrice,pdToUpdate );

            pdToUpdate.Id = priceDetailsId;
            pdToUpdate = completeCRBalance(selectedPrice,pdToUpdate );

            pdToUpdate.gf_on_bal_mrgn_gen_amount__c = resp.data.engineWorksWith.operations[0].amortization.notional.onBalance.setScale(2); //  -> Nominal OnB (Thousands)
            System.debug('mapeo update pricing');
            if (selectedPrice.riskWeightedAssests != null) {
                for (PRC_PFS_Scenario.riskWeightedAssests rwa: selectedPrice.riskWeightedAssests) {
                    if (rwa.id == TOTAL_REGULATORY) {
                        pdToUpdate.gf_risk_regy_assets_tl_amount__c = rwa.amount;
                    } else if (rwa.id == REGULATORY_BY_CR) {
                        pdToUpdate.gf_rwa_reglty_thsd_amount__c = rwa.amount;
                    } else if (rwa.id == ECONOMIC_BY_CR) {
                        pdToUpdate.gf_tot_risk_wght_asset_amount__c = rwa.amount;
                    }
                }
            }


            if (selectedPrice.netProfit != null) {
                System.debug('netprofit: ' + selectedPrice.netProfit.amount);
                pdToUpdate.net_income_amount__c = selectedPrice.netProfit.amount;
            }

            if ( selectedPrice.operationalRisks != null && !selectedPrice.operationalRisks.isEmpty()) {
                System.debug('selectedPrice.operationalRisk: ' + selectedPrice.operationalRisks);
                for (PRC_PFS_Scenario.amounts am: selectedPrice.operationalRisks[0].amounts) {
                    if (am.id == ECONOMIC_CAPITAL) {
                        System.debug('ECONOMIC_CAPITAL: ' + am.amount);
                        pdToUpdate.gf_economic_capital_amount__c = am.amount.setScale(2) + (pdToUpdate.gf_oper_cr_rsk_econ_cpt_amount__c == null ? 0 : pdToUpdate.gf_oper_cr_rsk_econ_cpt_amount__c);
                    }
                }
            }

            System.debug('fin mapeo update pricing');



            update pdToUpdate;
        }
    }


    /**
    * @description
    * @author Global Desktop | 03-05-2021
    * @param selectedPrice
    * @param priceDetail
    * @return PRC_Pricing_Detail__c
    **/
    private static PRC_Pricing_Detail__c completeScenario (PRC_PFS_Scenario selectedPrice, PRC_Pricing_Detail__c priceDetail) {
        final PRC_Pricing_Detail__c pdToUpdate = priceDetail;


        for (PRC_PFS_Scenario.income inc: selectedPrice.incomes) {
            if (inc.id == DEAL_END_OF_YEAR) {
                    pdToUpdate.gf_ope_ft_yr_ti_amount__c = inc.amount.setScale(2);
                    break;
            }
        }

        for (PRC_PFS_Scenario.exposuresAtDefault ead: selectedPrice.exposuresAtDefault) {
                if (ead.model == ECONOMICAL) {
                        pdToUpdate.ead_amount__c = ead.amount.setScale(2);
                        pdToUpdate.currency_id__c = ead.currenc_y;
                        break;
                }
        }

        pdToUpdate.total_nominal_amount__c = selectedPrice.maximumBalance.amount;
        pdToUpdate.gf_trd_prpsl_avg_life_y_number__c = selectedPrice.averageLifeInYears;


        return pdToUpdate;
    }

    /*
    * Method aux
    */
    private static PRC_Pricing_Detail__c completeCRBalance (PRC_PFS_Scenario selectedPrice, PRC_Pricing_Detail__c priceDetail) {
        PRC_Pricing_Detail__c pdToUpdate = priceDetail;

        pdToUpdate = completeCRBalance2(pdToUpdate, selectedPrice);
        pdToUpdate.gf_value_date__c = Date.today();
            //pdToUpdate.PRC_Pricing_Form_Edited_NEW__c = true; //Este campo de control debería ya haberse puesto a TRUE al pinchar en cualquiera de los dos botones del pricingForm: tanto el botón Save como Calculate
        system.debug('precio seleccionado :'+selectedPrice);
            //rellenamos en el OppLI los datos de la response y el precio (escenario) seleccionado
        pdToUpdate.gf_on_balance_funding_per__c = selectedPrice.funds[0].onBalance.setScale(2);
        pdToUpdate.gf_off_balance_funding_per__c = selectedPrice.funds[0].offBalance.setScale(2);

        system.debug('>>>>>valores sensibily :' +(selectedPrice.sensitivities[0].id == 'SENSIVITY' ? selectedPrice.sensitivities[0].margin.onBalance.setScale(2) : selectedPrice.sensitivities[1].margin.onBalance.setScale(2)));
        pdToUpdate.gf_on_balance_mrgn_stvy_per__c = (selectedPrice.sensitivities[0].id == 'SENSIVITY' ? selectedPrice.sensitivities[0].margin.onBalance.setScale(2) : selectedPrice.sensitivities[1].margin.onBalance.setScale(2));
        pdToUpdate.gf_off_balance_mrgn_stvy_per__c = (selectedPrice.sensitivities[0].id == 'SENSIVITY' ? selectedPrice.sensitivities[0].margin.offBalance.setScale(2) : selectedPrice.sensitivities[1].margin.offBalance.setScale(2));

        pdToUpdate.gf_on_balance_total_per__c = selectedPrice.allIn.onBalance.setScale(2);
        pdToUpdate.gf_off_balance_total_per__c = selectedPrice.allIn.offBalance.setScale(2);

        pdToUpdate.gf_lgd_avg_per__c = selectedPrice.averageLossGivenDefault.setScale(2);
        pdToUpdate.gf_expected_loss_eqv_rating_id__c = selectedPrice.equivalentRating;

        //estos dos campos son en funcion del tipo de amortizacion: Linear o Bullet, a lo mejor hay tener esto en cuenta y hacer alguna lógica, de momento los guardamos sin más
        pdToUpdate.gf_ope_on_balance_margin_per__c = selectedPrice.operations[0].margin.onBalance.setScale(2); //  -> Margin OnB (B.P.)
        pdToUpdate.gf_ope_off_balance_margin_per__c = selectedPrice.operations[0].margin.offBalance.setScale(2); //  -> Margin OnB (B.P.)

        return pdToUpdate;
    }

    /*
    * Method aux
    */
    private static PRC_Pricing_Detail__c completeCRBalance2 (PRC_Pricing_Detail__c priceDetail, PRC_PFS_Scenario selectedPrice) {
        final PRC_Pricing_Detail__c pdToUpdate = priceDetail;
        for (PRC_PFS_Scenario.creditRisk crk: selectedPrice.creditRisks) {
            if (crk.id == CREDIT_RISK) {
                pdToUpdate.gf_expected_loss_amount__c = crk.amounts[0].id == EXPECTED_LOSS ? crk.amounts[0].amount.setScale(2) : crk.amounts[1].amount.setScale(2);
                pdToUpdate.gf_oper_cr_rsk_econ_cpt_amount__c = crk.amounts[0].id == ECONOMIC_CAPITAL ? crk.amounts[0].amount.setScale(2) : crk.amounts[1].amount.setScale(2);
                break;
            }
        }
        return pdToUpdate;
    }

   /**
    * @author       JSS
    * @description  Guarda en el registro de Profitability Scenario de Salesforce los datos relativos a escenarios de rentabilidad del Price seleccionado
    */
    private void saveProfitabilityScenarios( Id oppId, PRC_PFS_Scenario selectedPrice) {
        System.debug('>>>>>>>>>>>> Entrando saveProfitabilityScenarios');
        list<PRC_Profitability_Scenarios__c> psToDeleteList = new list<PRC_Profitability_Scenarios__c>();// lista de los escenarios previos que hay que eliminar si se vuelve a seleccionar otro precio de la matriz
        list<PRC_Profitability_Scenarios__c> psList = new list<PRC_Profitability_Scenarios__c>();// lista de escenarios que se guardarán correspondientes al precio seleccionado

        //recuperamos la lista de escenarios que existian previamente y que hay que eliminar porque ya no aplican
        psToDeleteList = getScenariosListFromOppid(oppId);
        System.debug('>>>>>>>>>>>> Lista de escenarios que existian previamente y que hay que eliminar: ' + psToDeleteList.toString());
        if (!psToDeleteList.isEmpty()) {
            delete psToDeleteList;
        }

        for (PRC_PFS_Scenario.result result: selectedPrice.results) {
            // recuperamos el id del OppLI donde queremos guardar los datos
            PRC_Profitability_Scenarios__c newPS = new PRC_Profitability_Scenarios__c();
            newPS.PRC_Opportunity__c = oppId;

            newPS.gf_econ_regy_result_name__c = result.resultType;
            newPS.gf_nominal_interest_amount__c = result.interest.amount;

            for (PRC_PFS_Scenario.amount am: result.amounts) {
                    switch on am.id {
                        when 'FUNDING_COST' {
                             newPS.gf_loan_fund_cost_amount__c = am.amount;
                        }
                        when 'ACCRUAL_FEES' {
                              newPS.gf_accrual_fees_amount__c = am.amount;
                        }
                        when 'UPFRONT_FEES' {
                              newPS.oppy_upfront_fee_amount__c = am.amount;
                        }
                        when 'ECONOMIC_CAPITAL' {
                              newPS.economic_capital_amount__c = am.amount;
                        }
                        when 'EXPECTED_LOSS' {
                              newPS.gf_expected_loss_amount__c = am.amount;
                        }
                        when 'EXPECTED_LOSS_FOR_RORC' {
                              newPS.gf_rorc_cpt_el_amount__c = am.amount;
                        }
                        when 'OPEX_VALUE' {
                              newPS.gf_opern_expenditures_amount__c = am.amount;
                        }
                        when 'EXPOSURE_AT_DEFAULT' {
                              newPS.ead_amount__c = am.amount;
                              newPS.currencyIsoCode = am.currenc_y;
                        }
                    }
              }

            newPS.gf_reference_index_rate_per__c = result.offerRate;
            newPS.gf_operational_risk_per__c = result.operationalRisk;
            newPS.gf_taxes_amount__c = result.taxes;
            newPS.year_id__c = result.year;

            psList.add(newPS);
        }

        if (!psList.isEmpty()) {
            insert psList;
        }
    }

    /**
    * @description
    * @author Global Desktop | 03-05-2021
    * @return String
    **/
    public String getFederationId(){
        User currentuser = [select Id,FederationIdentifier from User where Id =:UserInfo.getUserId()][0];
        return currentuser.FederationIdentifier;
    }


    /**
    * @description
    * @author Global Desktop | 03-05-2021
    * @return Map<String, PRC_Combo_Validation__mdt>
    **/
    public Map<String, PRC_Combo_Validation__mdt>  getCombosVal() { //NOSONAR
    	final Map<String, PRC_Combo_Validation__mdt> Combos = new Map<String, PRC_Combo_Validation__mdt> ();
        final PRC_Combo_Validation__mdt[] rating = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, Product__c, API_key__c FROM PRC_Combo_Validation__mdt ]; //NOSONAR
        for(PRC_Combo_Validation__mdt combov : rating) {
        	Combos.put(combov.Label,combov);
        }
        return Combos;
    }
}