/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ToAssign_service
* @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
* @Date     Created: 2019-05-04
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class used for the button to Assign in the stage of Sanction.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-05-04 angel.fuertes2@bbva.com
*             Class creation.
* |2020-02-28 juanignacio.hita.contractor@bbva.com
*             Added traceability to "toAssign"
* |2020-03-03 juanignacio.hita.contractor@bbva.com
*             Changed the object to create traceability
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-04 juanignacio.hita.contractor@bbva.com
*             Adds aha name (analysisId) param in traceability record
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ToAssign_service {
    /**
        * @Description: String with the dev name of the recordtype
    */
    static final string TASK_DEV_NAME = 'Arc_Gen_ARCE_Task';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty priavate constructor
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-09-25
    * @example private Arc_Gen_ToAssign_service ()
    **/
    @TestVisible
    private Arc_Gen_ToAssign_service () {
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to find users
    * ---------------------------------------------------------------------------------------------------
    * @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
    * @Date     Created: 2019-05-04
    * @param inputTerm - String to find users
    * @return a list of map with the users
    * @example searchUser(inputTerm)
    * ---------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<map<String,String>> searchUser(String inputTerm){
        List<map<String,String>> ltsUsers = new list<map<String,String>>();
        List<arce.Arc_Gen_User_Wrapper> lstWrap = arce.Arc_Gen_User_Locator.getUsers(inputTerm);
        for(arce.Arc_Gen_User_Wrapper wrap : lstWrap) {
            ltsUsers.add(new map<String,String>{'nameUser' => wrap.userBasicInfo.Name, 'perfilUser' => wrap.profileName, 'idUser' => wrap.userBasicInfo.Id});
        }
        return ltsUsers;
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to assign the arce
    * ---------------------------------------------------------------------------------------------------
    * @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
    * @Date     Created: 2019-05-04
    * @param userId - id of the user selected
    * @param recordId - id of the arce
    * @return a string
    * @example toAssign(userId, recordId)
    * ---------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String toAssign(Id userId, Id recordId) {
        final arce.Arc_Gen_User_Wrapper wrpUserCurrent = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(UserId);
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(recordId);

        arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(new List<arce__Analysis__c>{(arce__Analysis__c) arceVar});
        insert arce.Arc_Gen_GenericUtilities.createTask(userId, arceVar.Id, System.Label.Arc_Gen_ArcePropose, TASK_DEV_NAME);

        final string traceComments = Label.Arc_Gen_PreviousUserTrace + ': ' + wrpUserCurrent.userBasicInfo.Name.abbreviate(60) + ' | ' + Label.Arc_Gen_AssignedUserTrace + ': ' + wrpUser.userBasicInfo.Name.abbreviate(60);
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(recordId, new List<String>{ 'Id', 'Name' });
        final Map<String, String> auditAttr = Arc_Gen_Traceability.genAuditAttr(System.Label.Arc_Gen_BtnToAssign, 'sendBack', traceComments.abbreviate(255), accHasAnalysis.Name);
        final Map<String, String> auditWF = Arc_Gen_Traceability.genAuditWF(wrpUser.ambitUser, '', '', '');

        Arc_Gen_Traceability.saveTrace(arceVar.Id, auditAttr, auditWF);
        return System.Label.Arc_Gen_AssignedARCESuccess;
    }
}