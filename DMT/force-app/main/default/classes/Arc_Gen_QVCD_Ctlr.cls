/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_QVCD_Ctlr
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 09/09/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class for qvcd component
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-09-09 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_QVCD_Ctlr {
    /**
        * @Description: String with value SUCCESS
    */
    static final String SUCCESS = 'SUCCESS';
    /**
        * @Description: String with value ERROR
    */
    static final String ERROR = 'ERROR';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 09/09/2019
    * @param void
    * @return void
    * @example Arc_Gen_QVCD_Ctlr ctlr = new Arc_Gen_QVCD_Ctlr()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_QVCD_Ctlr() {

    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description Wrapper that contain configuration info for qvcd
    * -----------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 2019-09-09
    * @param void
    * @return info configuration
    * @example qVCD_Wrapper wrapper = new qVCD_Wrapper()
    * -----------------------------------------------------------------------------------------------
    **/
    public class QVCD_Wrapper {
        /**
        * @Description: Map<String,String> with the configuration of the qvcd
        */
        @AuraEnabled public Map<String,String> config {get;set;}
        /**
        * @Description: String with a status
        */
        @AuraEnabled public String status {get;set;}
        /**
        * @Description: String with an error message
        */
        @AuraEnabled public String errorMessage {get;set;}
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Return info for qvcd
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 09/09/2019
    * @param recordId - Id of the account has analysis object
    * @return qVCD_Wrapper - info configuration of qvcd
    * @example Arc_Gen_QVCD_Ctlr.getConfiguration(recordId);
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static QVCD_Wrapper getConfiguration(Id recordId) {
        QVCD_Wrapper response = new QVCD_Wrapper();
        try {
            response.status = SUCCESS;
            response.config = Arc_Gen_QVCD_Service.getConfigurationService(recordId);
        } catch (Exception exep) {
            response.status = ERROR;
            response.errorMessage = exep.getMessage() + ' : ' + exep.getLineNumber();
        }
        return response;
    }
}