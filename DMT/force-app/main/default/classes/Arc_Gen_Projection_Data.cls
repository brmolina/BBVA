/**
* @File Name          : Arc_Gen_Projection_Data.cls
* @Description        : Data class to get data about Projections and EEFF
* @Author             : joseluis.miralles.contractor@bbva.com - aleksandar.dinkov.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 10-17-2024
* @Changes
*========================================================================================
* Ver         Date                     Author                 Modification
*========================================================================================
* 1.0    15/05/2023  joseluis.miralles.contractor@bbva.com     Initial Version
**/
@SuppressWarnings('sf:TooManyMethods, sf:LongVariable, sf:AvoidGetSetMethods')
public without sharing class Arc_Gen_Projection_Data {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor to avoid SonarQube warning.
    *-------------------------------------------------------------------------------
    **/
    private Arc_Gen_Projection_Data() { }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get all projection data by Aha id
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    projectionId setAhaIds
    * @example    Arc_Gen_Projection_Data.getProjectionData(aHaId);
    */
    public static List<arce__Projection__c> getProjectionData(String aHaId) {
        return [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, arce__SelectedCurrency__c, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, arce__Account_has_Analysis__c, arce__Amortization_Depreciation__c, arce__Avg_Days_Inventory_Out__c, arce__Avg_Days_Payable_Out__c, arce__Avg_Days_Sales_Out__c, arce__Banks_Bonds_Derivatives_Leases_LT__c, arce__Banks_Bonds_Derivatives_Leases_LT_pct__c, arce__Banks_Bonds_Derivatives_Leases_ST__c, arce__Banks_Bonds_Derivatives_Leases_ST_pct__c, arce__Capex_Key__c, arce__Capex__c, arce__Cash_generated_consumed__c, arce__Change_in_Working_Capital__c, arce__Confirmed_Projection__c, arce__Current_Assets__c, arce__Current_Assets_pct__c, arce__Current_Liabiities__c, arce__Current_Liabiities_pct__c, arce__Dividend__c, arce__Dividend_received__c, arce__EBITDA_Interest_expenses__c, arce__Ebit__c, arce__Ebit_pct__c, arce__Ebitda__c, arce__Ebitda_pct__c, arce__Edit_Base_Case__c, arce__Cash_cash_equivalents__c, arce__Cash_cash_equivalents_base__c, arce__Cash_cash_equivalents_calc__c, arce__Cash_cash_equivalents_pct__c, arce__Ending_cash__c, arce__FFO_Net_Debt__c, arce__FOCF_Net_Debt__c, arce__Free_Cash_Flow_to_Shareholders__c, arce__Free_Cash_Flowto_Debt_Service__c, arce__Gross_Debt_Ebitda__c, arce__Interest_expense__c, arce__Interest_expense_pct__c, arce__Interest_expenses__c, arce__Inventories__c, arce__Inventories_pct__c, arce__Margen_Ebitda__c, arce__Net_Debt_Ebitda__c, arce__Net_Income_Atributable__c, arce__Net_Income_Atributable_pct__c, arce__Net_Result_after_taxes__c, arce__Net_Result_after_taxes_pct__c, arce__Net_Worth__c, arce__Net_Worth_pct__c, arce__Net_income__c, arce__Non_Current_Assets__c, arce__Non_Current_Assets_pct__c, arce__Non_Current_Liabilities__c, arce__Non_Current_Liabilities_pct__c, arce__Pay_out__c, arce__Projection_Criteria__c, arce__Projection_Header__c, arce__Projection_Id__c, arce__Projection_Type__c, arce__Revenue__c, arce__Revenue_growth__c, arce__Scenario_Comment__c, arce__Scenario_Type__c, arce__Simulation_Calculated__c, arce__Simulation_Long_Scale_Value__c, arce__Simulation_Score__c, arce__Simulation_Short_Scale_Value__c, arce__Total_Assets__c, arce__Total_Assets_pct__c, arce__Total_Equity_Liabilities__c, arce__Total_Equity_Liabilities_pct__c, arce__Total_Revenues__c, arce__Total_Revenues_pct__c, arce__Trade_Accounts_Payable__c, arce__Trade_Accounts_Payable_pct__c, arce__Trade_accounts_receivables__c, arce__Trade_accounts_receivables_pct__c, arce__Var_Debt__c, arce__Statement_Currency__c, arce__FinancialStatement_Type__c, arce__Period_StartDate__c, arce__Period_EndDate__c
                                            FROM arce__Projection__c
                                            WHERE arce__Account_has_Analysis__c = :aHaId AND arce__Projection_Type__c = 'Projection'
                                            ORDER BY arce__Period_EndDate__c ASC];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get all projection data by Aha id
    *--------------------------------------------------------------------------------
    * @date        27/06/2023
    * @author    aleksandar.dinkov.contractor@bbva.com
    * @param    String aHaId
    * @example    Arc_Gen_Projection_Data.getProjectionByAhaId(aHaId);
    */
    public static List<arce__Projection__c> getProjectionByAhaId(String aHaId) {
        return [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, arce__SelectedCurrency__c, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, arce__Account_has_Analysis__c, arce__Amortization_Depreciation__c, arce__Avg_Days_Inventory_Out__c, arce__Avg_Days_Payable_Out__c, arce__Avg_Days_Sales_Out__c, arce__Banks_Bonds_Derivatives_Leases_LT__c, arce__Banks_Bonds_Derivatives_Leases_LT_pct__c, arce__Banks_Bonds_Derivatives_Leases_ST__c, arce__Banks_Bonds_Derivatives_Leases_ST_pct__c, arce__Capex_Key__c, arce__Capex__c, arce__Cash_generated_consumed__c, arce__Change_in_Working_Capital__c, arce__Confirmed_Projection__c, arce__Current_Assets__c, arce__Current_Assets_pct__c, arce__Current_Liabiities__c, arce__Current_Liabiities_pct__c, arce__Dividend__c, arce__Dividend_received__c, arce__EBITDA_Interest_expenses__c, arce__Ebit__c, arce__Ebit_pct__c, arce__Ebitda__c, arce__Ebitda_pct__c, arce__Edit_Base_Case__c, arce__Cash_cash_equivalents__c, arce__Cash_cash_equivalents_base__c, arce__Cash_cash_equivalents_calc__c, arce__Cash_cash_equivalents_pct__c, arce__Ending_cash__c, arce__FFO_Net_Debt__c, arce__FOCF_Net_Debt__c, arce__Free_Cash_Flow_to_Shareholders__c, arce__Free_Cash_Flowto_Debt_Service__c, arce__Gross_Debt_Ebitda__c, arce__Interest_expense__c, arce__Interest_expense_pct__c, arce__Interest_expenses__c, arce__Inventories__c, arce__Inventories_pct__c, arce__Margen_Ebitda__c, arce__Net_Debt_Ebitda__c, arce__Net_Income_Atributable__c, arce__Net_Income_Atributable_pct__c, arce__Net_Result_after_taxes__c, arce__Net_Result_after_taxes_pct__c, arce__Net_Worth__c, arce__Net_Worth_pct__c, arce__Net_income__c, arce__Non_Current_Assets__c, arce__Non_Current_Assets_pct__c, arce__Non_Current_Liabilities__c, arce__Non_Current_Liabilities_pct__c, arce__Pay_out__c, arce__Projection_Criteria__c, arce__Projection_Header__c, arce__Projection_Id__c, arce__Projection_Type__c, arce__Revenue__c, arce__Revenue_growth__c, arce__Scenario_Comment__c, arce__Scenario_Type__c, arce__Simulation_Calculated__c, arce__Simulation_Long_Scale_Value__c, arce__Simulation_Score__c, arce__Simulation_Short_Scale_Value__c, arce__Total_Assets__c, arce__Total_Assets_pct__c, arce__Total_Equity_Liabilities__c, arce__Total_Equity_Liabilities_pct__c, arce__Total_Revenues__c, arce__Total_Revenues_pct__c, arce__Trade_Accounts_Payable__c, arce__Trade_Accounts_Payable_pct__c, arce__Trade_accounts_receivables__c, arce__Trade_accounts_receivables_pct__c, arce__Var_Debt__c, arce__Statement_Currency__c, arce__FinancialStatement_Type__c, arce__Period_StartDate__c, arce__Period_EndDate__c, arce__Amortization_Depreciation_calc__c, arce__Banks_Bonds_Derivatives_Leases_LT_calc__c, arce__Banks_Bonds_Derivatives_Leases_ST_calc__c, arce__Capex_Key_calc__c, arce__Capex_calc__c, arce__Cash_generated_consumed_calc__c, arce__Change_in_Working_Capital_calc__c, arce__Current_Assets_calc__c, arce__Current_Liabiities_calc__c, arce__Dividend_calc__c, arce__Dividend_received_calc__c, arce__EBITDA_Interest_expenses_calc__c, arce__Ebit_calc__c, arce__Ebitda_calc__c, arce__Ending_cash_calc__c, arce__Free_Cash_Flow_to_Shareholders_calc__c, arce__Free_Cash_Flowto_Debt_Service_calc__c, arce__Gross_Debt_Ebitda_calc__c, arce__Interest_expense_calc__c, arce__Inventories_calc__c, arce__Net_Debt_Ebitda_calc__c, arce__Net_Income_Atributable_calc__c, arce__Net_Result_after_taxes_calc__c, arce__Net_Worth_calc__c, arce__Net_income_calc__c, arce__Non_Current_Assets_calc__c, arce__Non_Current_Liabilities_calc__c, arce__Total_Assets_calc__c, arce__Total_Equity_Liabilities_calc__c, arce__Total_Revenues_calc__c, arce__Trade_Accounts_Payable_calc__c, arce__Trade_accounts_receivables_calc__c, arce__Var_Debt_calc__c, arce__Revenue_calc__c, arce__Units_Type__c, arce__Amortization_Depreciation_base__c, arce__Banks_Bonds_Derivatives_Leases_LT_base__c, arce__Banks_Bonds_Derivatives_Leases_ST_base__c, arce__Capex_Key_base__c, arce__Capex_base__c, arce__Cash_generated_consumed_base__c, arce__Change_in_Working_Capital_base__c, arce__Current_Assets_base__c, arce__Current_Liabiities_base__c, arce__Dividend_base__c, arce__Dividend_received_base__c, arce__EBITDA_Interest_expenses_base__c, arce__Ebit_base__c, arce__Ebitda_base__c, arce__Ending_cash_base__c, arce__Free_Cash_Flow_to_Shareholders_base__c, arce__Free_Cash_Flowto_Debt_Service_base__c, arce__Gross_Debt_Ebitda_base__c, arce__Interest_expense_base__c, arce__Inventories_base__c, arce__Net_Debt_Ebitda_base__c, arce__Net_Income_Atributable_base__c, arce__Net_Result_after_taxes_base__c, arce__Net_Worth_base__c, arce__Net_income_base__c, arce__Non_Current_Assets_base__c, arce__Non_Current_Liabilities_base__c, arce__Total_Assets_base__c, arce__Total_Equity_Liabilities_base__c, arce__Total_Revenues_base__c, arce__Trade_Accounts_Payable_base__c, arce__Trade_accounts_receivables_base__c, arce__Var_Debt_base__c, arce__Revenue_base__c
                FROM arce__Projection__c
                WHERE arce__Account_has_Analysis__c = :aHaId
                ORDER BY arce__Period_EndDate__c ASC];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get projection data by Id
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    projectionId setAhaIds
    * @example    Arc_Gen_Projection_Data.getProjectionById(projectionId);
    */
    public static arce__Projection__c getProjectionById(String projectionId) {
        return [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, arce__SelectedCurrency__c, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, arce__Account_has_Analysis__c, arce__Amortization_Depreciation__c, arce__Avg_Days_Inventory_Out__c, arce__Avg_Days_Payable_Out__c, arce__Avg_Days_Sales_Out__c, arce__Banks_Bonds_Derivatives_Leases_LT__c, arce__Banks_Bonds_Derivatives_Leases_LT_pct__c, arce__Banks_Bonds_Derivatives_Leases_ST__c, arce__Banks_Bonds_Derivatives_Leases_ST_pct__c, arce__Capex_Key__c, arce__Capex__c, arce__Cash_generated_consumed__c, arce__Change_in_Working_Capital__c, arce__Confirmed_Projection__c, arce__Current_Assets__c, arce__Current_Assets_pct__c, arce__Current_Liabiities__c, arce__Current_Liabiities_pct__c, arce__Dividend__c, arce__Dividend_received__c, arce__EBITDA_Interest_expenses__c, arce__Ebit__c, arce__Ebit_pct__c, arce__Ebitda__c, arce__Ebitda_pct__c, arce__Edit_Base_Case__c, arce__Cash_cash_equivalents__c, arce__Cash_cash_equivalents_base__c, arce__Cash_cash_equivalents_calc__c, arce__Cash_cash_equivalents_pct__c, arce__Ending_cash__c, arce__FFO_Net_Debt__c, arce__FOCF_Net_Debt__c, arce__Free_Cash_Flow_to_Shareholders__c, arce__Free_Cash_Flowto_Debt_Service__c, arce__Gross_Debt_Ebitda__c, arce__Interest_expense__c, arce__Interest_expense_pct__c, arce__Interest_expenses__c, arce__Inventories__c, arce__Inventories_pct__c, arce__Margen_Ebitda__c, arce__Net_Debt_Ebitda__c, arce__Net_Income_Atributable__c, arce__Net_Income_Atributable_pct__c, arce__Net_Result_after_taxes__c, arce__Net_Result_after_taxes_pct__c, arce__Net_Worth__c, arce__Net_Worth_pct__c, arce__Net_income__c, arce__Non_Current_Assets__c, arce__Non_Current_Assets_pct__c, arce__Non_Current_Liabilities__c, arce__Non_Current_Liabilities_pct__c, arce__Pay_out__c, arce__Projection_Criteria__c, arce__Projection_Header__c, arce__Projection_Id__c, arce__Projection_Type__c, arce__Revenue__c, arce__Revenue_growth__c, arce__Scenario_Comment__c, arce__Scenario_Type__c, arce__Simulation_Calculated__c, arce__Simulation_Long_Scale_Value__c, arce__Simulation_Score__c, arce__Simulation_Short_Scale_Value__c, arce__Total_Assets__c, arce__Total_Assets_pct__c, arce__Total_Equity_Liabilities__c, arce__Total_Equity_Liabilities_pct__c, arce__Total_Revenues__c, arce__Total_Revenues_pct__c, arce__Trade_Accounts_Payable__c, arce__Trade_Accounts_Payable_pct__c, arce__Trade_accounts_receivables__c, arce__Trade_accounts_receivables_pct__c, arce__Var_Debt__c, arce__Statement_Currency__c, arce__FinancialStatement_Type__c, arce__Period_StartDate__c, arce__Period_EndDate__c
                                      FROM arce__Projection__c
                                      WHERE Id = :projectionId
                                      ORDER BY arce__Period_EndDate__c ASC
                                      LIMIT 1];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get projection data by scenario
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    aHaId setAhaIds
    * @param     scenario
    * @example    Arc_Gen_Projection_Data.getProjScenarioData(aHaId,scenario);
    */
    public static List<arce__Projection__c> getProjScenarioData(String aHaId, String scenario) {
        return [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, arce__SelectedCurrency__c, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, arce__Account_has_Analysis__c, arce__Amortization_Depreciation__c, arce__Avg_Days_Inventory_Out__c, arce__Avg_Days_Payable_Out__c, arce__Avg_Days_Sales_Out__c, arce__Banks_Bonds_Derivatives_Leases_LT__c, arce__Banks_Bonds_Derivatives_Leases_LT_pct__c, arce__Banks_Bonds_Derivatives_Leases_ST__c, arce__Banks_Bonds_Derivatives_Leases_ST_pct__c, arce__Capex_Key__c, arce__Capex__c, arce__Cash_generated_consumed__c, arce__Change_in_Working_Capital__c, arce__Confirmed_Projection__c, arce__Current_Assets__c, arce__Current_Assets_pct__c, arce__Current_Liabiities__c, arce__Current_Liabiities_pct__c, arce__Dividend__c, arce__Dividend_received__c, arce__EBITDA_Interest_expenses__c, arce__Ebit__c, arce__Ebit_pct__c, arce__Ebitda__c, arce__Ebitda_pct__c, arce__Edit_Base_Case__c, arce__Cash_cash_equivalents__c, arce__Cash_cash_equivalents_base__c, arce__Cash_cash_equivalents_calc__c, arce__Cash_cash_equivalents_pct__c, arce__Ending_cash__c, arce__FFO_Net_Debt__c, arce__FOCF_Net_Debt__c, arce__Free_Cash_Flow_to_Shareholders__c, arce__Free_Cash_Flowto_Debt_Service__c, arce__Gross_Debt_Ebitda__c, arce__Interest_expense__c, arce__Interest_expense_pct__c, arce__Interest_expenses__c, arce__Inventories__c, arce__Inventories_pct__c, arce__Margen_Ebitda__c, arce__Net_Debt_Ebitda__c, arce__Net_Income_Atributable__c, arce__Net_Income_Atributable_pct__c, arce__Net_Result_after_taxes__c, arce__Net_Result_after_taxes_pct__c, arce__Net_Worth__c, arce__Net_Worth_pct__c, arce__Net_income__c, arce__Non_Current_Assets__c, arce__Non_Current_Assets_pct__c, arce__Non_Current_Liabilities__c, arce__Non_Current_Liabilities_pct__c, arce__Pay_out__c, arce__Projection_Criteria__c, arce__Projection_Header__c, arce__Projection_Id__c, arce__Projection_Type__c, arce__Revenue__c, arce__Revenue_growth__c, arce__Scenario_Comment__c, arce__Scenario_Type__c, arce__Simulation_Calculated__c, arce__Simulation_Long_Scale_Value__c, arce__Simulation_Score__c, arce__Simulation_Short_Scale_Value__c, arce__Total_Assets__c, arce__Total_Assets_pct__c, arce__Total_Equity_Liabilities__c, arce__Total_Equity_Liabilities_pct__c, arce__Total_Revenues__c, arce__Total_Revenues_pct__c, arce__Trade_Accounts_Payable__c, arce__Trade_Accounts_Payable_pct__c, arce__Trade_accounts_receivables__c, arce__Trade_accounts_receivables_pct__c, arce__Var_Debt__c, arce__Statement_Currency__c, arce__FinancialStatement_Type__c, arce__Period_StartDate__c, arce__Period_EndDate__c, arce__Amortization_Depreciation_calc__c, arce__Banks_Bonds_Derivatives_Leases_LT_calc__c, arce__Banks_Bonds_Derivatives_Leases_ST_calc__c, arce__Capex_Key_calc__c, arce__Capex_calc__c, arce__Cash_generated_consumed_calc__c, arce__Change_in_Working_Capital_calc__c, arce__Current_Assets_calc__c, arce__Current_Liabiities_calc__c, arce__Dividend_calc__c, arce__Dividend_received_calc__c, arce__EBITDA_Interest_expenses_calc__c, arce__Ebit_calc__c, arce__Ebitda_calc__c, arce__Ending_cash_calc__c, arce__Free_Cash_Flow_to_Shareholders_calc__c, arce__Free_Cash_Flowto_Debt_Service_calc__c, arce__Gross_Debt_Ebitda_calc__c, arce__Interest_expense_calc__c, arce__Inventories_calc__c, arce__Net_Debt_Ebitda_calc__c, arce__Net_Income_Atributable_calc__c, arce__Net_Result_after_taxes_calc__c, arce__Net_Worth_calc__c, arce__Net_income_calc__c, arce__Non_Current_Assets_calc__c, arce__Non_Current_Liabilities_calc__c, arce__Total_Assets_calc__c, arce__Total_Equity_Liabilities_calc__c, arce__Total_Revenues_calc__c, arce__Trade_Accounts_Payable_calc__c, arce__Trade_accounts_receivables_calc__c, arce__Var_Debt_calc__c, arce__Revenue_calc__c, arce__Units_Type__c, arce__Amortization_Depreciation_base__c, arce__Banks_Bonds_Derivatives_Leases_LT_base__c, arce__Banks_Bonds_Derivatives_Leases_ST_base__c, arce__Capex_Key_base__c, arce__Capex_base__c, arce__Cash_generated_consumed_base__c, arce__Change_in_Working_Capital_base__c, arce__Current_Assets_base__c, arce__Current_Liabiities_base__c, arce__Dividend_base__c, arce__Dividend_received_base__c, arce__EBITDA_Interest_expenses_base__c, arce__Ebit_base__c, arce__Ebitda_base__c, arce__Ending_cash_base__c, arce__Free_Cash_Flow_to_Shareholders_base__c, arce__Free_Cash_Flowto_Debt_Service_base__c, arce__Gross_Debt_Ebitda_base__c, arce__Interest_expense_base__c, arce__Inventories_base__c, arce__Net_Debt_Ebitda_base__c, arce__Net_Income_Atributable_base__c, arce__Net_Result_after_taxes_base__c, arce__Net_Worth_base__c, arce__Net_income_base__c, arce__Non_Current_Assets_base__c, arce__Non_Current_Liabilities_base__c, arce__Total_Assets_base__c, arce__Total_Equity_Liabilities_base__c, arce__Total_Revenues_base__c, arce__Trade_Accounts_Payable_base__c, arce__Trade_accounts_receivables_base__c, arce__Var_Debt_base__c, arce__Revenue_base__c
                                            FROM arce__Projection__c
                                            WHERE arce__Account_has_Analysis__c = :aHaId AND (arce__Scenario_Type__c = :scenario OR arce__Projection_Type__c = 'Anchor')
                                            ORDER BY arce__Period_EndDate__c ASC];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get projection data by set<String>
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    Set<String> setAhaIds
    * @param     scenarios
    * @param     projType
    * @example    Arc_Gen_Projection_Data.getProjByAhaScenProjType(aHaId,scenarios,projType);
    */
    public static List<arce__Projection__c> getProjByAhaScenProjType(String aHaId, Set<String> scenarios, String projType) {
        return [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, arce__SelectedCurrency__c, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, arce__Account_has_Analysis__c, arce__Amortization_Depreciation__c, arce__Avg_Days_Inventory_Out__c, arce__Avg_Days_Payable_Out__c, arce__Avg_Days_Sales_Out__c, arce__Banks_Bonds_Derivatives_Leases_LT__c, arce__Banks_Bonds_Derivatives_Leases_LT_pct__c, arce__Banks_Bonds_Derivatives_Leases_ST__c, arce__Banks_Bonds_Derivatives_Leases_ST_pct__c, arce__Capex_Key__c, arce__Capex__c, arce__Cash_generated_consumed__c, arce__Change_in_Working_Capital__c, arce__Confirmed_Projection__c, arce__Current_Assets__c, arce__Current_Assets_pct__c, arce__Current_Liabiities__c, arce__Current_Liabiities_pct__c, arce__Dividend__c, arce__Dividend_received__c, arce__EBITDA_Interest_expenses__c, arce__Ebit__c, arce__Ebit_pct__c, arce__Ebitda__c, arce__Ebitda_pct__c, arce__Edit_Base_Case__c, arce__Cash_cash_equivalents__c, arce__Cash_cash_equivalents_base__c, arce__Cash_cash_equivalents_calc__c, arce__Cash_cash_equivalents_pct__c, arce__Ending_cash__c, arce__FFO_Net_Debt__c, arce__FOCF_Net_Debt__c, arce__Free_Cash_Flow_to_Shareholders__c, arce__Free_Cash_Flowto_Debt_Service__c, arce__Gross_Debt_Ebitda__c, arce__Interest_expense__c, arce__Interest_expense_pct__c, arce__Interest_expenses__c, arce__Inventories__c, arce__Inventories_pct__c, arce__Margen_Ebitda__c, arce__Net_Debt_Ebitda__c, arce__Net_Income_Atributable__c, arce__Net_Income_Atributable_pct__c, arce__Net_Result_after_taxes__c, arce__Net_Result_after_taxes_pct__c, arce__Net_Worth__c, arce__Net_Worth_pct__c, arce__Net_income__c, arce__Non_Current_Assets__c, arce__Non_Current_Assets_pct__c, arce__Non_Current_Liabilities__c, arce__Non_Current_Liabilities_pct__c, arce__Pay_out__c, arce__Projection_Criteria__c, arce__Projection_Header__c, arce__Projection_Id__c, arce__Projection_Type__c, arce__Revenue__c, arce__Revenue_growth__c, arce__Scenario_Comment__c, arce__Scenario_Type__c, arce__Simulation_Calculated__c, arce__Simulation_Long_Scale_Value__c, arce__Simulation_Score__c, arce__Simulation_Short_Scale_Value__c, arce__Total_Assets__c, arce__Total_Assets_pct__c, arce__Total_Equity_Liabilities__c, arce__Total_Equity_Liabilities_pct__c, arce__Total_Revenues__c, arce__Total_Revenues_pct__c, arce__Trade_Accounts_Payable__c, arce__Trade_Accounts_Payable_pct__c, arce__Trade_accounts_receivables__c, arce__Trade_accounts_receivables_pct__c, arce__Var_Debt__c, arce__Statement_Currency__c, arce__FinancialStatement_Type__c, arce__Period_StartDate__c, arce__Period_EndDate__c
                                            FROM arce__Projection__c
                                            WHERE arce__Account_has_Analysis__c = :aHaId AND arce__Scenario_Type__c IN:scenarios AND arce__Projection_Type__c = :projType];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get projection data by set<String>
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    Set<String> setAhaIds
    * @example    Arc_Gen_Projection_Data.getProjectionDataSet(setAhaIds);
    */
    public static List<arce__Projection__c> getProjectionDataSet(Set<String> setAhaIds) {
        return [SELECT id, arce__Statement_Currency__c, CurrencyIsoCode, arce__SelectedCurrency__c FROM arce__Projection__c WHERE id = :setAhaIds];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    aleksandar.dinkov.contractor@bbva.com
    * @param    ahaId
    * @return   List<arce__Projections__mdt>
    * @example    Arc_Gen_Projection_Data.getRiskAssByAhaId(ahaId);
    */
    public static arce__Account_has_Analysis__c getRiskAssByAhaId(String ahaId) {
        return [SELECT id, Name,arce__Analysis__r.arce__Stage__c, arce__FR_Unit_Type__c FROM arce__Account_has_Analysis__c WHERE id = :ahaId];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to Update Projection
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    List<arce__Projection__c>  prData
    * @example    Arc_Gen_Projection_Data.updateProjectionData(prData);
    */
    public static void updateProjectionData(List<arce__Projection__c> prData) {
        if (!prData.isEmpty()) {
            upsert prData;
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to update Base Case with projection criteria and edit Base case value
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    ahaId
    * @param    editCase
    * @param    projecCriteria
    * @return   void
    * @example    Arc_Gen_Projection_Data.updateBaseCase(ahaId,editCase,projecCriteria);
    */
    public static void updateBaseCase(String ahaId, String editCase, String projecCriteria) {
        final List<arce__Projection__c> prData = getProjScenarioData(ahaId, 'Base Case');
        for (arce__Projection__c pr : prData) {
            pr.arce__Edit_Base_Case__c = editCase;
            pr.arce__Projection_Criteria__c = projecCriteria;
        }
        updateProjectionData(prData);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get data from EEFF selected
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author
    * @param    ahaId
    * @return   arce__Financial_Statements__c
    * @example    Arc_Gen_Projection_Data.getDataFFSS(ahaId,);
    */
    public static arce__Financial_Statements__c getDataFFSS(String ahaId) {
        final arce__Account_has_Analysis__c ahaRecord = [SELECT id, arce__ffss_for_rating_id__c
                                                    FROM arce__Account_has_Analysis__c
                                                    WHERE Id = :ahaId
                                                    LIMIT 1]; 
        return [SELECT Id, CurrencyIsoCode, arce__magnitude_unit_type__c
        FROM arce__Financial_Statements__c
        WHERE Id = :ahaRecord.arce__ffss_for_rating_id__c
        LIMIT 1];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description method to get all projection metadata
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    aleksandar.dinkov.contractor@bbva.com
    * @param
    * @return   List<arce__Projections__mdt>
    * @example    Arc_Gen_Projection_Data.getAllProjectionsMdt();
    */
    public static List<arce__Projections__mdt> getAllProjectionsMdt() {
        return [SELECT Label, DeveloperName, arce__id__c, arce__Map_field__c, arce__Calc_field__c, arce__Base_field__c, arce__Order__c, arce__Percentage_Map__c, arce__Table_ID__c
                FROM arce__Projections__mdt
                ORDER BY arce__Order__c ASC LIMIT 200];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to insert records
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author    aleksandar.dinkov.contractor@bbva.com
    * @param    recordsToInsert
    * @param    Arc_Gen_Projection_ServiceWrapper srvWrap
    * @return   List<arce__Projections__mdt>
    * @example    Arc_Gen_Projection_Data.insertRecords(recordsToInsert, srvWrap);
    */
    public static Arc_Gen_Projection_ServiceWrapper insertRecords(List<sObject> recordsToInsert, Arc_Gen_Projection_ServiceWrapper srvWrap) {
        final Database.SaveResult[] srList = Database.insert (recordsToInsert, false);
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    srvWrap.addMessage('500', String.valueOf(err.getStatusCode()), err.getMessage());
                }
            }
        }
        return srvWrap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description methos to delete records
    *--------------------------------------------------------------------------------
    * @date        01/05/2023
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @param    recordsToDelete
    * @param    Arc_Gen_Projection_ServiceWrapper srvWrap
    * @return   List<arce__Projections__mdt>
    * @example    Arc_Gen_Projection_Data.deleteRecords(recordsToDelete, srvWrap);
    */
    public static Arc_Gen_Projection_ServiceWrapper deleteRecords(List<sObject> recordsToDelete, Arc_Gen_Projection_ServiceWrapper srvWrap) {
        final Database.DeleteResult[] drList = Database.delete (recordsToDelete, false);
        for (Database.DeleteResult dr : drList) {
            if (!dr.isSuccess()) {
                for (Database.Error err : dr.getErrors()) {
                    srvWrap.addMessage('500', String.valueOf(err.getStatusCode()), err.getMessage());
                }
            }
        }
        return srvWrap;
    }

}