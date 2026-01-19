/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SaveBusinessRisk
* @Author   Ricardo Almanza Angeles
* @Date     Created: 15/01/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages dyanmic form save for Business Risk.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-01-15 Ricardo Almanza Angeles
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_SaveBusinessRisk implements dyfr.Save_Interface {
    public String save(List<sObject> listObject) {
        Boolean succes=true;
        if(!listObject.isEmpty()) {
            Final set<String> arcAcc = new Set<String>();
            for(sObject obj : listObject) {
                String accHasId = String.valueOf(obj.get('Id'));

                // Validate that the user has permission to edit the record
                // before saving.
                if (Arc_Gen_TabSet_service.getPermissionToEdit(accHasId) != 'true') {
                    throw new AuraHandledException(Label.Arc_Gen_Generic_NotAllowed);
                }

                arcAcc.add(accHasId);
            }
            succes = Arc_Gen_PersistanceBR_Service.persistBR(new List<String>(arcAcc),listObject);
        }
        return JSON.serialize(new arce.Arc_Gen_wrpSave(succes,Label.Arc_Gen_Generic_ErrorSumPersBR,listObject));
    }
}