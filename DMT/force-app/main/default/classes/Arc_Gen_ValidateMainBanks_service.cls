/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidateMainBanks_service
* @Author   Juan Ignacio Hita
* @Date     Created: 2019-10-27
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations in Maing Banks
* ------------------------------------------------------------------------------------------------
* |2019-10-27 juanignacio.hita.contractor@bbva.com@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateMainBanks_service implements rrtm.RelatedManager_Interface {
    /**
        * @Description: integer with maxPercent
    */
    static Integer maxPercent = 100;
    /**
    * --------------------------------------------------------------------------------------
    * @Description Wrapper class
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hita.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * --------------------------------------------------------------------------------------
    **/
    class Wrapper extends rrtm.RelatedRecord_WrapperValidation {}
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates the info coming from main banks table
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hita.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param    List<Object> lstRecords for wrapper detail
    * @return   JSON String with validation result and messages updated
    * @example static String beforeSaveData(List<Object> lstRecords)
    * --------------------------------------------------------------------------------------
    **/
    public static String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.validation = true;
        wrapper.msgInfo = '';
        Decimal sumPercent = 0;
        final Set<String> ahaIds = new Set<String>();

        if(!lstRecords.isEmpty()) {
            Integer ite = 0;
            for (Object obj : lstRecords) {
                final String strJson = JSON.serialize(obj);
                ite++;
                final Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(strJson);

                ahaIds.add((String) mapObj.get('arce__account_has_analysis_id__c'));

                final String percent = String.valueOf(mapObj.get('arce__entity_quota_share_per__c'));
                final String entityName = String.valueOf(mapObj.get('arce__entity_name__c'));

                if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(entityName)) {
                    wrapper.msgInfo += string.format(Label.Arc_Gen_CompleteField_Name, new List<String>{String.valueOf(ite)});
                    wrapper.validation = false;
                }
                if(arce.Arc_Gen_ValidateInfo_utils.isFilled(percent)) {
                    sumPercent += Decimal.valueOf(percent);
                } else {
                    wrapper.msgInfo += string.format(Label.Arc_Gen_CompleteField_Per, new List<String>{String.valueOf(ite)});
                    wrapper.validation = false;
                }

            }
        }

        for (String ahaId : ahaIds) {
            if (Arc_Gen_TabSet_service.getPermissionToEdit(ahaId) != 'true') {
                wrapper.msgInfo += Label.Arc_Gen_Generic_NotAllowed;
                wrapper.validation = false;
            }
        }
        if (sumPercent > maxPercent) {
            wrapper.msgInfo = Label.Arc_Gen_Generic_ErrorSumPercent;
            wrapper.validation = false;
        }
        return JSON.serialize(wrapper);
    }

}