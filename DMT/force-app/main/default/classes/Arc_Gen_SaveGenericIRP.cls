/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveGenericIRP
* @Author   ARCE TEAM
* @Date     Created: 10/06/2022
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that validates that the user saving a dynamic form tab on the ARCE IRP
* has edit access to the analysis.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2022-06-10 juanignacio.hita.contractor@bbva.com
*             Class creation and add checkChangesQualQuestion validation
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveGenericIRP implements dyfr.Save_Interface {
    /**
    * @Description : Variable true literal
    */
    static final String TRUE_VAL = 'true';
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for invoking the classes to save the basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  ARCE Team
    * @Date    Created: 2022-06-10
    * @param   listObject - List of the account has analisys object
    * @return  String with the execution message
    * @example save (listObject)
    * -----------------------------------------------------------------------------------------------
    **/
    public String save(List<sObject> listObject) {
        for(sObject obj : listObject) {
            final String recordId = String.valueOf(obj.get('Id'));

            // Only validate if what is being saved is an Account_has_analysis__c
            // record.
            if (Id.valueOf(recordId).getSobjectType() != arce__Account_has_Analysis__c.SObjectType) {
                continue;
            }

            // Validate that the user has permission to edit the record
            // before saving.
            if (Arc_Gen_TabSet_service.getPermissionToEdit(recordId) != TRUE_VAL) {
                throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
            }
        }
        final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];
        Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(ahaData, accHasAnalysis, String.valueOf(Arc_Gen_SaveGenericIRP.class.getName()));
        return JSON.serialize(
            new arce.Arc_Gen_wrpSave(true, Label.Arc_Gen_Generic_ErrorSumPersBR, listObject));
    }
}