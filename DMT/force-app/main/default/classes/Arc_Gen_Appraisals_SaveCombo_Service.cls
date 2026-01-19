/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Appraisals_SaveCombo_Service
* @Author   Juan Manuel Perez Ortiz
* @Date     Created: 2020-11-10
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for save currency and units combo from Contracts and Appraisals Table
* ------------------------------------------------------------------------------------------------
* |2020-11-10 juanmanuel.perez.ortiz.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
public class Arc_Gen_Appraisals_SaveCombo_Service implements Arc_Gen_RelatedTableManager_Interface {
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Save currency and unit combo box
    *---------------------------------------------------------------------------------------------------
    * @Author  juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date    2020-11-10
    * @param   recordId - id of the account has analysis
    * @param   value - value to save
    * @param   combo - type of combo
    * @return  String
    * @example saveCombos(recordId, value, combo)
    * --------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse saveCombos(String recordId, String value, String combo) {
        arce.Arc_Gen_ServiceAndSaveResponse wrapperResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        final List<arce__contracts_and_appraisals__c> contractsAppraisals = Arc_Gen_Contracts_Appraisals_Locator.getContractsAppraisalsRecords(recordId);
        if (combo == 'currency' && !contractsAppraisals.isEmpty()) {
            for (arce__contracts_and_appraisals__c appraisal: contractsAppraisals) {
                appraisal.CurrencyIsoCode = value;
            }
            wrapperResp = Arc_Gen_Contracts_Appraisals_Locator.updateContractsAppraisals(contractsAppraisals);
        } else if (combo == 'unit' && !contractsAppraisals.isEmpty()) {
            for (arce__contracts_and_appraisals__c appraisal: contractsAppraisals) {
                appraisal.arce__magnitude_unit_type__c = value;
            }
            wrapperResp = Arc_Gen_Contracts_Appraisals_Locator.updateContractsAppraisals(contractsAppraisals);
        }
        return wrapperResp;
    }

}