/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Category_SaveCombo_Service
* @Author   moises.martinez.dominguez.contractor@bbva.com
* @Date     Created: 2020-11-12
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for save currency and units combo from Analysis Category Table
* ------------------------------------------------------------------------------------------------
* |2020-11-12 moises.martinez.dominguez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
public class Arc_Gen_Category_SaveCombo_Service implements Arc_Gen_RelatedTableManager_Interface {
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
        final List<arce__hotel_analysis_category__c> analysisCategory = Arc_Gen_Analysis_Category_Locator.getCategoryRecords(recordId);
        if (combo == 'currency' && !analysisCategory.isEmpty()) {
            for (arce__hotel_analysis_category__c category: analysisCategory) {
                category.CurrencyIsoCode = value;
            }
            wrapperResp = Arc_Gen_Analysis_Category_Locator.updateAnalysisCategory(analysisCategory);
        } else if (combo == 'unit' && !analysisCategory.isEmpty()) {
            for (arce__hotel_analysis_category__c category: analysisCategory) {
                category.arce__magnitude_unit_type__c = value;
            }
            wrapperResp = Arc_Gen_Analysis_Category_Locator.updateAnalysisCategory(analysisCategory);
        }
        return wrapperResp;
    }

}