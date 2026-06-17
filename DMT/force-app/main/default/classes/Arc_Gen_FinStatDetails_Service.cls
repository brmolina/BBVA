/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinStatDetails_Service
* @Author   mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 19/12/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_ModalFinanStatemController
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-12-19 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2022-03-14 francisco.munoz.torres.contractor@bbva.com
*             Set FFSS Audit data into FFSS
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_FinStatDetails_Service {
    /**
        * @Description: Non adjusted type ffss
    */
    static final string FFSS_CT_AUDITED = 'AUDITED';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-12-19
    * @param void
    * @return void
    * @example Arc_Gen_FinStatDetails_Service service = new Arc_Gen_FinStatDetails_Service()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_FinStatDetails_Service() {

    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that set the number of employess of the subsidiary
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date Created: 2019-12-19
    * @param recordId - Id of the account_has_analysis
    * @param fsServiceId - Id of the financial statement
    * @return boolean
    * @example setNumberOfEmployees(recordId, recordId) {
    * ----------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static void setNumberOfEmployees(String ahaId, Integer employeesNumber) {
        final arce__Account_has_Analysis__c acchasAnalysis = new arce__Account_has_Analysis__c();
        acchasAnalysis.Id = ahaId;
        acchasAnalysis.arce__employees_number__c = employeesNumber;
        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(new List<arce__Account_has_Analysis__c>{acchasAnalysis});
    }
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that set the audit data of the FFSS
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author francisco.munoz.torres.contractor@bbva.com
    * @Date Created: 2022-03-14
    * @param ffssId - Id of the Financial statement
    * @param auditData - AuditData
    * @example setFFSSAuditData(ffssId, recordId) {
    * ----------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static void setFFSSAuditData(arce__Financial_Statements__c ffssData, Arc_Gen_ModalFinanStatemController.Audit auditData) {
      arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
      final Integer auditorOpMaxLength = arce__Financial_Statements__c.arce__ffss_auditor_opinion_desc__c.getDescribe().getLength();
      ffss.id = ffssData.id;
       // Validate auditData and auditor are not null before accessing properties
      // Handle null audit data first
      if (auditData == null || auditData.auditor == null) {
        ffss.arce__ffss_auditor_qlfn_type__c = getAuditorQualification(ffssData.arce__ffss_certification_type__c, null);
      } else {
        ffss.arce__ffss_auditor_opinion_desc__c = auditData.auditor.opinion == null ? null : auditData.auditor.opinion.abbreviate(auditorOpMaxLength);
        ffss.arce__ffss_auditor_opinion_type__c = auditData.auditor.hasQualification;
        ffss.arce__ffss_auditor_name__c = auditData.auditor.name;
        ffss.arce__ffss_auditor_qlfn_type__c = getAuditorQualification(ffssData.arce__ffss_certification_type__c, ffss.arce__ffss_auditor_opinion_type__c);
      }
      update ffss;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Gets the value of the "Auditor qualification" field.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    21/10/2020
    * @param certType Certification type of FFSS
    * @param hasQulf Has qualification value
    */
    private static String getAuditorQualification(String certType, String hasQulf) {
      String auditorQulf;
      if (certType == FFSS_CT_AUDITED && hasQulf == 'S') {
          auditorQulf = '1';
      } else if (certType == FFSS_CT_AUDITED && hasQulf == 'N') {
          auditorQulf = '2';
      } else {
          auditorQulf = '3';
      }

      return auditorQulf;
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description method that consult the financial statement details service
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author francisco.munoz.torres.contractor@bbva.com
    * @Date Created: 2022-03-14
    * @param ahaId - Id of the account_has_analysis
    * @param fsServiceId - Id of the financial statement
    * @return Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper
    * @example getFFSSDetail(ahaId, recordId) {
    * ----------------------------------------------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_ModalFinanStatemController.FinancialDetailsWrapper getFFSSDetail(String ahaId,String fsServiceId) {
      return Arc_Gen_FinStatDetails_Service_Helper.getFFSSDetail(ahaId, fsServiceId);
    }
}