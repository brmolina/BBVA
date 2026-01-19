/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidateAnalysisCategory_Service
* @Author   Moises Martinez Dominguez
* @Date     Created: 2020-11-06
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations in Analysis Category
* ------------------------------------------------------------------------------------------------
* |2020-11-06 moises.martinez.dominguez.contractor@bbva.com
*             Class creation.
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateAnalysisCategory_Service implements rrtm.RelatedManager_Interface {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Wrapper class
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * --------------------------------------------------------------------------------------
    **/
    class Wrapper extends rrtm.RelatedRecord_WrapperValidation {}
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates the info coming from main banks table
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param    List<Object> lstRecords for wrapper detail
    * @return   JSON String with validation result and messages updated
    * @example static String beforeSaveData(List<Object> lstRecords)
    * --------------------------------------------------------------------------------------
    **/
    public static String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.validation = true;
        wrapper.msgInfo = '';
        if(!lstRecords.isEmpty()) {
            if(lstRecords.size() > 100) {
                wrapper.validation = false;
                wrapper.msgInfo = Label.Arc_Gen_MaxRecordsTable;
            } else {
                Integer ite = 0;
                for (Object obj : lstRecords) {
                    String strJson = JSON.serialize(obj);
                    ite++;
                    Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(strJson);
                    wrapper = validateFields(mapObj,wrapper,ite);
                }
            }
        }
        return JSON.serialize(wrapper);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description beforsavedata method
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * @param Map mapObj with the record information
    * @param Wrapper with validation result and messages
    * @param Integer ite with line number
    * @return Wrapper with validation result and messages updated
    * @example public static Wrapper validateInfo(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite)
    * --------------------------------------------------------------------------------------
    **/
    public static Wrapper validateFields(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite) {
        final String category = String.valueOf(mapObj.get('arce__gf_hotel_category_type__c'));
        final String percent = String.valueOf(mapObj.get('arce__gf_hotel_occupancy_per__c'));
        final String avgAmount = String.valueOf(mapObj.get('arce__gf_hotel_avg_daily_rate_amount__c'));
        final String revAmount = String.valueOf(mapObj.get('arce__gf_rev_per_avail_room_amount__c'));
        if (!arce.Arc_Gen_ValidateInfo_utils.isFilled(category)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Category, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
                }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(percent)) {
            if (Double.valueOf(mapObj.get('arce__gf_hotel_occupancy_per__c')) > 100) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_MaxPercentAllowed, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        } else {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Per, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if (!arce.Arc_Gen_ValidateInfo_utils.isFilled(avgAmount)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Amount, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if (!arce.Arc_Gen_ValidateInfo_utils.isFilled(revAmount)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Amount, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        return strucWrapper;
    }
}