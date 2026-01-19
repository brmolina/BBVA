/**
* ____________________________________________________________________________
* Controller class for RPP_Calculator.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-02-15
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class RPP_Calculator_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    @TestVisible
    public RPP_Calculator_Ctrl() {}
    /**
    * @description Get initial data
    * @param recordId : RPP Calculator Id
    * @param selectedSimulation : Selected Simulation Id
    * @return retMap initial data
    */
    @AuraEnabled
    public static Map<String,Object> initialData(String recordId, String selectedSimulation) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<Errors_Wrapper> errorsList = new List<Errors_Wrapper>();
        RPP_Calculator__c RPPCalculator = getRPPCalculator(recordId);
        Map<String, String> RPPCalculatorFields = RPP_Utils.getObjectFields('RPP_Calculator__c');
        List<RPP_Calculator_Debtor__c> RPPCalculatorDebtors = getRPPCalculatorDebtors(RPPCalculator.Id);
        Map<String, String> RPPCalculatorDebtorFields = RPP_Utils.getObjectFields('RPP_Calculator_Debtor__c');
        Boolean hasSimulations = false;
        Boolean canSimulate = false;
        Boolean showSimulationButtons = true;
        Boolean showSimulationResults = false;
        Boolean isGoal1 = true;
        if (RPPCalculator.Target__c == Label.RPP_Target_Value2_Service) {
            isGoal1 = false;
        }
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = new RPP_Calculator_Simulation__c();
        Map<String, String> RPPCalculatorSimFields = RPP_Utils.getObjectFields('RPP_Calculator_Simulation__c');
        List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimulationDebtors = new List<RPP_Calculator_Simulation_Debtor__c>();
        Map<String, String> RPPCalculatorSimDebtorFields = RPP_Utils.getObjectFields('RPP_Calculator_Simulation_Debtor__c');
        List<Simulation_Wrapper> simulationsWrapperList = new List<Simulation_Wrapper>();
        if (RPPCalculator.IsValidated__c) {
            for (RPP_Calculator_Simulation__c RPPCalculatorSim : [SELECT Id, Name, Final_Simulation__c FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :recordId ORDER BY Version__c]) {
                Simulation_Wrapper simulationWrapper = new Simulation_Wrapper();
                simulationWrapper.id = RPPCalculatorSim.Id;
                simulationWrapper.name = RPPCalculatorSim.Name;
                if (RPPCalculatorSim.Id == selectedSimulation) {
                    simulationWrapper.selected = true;
                }else {
                    simulationWrapper.selected = false;
                }
                simulationsWrapperList.add(simulationWrapper);
                if (RPPCalculatorSim.Final_Simulation__c) {
                    showSimulationButtons = false;
                }
            }
            if (simulationsWrapperList.size() > 0) {
                hasSimulations = true;
                if (selectedSimulation == null) {
                    RPPCalculatorSimulation = getRPPCalculatorSimulation(simulationsWrapperList[0].id);
                    RPPCalculatorSimulationDebtors = getRPPCalculatorSimDebtors(simulationsWrapperList[0].id);
                    selectedSimulation = simulationsWrapperList[0].id;
                }else {
                    RPPCalculatorSimulation = getRPPCalculatorSimulation(selectedSimulation);
                    RPPCalculatorSimulationDebtors = getRPPCalculatorSimDebtors(selectedSimulation);
                }
                if (!RPPCalculatorSimulation.Simulated__c) {
                    canSimulate = true;
                }else {
                    showSimulationResults = true;
                }
            }
        }else {
            errorsList = validateGSheetData(RPPCalculator.Id);
            if (errorsList.size() == 0) {
                retMap.put('refresh', true);
            }
        }
        retMap.put('RPPCalculator', RPPCalculator);
        retMap.put('RPPCalculatorFields', RPPCalculatorFields);
        if (errorsList.size() == 0) {
            retMap.put('RPPCalculatorDebtors', RPPCalculatorDebtors);
            retMap.put('RPPCalculatorDebtorFields', RPPCalculatorDebtorFields);
            retMap.put('simulationsWrapperList', simulationsWrapperList);
            retMap.put('selectedSimulation', selectedSimulation);
            retMap.put('hasSimulations', hasSimulations);
            retMap.put('canSimulate', canSimulate);
            retMap.put('showSimulationResults', showSimulationResults);
            retMap.put('showSimulationButtons', showSimulationButtons);
            retMap.put('hasPermission', RPP_Utils.checkPermissionSet(UserInfo.getUserId()));
            retMap.put('isGoal1', isGoal1);
            retMap.put('RPPCalculatorSimulation', RPPCalculatorSimulation);
            retMap.put('RPPCalculatorSimFields', RPPCalculatorSimFields);
            retMap.put('RPPCalculatorSimulationDebtors', RPPCalculatorSimulationDebtors);
            retMap.put('RPPCalculatorSimDebtorFields', RPPCalculatorSimDebtorFields);
            retMap.put('success', true);
        }else {
            retMap.put('errorsList', errorsList);
            retMap.put('success', false);
        }
        return retMap;
    }
    /**
    * @description Get RPP Calculator data
    * @param id : RPP Calculator Id
    * @return rppCalculator RPP Calculator record
    */
    @AuraEnabled
    public static RPP_Calculator__c getRPPCalculator(String id) {
        RPP_Calculator__c rppCalculator = [SELECT Name,
                                                IsValidated__c,
                                                Tax_Id__c,
                                                Seller_Assignor__c,
                                                Target__c,
                                                Target_Rating_Sim__c,
                                                Prefixed_First_Loss__c,
                                                Obligors_Debtors_Number__c,
                                                Average_Portfolio_Dilution__c,
                                                Max_Unrated_Limit__c,
                                                Unrated_PD_Equivalency__c,
                                                Seller_Internal_Rating__c,
                                                Mean_Dilution__c,
                                                Mean_Dilution_Deviation__c,
                                                Insurer__c,
                                                Insurer_Limit__c,
                                                Insurer_Name__c,
                                                Insurer_Internal_Rating__c,
                                                Number_Of_Simulations__c,
                                                LGD_Capital__c,
                                                Maturity__c,
                                                CreatedDate,
                                                CreatedBy.Name,
                                                RPP_Calculator__c
                                            FROM RPP_Calculator__c
                                            WHERE Id = :id];
        return rppCalculator;
    }
    /**
    * @description Get RPP Calculator Debtors data
    * @param Id : RPP Calculator Id
    * @return rppCalculator RPP Calculator Debtors records
    */
    @AuraEnabled
    public static List<RPP_Calculator_Debtor__c> getRPPCalculatorDebtors(String Id) {
        // recorrer la query para ir añadiendo los que tienen índice y guardar el "Total" en variable auxiliar para grabarlo al salir del bucle
        List<RPP_Calculator_Debtor__c> rppCalculatorDebtorList = new List<RPP_Calculator_Debtor__c>();
        RPP_Calculator_Debtor__c RPPCalculatorDebtorTotal = new RPP_Calculator_Debtor__c();
        for (RPP_Calculator_Debtor__c rppCalculatorDebtor : [SELECT Name,
                                                                    Number__c,
                                                                    Insurer_Internal_Rating__c,
                                                                    Tax_Id__c,
                                                                    LEI__c,
                                                                    Obligor_Debtor__c,
                                                                    Currency__c,
                                                                    Total_Amount_Local__c,
                                                                    Total_Amount_EUR__c,
                                                                    Authorised_Limit_Local__c,
                                                                    Authorised_Limit_EUR__c,
                                                                    Percentage__c,
                                                                    Internal_Rating__c,
                                                                    External_Rating__c
                                                                FROM RPP_Calculator_Debtor__c
                                                                WHERE RPP_Calculator__c = :Id
                                                                ORDER BY Number__c]) {
            if (rppCalculatorDebtor.Obligor_Debtor__c == 'Total') {
                RPPCalculatorDebtorTotal = rppCalculatorDebtor;
            }else {
                rppCalculatorDebtorList.add(rppCalculatorDebtor);
            }
        }
        if (RPPCalculatorDebtorTotal.Obligor_Debtor__c == 'Total') {
            rppCalculatorDebtorList.add(RPPCalculatorDebtorTotal);
        }
        return rppCalculatorDebtorList;
    }
    /**
    * @description Get RPP Calculator Simulation data
    * @param id : RPP Calculator Simulation Id
    * @return rppCalculator RPP Calculator Simulation record
    */
    @AuraEnabled
    public static RPP_Calculator_Simulation__c getRPPCalculatorSimulation(String id) {
        RPP_Calculator_Simulation__c rppCalculatorSimulation = [SELECT Name,
                                                            Source_RPP_Calculator__c,
                                                            Tax_Id__c,
                                                            Seller_Assignor__c,
                                                            Total_Amount_EUR__c,
                                                            Total_Limit_EUR__c,
                                                            Internal_Rating__c,
                                                            External_Rating__c,
                                                            Obligor_Rating__c,
                                                            SP_Method_Rating__c,
                                                            EAD__c,
                                                            Average_PD__c,
                                                            Expected_Loss__c,
                                                            Simulated__c,
                                                            Final_Simulation__c,
                                                            RWA__c,
                                                            CE__c,
                                                            Equivalent_Rating__c,
                                                            Objective_Rating_SP_1__c,
                                                            Objective_Rating_SP_2__c,
                                                            Objective_Rating_SP_3__c,
                                                            First_Loss_1__c,
                                                            First_Loss_2__c,
                                                            First_Loss_3__c,
                                                            Rating_Loss_1__c,
                                                            Rating_Loss_2__c,
                                                            Rating_Loss_3__c,
                                                            Senior_Tranche_Rating__c,
                                                            First_Loss__c,
                                                            Max_Or_Fixed__c,
                                                            FL_SIM__c,
                                                            Rating_Under_95__c,
                                                            Total_Limit__c,
                                                            Goal_Rating_SP_Methodology__c,
                                                            Maximum_Insurance_Liability_Value__c,
                                                            Maximum_Insurance_Liability_Percent__c,
                                                            Dilution_Value__c,
                                                            Dilution_Percent__c,
                                                            Risk_Retention_Value__c,
                                                            Risk_Retention_Percent__c,
                                                            Senior_Tranche_Value__c,
                                                            Senior_Tranche_Percent__c,
                                                            Maximum_Insurance_Amount_Value__c,
                                                            Maximum_Insurance_Amount_Percent__c
                                                        FROM RPP_Calculator_Simulation__c
                                                        WHERE Id = :id];
        return rppCalculatorSimulation;
    }
    /**
    * @description Get RPP Calculator Debtors data
    * @param id : RPP Calculator Simulation Id
    * @return rppCalculator RPP Calculator Debtors records
    */
    @AuraEnabled
    public static List<RPP_Calculator_Simulation_Debtor__c> getRPPCalculatorSimDebtors(String id) {
        // recorrer la query para ir añadiendo los que tienen índice y guardar el "Total" en variable auxiliar para grabarlo al salir del bucle
        List<RPP_Calculator_Simulation_Debtor__c> rppCalculatorSimDebtorList = new List<RPP_Calculator_Simulation_Debtor__c>();
        RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtorTotal = new RPP_Calculator_Simulation_Debtor__c();
        for (RPP_Calculator_Simulation_Debtor__c rppCalculatorSimDebtor : [SELECT Name,
                                                                            Number__c,
                                                                            Insurer_Internal_Rating__c,
                                                                            Tax_Id__c,
                                                                            LEI__c,
                                                                            Obligor_Debtor__c,
                                                                            Currency__c,
                                                                            Total_Amount_Local__c,
                                                                            Total_Amount_EUR__c,
                                                                            Authorised_Limit_Local__c,
                                                                            Authorised_Limit_EUR__c,
                                                                            Percentage__c,
                                                                            Internal_Rating__c,
                                                                            External_Rating__c,
                                                                            Obligor_Rating__c,
                                                                            SP_Method_Rating__c,
                                                                            EAD__c,
                                                                            PD__c,
                                                                            Expected_Loss__c,
                                                                            KIRB__c
                                                                        FROM RPP_Calculator_Simulation_Debtor__c
                                                                        WHERE RPP_Calculator_Simulation__c = :id
                                                                        ORDER BY Number__c]) {
            if (rppCalculatorSimDebtor.Obligor_Debtor__c == 'Total') {
                RPPCalculatorSimDebtorTotal = rppCalculatorSimDebtor;
            }else {
                rppCalculatorSimDebtorList.add(rppCalculatorSimDebtor);
            }
        }
        rppCalculatorSimDebtorList.add(RPPCalculatorSimDebtorTotal);
        return rppCalculatorSimDebtorList;
    }
    /**
    * @description Get data from services
    * @param recordId : RPP Calculator Id
    * @return retMap ??????
    */
    @AuraEnabled
    //public static List<String> validateGSheetData(String recordId) {
    public static List<Errors_Wrapper> validateGSheetData(String recordId) {
        RPP_Calculator__c RPPCalculator = [SELECT Name FROM RPP_Calculator__c WHERE Id = :recordId];
        List<RPP_Calculator_Debtor__c> RPPCalculatorDebtorList = new List<RPP_Calculator_Debtor__c>();
        List<Errors_Wrapper> errorsList = new List<Errors_Wrapper>();
        Integer row = 0;
        Integer debtorsCount = 0;
        Boolean typeCalculator = false;
        Boolean typeConfig = false;
        Boolean typeDebtor = false;
        Map<String, String> RPPCalculatorFields = RPP_Utils.getObjectFields('RPP_Calculator__c');
        Map<String, String> RPPCalculatorDebtorFields = RPP_Utils.getObjectFields('RPP_Calculator_Debtor__c');
        for (RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog : [SELECT Data__c FROM RPP_Calculator_Google_Sheet_Log__c WHERE RPP_Calculator__c = :recordId ORDER BY Name]) {
            row++;
            List<String> data = (List<String>) JSON.deserialize(RPPCalculatorGoogleSheetLog.Data__c, List<String>.class);
            if (data.size() > 0) {
                switch on data[0] {
                    when 'TYPE' {
                        if (data.size() != 18) {
                            errorsList.add(generateError(Label.RPP_SALESFORCE, '-', '-', '-' , '-' , Label.RPP_Wrong_Number_Of_Columns, '-'));
                        }
                    }
                    when 'CALCULATOR' {
                        typeCalculator = true;
                        // Validate 'Name' field
                        if (data.size() > 1) {
                            if (data[1] == null || (data[1]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_RPP_PORT, 'B5', '-', Label.RPP_CALCULATOR, '-' , Label.RPP_Error_Description_Empty, '-'));
                            }else {
                                if ((data[1]).trim().length() > 71) {
                                    errorsList.add(generateError(Label.RPP_RPP_PORT, 'B5', '-', Label.RPP_CALCULATOR, '-' , Label.RPP_Incorrect_Length.replace('%LENGTH%', '71'), '-'));
                                }else {
                                    RPPCalculator.Name = (data[1]).trim();
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_RPP_PORT, 'B5', '-', Label.RPP_CALCULATOR, '-' , Label.RPP_Error_Description_Empty, '-'));
                        }
                        // Validate 'Tax_Id__c' field
                        if (data.size() > 2) {
                            if (data[2] == null || (data[2]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_RPP_PORT, '-', '-', Label.RPP_CALCULATOR, RPPCalculatorFields.get('tax_id__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[2]).trim().length() > 20) {
                                    errorsList.add(generateError(Label.RPP_RPP_PORT, '-', '-', Label.RPP_CALCULATOR, RPPCalculatorFields.get('tax_id__c'), Label.RPP_Incorrect_Length.replace('%LENGTH%', '20'), '-'));
                                }else {
                                    RPPCalculator.Tax_Id__c = (data[2]).trim();
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_RPP_PORT, '-', '-', Label.RPP_CALCULATOR, RPPCalculatorFields.get('tax_id__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Seller_Assignor__c' field
                        if (data.size() > 3) {
                            if (data[3] == null || (data[3]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_RPP_PORT, '-', '-', Label.RPP_CALCULATOR, RPPCalculatorFields.get('seller_assignor__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                RPPCalculator.Seller_Assignor__c = (data[3]).trim();
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_RPP_PORT, '-', '-', Label.RPP_CALCULATOR, RPPCalculatorFields.get('seller_assignor__c'), Label.RPP_Empty_Cell, '-'));
                        }
                    }
                    when 'CONFIG' {
                        typeConfig = true;
                        // Validate 'Target__c' field
                        if (data.size() > 1) {
                            if (data[1] == null || (data[1]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('target__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                List<String> config_01PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator__c','Target__c');
                                if (config_01PicklistValues.contains((data[1]).trim())) {
                                    RPPCalculator.Target__c = (data[1]).trim();
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('target__c'), Label.RPP_Error_Wrong_Value, String.join(config_01PicklistValues,', ')));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('target__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Target_Rating_Sim__c' field
                        if (data.size() > 2) {
                            if (data[2] == null || (data[2]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('target_rating_sim__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                List<String> config_02PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator__c','Target_Rating_Sim__c');
                                if (config_02PicklistValues.contains((data[2]).trim())) {
                                    RPPCalculator.Target_Rating_Sim__c = (data[2]).trim();
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('target_rating_sim__c'), Label.RPP_Error_Wrong_Value, String.join(config_02PicklistValues,', ')));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('target_rating_sim__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Prefixed_First_Loss__c' field
                        if (data.size() > 3) {
                            if (data[4] == null || (data[3]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('prefixed_first_loss__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[3]).trim().replace(',','').replace('%','').isNumeric()) {
                                    RPPCalculator.Prefixed_First_Loss__c = Decimal.valueOf((data[3]).trim().replace(',','.').replace('%',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('prefixed_first_loss__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('prefixed_first_loss__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Obligors_Debtors_Number__c' field
                        if (data.size() > 4) {
                            if (data[4] == null || (data[4]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('obligors_debtors_number__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[4]).trim().replace('.','').isNumeric()) {
                                    RPPCalculator.Obligors_Debtors_Number__c = Decimal.valueOf((data[4]).trim().replace('.',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('obligors_debtors_number__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('obligors_debtors_number__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Average_Portfolio_Dilution__c' field
                        if (data.size() > 5) {
                            if (data[5] == null || (data[5]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('average_portfolio_dilution__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[5]).trim().replace(',','').replace('%','').isNumeric()) {
                                    RPPCalculator.Average_Portfolio_Dilution__c = Decimal.valueOf((data[5]).trim().replace(',','.').replace('%',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('average_portfolio_dilution__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('average_portfolio_dilution__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Max_Unrated_Limit__c' field
                        if (data.size() > 6) {
                            if (data[6] == null || (data[6]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('max_unrated_limit__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[6]).trim().replace(',','').replace('%','').isNumeric()) {
                                    RPPCalculator.Max_Unrated_Limit__c = Decimal.valueOf((data[6]).trim().replace(',','.').replace('%',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('max_unrated_limit__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('max_unrated_limit__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Unrated_PD_Equivalency__c' field
                        if (data.size() > 7) {
                            if (data[7] == null || (data[7]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('unrated_pd_equivalency__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                List<String> config_07PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator__c','Unrated_PD_Equivalency__c');
                                if (config_07PicklistValues.contains((data[7]).trim())) {
                                    RPPCalculator.Unrated_PD_Equivalency__c = (data[7]).trim();
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('unrated_pd_equivalency__c'), Label.RPP_Error_Wrong_Value, String.join(config_07PicklistValues,', ')));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('unrated_pd_equivalency__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Seller_Internal_Rating__c' field
                        if (data.size() > 8) {
                            if (data[8] == null || (data[8]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('seller_internal_rating__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                List<String> config_08PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator__c','Seller_Internal_Rating__c');
                                if (config_08PicklistValues.contains((data[8]).trim())) {
                                    RPPCalculator.Seller_Internal_Rating__c = (data[8]).trim();
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('seller_internal_rating__c'), Label.RPP_Error_Wrong_Value, String.join(config_08PicklistValues,', ')));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('seller_internal_rating__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Mean_Dilution__c' field
                        if (data.size() > 9) {
                            if (data[9] == null || (data[9]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('mean_dilution__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[9]).trim().replace(',','').replace('%','').isNumeric()) {
                                    RPPCalculator.Mean_Dilution__c = Decimal.valueOf((data[9]).trim().replace(',','.').replace('%',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('mean_dilution__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('mean_dilution__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Mean_Dilution_Deviation__c' field
                        if (data.size() > 10) {
                            if (data[10] == null || (data[10]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('mean_dilution_deviation__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[10]).trim().replace(',','').replace('%','').isNumeric()) {
                                    RPPCalculator.Mean_Dilution_Deviation__c = Decimal.valueOf((data[10]).trim().replace(',','.').replace('%',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('mean_dilution_deviation__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('mean_dilution_deviation__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Insurer__c' field
                        if (data.size() > 11) {
                            if (data[11] == null || (data[11]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                List<String> config_11PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator__c','Insurer__c');
                                if (config_11PicklistValues.contains((data[11]).trim())) {
                                    RPPCalculator.Insurer__c = (data[11]).trim();
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer__c'), Label.RPP_Error_Wrong_Value, String.join(config_11PicklistValues,', ')));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Insurer_Limit__c' field
                        if (data.size() > 12) {
                            if (data[12] == null || (data[12]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_limit__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[12]).trim().replace(',','').replace('%','').isNumeric()) {
                                    RPPCalculator.Insurer_Limit__c = Decimal.valueOf((data[12]).trim().replace(',','.').replace('%',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_limit__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_limit__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Insurer_Name__c' field
                        if (data.size() > 13) {
                            if (data[13] == null || (data[13]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_name__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                RPPCalculator.Insurer_Name__c = (data[13]).trim();
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_name__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Insurer_Internal_Rating__c' field
                        if (data.size() > 14) {
                            if (data[14] == null || (data[14]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_internal_rating__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                List<String> config_14PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator__c','Insurer_Internal_Rating__c');
                                if (config_14PicklistValues.contains((data[14]).trim())) {
                                    RPPCalculator.Insurer_Internal_Rating__c = (data[14]).trim();
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_internal_rating__c'), Label.RPP_Error_Wrong_Value, String.join(config_14PicklistValues,', ')));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('insurer_internal_rating__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Number_Of_Simulations__c' field
                        if (data.size() > 15) {
                            if (data[15] == null || (data[15]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('number_of_simulations__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[15]).trim().replace('.','').isNumeric()) {
                                    RPPCalculator.Number_Of_Simulations__c = Decimal.valueOf((data[15]).trim().replace('.',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('number_of_simulations__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('number_of_simulations__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'LGD_Capital__c' field
                        if (data.size() > 16) {
                            if (data[16] == null || (data[16]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('lgd_capital__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[16]).trim().replace(',','').replace('%','').isNumeric()) {
                                    RPPCalculator.LGD_Capital__c = Decimal.valueOf((data[16]).trim().replace(',','.').replace('%',''));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('lgd_capital__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('lgd_capital__c'), Label.RPP_Empty_Cell, '-'));
                        }
                        // Validate 'Maturity__c' field
                        if (data.size() > 17) {
                            if (data[17] == null || (data[17]).trim() == '') {
                                errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('maturity__c'), Label.RPP_Empty_Cell, '-'));
                            }else {
                                if ((data[17]).trim().replace(',','').replace('.','').isNumeric()) {
                                    RPPCalculator.Maturity__c = Decimal.valueOf((data[17]).trim().replace('.','').replace(',','.'));
                                }else {
                                    errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('maturity__c'), Label.RPP_Error_Wrong_Value, '-'));
                                }
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_CONFIG, '-', '-', Label.RPP_CONFIG , RPPCalculatorFields.get('maturity__c'), Label.RPP_Empty_Cell, '-'));
                        }
                    }
                    when 'DEBTOR' {
                        typeDebtor = true;
                        debtorsCount++;
                        if (data.size() > 1) {
                            RPP_Calculator_Debtor__c RPPCalculatorDebtor = new RPP_Calculator_Debtor__c();
                            RPPCalculatorDebtor.RPP_Calculator__c = RPPCalculator.Id;
                            // Validate 'Obligor_Debtor__c' field
                            if (data.size() > 4) {
                                if (data[4] == null || (data[4]).trim() == '') {
                                    errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('obligor_debtor__c'), Label.RPP_Empty_Cell, '-'));
                                }else {
                                    if ((data[4]).trim().length() > 255) {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('obligor_debtor__c'), Label.RPP_Incorrect_Length.replace('%LENGTH%', '255'), '-'));
                                    }else {
                                        RPPCalculatorDebtor.Obligor_Debtor__c = (data[4]).trim();
                                    }
                                }
                            }else {
                                errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('obligor_debtor__c'), Label.RPP_Empty_Cell, '-'));
                            }
                            // Validate 'Insurer_Internal_Rating__c' field
                            if (errorsList.size() == 0) {
                                if (data.size() > 1 && data[1] != null && data[1] != '') {
                                    List<String> field01PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator_Debtor__c','Insurer_Internal_Rating__c');
                                    if (field01PicklistValues.contains((data[1]).trim())) {
                                        if (data.size() > 3) {
                                            if ((data[4]).trim() != 'Total') {
                                                RPPCalculatorDebtor.Insurer_Internal_Rating__c = (data[1]).trim();
                                            }
                                        }
                                    }else {
                                        errorsList.add(generateError(Label.RPP_CONFIG, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('insurer_internal_rating__c'), Label.RPP_Error_Wrong_Value, String.join(field01PicklistValues,', ')));
                                    }
                                }
                            }
                            // Validate 'Tax_Id__c' field
                            if (errorsList.size() == 0) {
                                if (data.size() > 2) {
                                    if ((data[4]).trim() != 'Total') {
                                        if ((data[2]).trim().length() > 20) {
                                            errorsList.add(generateError(Label.RPP_RPP_PORT, '-', '-', Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('tax_id__c'), Label.RPP_Incorrect_Length.replace('%LENGTH%', '20'), '-'));
                                        }else {
                                            RPPCalculatorDebtor.Tax_Id__c = (data[2]).trim();
                                        }
                                    }
                                }
                            }
                            // Validate 'LEI__c' field
                            if (errorsList.size() == 0) {
                                if (data.size() > 3) {
                                    if ((data[4]).trim() != 'Total') {
                                        RPPCalculatorDebtor.LEI__c = (data[3]).trim();
                                    }
                                }
                            }
                            // Validate 'Currency__c' fields
                            if (data.size() > 5) {
                                if ((data[5] == null || (data[5]).trim() == '') && (data[4]).trim() != 'Total') {
                                    errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('currency__c'), Label.RPP_Empty_Cell, '-'));
                                }else {
                                    List<String> field05PicklistValues = RPP_Utils.getPicklistValues('RPP_Calculator_Debtor__c','Currency__c');
                                    if (field05PicklistValues.contains((data[5]).trim())) {
                                        if ((data[4]).trim() != 'Total') {
                                            RPPCalculatorDebtor.Currency__c = (data[5]).trim();
                                        }
                                    }else {
                                        if ((data[4]).trim() != 'Total') {
                                            errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('currency__c'), Label.RPP_Error_Wrong_Value, Label.RPP_Error_ISO_3_Currency));
                                        }
                                    }
                                }
                            }else {
                                if (errorsList.size() == 0) {
                                    if (data.size() > 3) {
                                        if ((data[4]).trim() != 'Total') {
                                            errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('currency__c'), Label.RPP_Empty_Cell, '-'));
                                        }
                                    }else {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('currency__c'), Label.RPP_Empty_Cell, '-'));
                                    }
                                }
                            }
                            // Validate 'Total_Amount_Local__c' field
                            if (data.size() > 6) {
                                if ((data[6]).trim().replace(',','').replace('.','').isNumeric()) {
                                    if ((data[4]).trim() != 'Total') {
                                        RPPCalculatorDebtor.Total_Amount_Local__c = Decimal.valueOf((data[6]).trim().replace('.','').replace(',','.'));
                                    }
                                }else {
                                    if (data[6] == null || (data[6]).trim() == '') {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('total_amount_local__c'), Label.RPP_Empty_Cell, '-'));
                                    }else {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('total_amount_local__c'), Label.RPP_Error_Wrong_Value, '-'));
                                    }
                                }
                            }else {
                                if (errorsList.size() == 0) {
                                    if (data.size() > 3) {
                                        if ((data[4]).trim() != 'Total') {
                                            errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('total_amount_local__c'), Label.RPP_Empty_Cell, '-'));
                                        }
                                    }else {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('total_amount_local__c'), Label.RPP_Empty_Cell, '-'));
                                    }
                                }
                            }
                            // Validate 'Authorised_Limit_Local__c' field
                            if (data.size() > 7) {
                                if ((data[7]).trim().replace(',','').replace('.','').isNumeric()) {
                                    if ((data[4]).trim() != 'Total') {
                                        RPPCalculatorDebtor.Authorised_Limit_Local__c = Decimal.valueOf((data[7]).trim().replace('.','').replace(',','.'));
                                    }
                                }else {
                                    if (data[7] == null || (data[7]).trim() == '') {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('authorised_limit_local__c'), Label.RPP_Empty_Cell, '-'));
                                    }else {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('authorised_limit_local__c'), Label.RPP_Error_Wrong_Value, '-'));
                                    }
                                }
                            }else {
                                if (errorsList.size() == 0) {
                                    if (data.size() > 3) {
                                        if ((data[4]).trim() != 'Total') {
                                            errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('authorised_limit_local__c'), Label.RPP_Empty_Cell, '-'));
                                        }
                                    }else {
                                        errorsList.add(generateError(Label.RPP_RPP_PORT, '-', String.valueOf(debtorsCount), Label.RPP_DEBTOR , RPPCalculatorDebtorFields.get('authorised_limit_local__c'), Label.RPP_Empty_Cell, '-'));
                                    }
                                }
                            }
                            //
                            if (errorsList.size() == 0) {
                            // Assign 'Number__c' field
                            //if (data.size() > 3) {
                                if ((data[4]).trim() != 'Total') {
                                    RPPCalculatorDebtor.Number__c = debtorsCount;
                                }
                            //}
                                RPPCalculatorDebtorList.add(RPPCalculatorDebtor);
                            }
                        }else {
                            errorsList.add(generateError(Label.RPP_SALESFORCE, '-', String.valueOf(debtorsCount), '-' , '-' , Label.RPP_Error_Debtor_No_Info, '-'));
                        }
                    }
                    when else {
                        errorsList.add(generateError(Label.RPP_SALESFORCE, '-', String.valueOf(row), '-' , '-' , Label.RPP_Error_Wrong_Type, '-'));
                    }
                }
            }else {
                errorsList.add(generateError(Label.RPP_SALESFORCE, '-', String.valueOf(row), '-' , '-' , Label.RPP_Empty_Line, '-'));
            }
        }
        if (!typeCalculator) {
            errorsList.add(generateError(Label.RPP_SALESFORCE, '-', '-' , '-', '-' , Label.RPP_Error_No_Type.replace('%TYPE%', 'CALCULATOR'), '-'));
        }
        if (!typeConfig) {
            errorsList.add(generateError(Label.RPP_SALESFORCE, '-', '-', '-', '-' , Label.RPP_Error_No_Type.replace('%TYPE%', 'CONFIG'), '-'));
        }
        if (!typeDebtor) {
            errorsList.add(generateError(Label.RPP_SALESFORCE, '-', '-', '-', '-' , Label.RPP_Error_No_Type.replace('%TYPE%', 'DEBTOR'), '-'));
        }
        if (errorsList.size() == 0) {
            RPPCalculator.IsValidated__c = true;
            update RPPCalculator;
            insert RPPCalculatorDebtorList;
        }else {
            update RPPCalculator;
        }
        return errorsList;
    }
    /**
    * @description generate errors
    * @param tab : Google Sheet tab
    * @param cell : Google Sheet cell
    * @param row : Google Sheet row
    * @param type : SALESFORCE tab row type
    * @param field : Field
    * @param message : Error message
    * @param values : Possible values
    * @return errorMessage Error message
    */
    @AuraEnabled
    public static Errors_Wrapper generateError(String tab, String cell, String row, String type, String field, String message, String values) {
        Errors_Wrapper errorMessage = new Errors_Wrapper();
        errorMessage.tab = tab;
        errorMessage.row = row;
        errorMessage.type = type;
        errorMessage.message = message;
        errorMessage.field = field;
        errorMessage.values = values;
        errorMessage.cell = cell;
        return errorMessage;
    }
    /**
    * @description Retrieve ratings from XXXXXX service
    * @param id : RPP Calculator Id
    * @return retMap ????
    */
    @AuraEnabled
    public static Map<String,Object> getRatings(String id) {
        Map<String, Object> retMap = new Map<String, Object>();
        RPP_Calculator__c rppCalculator = getRPPCalculator(id);
        RPP_CalculateFactoringRequest_Wrapper calculateFactoringRequest = new RPP_CalculateFactoringRequest_Wrapper();
        RPP_CalculateFactoringRequest_Wrapper.Assignor assignor = new RPP_CalculateFactoringRequest_Wrapper.Assignor();
        assignor.document = rppCalculator.Tax_Id__c;
        assignor.name = rppCalculator.Seller_Assignor__c;
        calculateFactoringRequest.assignor = assignor;
        List<RPP_CalculateFactoringRequest_Wrapper.Debtor> debtorsList = new List<RPP_CalculateFactoringRequest_Wrapper.Debtor>();
        List<RPP_Calculator_Debtor__c> RPPCalculatorDebtors = getRPPCalculatorDebtors(id);
        for (RPP_Calculator_Debtor__c RPPCalculatorDebtor : RPPCalculatorDebtors) {
            RPP_CalculateFactoringRequest_Wrapper.Debtor debtor = new RPP_CalculateFactoringRequest_Wrapper.Debtor();
            if (RPPCalculatorDebtor.Obligor_Debtor__c != 'Total') {
                debtor.name = RPPCalculatorDebtor.Obligor_Debtor__c;
                debtor.document = RPPCalculatorDebtor.Tax_Id__c;
                debtor.lei = RPPCalculatorDebtor.LEI__c;
                RPP_CalculateFactoringRequest_Wrapper.AmountCurrency amountTotalBills = new RPP_CalculateFactoringRequest_Wrapper.AmountCurrency();
                amountTotalBills.amount = RPPCalculatorDebtor.Total_Amount_Local__c;
                amountTotalBills.currency_y = RPPCalculatorDebtor.Currency__c;
                debtor.amountTotalBills = amountTotalBills;
                RPP_CalculateFactoringRequest_Wrapper.AmountCurrency amountLimit = new RPP_CalculateFactoringRequest_Wrapper.AmountCurrency();
                amountLimit.amount = RPPCalculatorDebtor.Authorised_Limit_Local__c;
                amountLimit.currency_y = RPPCalculatorDebtor.Currency__c;
                debtor.amountLimit = amountLimit;
                debtorsList.add(debtor);
            }
            calculateFactoringRequest.debtorsList = debtorsList;
        }
        final Map<String,String> jsonInputMap = new Map<String,String>();
        jsonInputMap.put('JSONinput', JSON.serialize(calculateFactoringRequest).replaceAll('currency_y','currency'));
        final HttpResponse response = RPP_Utils.callWebService('calculateFactoring', jsonInputMap);
        switch on response.getStatusCode() {
            when 200, 201 {
                final String responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                RPP_CalculateFactoringResponse_Wrapper calculateFactoringResponse = (RPP_CalculateFactoringResponse_Wrapper) JSON.deserialize(JSON.serialize(responseMap.get('data')), RPP_CalculateFactoringResponse_Wrapper.class);
                retMap = createSimulation(rppCalculator, RPPCalculatorDebtors, calculateFactoringResponse);
            }
            when else {
                String error = null;
                Map<String,Object> errorMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                if (errorMap.containsKey('messages')) {
                    List<Object> messageMapList = (List <Object>) errorMap.get('messages');
                    Map<String,Object> messageMap = (Map<String,Object>) messageMapList[0];
                    if (messageMap.containsKey('message')) {
                        error = (String) messageMap.get('message');
                    }
                }
                retMap.put('success', false);
                retMap.put('errorMessage', error);
            }
        }
        return retMap;
    }
    /**
    * @description Retrieve ratings from 'simulate' service
    * @param rppCalculator : RPP_Calculator_Debtor__c parent record
    * @param RPPCalculatorDebtors : list of RPP_Calculator_Debtor__c records from the parent record
    * @param calculateFactoringResponse : Calculate Factoring service response
    * @return retMap
    */
    @AuraEnabled
    public static Map<String,Object> createSimulation(RPP_Calculator__c rppCalculator, List<RPP_Calculator_Debtor__c> RPPCalculatorDebtors, RPP_CalculateFactoringResponse_Wrapper calculateFactoringResponse) {
        Map<String, Object> retMap = new Map<String, Object>();
        Decimal version = 0;
        List<RPP_Calculator_Simulation__c> rppCalculatorSimMaxVersion = [SELECT Version__c FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :rppCalculator.Id ORDER BY Version__c DESC];
        RPP_Calculator_Simulation__c rppCalculatorSimulation = new RPP_Calculator_Simulation__c();
        if (rppCalculatorSimMaxVersion.size() >= 1) {
            rppCalculatorSimulation.Version__c = rppCalculatorSimMaxVersion[0].Version__c + 1;
        }else {
            rppCalculatorSimulation.Version__c = 1;
        }
        rppCalculatorSimulation.Name = rppCalculator.Name + ' - ' + Label.RPP_Simulation + ' v' + rppCalculatorSimulation.Version__c;
        rppCalculatorSimulation.Source_RPP_Calculator__c = rppCalculator.Id;
        rppCalculatorSimulation.Tax_Id__c = rppCalculator.Tax_Id__c;
        rppCalculatorSimulation.Seller_Assignor__c = rppCalculator.Seller_Assignor__c;
        rppCalculatorSimulation.Total_Amount_EUR__c = calculateFactoringResponse.assignor.totalBills.amount;
        rppCalculatorSimulation.Total_Limit_EUR__c = calculateFactoringResponse.assignor.totalLimit.amount;
        rppCalculatorSimulation.Internal_Rating__c = calculateFactoringResponse.assignor.internalRating;
        rppCalculatorSimulation.External_Rating__c = calculateFactoringResponse.assignor.externalRating;
        insert rppCalculatorSimulation;
        Map<String,RPP_CalculateFactoringResponse_Wrapper.Debtor> debtorDocumentMap = new Map<String,RPP_CalculateFactoringResponse_Wrapper.Debtor>();
        Map<String,RPP_CalculateFactoringResponse_Wrapper.Debtor> debtorLeiMap = new Map<String,RPP_CalculateFactoringResponse_Wrapper.Debtor>();
        Map<String,RPP_CalculateFactoringResponse_Wrapper.Debtor> debtorOtherMap = new Map<String,RPP_CalculateFactoringResponse_Wrapper.Debtor>();
        for (RPP_CalculateFactoringResponse_Wrapper.Debtor debtor : calculateFactoringResponse.debtorsList) {
            if (debtor.document != '' && debtor.document != null) {
                debtorDocumentMap.put(debtor.document + debtor.amountTotalBills.currency_y + debtor.name, debtor);
            }
            if (debtor.lei != '' && debtor.lei != null) {
                debtorLeiMap.put(debtor.lei + debtor.amountTotalBills.currency_y + debtor.name, debtor);
            }
            if (debtor.document == '' || debtor.document == null || debtor.lei == '' || debtor.lei == null) {
                debtorOtherMap.put(debtor.name, debtor);
            }
        }
        Boolean errorResponseDebtor = false;
        List<String> errorMessages = new List<String>();
        Decimal totalPercentage = 0;
        List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtors = new List<RPP_Calculator_Simulation_Debtor__c>();
        RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtorTotal = new RPP_Calculator_Simulation_Debtor__c();
        for (RPP_Calculator_Debtor__c RPPCalculatorDebtor : RPPCalculatorDebtors) {
            RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtor = new RPP_Calculator_Simulation_Debtor__c();
            RPPCalculatorSimDebtor.RPP_Calculator_Simulation__c = rppCalculatorSimulation.Id;
            RPPCalculatorSimDebtor.Number__c = RPPCalculatorDebtor.Number__c;
            RPPCalculatorSimDebtor.Insurer_Internal_Rating__c = RPPCalculatorDebtor.Insurer_Internal_Rating__c;
            RPPCalculatorSimDebtor.Tax_Id__c = RPPCalculatorDebtor.Tax_Id__c;
            RPPCalculatorSimDebtor.LEI__c = RPPCalculatorDebtor.LEI__c;
            RPPCalculatorSimDebtor.Obligor_Debtor__c = RPPCalculatorDebtor.Obligor_Debtor__c;
            RPPCalculatorSimDebtor.Currency__c = RPPCalculatorDebtor.Currency__c;
            RPPCalculatorSimDebtor.Total_Amount_Local__c = RPPCalculatorDebtor.Total_Amount_Local__c;
            RPPCalculatorSimDebtor.Authorised_Limit_Local__c = RPPCalculatorDebtor.Authorised_Limit_Local__c;
            RPP_CalculateFactoringResponse_Wrapper.Debtor responseDebtor = new RPP_CalculateFactoringResponse_Wrapper.Debtor();
            if (RPPCalculatorDebtor.Tax_Id__c != null && RPPCalculatorDebtor.Tax_Id__c != '') {
                responseDebtor = debtorDocumentMap.get(RPPCalculatorDebtor.Tax_Id__c + RPPCalculatorDebtor.Currency__c + RPPCalculatorDebtor.Obligor_Debtor__c);
                if (responseDebtor == null) {
                    errorResponseDebtor = true;
                }else {
                    RPPCalculatorSimDebtor.Total_Amount_EUR__c = responseDebtor.amountTotalBillsEuros.amount;
                    RPPCalculatorSimDebtor.Authorised_Limit_EUR__c = responseDebtor.amountLimitEuros.amount;
                    RPPCalculatorSimDebtor.Percentage__c = responseDebtor.percentage;
                    totalPercentage = totalPercentage + RPPCalculatorSimDebtor.Percentage__c;
                    RPPCalculatorSimDebtor.Internal_Rating__c = responseDebtor.internalRating;
                    RPPCalculatorSimDebtor.External_Rating__c = responseDebtor.externalRating;
                }
            }else if (RPPCalculatorDebtor.LEI__c != null && RPPCalculatorDebtor.LEI__c != '') {
                responseDebtor = debtorLeiMap.get(RPPCalculatorDebtor.LEI__c + RPPCalculatorDebtor.Currency__c + RPPCalculatorDebtor.Obligor_Debtor__c);
                if (responseDebtor == null) {
                    errorResponseDebtor = true;
                }else {
                    RPPCalculatorSimDebtor.Total_Amount_EUR__c = responseDebtor.amountTotalBillsEuros.amount;
                    RPPCalculatorSimDebtor.Authorised_Limit_EUR__c = responseDebtor.amountLimitEuros.amount;
                    RPPCalculatorSimDebtor.Percentage__c = responseDebtor.percentage;
                    totalPercentage = totalPercentage + RPPCalculatorSimDebtor.Percentage__c;
                    RPPCalculatorSimDebtor.Internal_Rating__c = responseDebtor.internalRating;
                    RPPCalculatorSimDebtor.External_Rating__c = responseDebtor.externalRating;
                }
            }else {
                responseDebtor = debtorOtherMap.get(RPPCalculatorDebtor.Obligor_Debtor__c);
                if (responseDebtor == null) {
                        errorResponseDebtor = true;
                }else {
                    RPPCalculatorSimDebtor.Total_Amount_EUR__c = responseDebtor.amountTotalBillsEuros.amount;
                    RPPCalculatorSimDebtor.Authorised_Limit_EUR__c = responseDebtor.amountLimitEuros.amount;
                    RPPCalculatorSimDebtor.Percentage__c = responseDebtor.percentage;
                    totalPercentage = totalPercentage + RPPCalculatorSimDebtor.Percentage__c;
                    RPPCalculatorSimDebtor.Internal_Rating__c = responseDebtor.internalRating;
                    RPPCalculatorSimDebtor.External_Rating__c = responseDebtor.externalRating;
                }
            }
            RPPCalculatorSimDebtors.add(RPPCalculatorSimDebtor);
        }
        // Add Total
        RPPCalculatorSimDebtorTotal.RPP_Calculator_Simulation__c = rppCalculatorSimulation.Id;
        RPPCalculatorSimDebtorTotal.Obligor_Debtor__c = 'Total';
        RPPCalculatorSimDebtorTotal.Total_Amount_EUR__c = calculateFactoringResponse.assignor.totalBills.amount;
        RPPCalculatorSimDebtorTotal.Authorised_Limit_EUR__c = calculateFactoringResponse.assignor.totalLimit.amount;
        RPPCalculatorSimDebtorTotal.Percentage__c = totalPercentage;
        RPPCalculatorSimDebtors.add(RPPCalculatorSimDebtorTotal);
        if (!errorResponseDebtor) {
            insert RPPCalculatorSimDebtors;
            retMap.put('success', true);
            retMap.put('selectedSimulation', rppCalculatorSimulation.Id);
        }else {
            retMap.put('success', false);
            retMap.put('errorMessages', errorMessages);
        }
        return retMap;
    }
    /**
    * @description Retrieve final data from XXXXXX service
    * @param id : RPP Calculator Id
    * @return retMap Picklist values
    */
    @AuraEnabled
    public static Map<String,Object> getFinalData(String id) {
        Map<String, Object> retMap = new Map<String, Object>();
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = getRPPCalculatorSimulation(id);
        RPP_Calculator__c rppCalculator = getRPPCalculator(RPPCalculatorSimulation.Source_RPP_Calculator__c);
        RPP_SimulateFactoringRequest_Wrapper simulateFactoringRequest = new RPP_SimulateFactoringRequest_Wrapper();
        RPP_SimulateFactoringRequest_Wrapper.Assignor assignor = new RPP_SimulateFactoringRequest_Wrapper.Assignor();
        assignor.internalRating = RPPCalculatorSimulation.Internal_Rating__c;
        RPP_SimulateFactoringRequest_Wrapper.AmountCurrency totalLimit = new RPP_SimulateFactoringRequest_Wrapper.AmountCurrency();
        totalLimit.amount = RPPCalculatorSimulation.Total_Limit_EUR__c;
        totalLimit.currency_y = 'EUR';
        assignor.totalLimit = totalLimit;
        simulateFactoringRequest.assignor = assignor;
        RPP_SimulateFactoringRequest_Wrapper.Configuration configuration = new RPP_SimulateFactoringRequest_Wrapper.Configuration();
        String DDD = Label.RPP_Insurer_Value1;
        if (rppCalculator.Insurer__c == Label.RPP_Insurer_Value1) {
            configuration.applyInssurance = true;
        }else if (rppCalculator.Insurer__c == Label.RPP_Insurer_Value2) {
            configuration.applyInssurance = false;
        }
        configuration.assignorRating = rppCalculator.Insurer_Internal_Rating__c;
        configuration.averageDilution = rppCalculator.Average_Portfolio_Dilution__c;
        configuration.deviationDilution = rppCalculator.Mean_Dilution_Deviation__c;
        configuration.equivalencePDNonRated = rppCalculator.Unrated_PD_Equivalency__c;
        configuration.firstLossLevel = rppCalculator.Prefixed_First_Loss__c;
        if (rppCalculator.Target__c == Label.RPP_Target_Value1_Service) {
            configuration.goal = Label.RPP_Target_Value1;
        }else if (rppCalculator.Target__c == Label.RPP_Target_Value2_Service) {
            configuration.goal = Label.RPP_Target_Value2;
        }
        configuration.isInssuranceLiability = rppCalculator.Insurer_Limit__c;
        configuration.lgdCapital = rppCalculator.LGD_Capital__c;
        configuration.maturity = rppCalculator.Maturity__c;
        configuration.maxLimitNonRated = rppCalculator.Max_Unrated_Limit__c;
        configuration.numberSimulations = rppCalculator.Number_Of_Simulations__c;
        configuration.ratingSimLosses = rppCalculator.Target_Rating_Sim__c;
        configuration.sellerRating = rppCalculator.Seller_Internal_Rating__c;
        simulateFactoringRequest.configuration = configuration;
        List<RPP_SimulateFactoringRequest_Wrapper.Debtor> debtorsList = new List<RPP_SimulateFactoringRequest_Wrapper.Debtor>();
        List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimulationDebtors = getRPPCalculatorSimDebtors(id);
        for (RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimulationDebtor : RPPCalculatorSimulationDebtors) {
            RPP_SimulateFactoringRequest_Wrapper.Debtor debtor = new RPP_SimulateFactoringRequest_Wrapper.Debtor();
            if (RPPCalculatorSimulationDebtor.Obligor_Debtor__c != 'Total') {
                RPP_SimulateFactoringRequest_Wrapper.AmountCurrency amountLimit = new RPP_SimulateFactoringRequest_Wrapper.AmountCurrency();
                amountLimit.amount = RPPCalculatorSimulationDebtor.Authorised_Limit_EUR__c;
                amountLimit.currency_y = 'EUR';
                debtor.amountLimit = amountLimit;
                debtor.document = RPPCalculatorSimulationDebtor.Tax_Id__c;
                debtor.internalRating = RPPCalculatorSimulationDebtor.Internal_Rating__c;
                debtor.lei = RPPCalculatorSimulationDebtor.LEI__c;
                debtor.name = RPPCalculatorSimulationDebtor.Obligor_Debtor__c;
                debtorsList.add(debtor);
            }
        }
        simulateFactoringRequest.debtorsList = debtorsList;
        final Map<String,String> jsonInputMap = new Map<String,String>();
        jsonInputMap.put('JSONinput', JSON.serialize(simulateFactoringRequest).replaceAll('currency_y','currency'));
        final HttpResponse response = RPP_Utils.callWebService('simulateFactoring', jsonInputMap);
        switch on response.getStatusCode() {
            when 200, 201 {
                final String responseReplace = response.getBody().replaceAll('"currency":','"currency_y":');
                final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseReplace);
                RPP_SimulateFactoringResponse_Wrapper simulateFactoringResponse = (RPP_SimulateFactoringResponse_Wrapper) JSON.deserialize(JSON.serialize(responseMap.get('data')), RPP_SimulateFactoringResponse_Wrapper.class);
                retMap = updateSimulation(RPPCalculatorSimulation, RPPCalculatorSimulationDebtors, simulateFactoringResponse);
            }
            when else {
                String error = null;
                Map<String,Object> errorMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
                if (errorMap.containsKey('messages')) {
                    List<Object> messageMapList = (List <Object>) errorMap.get('messages');
                    Map<String,Object> messageMap = (Map<String,Object>) messageMapList[0];
                    if (messageMap.containsKey('message')) {
                        error = (String) messageMap.get('message');
                    }
                }
                retMap.put('success', false);
                retMap.put('errorMessage', error);
            }
        }
        return retMap;
    }
    /**
    * @description Retrieve ratings from 'simulate' service
    * @param rppCalculator : RPP_Calculator_Debtor__c parent record
    * @param RPPCalculatorDebtors : list of RPP_Calculator_Debtor__c records from the parent record
    * @param calculateFactoringResponse : Calculate Factoring service response
    * @return retMap
    */
    @AuraEnabled
    public static Map<String,Object> updateSimulation(RPP_Calculator_Simulation__c RPPCalculatorSimulation, List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimulationDebtors, RPP_SimulateFactoringResponse_Wrapper simulateFactoringResponse) {
        Map<String, Object> retMap = new Map<String, Object>();
        // Update RPP_Calculator_Simulation__c
        RPPCalculatorSimulation.Simulated__c = true;
        RPPCalculatorSimulation.Average_PD__c = simulateFactoringResponse.assignor.averagePD;
        RPPCalculatorSimulation.Obligor_Rating__c = simulateFactoringResponse.assignor.debtRating;
        RPPCalculatorSimulation.EAD__c = simulateFactoringResponse.assignor.ead;
        RPPCalculatorSimulation.Expected_Loss__c = simulateFactoringResponse.assignor.expectedLoss;
        RPPCalculatorSimulation.SP_Method_Rating__c = simulateFactoringResponse.assignor.ratingStandardAndPoors;
        RPPCalculatorSimulation.Dilution_Value__c = simulateFactoringResponse.resultsDilution.dilution.value;
        RPPCalculatorSimulation.Dilution_Percent__c = simulateFactoringResponse.resultsDilution.dilution.percentage;
        RPPCalculatorSimulation.Maximum_Insurance_Liability_Value__c = simulateFactoringResponse.resultsDilution.maximumLiability.value;
        RPPCalculatorSimulation.Maximum_Insurance_Liability_Percent__c = simulateFactoringResponse.resultsDilution.maximumLiability.percentage;
        RPPCalculatorSimulation.Risk_Retention_Value__c = simulateFactoringResponse.resultsDilution.riskRetention.value;
        RPPCalculatorSimulation.Risk_Retention_Percent__c = simulateFactoringResponse.resultsDilution.riskRetention.percentage;
        RPPCalculatorSimulation.Senior_Tranche_Value__c = simulateFactoringResponse.resultsDilution.seniorTranche.value;
        RPPCalculatorSimulation.Senior_Tranche_Percent__c = simulateFactoringResponse.resultsDilution.seniorTranche.percentage;
        RPPCalculatorSimulation.Maximum_Insurance_Amount_Value__c = simulateFactoringResponse.resultsDilution.maximumInsuranceAmount.value;
        RPPCalculatorSimulation.Maximum_Insurance_Amount_Percent__c = simulateFactoringResponse.resultsDilution.maximumInsuranceAmount.percentage;
        RPPCalculatorSimulation.First_Loss_1__c = simulateFactoringResponse.resultsStandardAndPoors[0].firstLoss;
        RPPCalculatorSimulation.Objective_Rating_SP_1__c = simulateFactoringResponse.resultsStandardAndPoors[0].objectiveRating;
        RPPCalculatorSimulation.Rating_Loss_1__c = simulateFactoringResponse.resultsStandardAndPoors[0].ratingLoss;
        RPPCalculatorSimulation.First_Loss_2__c = simulateFactoringResponse.resultsStandardAndPoors[1].firstLoss;
        RPPCalculatorSimulation.Objective_Rating_SP_2__c = simulateFactoringResponse.resultsStandardAndPoors[1].objectiveRating;
        RPPCalculatorSimulation.Rating_Loss_2__c = simulateFactoringResponse.resultsStandardAndPoors[1].ratingLoss;
        RPPCalculatorSimulation.First_Loss_3__c = simulateFactoringResponse.resultsStandardAndPoors[2].firstLoss;
        RPPCalculatorSimulation.Objective_Rating_SP_3__c = simulateFactoringResponse.resultsStandardAndPoors[2].objectiveRating;
        RPPCalculatorSimulation.Rating_Loss_3__c = simulateFactoringResponse.resultsStandardAndPoors[2].ratingLoss;
        RPPCalculatorSimulation.First_Loss__c = simulateFactoringResponse.simulationResults.firstLoss;
        RPPCalculatorSimulation.Rating_Under_95__c = simulateFactoringResponse.simulationResults.lowerRating;
        RPPCalculatorSimulation.Max_Or_Fixed__c = simulateFactoringResponse.simulationResults.maxOrFixed;
        RPPCalculatorSimulation.Senior_Tranche_Rating__c = simulateFactoringResponse.simulationResults.ratingSenior;
        RPPCalculatorSimulation.FL_SIM__c = simulateFactoringResponse.simulationResults.simulatedRating;
        RPPCalculatorSimulation.Total_Limit__c = simulateFactoringResponse.simulationResults.totalLimit;
        RPPCalculatorSimulation.CE__c = simulateFactoringResponse.totalSimulation.ce;
        RPPCalculatorSimulation.Equivalent_Rating__c = simulateFactoringResponse.totalSimulation.equivalentRating;
        RPPCalculatorSimulation.RWA__c = simulateFactoringResponse.totalSimulation.rwa;
        RPPCalculatorSimulation.Goal_Rating_SP_Methodology__c = simulateFactoringResponse.ratingStandardAndPoors;
        //update RPPCalculatorSimulation;
        Map<String,RPP_SimulateFactoringResponse_Wrapper.Debtor> debtorDocumentMap = new Map<String,RPP_SimulateFactoringResponse_Wrapper.Debtor>();
        Map<String,RPP_SimulateFactoringResponse_Wrapper.Debtor> debtorLeiMap = new Map<String,RPP_SimulateFactoringResponse_Wrapper.Debtor>();
        Map<String,RPP_SimulateFactoringResponse_Wrapper.Debtor> debtorOtherMap = new Map<String,RPP_SimulateFactoringResponse_Wrapper.Debtor>();
        for (RPP_SimulateFactoringResponse_Wrapper.Debtor debtor : simulateFactoringResponse.debtorsList) {
            if (debtor.document != '' && debtor.document != null) {
                debtorDocumentMap.put(debtor.document + debtor.name, debtor);
            }
            if (debtor.lei != '' && debtor.lei != null) {
                debtorLeiMap.put(debtor.lei + debtor.name, debtor);
            }
            if (debtor.document == '' || debtor.document == null || debtor.lei == '' || debtor.lei == null) {
                debtorOtherMap.put(debtor.name, debtor);
            }
        }
        Boolean errorResponseDebtor = false;
        List<String> errorMessages = new List<String>();
        RPP_SimulateFactoringResponse_Wrapper.Debtor responseDebtor = new RPP_SimulateFactoringResponse_Wrapper.Debtor();
        for (RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimulationDebtor : RPPCalculatorSimulationDebtors) {
            if (RPPCalculatorSimulationDebtor.Obligor_Debtor__c != 'Total') {
                if (RPPCalculatorSimulationDebtor.Tax_Id__c != null && RPPCalculatorSimulationDebtor.Tax_Id__c != '') {
                    responseDebtor = debtorDocumentMap.get(RPPCalculatorSimulationDebtor.Tax_Id__c + RPPCalculatorSimulationDebtor.Obligor_Debtor__c);
                }else if (RPPCalculatorSimulationDebtor.LEI__c != null && RPPCalculatorSimulationDebtor.LEI__c != '') {
                    responseDebtor = debtorLeiMap.get(RPPCalculatorSimulationDebtor.LEI__c + RPPCalculatorSimulationDebtor.Obligor_Debtor__c);
                }else {
                    responseDebtor = debtorOtherMap.get(RPPCalculatorSimulationDebtor.Obligor_Debtor__c);
                }
                if (responseDebtor == null) {
                    errorResponseDebtor = true;
                }else {
                    RPPCalculatorSimulationDebtor.PD__c = responseDebtor.averagePD;
                    RPPCalculatorSimulationDebtor.Obligor_Rating__c = responseDebtor.calculatedRating;
                    RPPCalculatorSimulationDebtor.SP_Method_Rating__c = responseDebtor.calculatedRatingStandardAndPoors;
                    RPPCalculatorSimulationDebtor.EAD__c = responseDebtor.ead;
                    RPPCalculatorSimulationDebtor.Expected_Loss__c = responseDebtor.expectedLoss;
                    RPPCalculatorSimulationDebtor.KIRB__c = responseDebtor.kirb;
                }
            }else {
                RPPCalculatorSimulationDebtor.Expected_Loss__c = simulateFactoringResponse.totalSimulation.totalExpectedLoss;
                RPPCalculatorSimulationDebtor.KIRB__c = simulateFactoringResponse.totalSimulation.totalKIRB;
            }
        }
        if (!errorResponseDebtor) {
            update RPPCalculatorSimulation;
            update RPPCalculatorSimulationDebtors;
            retMap.put('success', true);
            retMap.put('selectedSimulation', RPPCalculatorSimulation.Id);
        }else {
            retMap.put('success', false);
            retMap.put('errorMessage', Label.RPP_Error_When_Simulating);
        }
        return retMap;
    }
    /**
    * @description Get simulation data
    * @param id : RPP Calculator Id
    * @return retMap Simulation data
    */
    @AuraEnabled
    public static Map<String,Object> getSimulationData(String id) {
        Map<String, Object> retMap = new Map<String, Object>();
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = getRPPCalculatorSimulation(id);
        List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimulationDebtors = getRPPCalculatorSimDebtors(id);
        Boolean canSimulate = false;
        Boolean showSimulationResults = false;
        if (!RPPCalculatorSimulation.Simulated__c) {
            canSimulate = true;
        }else {
            showSimulationResults = true;
        }
        retMap.put('RPPCalculatorSimulation', RPPCalculatorSimulation);
        retMap.put('RPPCalculatorSimulationDebtors', RPPCalculatorSimulationDebtors);
        retMap.put('canSimulate', canSimulate);
        retMap.put('showSimulationResults', showSimulationResults);
        return retMap;
    }
    /**
    * @description Select RPP Calculator Simulation as Final
    * @param id : RPP Calculator Simulation Id
    * @param name : RPP Calculator Simulation Name
    * @param RPPCalculatorId : RPP Calculator Id
    * @return retMap success
    */
    @AuraEnabled
    public static Map<String,Object> setFinalSimulation(String id, String name, String RPPCalculatorId) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<RPP_Calculator_Simulation__c> RPPCalculatorSimulationList = [SELECT Id FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculatorId AND Final_Simulation__c = true];
        if (RPPCalculatorSimulationList.size() == 0) {
            RPP_Calculator_Simulation__c RPPCalculatorSimulation = new RPP_Calculator_Simulation__c();
            RPPCalculatorSimulation.Id = id;
            RPPCalculatorSimulation.Name = name + 'f';
            RPPCalculatorSimulation.Final_Simulation__c = true;
            update RPPCalculatorSimulation;
            retMap.put('success', true);
            retMap.put('showSimulationButtons', false);
        }else {
            retMap.put('success', false);
        }
        return retMap;
    }
    /**
    * @description Wrapper used to show existing Simulations
    */
	public class Simulation_Wrapper {
		@AuraEnabled
		public String name {get; set;}
		@AuraEnabled
		public String id {get; set;}
        @AuraEnabled
		public Boolean selected {get; set;}
	}
    /**
    * @description Wrapper used to show error messages
    */
	public class Errors_Wrapper {
		@AuraEnabled
		public String tab {get; set;}
        @AuraEnabled
		public String cell {get; set;}
		@AuraEnabled
		public String row {get; set;}
        @AuraEnabled
		public String type {get; set;}
        @AuraEnabled
		public String field {get; set;}
        @AuraEnabled
		public String message {get; set;}
        @AuraEnabled
		public String values {get; set;}
	}
}