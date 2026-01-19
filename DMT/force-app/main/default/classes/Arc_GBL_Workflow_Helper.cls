/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Workflow_Helper
* @Author   Juan Ignacio Hita Manso juanignacio.hita.contractor@bbva.com
* @Date     Created: 2020-01-07
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper class local execute method of workflow
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-01-07 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2020-03-31 juanignacio.hita.contractor@bbva.com
*             Added PROPOSE-RAIP action and service message
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-04-24 jose.hijar.contractor@bbva.com
*             Added fetchUsersByAmbit, getUsersAmbit, getStringAmbit methods for getting a list of users queried by an ambit
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:DMLWithoutSharingEnabled')
public class Arc_GBL_Workflow_Helper {
    /**
    * @Description : Service message class
    */
    static final arce.Arc_Gen_CustomServiceMessages SERVICE_MESSAGES = new arce.Arc_Gen_CustomServiceMessages();
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 07/01/2019
    * @param void
    * @return void
    * @example Arc_GBL_Workflow_Helper data = new Arc_GBL_Workflow_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_GBL_Workflow_Helper() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description scheduleAction : Schedule action method
    *--------------------------------------------------------------------------------
    * @date		07/01/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @param    Arc_Gen_Delegation_Wrapper : wrapper
    * @return   Arc_Gen_Delegation_Wrapper
    * @example	Arc_Gen_Workflow_Helper.scheduleAction(Arc_Gen_Delegation_Wrapper wrapper);
    */
    public static Arc_Gen_Delegation_Wrapper scheduleAction(Arc_Gen_Delegation_Wrapper wrapper) {
        try {
            final List<String> valuesSelected = new List<String>{'1'};
            final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__bbva_committees_type__c', valuesSelected);
            wrapper.lstComittees = lstPicklist;
            wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
        } catch (Exception e) {
            wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
            wrapper.msgInfo = 'Error Schedule Action : ' + e.getMessage();
        }
        return wrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description proposeAction : Propose action method
    *--------------------------------------------------------------------------------
    * @date		08/01/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @param    Arc_Gen_Delegation_Wrapper : wrapper
    * @return   Arc_Gen_Delegation_Wrapper
    * @example	Arc_Gen_Workflow_Helper.proposeAction(Arc_Gen_Delegation_Wrapper wrapper);
    */
    public static Arc_Gen_Delegation_Wrapper proposeAction(Arc_Gen_Delegation_Wrapper wrapper) {
        try {
            final List<String> valuesSelected = new List<String>{'1', '2', '3'};
            final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
            wrapper.lstAmbits = lstPicklist;
            wrapper.sanctionAmbit = '1';
            wrapper.hasDelegation = 'NO';
            wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
        } catch (Exception e) {
            wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
            wrapper.msgInfo = 'Error Propose Action : ' + e.getMessage();
        }
        return wrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description proposeRAIPAction : Propose RAIP Action
    *--------------------------------------------------------------------------------
    * @date		31/03/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @param    Arc_Gen_Delegation_Wrapper : wrapper
    * @return   Arc_Gen_Delegation_Wrapper
    * @example	Arc_Gen_Workflow_Helper.proposeAction(Arc_Gen_Delegation_Wrapper wrapper);
    */
    public static Arc_Gen_Delegation_Wrapper proposeRAIPAction(Arc_Gen_Delegation_Wrapper wrapper) {
        try {
            final List<String> valuesSelected = new List<String>{'1', '2', '3'};
            final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
            wrapper.lstAmbits = lstPicklist;
            wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
        } catch (Exception e) {
            wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
            wrapper.msgInfo = 'Error Propose RAIP Action : ' + e.getMessage();
        }
        return wrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description proposeAction : Propose action method
    *--------------------------------------------------------------------------------
    * @date		08/01/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @param    Arc_Gen_Delegation_Wrapper : wrapper
    * @return   Arc_Gen_Delegation_Wrapper
    * @example	Arc_Gen_Workflow_Helper.proposeAction(Arc_Gen_Delegation_Wrapper wrapper);
    */
    public static Arc_Gen_Delegation_Wrapper returnAction(Arc_Gen_Delegation_Wrapper wrapper) {
        try {
            final List<String> valuesSelected = new List<String>{'2'};
            final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
            wrapper.lstAmbits = lstPicklist;
            wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
        } catch (Exception e) {
            wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
            wrapper.msgInfo = 'Error Return Action : ' + e.getMessage();
        }
        return wrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description sanctionAction : Sanction action method
    *--------------------------------------------------------------------------------
    * @date		22/01/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @param    Arc_Gen_Delegation_Wrapper : wrapper
    * @return   Arc_Gen_Delegation_Wrapper
    * @example	Arc_Gen_Workflow_Helper.sanctionAction(Arc_Gen_Delegation_Wrapper wrapper);
    */
    public static Arc_Gen_Delegation_Wrapper sanctionAction(Arc_Gen_Delegation_Wrapper wrapper) {
        try {
            final List<String> valSelAmbit = new List<String>{'2'};
            final List<String> valSelSanction = new List<String>{'1', '2', '3', '4', '5', '6'};
            final List<Map<String,String>> lstMapAmbits = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valSelAmbit);
            final List<Map<String,String>> lstMapSanction = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_sanction_rslt_type__c', valSelSanction);
            wrapper.lstAmbits = lstMapAmbits;
            wrapper.lstActions = lstMapSanction;
            wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
        } catch (Exception e) {
            wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
            wrapper.msgInfo = 'Error Sanction Action : ' + e.getMessage();
        }
        return wrapper;
    }

  /**
  *-------------------------------------------------------------------------------
  * @description fetchUsersByAmbit : Arc_Gen_Delegation_Wrapper
  *--------------------------------------------------------------------------------
  * @date   27/04/2021
  * @author ARCE Corporate
  * @param    String : selectedAmbit
  * @return   Arc_Gen_Delegation_Wrapper
  * @example  Arc_Gen_Workflow_Helper.fetchUsersByAmbit(Arc_Gen_Delegation_Wrapper wrapper);
  */
  public static Arc_Gen_Delegation_Wrapper fetchUsersByAmbit(String selectedAmbit) {
    final Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
    try {
      wrapper.lstUsers = getUsersAmbit(selectedAmbit);
      wrapper.codStatus = SERVICE_MESSAGES.CODE_200;
    } catch (Exception e) {
      wrapper.codStatus = SERVICE_MESSAGES.CODE_500;
      wrapper.msgInfo = 'Error Propose RAIP Action : ' + e.getMessage();
    }
    return wrapper;
  }

  /*
  * @author Global Desktop
  */
  private static List<Map<String, String>> getUsersAmbit(String selectedAmbit) {
    final String ambitString = getStringAmbit(selectedAmbit);
    final List<User> lstUsers = Arc_GBL_User_Locator.getUserByAmbit(ambitString);

    final List<Map<String, String>> listAmbitUser = new List<Map<String, String>>();
    for(User usr : lstUsers) {
      listAmbitUser.add(new map<String,String>{'label' => usr.Name , 'value' => usr.Id});
    }
    return listAmbitUser;
  }

  /*
  * @author Global Desktop
  */
  public static String getStringAmbit(String selectedAmbit) {
    final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
      SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, canRead__c, canEdit__c, canPropose__c, canValidate__c
      FROM Arce_ambit_hierarchy__mdt
      WHERE Ambit__c = :selectedAmbit
      LIMIT 40000
    ]);

    String ambitString = '';
    if(!ambitMetadatas.isEmpty()) {
      ambitString = ambitMetadatas.get(0).Region__c + ' - ' + ambitMetadatas.get(0).Level__c + (ambitMetadatas.get(0).Description__c == null || ambitMetadatas.get(0).Description__c == '' ? ' -' : ' - ' + ambitMetadatas.get(0).Description__c);
    }
    return ambitString;
  }
}