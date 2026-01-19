/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Content
* @Author   Juan Ignacio Hita
* @Date     Created: 2019-10-27
* @Group    ARCE

* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations
* ------------------------------------------------------------------------------------------------
* |2019-10-27 juanignacio.hita.contractor@bbva.com@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateThirdParticipant_service implements rrtm.RelatedManager_Interface {
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
        final String percent = String.valueOf(mapObj.get('arce__third_participant_per__c'));
        final String seeker = String.valueOf(mapObj.get('Seeker'));
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(percent)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Per, new List<String>{String.valueOf(ite)});
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
    * @Description Method that validates the info coming from some tables
    * --------------------------------------------------------------------------------------
    * @Author   juan.ignacion.hita.contractor@bbva.com
    * @Date     Created: 2019-11-04
    * @param    List<Object> lstRecords for wrapper detail
    * @return   String with the info of the validation class
    * @example static String beforeSaveData(List<Object> lstRecords)
    * --------------------------------------------------------------------------------------
    **/
    public static String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.validation = true;
        wrapper.msgInfo = '';
        Decimal sumPercent = 0;
        final Set<String> arcAcc = new Set<String>();

        if(!lstRecords.isEmpty()) {
            Integer ite = 0;
            for (Object obj : lstRecords) {
                final String strJson = JSON.serialize(obj);
                ite++;

                final Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(strJson);
                arcAcc.add(String.valueOf(mapObj.get('arce__account_has_analysis_id__c')));
                final String percent = String.valueOf(mapObj.get('arce__third_participant_per__c'));
                wrapper = validateInfo(mapObj,wrapper,ite);
                sumPercent += (percent == null) ? 0 : Decimal.valueOf(percent);
            }
        }

        // Check edit permission on Account_has_Analysis__c record.
        for (String accHasId : arcAcc) {
            if (Arc_Gen_TabSet_service.getPermissionToEdit(accHasId) != 'true') {
                wrapper.msgInfo += Label.Arc_Gen_Generic_NotAllowed;
                wrapper.validation = false;
            }
        }

        if (sumPercent > maxPercent) {
            wrapper.msgInfo += Label.Arc_Gen_Generic_ErrorSumPercent;
            wrapper.validation = false;
        }
        if(wrapper.validation) {
            final Boolean succesPers=true;
            //succesPers = Arc_Gen_PersistanceBR_Service.persistBR(new List<String>(arcAcc),new List<sObject>());
            if(!succesPers) {
                wrapper.msgInfo = wrapper.msgInfo + Label.Arc_Gen_Generic_ErrorSumPersBR;
                wrapper.validation = succesPers;
            }
        }
        return JSON.serialize(wrapper);
    }

}