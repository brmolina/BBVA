/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidContractAppraisals_service
* @Author   Juan Manuel Perez Ortiz
* @Date     Created: 2020-11-06
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations
* ------------------------------------------------------------------------------------------------
* |2020-11-06 juanmanuel.perez.ortiz.contractor@bbva.com
*             Class creation.
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidContractAppraisals_service implements rrtm.RelatedManager_Interface {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Wrapper class
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
    * @Date     Created: 2020-11-06
    * --------------------------------------------------------------------------------------
    **/
    class Wrapper extends rrtm.RelatedRecord_WrapperValidation {}
    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates the info coming from contracts and appraisals table
    * --------------------------------------------------------------------------------------
    * @Author   juanmanuel.perez.ortiz.contractor@bbva.com
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
                    wrapper = validateInfo(mapObj,wrapper,ite);
                }
            }
        }
        return JSON.serialize(wrapper);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that validates completeness of the info
    --------------------------------------------------------------------------------
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @date 2020-11-06
    * @param Map mapObj with the record information, Wrapper with validation result and messages, Integer ite with line number
    * @return Wrapper with validation result and messages updated
    * @example public static Wrapper validateInfo(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite)
    **/
    private static Wrapper validateInfo(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite) {
        String hotelName = String.valueOf(mapObj.get('arce__gf_hotel_name__c'));
        String appraisalAmount = String.valueOf(mapObj.get('arce__appraisal_amount__c'));
        String lastAppraisal = String.valueOf(mapObj.get('arce__last_assessed_date__c'));
        String contractPeriod = String.valueOf(mapObj.get('arce__gf_htl_ownshp_ctrct_dur_number__c'));
        String contractExpiration = String.valueOf(mapObj.get('arce__gf_current_expiration_date__c'));
        String typeContract = String.valueOf(mapObj.get('arce__gf_hotel_contract_type_name__c'));
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(hotelName)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_HotelName, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(appraisalAmount)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_AppraisalValue, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(lastAppraisal)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_LastApprDate, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(contractPeriod)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_ContractPeriod, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(contractExpiration)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_ContractExpiration, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(typeContract)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_TypeContract, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        return strucWrapper;
    }

}