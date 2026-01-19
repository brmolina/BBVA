/**
  * @File Name : Arc_Gen_ScheduleInSanction_Controller.cls
  * @Description : Controller of schedule in Sanction Component
  * @Author : luisarturo.parra.externo@bbva.com
  * @Group : ARCE - BBVA Bancomer
  * @Last Modified By : Global Desktop
  * @Last Modified On : 23-02-2022
  * @Modification Log :
  *==============================================================================
  * Ver Date Author          Modification
  *==============================================================================
  * 1.0 5/10/2019  ARCE TEAM Creación.
  * 1.1 13/07/2020 Add check for edit permissions.
  * 1.2 18/08/2020 Change reference from Arc_Gen_StatusButtons to arce.Arc_Gen_GenericUtilities.
  * 1.2 23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
  **/
public class Arc_Gen_ScheduleInSanction_Controller {
    /**
    *-------------------------------------------------------------------------------
    * @description private method to avoid intances
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.externo@bbva.com
    * @date 5/10/2019
    * @param none
    * @return none
    **/
  @TestVisible
  private Arc_Gen_ScheduleInSanction_Controller() {
  }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get all committee types for pick list selection
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.externo@bbva.com
    * @date 5/10/2019
    * @param none
    * @return  List < String >
    **/
  @auraEnabled
  public static String initDelegation(Id accHasAnalysisId) {
    try {
      final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
      final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
      Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, arceVar.Id, 'SCHEDULE',false);
      return JSON.serialize(wrapper);
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
  }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to save the user selection
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.externo@bbva.com
    * @date 5/10/2019
    * @param string committee, string recordId
    * @return
    **/
  @auraEnabled
  public static void updateCommittee(String committeeValue, Id recordId, String committeeDesc) {
    if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(recordId, 'Arc_Gen_ScheduleInSanction')) {
      throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
    }
    try {
      Arc_Gen_ScheduleInSanction_Service.updateCommitteeService(committeeValue, recordId, committeeDesc);
    } catch (Exception e) {
          throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
      }
  }
}