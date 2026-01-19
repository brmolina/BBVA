/**
* ────────────────────────────────────────────────────────────────────
* RPP_Calculator_GSheets_Transformation
* Transformation class for GSheets Component
* ────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-02-06
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('sf:DMLWithoutSharingEnabled')
global class RPP_Calculator_GSheets_Transformation implements gsheets.GSheets_Data_Transformation_Interface{
    /**
    * @description ???
    * @param data : ????
    * @param header : ????
    * @return ????
    */
    global List<List<Object>> transformData (List<List<Object>> data, List <Object> header) {
        List<List<Object>> emptyData = new List<List<Object>>();
        // Insert new RPP_Calculator__c
        RPP_Calculator__c newRPPCalculator = new RPP_Calculator__c();
        newRPPCalculator.Name = Label.RPP_RPP_Calculator + ' - ' + datetime.now();
        insert newRPPCalculator;
        // Insert header into RPP_Calculator_Google_Sheet_Log__c object linked to the RPP_Calculator__c record just inserted
        List<RPP_Calculator_Google_Sheet_Log__c> rppCalculatorGoogleSheetLogList = new List<RPP_Calculator_Google_Sheet_Log__c>();
        RPP_Calculator_Google_Sheet_Log__c rppCalculatorGoogleSheetLogHeader = new RPP_Calculator_Google_Sheet_Log__c();
        rppCalculatorGoogleSheetLogHeader.Data__c = JSON.serialize(header);
        rppCalculatorGoogleSheetLogHeader.RPP_Calculator__c = newRPPCalculator.Id;
        rppCalculatorGoogleSheetLogList.add(rppCalculatorGoogleSheetLogHeader);       
        // Insert data into RPP_Calculator_Google_Sheet_Log__c object linked to the RPP_Calculator__c record just inserted
        for (List <Object> row: data) {
            RPP_Calculator_Google_Sheet_Log__c rppCalculatorGoogleSheetLogRow = new RPP_Calculator_Google_Sheet_Log__c();
            rppCalculatorGoogleSheetLogRow.Data__c = JSON.serialize(row);
            rppCalculatorGoogleSheetLogRow.RPP_Calculator__c = newRPPCalculator.Id;
            rppCalculatorGoogleSheetLogList.add(rppCalculatorGoogleSheetLogRow);
        }
        insert rppCalculatorGoogleSheetLogList;
        return emptyData;
    }
}