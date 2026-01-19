/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidateAnalysisPerDate_Service
* @Author   Moises Martinez Dominguez
* @Date     Created: 2020-11-06
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations in Analysis Date or Period
* ------------------------------------------------------------------------------------------------
* |2020-11-06 moises.martinez.dominguez.contractor@bbva.com
*             Class creation.
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateAnalysisPerDate_Service implements rrtm.RelatedManager_Interface {
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
        final String initialDate = String.valueOf(mapObj.get('arce__gf_period_start_date__c'));
        final String endDate = String.valueOf(mapObj.get('arce__gf_period_end_date__c'));
        final String percent = String.valueOf(mapObj.get('arce__gf_hotel_occupancy_per__c'));
        final String avgAmount = String.valueOf(mapObj.get('arce__gf_hotel_avg_daily_rate_amount__c'));
        final String revpar = String.valueOf(mapObj.get('arce__gf_rev_per_avail_room_amount__c'));

        recordDates(initialDate, endDate, strucWrapper, ite);
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
        if (!arce.Arc_Gen_ValidateInfo_utils.isFilled(revpar)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Amount, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        return strucWrapper;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description recordDates method
    * --------------------------------------------------------------------------------------
    * @Author   moises.martinez.dominguez.contractor@bbva.com
    * @Date     Created: 2020-11-20
    * @param String initialDate with the initial date
    * @param String endDate with the end date
    * @param Wrapper with validation result and messages
    * @param Integer ite with line number
    * @return Wrapper with validation result and messages updated
    * @example public static Wrapper recordDates (String initialDate, String endDate, Wrapper strucWrapper, Integer ite)
    * --------------------------------------------------------------------------------------
    **/
    public static Wrapper recordDates (String initialDate, String endDate, Wrapper strucWrapper, Integer ite) {
        if (!arce.Arc_Gen_ValidateInfo_utils.isFilled(initialDate)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_StartDate, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
                }
        if (!arce.Arc_Gen_ValidateInfo_utils.isFilled(endDate)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_EndDate, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(initialDate) && arce.Arc_Gen_ValidateInfo_utils.isFilled(endDate) && Date.valueOf(initialDate) > Date.valueOf(endDate)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_ChangeDate, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }

        return strucWrapper;
    }
}