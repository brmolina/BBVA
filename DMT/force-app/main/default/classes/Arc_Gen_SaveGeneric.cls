/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveGeneric
* @Author   José Luis García <joseluis.garcia4.contractor@bbva.com>
* @Date     Created: 26/02/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that validates that the user saving a dynamic form tab on the ARCE analysis
* has edit access to the analysis. This class is only used for validating permissions on tabs that
* do not implement custom save logic.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-02-26 José Luis García <joseluis.garcia4.contractor@bbva.com>
*             Class creation.
* |2022-06-03 juanignacio.hita.contractor@bbva.com
*             Add checkChangesQualQuestion validation
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveGeneric implements dyfr.Save_Interface {
    public String save(List<sObject> listObject) {
        for(sObject obj : listObject) {
            String recordId = String.valueOf(obj.get('Id'));

            // Only validate if what is being saved is an Account_has_analysis__c
            // record.
            if (Id.valueOf(recordId).getSobjectType() != arce__Account_has_Analysis__c.SObjectType) {
                continue;
            }

            // Validate that the user has permission to edit the record
            // before saving.
            if (Arc_Gen_TabSet_service.getPermissionToEdit(recordId) != 'true') {
                throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
            }
        }
        final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
        final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];
        Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(ahaData, accHasAnalysis, String.valueOf(Arc_Gen_SaveGeneric.class.getName()));
        return JSON.serialize(
            new arce.Arc_Gen_wrpSave(true, Label.Arc_Gen_Generic_ErrorSumPersBR, listObject));
    }
}