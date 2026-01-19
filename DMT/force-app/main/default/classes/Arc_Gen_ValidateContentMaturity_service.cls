/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_ContentMaturity_service
* @Author   Javier Soto Carrascosa
* @Date     Created: 2019-11-03
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations
* ------------------------------------------------------------------------------------------------
* |2019-11-03 javier.soto.carrascosa@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-06-29 juanignacio.hita.contractor@bbva.com
*             Created checkYearRepeated method, validates multiple records with same names and years
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateContentMaturity_service implements rrtm.RelatedManager_Interface {
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
    *-------------------------------------------------------------------------------
    * @description Method that validates completeness of the info
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-11-13
    * @param Map mapObj with the record information, Wrapper with validation result and messages, Integer ite with line number
    * @return Wrapper with validation result and messages updated
    * @example public static Wrapper validateInfo(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite)
    **/
    private static Wrapper validateInfo(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite) {
        String amount = String.valueOf(mapObj.get('arce__table_content_value__c'));
        String year = (String) mapObj.get('arce__table_content_year__c');
        String seeker = String.valueOf(mapObj.get('Seeker'));
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(amount)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Amount, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(year)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Year, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(seeker)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_SeekerMandatory, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        return strucWrapper;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description description Method that validates the info coming from maturity table
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hita.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param    List<Object> - lstRecords with records to validate
    * @return   JSON String with validation result and messages updated
    * @example static String beforeSaveData(List<Object> lstRecords)
    * --------------------------------------------------------------------------------------
    **/
    public static String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.validation = true;
        wrapper.msgInfo = '';

        Set<String> ahaIds = new Set<String>();

        if(!lstRecords.isEmpty()) {
            Integer ite = 0;
            final List<Map<String, Object>> lstMapObj = new List<Map<String, Object>>();
            final List<String> repeatYearName = new List<String>();
            for (Object obj : lstRecords) {
                String strJson = JSON.serialize(obj);
                Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(strJson);
                ite++;
                ahaIds.add((String) mapObj.get('arce__account_has_analysis_id__c'));
                wrapper = validateInfo(mapObj,wrapper,ite);
                final String repeatName = checkYearRepeated(lstMapObj, mapObj);
                if (repeatName != null) {
                    repeatYearName.add(repeatName);
                }
                lstMapObj.add(mapObj);
            }
            if (!repeatYearName.isEmpty()) {
                wrapper.msgInfo += String.format(Label.Arc_Gen_MaturityTable_InsertMultipleSameYears, repeatYearName);
                wrapper.validation = false;
            }
        }

        for (String ahaId : ahaIds) {
            if (Arc_Gen_TabSet_service.getPermissionToEdit(ahaId) != 'true') {
                wrapper.msgInfo += Label.Arc_Gen_Generic_NotAllowed;
                wrapper.validation = false;
            }
        }
        return JSON.serialize(wrapper);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Checks that no different records are used for the same year and name.
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor.contractor@bbva.com
    * @Date     Created: 2021-06-29
    * @param    List<Map<String, Object>> - lstMapObjects
    * @param    lstMap - List map records for maturity table
    * @return   String : string with name/year repeated
    * --------------------------------------------------------------------------------------
    **/
    private static String checkYearRepeated(List<Map<String, Object>> lstMapObjects, Map<String, Object> lstMap) {
        Boolean repeatRecord = false;
        String repeatStr = null; // NOSONAR
        Integer idx = 0;
        while (!repeatRecord && idx < lstMapObjects.size()) {
            final String seekerLst = String.valueOf(lstMapObjects[idx].get('Seeker'));
            final String yearTableLst = (String) lstMapObjects[idx].get('arce__table_content_year__c');
            final String seeker = String.valueOf(lstMap.get('Seeker'));
            final String yearTable = (String) lstMap.get('arce__table_content_year__c');
            if (seeker == seekerLst  && yearTable == yearTableLst) {
                repeatRecord = true;
                repeatStr = yearTableLst;
            }
            idx++;
        }
        return repeatStr;
    }
}