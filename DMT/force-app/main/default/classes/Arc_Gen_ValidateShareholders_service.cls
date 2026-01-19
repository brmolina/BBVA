/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Validate_Content
* @Author   Juan Ignacio Hita
* @Date     Created: 2019-10-27
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class for related records table manager validations
* ------------------------------------------------------------------------------------------------
* |2019-10-27 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             Api names modified with the correct name on business glossary
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-09 manuelhugo.castillo.contractor@bbva.com
*             modify complexity
* |2020-12-09 manuelhugo.castillo.contractor@bbva.com
*             fix null percent
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* |2022-05-18 juanignacio.hita.contractor@bbva.com
*             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateShareholders_service implements rrtm.RelatedManager_Interface {
    /**
        * @Description: integer with maxPercent
    */
    static Integer maxPercent = 100;
    /**
        * @Description: String with arce__third_participant_per__c
    */
    static final String PERCENT_FIELD = 'arce__third_participant_per__c';
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
    * @description Method that validates completeness of the info coming from Shareholders table
    --------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 2019-11-03
    * @param Map mapObj with the record information, Wrapper with validation result and messages, Integer ite with line number
    * @return Wrapper with validation result and messages updated
    * @example public static Wrapper validateInfo(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite)
    **/
    private static Wrapper validateInfo(Map<String, Object> mapObj, Wrapper strucWrapper, Integer ite) {
        final String percent = mapObj.get(PERCENT_FIELD) == null ? '' : String.valueOf(mapObj.get(PERCENT_FIELD));
        final String year = String.valueOf(mapObj.get('arce__shareholder_sponsor_year_id__c'));
        final String type = String.valueOf(mapObj.get('arce__shrhldr_financial_sponsor_type__c'));
        final String seeker = String.valueOf(mapObj.get('Seeker'));
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(percent)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_CompleteField_Per, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!validateFSInfo(type,year)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_ShareholdersFSVal, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        if(!arce.Arc_Gen_ValidateInfo_utils.isFilled(seeker)) {
            strucWrapper.msgInfo = strucWrapper.msgInfo + string.format(Label.Arc_Gen_SeekerMandatory, new List<String>{String.valueOf(ite)});
            strucWrapper.validation = false;
        }
        return strucWrapper;
    }
/**
*-------------------------------------------------------------------------------
* @description Method that validates the info coming from Shareholders table
--------------------------------------------------------------------------------
* @author juanignacio.hita.contractor@bbva.com
* @date 2019-10-27
* @param List<Object> lstRecords with records to validate
* @return JSON String with validation result and messages updated
* @example global static String beforeSaveData(List<Object> lstRecords)
**/
    public static String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.msgInfo = '';
        wrapper.validation = true;
        Decimal sumPercent = 0;
        final Set<String> arcAcc = new Set<String>();

        if(!lstRecords.isEmpty()) {
            Integer ite = 0;
            for (Object obj : lstRecords) {
                final String strJson = JSON.serialize(obj);
                ite++;
                final Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(strJson);
                arcAcc.add(String.valueOf(mapObj.get('arce__account_has_analysis_id__c')));
                final String percent = getPercent(mapObj);
                wrapper = validateInfo(mapObj,wrapper,ite);
                sumPercent += (percent == null) ? 0 : Decimal.valueOf(percent);
            }
        }
        if(!arcAcc.isEmpty()) {
            wrapper = validatePermission(arcAcc,wrapper);
        }
        if (sumPercent > maxPercent) {
            wrapper.msgInfo = wrapper.msgInfo + Label.Arc_Gen_Generic_ErrorSumPercent;
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
/**
*-------------------------------------------------------------------------------
* @description Method that contains the financial sponsor completeness logic
--------------------------------------------------------------------------------
* @author javier.soto.carrascosa@bbva.com
* @date 2019-11-03
* @param string type with the shareholder type information, string year with year information
* @return boolean true if completeness is ok, false if not
* @example private static boolean validateFSInfo(string type, string year)
**/
    private static boolean validateFSInfo(string type, string year) {
        boolean correctFS = false;
        if(type == '01' && arce.Arc_Gen_ValidateInfo_utils.isFilled(year)) {
            correctFS = true;
        }
        if ((type == '02' || type == '') && !arce.Arc_Gen_ValidateInfo_utils.isFilled(year)) {
            correctFS = true;
        }
        return correctFS;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that validate permissions
    --------------------------------------------------------------------------------
    * @author manuelhugo.castillo.contractor@bbva.com
    * @date 2020-12-09
    * @param Set<String> arcAcc - account has analysis id set
    * @param Wrapper wrapper - wrapper info
    * @return Wrapper - wrapper info permission
    * @example private static Wrapper validatePermission(Set<String> arcAcc)
    **/
    private static Wrapper validatePermission(Set<String> arcAcc, Wrapper wrapper) {
        // Check edit permission on Account_has_Analysis__c record.
        for (String accHasId : arcAcc) {
            if (Arc_Gen_TabSet_service.getPermissionToEdit(accHasId) != 'true') {
                wrapper.msgInfo += Label.Arc_Gen_Generic_NotAllowed;
                wrapper.validation = false;
            }
        }
        return wrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get percent
    --------------------------------------------------------------------------------
    * @author manuelhugo.castillo.contractor@bbva.com
    * @date 2020-12-09
    * @param Map<String, Object> mapObj - object with account has analysis info
    * @return String - percent
    * @example private static string getPercent(Map<String, Object> mapObj)
    **/
    private static String getPercent(Map<String, Object> mapObj) {
        return mapObj.get(PERCENT_FIELD) == null || mapObj.get(PERCENT_FIELD) == '' ? '0' : String.valueOf(mapObj.get(PERCENT_FIELD));
    }

}