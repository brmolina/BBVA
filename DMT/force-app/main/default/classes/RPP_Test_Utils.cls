/**
* ____________________________________________________________________________
* Test Utils class for RPP Calculator Application
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-07-07
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class RPP_Test_Utils {
    /**
    * @description Private constructor to avoid sonar err
    */
    @TestVisible
    public RPP_Test_Utils() {}
    /**
    * @description Insert RPP Calculator Data
    * @param name RPP Calculator Name
    * @param isValidated isValidated__c field
    * @param debtors Number of debtors
    * @param simulations Number of simulations
    * @return RPP_Calculator__c record
    */
    public static RPP_Calculator__c insertRPPCalculator(String name, Boolean isValidated, Integer debtors, Integer simulations) {
        RPP_Calculator__c RPPCalculator = new RPP_Calculator__c();
        RPPCalculator.Name = name;
        RPPCalculator.IsValidated__c = isValidated;
        if (isValidated) {
            RPPCalculator.Tax_Id__c = 'B12312323';
            RPPCalculator.Seller_Assignor__c = 'Assignor';
            RPPCalculator.Target__c = Label.RPP_Target_Value2_Service;
            RPPCalculator.Target_Rating_Sim__c = 'A';
            RPPCalculator.Prefixed_First_Loss__c = 50;
            RPPCalculator.Obligors_Debtors_Number__c = debtors;
            RPPCalculator.Average_Portfolio_Dilution__c = 0;
            RPPCalculator.Max_Unrated_Limit__c = 100;
            RPPCalculator.Unrated_PD_Equivalency__c = 'CC-';
            RPPCalculator.Seller_Internal_Rating__c = 'AA';
            RPPCalculator.Mean_Dilution__c = 0;
            RPPCalculator.Mean_Dilution_Deviation__c = 0;
            RPPCalculator.Insurer__c = 'Sí';
            RPPCalculator.Insurer_Limit__c = 100;
            RPPCalculator.Insurer_Name__c = 'Aseguradora A';
            RPPCalculator.Insurer_Internal_Rating__c = 'AA';
            RPPCalculator.Number_Of_Simulations__c = 100000;
            RPPCalculator.LGD_Capital__c = 40;
            RPPCalculator.Maturity__c = 1;
        }
        insert RPPCalculator;
        if (isValidated) {
            List<RPP_Calculator_Debtor__c> RPPCalculatorDebtorList = new List<RPP_Calculator_Debtor__c>();
            List<RPP_Calculator_Simulation__c> RPPCalculatorSimulationList = new List<RPP_Calculator_Simulation__c>();
            List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimulationDebtorList = new List<RPP_Calculator_Simulation_Debtor__c>();
            for (Integer i = 0; i < debtors; i++) {
                RPP_Calculator_Debtor__c RPPCalculatorDebtor = new RPP_Calculator_Debtor__c();
                RPPCalculatorDebtor.RPP_Calculator__c = RPPCalculator.Id;
                RPPCalculatorDebtor.Number__c = i + 1;
                RPPCalculatorDebtor.Insurer_Internal_Rating__c = '3';
                RPPCalculatorDebtor.Tax_Id__c = 'FR0000000' + (i+1);
                RPPCalculatorDebtor.LEI__c = '';
                RPPCalculatorDebtor.Obligor_Debtor__c = 'Debtor ' + (i + 1);
                RPPCalculatorDebtor.Currency__c = 'EUR';
                RPPCalculatorDebtor.Total_Amount_Local__c = 100000;
                RPPCalculatorDebtorList.add(RPPCalculatorDebtor);
            }
            if (debtors > 0) {
                insert RPPCalculatorDebtorList;
            }
            for (Integer i = 0; i < simulations; i++) {
                RPP_Calculator_Simulation__c RPPCalculatorSimulation = new RPP_Calculator_Simulation__c();
                RPPCalculatorSimulationList.add(RPPCalculatorSimulation);
                RPPCalculatorSimulation.Version__c = i + 1;
                RPPCalculatorSimulation.Name = RPPCalculator.Name + ' - ' + Label.RPP_Simulation + ' v' + RPPCalculatorSimulation.Version__c;
                RPPCalculatorSimulation.Source_RPP_Calculator__c = rppCalculator.Id;
                RPPCalculatorSimulation.Tax_Id__c = RPPCalculator.Tax_Id__c;
                RPPCalculatorSimulation.Seller_Assignor__c = RPPCalculator.Seller_Assignor__c;
                RPPCalculatorSimulation.Total_Amount_EUR__c = 2560000 * debtors;
                RPPCalculatorSimulation.Total_Limit_EUR__c = 2560000 * debtors;
                RPPCalculatorSimulation.Internal_Rating__c = 'AA';
                RPPCalculatorSimulation.External_Rating__c = 'AA';
            }
            if(simulations > 0) {
                insert RPPCalculatorSimulationList;
            }
            for (RPP_Calculator_Simulation__c RPPCalculatorSimulation : RPPCalculatorSimulationList) {
                for (RPP_Calculator_Debtor__c RPPCalculatorDebtor : RPPCalculatorDebtorList) {
                    RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimulationDebtor = new RPP_Calculator_Simulation_Debtor__c();
                    RPPCalculatorSimulationDebtor.RPP_Calculator_Simulation__c = RPPCalculatorSimulation.Id;
                    RPPCalculatorSimulationDebtor.Number__c = RPPCalculatorDebtor.Number__c;
                    RPPCalculatorSimulationDebtor.Insurer_Internal_Rating__c = RPPCalculatorDebtor.Insurer_Internal_Rating__c;
                    RPPCalculatorSimulationDebtor.Tax_Id__c = RPPCalculatorDebtor.Tax_Id__c;
                    RPPCalculatorSimulationDebtor.LEI__c = RPPCalculatorDebtor.LEI__c;
                    RPPCalculatorSimulationDebtor.Obligor_Debtor__c = RPPCalculatorDebtor.Obligor_Debtor__c;
                    RPPCalculatorSimulationDebtor.Currency__c = RPPCalculatorDebtor.Currency__c;
                    RPPCalculatorSimulationDebtor.Total_Amount_Local__c = RPPCalculatorDebtor.Total_Amount_Local__c;
                    RPPCalculatorSimulationDebtor.Authorised_Limit_Local__c = RPPCalculatorDebtor.Authorised_Limit_Local__c;
                    RPPCalculatorSimulationDebtor.Total_Amount_EUR__c = 2560000;
                    RPPCalculatorSimulationDebtor.Authorised_Limit_EUR__c = 2560000;
                    RPPCalculatorSimulationDebtor.Percentage__c = 100/debtors;
                    RPPCalculatorSimulationDebtor.Internal_Rating__c = 'AA';
                    RPPCalculatorSimulationDebtor.External_Rating__c = 'AA';
                    RPPCalculatorSimulationDebtorList.add(RPPCalculatorSimulationDebtor);
                }
                RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimulationDebtor = new RPP_Calculator_Simulation_Debtor__c();
                RPPCalculatorSimulationDebtor.RPP_Calculator_Simulation__c = RPPCalculatorSimulation.Id;
                RPPCalculatorSimulationDebtor.Obligor_Debtor__c = 'Total';
                RPPCalculatorSimulationDebtor.Total_Amount_EUR__c = 2560000 * debtors;
                RPPCalculatorSimulationDebtor.Authorised_Limit_EUR__c = 2560000 * debtors;
                RPPCalculatorSimulationDebtor.Percentage__c = 100;
                RPPCalculatorSimulationDebtorList.add(RPPCalculatorSimulationDebtor);
            }
            if(simulations > 0) {
                insert RPPCalculatorSimulationDebtorList;
            }
        }
        return RPPCalculator;
    }
}