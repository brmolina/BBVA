/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidateTablePermissions_service
* @Author   José Luis García Díaz <joseluis.garcia4.contractor@bbva.com>
* @Date     Created: 2020-03-09
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations
* ------------------------------------------------------------------------------------------------
* |2020-03-09 joseluis.garcia4.contractor@bbva.com
*             Class creation.
* |2020-03-20 joseluis.garcia4.contractor@bbva.com
*             Fixes class not being instantiable for dynamic creation in RRTM.
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_ValidateTablePermissions_service implements rrtm.RelatedManager_Interface {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Wrapper class
    * --------------------------------------------------------------------------------------
    * @Author   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-03-09
    * --------------------------------------------------------------------------------------
    **/
    class Wrapper extends rrtm.RelatedRecord_WrapperValidation {}

    /**
    *-------------------------------------------------------------------------------
    * @description Validates that the user has edit permission on the associated analysis.
    --------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 2020-03-09
    * @param lstRecords list of added records
    * @return the serialized wrapper validation object.
    **/
    public String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.validation = true;
        wrapper.msgInfo = '';

        // Fetch ID of Account_has_analysis__c record.
        if (lstRecords != null && !lstRecords.isEmpty()) {
            Map<String, Object> mapObj = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(lstRecords[0]));
            String ahaId = (String) mapObj.get('arce__account_has_analysis_id__c');

            if (Arc_Gen_TabSet_service.getPermissionToEdit(ahaId) != 'true') {
                wrapper.msgInfo += Label.Arc_Gen_Generic_NotAllowed;
                wrapper.validation = false;
            }
        }

        return JSON.serialize(wrapper);
    }
}