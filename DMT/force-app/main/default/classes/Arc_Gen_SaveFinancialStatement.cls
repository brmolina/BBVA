/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveFinancialStatement
* @Author   Bertha Elena Tellez Lira
* @Date     Created: 07/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for Financial Statement.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-02-06 Bertha Elena Téllez Lira
*             Class creation.
* |2020-04-14 berthaelena.tellez.contractor@bbva.com
*    resolve fix on mapeo data
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveFinancialStatement implements dyfr.Save_Interface {
/**
* -----------------------------------------------------------------------------------------------
* @Description - Method that is responsible for invoking the classes to save the financial
* statement information.
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 23/01/2020
* @param listObject - List of the account has analisys object
* @return String with the execution message
* @example save (listObject)
* -----------------------------------------------------------------------------------------------
**/
    public String save (List<sObject> listObject) {
        List<String> ids = new List<String>();
        List<Arc_Gen_SaveFinancialStatementHelper.FinacialStatements> datEnv = new List<Arc_Gen_SaveFinancialStatementHelper.FinacialStatements>();

        for(sObject obj : listObject) {
            String idAnalisis = obj.get('Id').toString();
            // Validate that the user has permission to edit the record
            // before saving.
            if (Arc_Gen_TabSet_service.getPermissionToEdit(idAnalisis) != 'true') {
                throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
            }

            Arc_Gen_SaveFinancialStatementHelper.FinacialStatements objrR = new Arc_Gen_SaveFinancialStatementHelper.FinacialStatements();
            ids.add(idAnalisis);
            objrR.id = obj.get('Id').toString();
            objrR.opinionAuditor = String.valueOf(obj.get('arce__ffss_auditor_opinion_type__c'));
            objrR.fullName = String.valueOf(obj.get('arce__ffss_auditor_fullname_name__c'));
            objrR.quality = String.valueOf(obj.get('arce__ffss_auditor_qlfn_type__c'));
            objrR.agentComments = String.valueOf(obj.get('arce__ffss_auditor_opinion_desc__c'));
            objrR.finStId = String.valueOf(obj.get('arce__ffss_submitted_type__c'));
            objrR.finStConsolidate = String.valueOf(obj.get('arce__ffss_cnsld_perimeter_desc__c'));
            objrR.currencyType = String.valueOf(obj.get('arce__currency_id__c'));
            objrR.units = String.valueOf(obj.get('arce__magnitude_unit_type__c'));
            objrR.availableMat = String.valueOf(obj.get('arce__debt_maturity_available_type__c'));
            objrR.debtMat = String.valueOf(obj.get('arce__debt_maturity_desc__c'));
            objrR.banksNumbre = String.valueOf(obj.get('arce__number_entity_type__c'));
            objrR.budgetType = String.valueOf(obj.get('arce__cust_budget_cyr_ind_type__c'));
            objrR.budgetIsInc = String.valueOf(obj.get('arce__cust_budget_incl_ffss_ind_type__c'));
            objrR.budgetComments = String.valueOf(obj.get('arce__cust_budget_incl_ffss_desc__c'));

            objrR.listIndicator = new List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>();
            objrR.listIndicator = getIndicators(obj);

            objrR.listVariations = new List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>();
            objrR.listVariations = getVariations(obj);

            objrR.listVariables = new List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>();
            objrR.listVariables = getVariables(obj);
            datEnv.add(objrR);
        }
        Boolean result = Arc_Gen_Persistance_FinSt_Service.persistenceFS(ids, datEnv);
        return JSON.serialize(new arce.Arc_Gen_wrpSave(result,'Errs',listObject));
    }
/**
* -----------------------------------------------------------------------------------------------
* @Description - Method that is responsible for filling out list of indicators
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 23/01/2020
* @param sObject - account has analisys object
* @return List<Arc_Gen_SaveFinancialStatementHelper.ArraysData> with the values list
* @example getIndicators(sObject obj)
* -----------------------------------------------------------------------------------------------
**/
    public List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>getIndicators(sObject obj) {
        List<Arc_Gen_SaveFinancialStatementHelper.ArraysData> indicators = new List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>();
        Arc_Gen_SaveFinancialStatementHelper.ArraysData ind1 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        ind1.id = obj.get('Id').toString();
        ind1.idIndicator = 'EQUITY_TOTAL_ASSET_LESS_20%';
        ind1.isActive = String.valueOf(obj.get('arce__Syn_equity_type__c'));
        ind1.commentsIndicators = String.valueOf(obj.get('arce__equity_desc__c'));
        Arc_Gen_SaveFinancialStatementHelper.ArraysData ind2 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        ind2.id = obj.get('Id').toString();
        ind2.idIndicator = 'EXTRAORDINARY_ITEMS';
        ind2.isActive = String.valueOf(obj.get('arce__Syn_significant_extraordinary_variab__c'));
        ind2.commentsIndicators = String.valueOf(obj.get('arce__significant_variables_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData ind3 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        ind3.id = obj.get('Id').toString();
        ind3.idIndicator = 'TREASURY';
        ind3.isActive = String.valueOf(obj.get('arce__off_balance_treasury_type__c'));
        ind3.commentsIndicators = String.valueOf(obj.get('arce__off_balance_treasury_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData ind4 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        ind4.id = obj.get('Id').toString();
        ind4.idIndicator = 'GUARANTEES';
        ind4.isActive = String.valueOf(obj.get('arce__oper_guarantee_given_type__c'));
        ind4.commentsIndicators = String.valueOf(obj.get('arce__guarantee_given_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData ind5 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        ind5.id = obj.get('Id').toString();
        ind5.idIndicator = 'RELEVANT_INFORMATION';
        ind5.isActive = String.valueOf(obj.get('arce__off_balance_rlvnt_info_type__c'));
        ind5.commentsIndicators = String.valueOf(obj.get('arce__off_balance_rlvnt_info_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData ind6 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        ind6.id = obj.get('Id').toString();
        ind6.idIndicator = 'ADVANCE_OF_THE_YEAR';
        ind6.isActive = String.valueOf(obj.get('arce__cust_evolution_cyr_ind_type__c'));
        ind6.commentsIndicators = String.valueOf(obj.get('arce__cust_evolution_cyr_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData ind7 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        ind7.id = obj.get('Id').toString();
        ind7.idIndicator = 'NEXT_2_3_YEARS_PROJECTION';
        ind7.isActive = String.valueOf(obj.get('arce__AFAS_projection_type__c'));
        ind7.commentsIndicators = String.valueOf(obj.get('arce__cust_proj_2yr_3yr_desc__c'));

        indicators.add(ind1);
        indicators.add(ind2);
        indicators.add(ind3);
        indicators.add(ind4);
        indicators.add(ind5);
        indicators.add(ind6);
        indicators.add(ind7);
        return indicators;
    }
/**
* -----------------------------------------------------------------------------------------------
* @Description - Method that is responsible for filling out list of Variations
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 23/01/2020
* @param sObject - account has analisys object
* @return List<Arc_Gen_SaveFinancialStatementHelper.ArraysData> with the values list
* @example getVariations(sObject obj)
* -----------------------------------------------------------------------------------------------
**/
    public List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>getVariations(sObject obj) {
        List<Arc_Gen_SaveFinancialStatementHelper.ArraysData> variations = new List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>();
        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia.id = obj.get('Id').toString();
        varia.idIndicator = 'ITEMS_MORE_THAN_20';
        varia.commentsIndicators = String.valueOf(obj.get('arce__var_over_20_balance_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia1 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia1.id = obj.get('Id').toString();
        varia1.idIndicator = 'ITEMS_BETWEEN_10_AND_20';
        varia1.commentsIndicators = String.valueOf(obj.get('arce__var_vary_10_and_10_bal_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia2 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia2.id = obj.get('Id').toString();
        varia2.idIndicator = 'ITEMS_MORE_THAN_20_NOT_BEFORE';
        varia2.commentsIndicators = String.valueOf(obj.get('arce__variables_vary_20_balance_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia3 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia3.id = obj.get('Id').toString();
        varia3.idIndicator = 'SALES_EVOLUTION';
        varia3.commentsIndicators = String.valueOf(obj.get('arce__sales_evolution_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia4 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia4.id = obj.get('Id').toString();
        varia4.idIndicator = 'EBITDA_EVOLUTION';
        varia4.commentsIndicators = String.valueOf(obj.get('arce__ebitda_3yr_evolution_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia5 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia5.id = obj.get('Id').toString();
        varia5.idIndicator = 'COSTS_STRUCTURE';
        varia5.commentsIndicators = String.valueOf(obj.get('arce__cost_structure_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia6 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia6.id = obj.get('Id').toString();
        varia6.idIndicator = 'EQUITY_VARIATION_NOT_EXPLAINED_BY_P&L';
        varia6.commentsIndicators = String.valueOf(obj.get('arce__equity_vary_not_expln_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia7 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia7.id = obj.get('Id').toString();
        varia7.idIndicator = 'FINANCIAL_LIQUIDITY';
        varia7.commentsIndicators = String.valueOf(obj.get('arce__financial_liquidity_desc__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData varia8 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        varia8.id = obj.get('Id').toString();
        varia8.idIndicator = 'FIXED_ASSETS';
        varia8.commentsIndicators = String.valueOf(obj.get('arce__property_ownership_desc__c'));

        variations.add(varia);
        variations.add(varia1);
        variations.add(varia2);
        variations.add(varia3);
        variations.add(varia4);
        variations.add(varia5);
        variations.add(varia6);
        variations.add(varia7);
        variations.add(varia8);
        return variations;
    }
/**
* -----------------------------------------------------------------------------------------------
* @Description - Method that is responsible for filling out list of Variables
* statement information.
* -----------------------------------------------------------------------------------------------
* @Author   Bertha Elena Téllez Lira  berthaelena.tellez.contractor@bbva.com
* @Date     Created: 23/01/2020
* @param sObject - account has analisys object
* @return List<Arc_Gen_SaveFinancialStatementHelper.ArraysData> with the values list
* @example getVariables(sObject obj)
* -----------------------------------------------------------------------------------------------
**/
    public List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>getVariables(sObject obj){
        List<Arc_Gen_SaveFinancialStatementHelper.ArraysData> variables = new List<Arc_Gen_SaveFinancialStatementHelper.ArraysData>();
        Arc_Gen_SaveFinancialStatementHelper.ArraysData variable1 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        variable1.id = obj.get('Id').toString();
        variable1.idIndicator = 'PROPERTY_OWNERSHIP';
        variable1.variableType = String.valueOf(obj.get('arce__property_ownership_type__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData variable2 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        variable2.id = obj.get('Id').toString();
        variable2.idIndicator = 'FUNDS_DESTINATION';
        variable2.variableType = String.valueOf(obj.get('arce__Funds_destination_type__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData variable3 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        variable3.id = obj.get('Id').toString();
        variable3.idIndicator = 'FINANCIAL_FLEXIBILITY';
        variable3.variableType = String.valueOf(obj.get('arce__financial_flexibility_type__c'));

        Arc_Gen_SaveFinancialStatementHelper.ArraysData variable4 = new Arc_Gen_SaveFinancialStatementHelper.ArraysData();
        variable4.id = obj.get('Id').toString();
        variable4.idIndicator = 'CLIENT_SITUATION';
        variable4.variableType = String.valueOf(obj.get('arce__client_situation_type__c'));

        variables.add(variable1);
        variables.add(variable2);
        variables.add(variable3);
        variables.add(variable4);
        return variables;
    }

}