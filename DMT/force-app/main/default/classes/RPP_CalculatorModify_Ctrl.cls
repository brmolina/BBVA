/**
* ____________________________________________________________________________
* Controller class for RPP_CalculatorModify.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-03-21
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class RPP_CalculatorModify_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    @TestVisible
    public RPP_CalculatorModify_Ctrl() {}
    /**
    * @description Get data from services
    * @param RPPCalculatorSimulationId : RPP Calculator Simulation Id
    * @return retMap Initial Data
    */
    @AuraEnabled
    public static Map<String,Object> initialData(String RPPCalculatorSimulationId) {
        Map<String, Object> retMap = new Map<String, Object>();
        List<RPP_Calculator_Simulation__c>  RPPCalculatorSimulation = [SELECT Tax_Id__c,
                                                                        Seller_Assignor__c,
                                                                        Total_Amount_EUR__c,
                                                                        Total_Limit_EUR__c,
                                                                        Internal_Rating__c,
                                                                        External_Rating__c
                                                                FROM RPP_Calculator_Simulation__c
                                                                WHERE Id = :RPPCalculatorSimulationId LIMIT 1];
        List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtors = new List<RPP_Calculator_Simulation_Debtor__c>();
        Map<Id,RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtorsMap = new Map<Id,RPP_Calculator_Simulation_Debtor__c>();
        for (RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimulationDebtor : [SELECT Number__c,
                                                                                        Insurer_Internal_Rating__c,
                                                                                        Tax_Id__c,
                                                                                        LEI__c,
                                                                                        Obligor_Debtor__c,
                                                                                        Total_Amount_EUR__c,
                                                                                        Authorised_Limit_EUR__c,
                                                                                        Percentage__c,
                                                                                        Internal_Rating__c,
                                                                                        External_Rating__c
                                                                                    FROM RPP_Calculator_Simulation_Debtor__c
                                                                                    WHERE RPP_Calculator_Simulation__c = :RPPCalculatorSimulationId
                                                                                    ORDER BY Number__c]) {
            if (RPPCalculatorSimulationDebtor.Obligor_Debtor__c != 'Total') {
                RPPCalculatorSimDebtors.add(RPPCalculatorSimulationDebtor);
                RPPCalculatorSimDebtorsMap.put(RPPCalculatorSimulationDebtor.Id,RPPCalculatorSimulationDebtor);
            }
        }
        Map<String, String> RPPCalculatorSimFields = RPP_Utils.getObjectFields('RPP_Calculator_Simulation__c');
        Map<String, String> RPPCalculatorSimDebtorFields = RPP_Utils.getObjectFields('RPP_Calculator_Simulation_Debtor__c');
        List<RPP_Utils.PicklistValue_Wrapper> internalRatingSimPicklist = RPP_Utils.getPicklistData('RPP_Calculator_Simulation__c','Internal_Rating__c');
        List<RPP_Utils.PicklistValue_Wrapper> externalRatingSimPicklist = RPP_Utils.getPicklistData('RPP_Calculator_Simulation__c','External_Rating__c');
        List<RPP_Utils.PicklistValue_Wrapper> internalRatingDebtorPicklist = RPP_Utils.getPicklistData('RPP_Calculator_Simulation_Debtor__c','Internal_Rating__c');
        List<RPP_Utils.PicklistValue_Wrapper> externalRatingDebtorPicklist = RPP_Utils.getPicklistData('RPP_Calculator_Simulation_Debtor__c','External_Rating__c');
        retMap.put('RPPCalculatorSimulation', RPPCalculatorSimulation);
        retMap.put('RPPCalculatorSimDebtors', RPPCalculatorSimDebtors);
        retMap.put('RPPCalculatorSimFields', RPPCalculatorSimFields);
        retMap.put('RPPCalculatorSimDebtorFields', RPPCalculatorSimDebtorFields);
        retMap.put('RPPCalculatorSimDebtorsMap', RPPCalculatorSimDebtorsMap);
        retMap.put('internalRatingSimPicklist', internalRatingSimPicklist);
        retMap.put('externalRatingSimPicklist', externalRatingSimPicklist);
        retMap.put('internalRatingDebtorPicklist', internalRatingDebtorPicklist);
        retMap.put('externalRatingDebtorPicklist', externalRatingDebtorPicklist);
        retMap.put('success', true);
        return retMap;
    }
    /**
    * @description modify data
    * @param RPPCalculatorSimulation : RPP Calculator Simulation screen data
    * @param RPPCalculatorSimulationOld : RPP Calculator Simulation original data
    * @param RPPCalculatorSimDebtors : RPP Calculator Simulation Debtors ids
    * @param RPPCalculatorSimDebtorsMap : Map RPP Calculator Simulation Debtors ids / RPP Calculator Simulation Debtors data
    * @return retMap success true/false
    */
    @AuraEnabled
    public static Map<String,Object> modifyData(List<RPP_Calculator_Simulation__c> RPPCalculatorSimulation, List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtors, Map<Id,RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtorsMap) {
        Map<String, Object> retMap = new Map<String, Object>();
        RPP_Calculator_Simulation__c RPPCalculatorSimulationOld = [SELECT Id, Internal_Rating__c, External_Rating__c
                                                                    FROM RPP_Calculator_Simulation__c
                                                                    WHERE Id = :RPPCalculatorSimulation[0].Id];
        RPP_Calculator_Simulation__c RPPCalculatorSimulationUpdate = new RPP_Calculator_Simulation__c();
        Boolean simulationDataModified = false;
        if (RPPCalculatorSimulation[0].Internal_Rating__c != '' || RPPCalculatorSimulationOld.Internal_Rating__c != null) {
            if (RPPCalculatorSimulation[0].Internal_Rating__c != RPPCalculatorSimulationOld.Internal_Rating__c) {
                RPPCalculatorSimulationUpdate.Internal_Rating__c = RPPCalculatorSimulation[0].Internal_Rating__c;
                simulationDataModified = true;
            }
        }
        if (RPPCalculatorSimulation[0].External_Rating__c != '' || RPPCalculatorSimulationOld.External_Rating__c != null) {     
            if (RPPCalculatorSimulation[0].External_Rating__c != RPPCalculatorSimulationOld.External_Rating__c) {
                RPPCalculatorSimulationUpdate.External_Rating__c = RPPCalculatorSimulation[0].External_Rating__c;
                simulationDataModified = true;
            }
        }   
        if (simulationDataModified) {
            RPPCalculatorSimulationUpdate.Id = RPPCalculatorSimulation[0].Id;
        }
        List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtorsUpdate = new List<RPP_Calculator_Simulation_Debtor__c>();
        for (RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtorNew : RPPCalculatorSimDebtors) {
            Boolean debtorsDataModified = false;
            RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtorOld = RPPCalculatorSimDebtorsMap.Get(RPPCalculatorSimDebtorNew.Id);
            RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtorUpdate = new RPP_Calculator_Simulation_Debtor__c();
            if (RPPCalculatorSimDebtorNew.Internal_Rating__c != '' || RPPCalculatorSimDebtorOld.Internal_Rating__c != null) {
                if (RPPCalculatorSimDebtorNew.Internal_Rating__c != RPPCalculatorSimDebtorOld.Internal_Rating__c) {
                    RPPCalculatorSimDebtorUpdate.Internal_Rating__c = RPPCalculatorSimDebtorNew.Internal_Rating__c;
                    debtorsDataModified = true;
                }
            }
            if (RPPCalculatorSimDebtorNew.External_Rating__c != '' || RPPCalculatorSimDebtorOld.External_Rating__c != null) {
                if (RPPCalculatorSimDebtorNew.External_Rating__c != RPPCalculatorSimDebtorOld.External_Rating__c) {
                    RPPCalculatorSimDebtorUpdate.External_Rating__c = RPPCalculatorSimDebtorNew.External_Rating__c;
                    debtorsDataModified = true;
                }
            }
            if (debtorsDataModified) {
                RPPCalculatorSimDebtorUpdate.Id = RPPCalculatorSimDebtorNew.Id;
                RPPCalculatorSimDebtorsUpdate.add(RPPCalculatorSimDebtorUpdate);
            }
        }
        if (RPPCalculatorSimDebtorsUpdate.size() > 0 || simulationDataModified) {
            if (simulationDataModified) {
                update RPPCalculatorSimulationUpdate;    
            }
            if (RPPCalculatorSimDebtorsUpdate.size() > 0) {
                update RPPCalculatorSimDebtorsUpdate;    
            }
            retMap.put('success', true);
        } else {
            retMap.put('success', false);
        }
        return retMap;
    }
}