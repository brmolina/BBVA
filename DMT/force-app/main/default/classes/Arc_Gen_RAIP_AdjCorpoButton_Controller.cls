/**
  * @Description        : Controller class for Adjust in Corporate button for IRP analysis
  * @Author             : juanignacio.hita.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : juanignacio.hita.contractor@bbva.com
  * @Last Modified On   : 27/04/2022 10:00:00
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                       Modification
  *==============================================================================
  * 1.0      27/04/2022      juanignacio.hita.contractor@bbva.com     Initial Version
  **/
public with sharing class Arc_Gen_RAIP_AdjCorpoButton_Controller {

  /**
  *-------------------------------------------------------------------------------
  * @description Empty constructor method
  *-------------------------------------------------------------------------------
  *@author juanignacio.hita.contractor@bbva.com
  *@Date   27/04/2022
  */
  @TestVisible
  private Arc_Gen_RAIP_AdjCorpoButton_Controller() { }

  /**
  *-------------------------------------------------------------------------------
  * @description get runaway url local configuration
  --------------------------------------------------------------------------------
  * @author  juanignacio.hita.contractor@bbva.com
  * @date    27/04/2022
  * @param   recordId : String
  * @return  Map<String, Object>
  * @example Map<String, Object> runaway = configLocalUrlOrg();
  **/
  @AuraEnabled
  public static Map<String, Object> configLocalUrlOrg(String recordId) {
    try {
      return Arc_Gen_RAIP_AdjCorpoButton_Service.configLocalUrlOrg(recordId);
    } catch (Exception e) {
      throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
    }
  }

  /**
  *-------------------------------------------------------------------------------
  * @description updates the stage/status of analysis and creates traceability record
  --------------------------------------------------------------------------------
  * @author  juanignacio.hita.contractor@bbva.com
  * @date    27/04/2022
  * @param   recordId : String
  * @return  Boolean
  * @example Boolean valRet = handleRedirect(recordId);
  **/
  @AuraEnabled
  public static Boolean handleRedirect(String recordId) {
    try {
      return Arc_Gen_RAIP_AdjCorpoButton_Service.handleRedirect(recordId);
    } catch (Exception e) {
      throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
    }
  }

}