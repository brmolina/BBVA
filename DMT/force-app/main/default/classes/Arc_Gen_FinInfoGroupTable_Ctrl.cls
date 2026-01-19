/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinInfoGroupTable_Ctrl
* @Author   BBVA
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_FinInfoGroupTable component
* ------------------------------------------------------------------------------------------------
* @Changes
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-06-29 mariohumberto.ramirez.contractor@bbva.com
*             Update class for HU GADRDCDE-1577 Mejora Tabla Información Financiera
* |2020-11-13 joseluis.garcia4.contractor@bbva.com
*             Build tables title using currency and units (fixed: use current year).
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class Arc_Gen_FinInfoGroupTable_Ctrl {
    /**
    * @Description: Wrapper to save the info to build the tables
    */
    public class FinInfoTableGp {
    /**
    * @Description: String with the Id of the limit exposure object
    */
    @AuraEnabled public Arc_Gen_DataTable tableFinValid {get;set;}
    /**
    * @Description: String with the Id of the limit exposure object
    */
    @AuraEnabled public Arc_Gen_DataTable tablePrevYear {get;set;}
    /**
    * @Description: Title to display in the tables (with currency and units).
    */
    @AuraEnabled public String tablesTitle {get;set;}
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-04-14
    * @param void
    * @return void
    * @example Arc_Gen_FinInfoGroupTable_Ctrl controller = new Arc_Gen_FinInfoGroupTable_Ctrl()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_FinInfoGroupTable_Ctrl() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that return the information to build the financial info group tables
    * ----------------------------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @date 2020-04-14
    * @param recordId - arce__Account_has_Analysis__c object id
    * @return FinInfoTableGp wrapper with the info to build the tables
    * @example getTableData(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static FinInfoTableGp getTableData(String recordId) {
        FinInfoTableGp retInfo = new FinInfoTableGp();
        Arc_Gen_DataTable jsonValidInfo = new Arc_Gen_DataTable();
        jsonValidInfo.columns = Arc_Gen_FinInfoGroupTable_Service.getColumnsInfo();
        jsonValidInfo.finInfoRow = Arc_Gen_FinInfoGroupTable_Service.getRowInfo(recordId, 'valid');
        Arc_Gen_DataTable jsonPrevYearInfo = new Arc_Gen_DataTable();
        jsonPrevYearInfo.columns = Arc_Gen_FinInfoGroupTable_Service.getColumnsInfo();
        jsonPrevYearInfo.finInfoRow = Arc_Gen_FinInfoGroupTable_Service.getRowInfo(recordId, 'previous');
        retInfo.tableFinValid = jsonValidInfo;
        retInfo.tablePrevYear = jsonPrevYearInfo;
        if (jsonValidInfo.finInfoRow.isEmpty()) {
            retInfo.tablesTitle = '';
        } else {
            retInfo.tablesTitle = getTablesTitle(jsonValidInfo.finInfoRow);
        }
        return retInfo;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that returns the title to show in Financial information table
    * ----------------------------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-11-13
    * @param rows - Rows of the table.
    * @return the title to display
    * ----------------------------------------------------------------------------------------------------
    **/
    public static String getTablesTitle(List<Arc_Gen_FinancialInfoRow> rows) {
        // Fetch units and currency from the first row with data.
        String currencyVal = 'N/A';
        for (Arc_Gen_FinancialInfoRow row : rows) {
            if (currencyVal == 'N/A') {
                currencyVal = row.currencyVal;
            }
        }

        // Build title.
        return System.Label.Arc_Gen_DataInThousands + ' - ' + currencyVal;
    }
}