/**
* ____________________________________________________________________________
* Controller class for RPP_LoadCalculatorGSheet.cmp aura Component
* ____________________________________________________________________________
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-02-14
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class RPP_LoadCalculatorGSheet_Ctrl {
    /**
    * @description Private constructor to avoid sonar err
    */
    @TestVisible
    public RPP_LoadCalculatorGSheet_Ctrl() {}
    /**
    * @description Check permissions to load Google Sheets
    * @param - : No parameters
    * @return retMap hasPermission - permission to load Google Sheets
    */
    @AuraEnabled
    public static Map<String,Object> initialData() {
        Map<String, Object> retMap = new Map<String, Object>();
        retMap.put('hasPermission', RPP_Utils.checkPermissionSet(UserInfo.getUserId()));
        return retMap;
    }
    /**
    * @description Load Google Sheet
    * @param - : No parameters
    * @return retMap success
    */
    @AuraEnabled
    public static Map<String,Object> loadGSheetData() {
        Map<String, Object> retMap = new Map<String, Object>();
        User currentUser = [SELECT Username FROM User WHERE Id = :UserInfo.getUserId()];
        List<gsheets__GSheets_Config__c> gSheetsConfigList = [SELECT Id FROM gsheets__GSheets_Config__c WHERE Name = :currentUser.Username];
        if (gSheetsConfigList.size() > 0 ) {
            gsheets.GSheets_Loader.loadData(currentUser.Username);
            retMap.put('success', true);
        }else {
            retMap.put('success', false);
            retMap.put('errorMessage', Label.RPP_Missing_GSheets_Config);
        }
        return retMap;
    }
}