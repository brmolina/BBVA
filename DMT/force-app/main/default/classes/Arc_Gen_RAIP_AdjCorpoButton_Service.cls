/**
  * @Description        : Service class for Adjust in Corporate button for IRP analysis
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
public with sharing class Arc_Gen_RAIP_AdjCorpoButton_Service {

  /**
  * @Description: String with external id of test group
  */
  static final String YES = 'Y';

  /**
  *-------------------------------------------------------------------------------
  * @description Empty constructor method
  *-------------------------------------------------------------------------------
  *@author juanignacio.hita.contractor@bbva.com
  *@Date   27/04/2022
  */
  @TestVisible
  private Arc_Gen_RAIP_AdjCorpoButton_Service() { }

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
  public static Map<String, Object> configLocalUrlOrg(String recordId) {
    final List<arce__Account_has_Analysis__c> lstAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
    final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(lstAha[0]);
    return new Map<String, Object> {
      'accWrapper' => Arc_Gen_NewAnalysis_data.getUniqueCustomerDatacl(clientId),
      'runWayURLConfig' => Arc_Gen_RatingAsIndepProcess_controller.localURLs()
    };
  }

  /**
  *-------------------------------------------------------------------------------
  * @description updates arce__gf_corporate_adj_indicator__c field of AHA extension
  --------------------------------------------------------------------------------
  * @author  juanignacio.hita.contractor@bbva.com
  * @date    27/04/2022
  * @param   recordId : String
  * @return  Boolean
  * @example Boolean valRet = handleRedirect(recordId);
  **/
  public static Boolean handleRedirect(String recordId) {
    final List<arce__Account_has_Analysis__c> lstAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
    final arce__AHA_Extension__c ahaExtension = new arce__AHA_Extension__c(Id = lstAha[0].arce__AHA_Extension__c);
    ahaExtension.arce__gf_ratg_corp_adj_ind_type__c = YES;
    final arce.Arc_Gen_GenericUtilities.saveResult saveResult = arce.Arc_Gen_GenericUtilities.updateRecords(new List<sObject>{ahaExtension});
    return Boolean.valueOf(saveResult.status);
  }

  /**
  *-------------------------------------------------------------------------------
  * @description save traceability record
  --------------------------------------------------------------------------------
  * @author  juanignacio.hita.contractor@bbva.com
  * @date    27/04/2022
  * @param   recordId : String
  * @return  void
  * @example saveTraceability(recordId);
  **/
  public static void saveTraceability(String recordId) {
    final List<arce__Account_has_Analysis__c> lstAha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId});
    final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_Traceability_13, 'sanction', System.Label.Arc_Gen_TraceabilityAdjustCorpo, lstAha[0].Name);
    Arc_Gen_Traceability.saveTrace(lstAha[0].arce__Analysis__c, auditAttr, new Map<String, String>());
  }

}