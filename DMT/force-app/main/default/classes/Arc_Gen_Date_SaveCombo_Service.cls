/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Date_SaveCombo_Service
* @Author   moises.martinez.dominguez.contractor@bbva.com
* @Date     Created: 2020-11-12
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for save currency and units combo from Analysis Date Table
* ------------------------------------------------------------------------------------------------
* |2020-11-12 moises.martinez.dominguez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
public class Arc_Gen_Date_SaveCombo_Service implements Arc_Gen_RelatedTableManager_Interface {
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description Save currency and unit combo box
    *---------------------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-12
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
        final List<arce__hotel_analysis_date_period__c> analysisDate = Arc_Gen_Analysis_Date_Locator.getAnalysisDateRecords(recordId);
        if (combo == 'currency' && !analysisDate.isEmpty()) {
            for (arce__hotel_analysis_date_period__c dummyDate: analysisDate) {
                dummyDate.CurrencyIsoCode = value;
            }
            wrapperResp = Arc_Gen_Analysis_Date_Locator.updateAnalysisDate(analysisDate);
        } else if (combo == 'unit' && !analysisDate.isEmpty()) {
            for (arce__hotel_analysis_date_period__c dummyDate: analysisDate) {
                dummyDate.arce__magnitude_unit_type__c = value;
            }
            wrapperResp = Arc_Gen_Analysis_Date_Locator.updateAnalysisDate(analysisDate);
        }
        return wrapperResp;
    }

}