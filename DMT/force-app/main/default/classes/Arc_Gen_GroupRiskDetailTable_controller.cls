/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_GroupRiskDetailTable_controller
* @Author   Juan Ignacio Hita juanginacio.hita.contractor@bbva.com
* @Date     Created: 18/11/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class for qvcd component
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-11-18 juanignacio.hita.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_GroupRiskDetailTable_controller {
    /**
    * @Description: Configuration name group risk detail table
    */
    static final String CONF_GROUPRISK = 'Arc_Gen_GroupRiskDetail_SI';
    /**
    * @Description: Configuration name group leveraged risk table
    */
    static final String CONF_LEVGDRISK = 'Arc_Gen_LeveragedGpTable_SI';

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 18/11/2020
    * @param   void
    * @return  void
    * @example Arc_Gen_GroupRiskDetailTable_controller controller = new Arc_Gen_GroupRiskDetailTable_controller()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_GroupRiskDetailTable_controller() {
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the json for creating of group risk table
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     18/11/2020
    * @param    accHasId - Id of the account has analysis object
    * @return   String
    * @example  String str = createGroupRiskTable(accHasId);
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String createGroupRiskTable(Id accHasId, String configurationId) {
        Arc_Gen_DwpTableWrapper_Controller.Configuration_Table configTable = new Arc_Gen_DwpTableWrapper_Controller.Configuration_Table();
        Arc_Gen_DwpTableWrapper wrapTable = new Arc_Gen_DwpTableWrapper();
        try {
            if (configurationId == CONF_GROUPRISK) {
                configTable = Arc_Gen_GroupRiskDetailTable_service.configGroupRiskDetail(accHasId);
            } else if (configurationId == CONF_LEVGDRISK) {
                configTable = Arc_Gen_GroupRiskDetailTable_service.configLeveragedGpTable(accHasId);
            }
            wrapTable = Arc_Gen_DwpTableWrapper_Controller.buildDwpTable(configTable);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
        return JSON.serialize(wrapTable);
    }
}