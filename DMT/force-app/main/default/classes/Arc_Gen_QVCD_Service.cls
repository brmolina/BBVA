/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_QVCD_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 09/09/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class for qvcd component
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-09-09 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-04-16 juanmanuel.perez.ortiz.contractor@bbva.com
*             Create new static variable called TB_ALL_CUSTOMERSM and modified getConfigurationService method.
* |2020-08-12 mariohumberto.ramirez.contractor@bbva.com
*             Added support for hu Renovation to getConfigurationService method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_QVCD_Service {
    /**
        * @Description: String with value 01
    */
    static final String ONE = '01';
    /**
        * @Description: String with value 02
    */
    static final String TWO = '02';
    /**
        * @Description: String with value TRUE
    */
    static final String V_TRUE = 'TRUE';
    /**
        * @Description: String with value FALSE
    */
    static final String V_FALSE = 'FALSE';
    /**
        * @Description: String with value Arc_Gen_tbAllCustomers
    */
    static final String TB_ALL_CUSTOMERS = 'Arc_Gen_tbAllCustomers';
    /**
        * @Description: String with value Arc_Gen_tbAllCustomersM to subprocess 3 (Modification)
    */
    static final String TB_ALL_CUSTOMERSM = 'Arc_Gen_tbAllCustomersM';
    /**
        * @Description: String with value Name
    */
    static final String NAME = 'Name';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 09/09/2019
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Service service = new Arc_Gen_QVCD_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_QVCD_Service() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Return info for qvcd
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 09/09/2019
    * @param recordId - Id of the account has analysis object
    * @return Map<String,String> - info configuration of qvcd
    * @example Arc_Gen_QVCD_Service.getConfigurationService(recordId);
    * ----------------------------------------------------------------------------------------------------
    **/
    public static Map<String,String> getConfigurationService(Id recordId) {
        Map<String,String> mapResponse = new Map<String,String>();
        final List<arce__Analysis__c> arceData = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{recordId});
        if (arceData[0].arce__analysis_customer_relation_type__c == ONE && arceData[0].arce__wf_status_id__c != ONE) {
            mapResponse.put('readRecords', V_TRUE);
            mapResponse.put('showSwitchIcon', V_TRUE);
            mapResponse.put('tableConfName', arceData[0].arce__anlys_wkfl_sub_process_type__c == '3' || arceData[0].arce__anlys_wkfl_sub_process_type__c == '1' ? TB_ALL_CUSTOMERSM : TB_ALL_CUSTOMERS);
        } else if (arceData[0].arce__analysis_customer_relation_type__c == TWO && arceData[0].arce__wf_status_id__c != ONE) {
            mapResponse.put('readRecords', V_FALSE);
            mapResponse.put('showSwitchIcon', V_FALSE);
            mapResponse.put('tableConfName', NAME);
        }
        return mapResponse;
    }

}