/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_BackLogTable_Service
* @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-15
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_BackLogTable_Ctrl
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-15 mariohumberto.ramirez.contractor@bbva.com
*             Class Creation
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             API names modified with the correct name on Business Glossary
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-06-29 juanignacio.hita.contractor@bbva.com
*             Created getYearColumns method
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_BackLogTable_Service {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-15
    * @param void
    * @return void
    * @example Arc_Gen_BackLogTable_Service service = new Arc_Gen_BackLogTable_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_BackLogTable_Service() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that return's the data needed to build the backLog Table
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-15
    * @param    arce__Account_has_Analysis__c accHas
    * @return Map<string,double> - map with the values to build the backLog Table
    * @example dataResp(recordId)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Map<string,double> dataResp(arce__Account_has_Analysis__c accHas) {
        Map<string,double> mapResponse =  new Map<string,double>();
        mapResponse.put('importX', accHas.arce__gf_backlog_pending_cyr_amount__c);
        mapResponse.put('importY', accHas.arce__gf_backlog_pending_pyr_amount__c);
        mapResponse.put('salesX', accHas.arce__gf_backlog_sales_cyr_number__c);
        mapResponse.put('salesY', accHas.arce__gf_backlog_sales_pyr_number__c);
        return mapResponse;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description - Method that save year columns (current year and previous year) data in wrapper
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2021-06-29
    * @param    arce__Account_has_Analysis__c accHas
    * @param    Arc_Gen_BackLogTable_Ctrl.BackLogTable backlogTable
    * @return   void
    * @example  getYearColumns(recordId, backlogTable);
    * ----------------------------------------------------------------------------------------------------
    **/
    public static void getYearColumns(arce__Account_has_Analysis__c accHas, Arc_Gen_BackLogTable_Ctrl.BackLogTable backlogTable) {
        final Date ffssEndDate = accHas.arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c;
        if (ffssEndDate == null) {
            backlogTable.errorResponse = Label.Arc_Gen_EmptyTableBacklog;
        } else {
            backlogTable.currentYear = ffssEndDate.year();
            backlogTable.lastYear = ffssEndDate.year() - 1;
        }
    }
}