/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_ValidateHotelProjectionInfo_Service
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-10-21
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Class for related records table manager validations
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-10-21 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  * |2020-11-12 mariohumberto.ramirez.contractor@bbva.com
  *             Fixed unhandled error that occurred when arce__gf_hotel_occupancy_per__c field was empty
  * |2022-05-18 juanignacio.hita.contractor@bbva.com
  *             Add warning suppression "UseSingleton" rule due to visibility problems between class and component.
  **/
@SuppressWarnings('sf:UseSingleton')
global class Arc_Gen_ValidateHotelProjInfo_Service implements rrtm.RelatedManager_Interface {
    /*
    *   @Description List of api names to validate
    */
    final static List<String> FIELD_API = new List<String>{'arce__gf_hotel_avg_daily_rate_amount__c','arce__gf_hotel_occupancy_per__c','arce__gf_rev_per_avail_room_amount__c','arce__gf_htl_gs_oper_profit_amount__c',
                                                            'arce__gf_debt_available_funds_amount__c','arce__gf_interest_expense_amount__c','arce__gf_loan_funded_amount__c','arce__gf_debt_svc_covrg_ratio_number__c','arce__gf_hotel_breakeven_occup_per__c'};
    /**
    * --------------------------------------------------------------------------------------
    * @Description Wrapper class
    * --------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-10-21
    * --------------------------------------------------------------------------------------
    **/
    class Wrapper extends rrtm.RelatedRecord_WrapperValidation {}

    /**
    * --------------------------------------------------------------------------------------
    * @Description Method that validates the info coming from hotel projection table
    * --------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-10-21
    * @param    List<Object> lstRecords for wrapper detail
    * @return   JSON String with validation result and messages updated
    * @example static String beforeSaveData(List<Object> lstRecords)
    * --------------------------------------------------------------------------------------
    **/
    public static String beforeSaveData(List<Object> lstRecords) {
        Wrapper wrapper = new Wrapper();
        wrapper.validation = true;
        wrapper.msgInfo = '';
        final Set<String> acchasIdLts = new Set<String>();
        Double percent = 0;
        if(!lstRecords.isEmpty()) {
            integer ite = 0;
            for (Object obj : lstRecords) {
                ite ++;
                final String strJson = JSON.serialize(obj);
                final Map<String, Object> mapObj = (Map<String, Object>)JSON.deserializeUntyped(strJson);
                if (mapObj.get('arce__gf_hotel_occupancy_per__c') != '') {
                    percent = Double.valueOf(mapObj.get('arce__gf_hotel_occupancy_per__c'));
                }
                acchasIdLts.add(String.valueOf(mapObj.get('arce__account_has_analysis_id__c')));
                if (isNotFilled(mapObj)) {
                    wrapper.validation = false;
                    wrapper.msgInfo += String.format(Label.Arc_Gen_FillEveryRecord, new List<String>{String.valueOf(ite)});
                } else if (hasBadEntries(mapObj)) {
                    wrapper.validation = false;
                    wrapper.msgInfo += String.format(Label.Arc_Gen_NoNegativeNumbers, new List<String>{String.valueOf(ite)});
                } else if (percent > 100) {
                    wrapper.validation = false;
                    wrapper.msgInfo += String.format(Label.Arc_Gen_MaxPercentAllowed, new List<String>{String.valueOf(ite)});
                }
            }
            if (validatePermToEdit(acchasIdLts) == false) {
                wrapper.validation = false;
                wrapper.msgInfo = Label.Arc_Gen_Generic_NotAllowed;
            }
        }
        return JSON.serialize(wrapper);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that validates if Map<String,Object> is filled
    --------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @Date Created: 2020-10-21
    * @param Map<String,Object> inputField with the Map information
    * @return boolean false if Map has information true if not
    * @example public static boolean isNotFilled(string inputField)
    **/
    public static boolean isNotFilled(Map<String,Object> mapObjinfo) {
        boolean retVal = false;
        List<String> listFields = new List<String>{'arce__gf_const_proj_year_number_type__c'};
        listFields.addAll(FIELD_API);
        for (String field: listFields) {
            if (mapObjinfo.get(field) == null || mapObjinfo.get(field) == '') {
                retVal = true;
            }
        }
        return retVal;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that validates if the field contains '-'
    --------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @Date Created: 2020-10-21
    * @param Map<String,Object> inputField with the Map information
    * @return boolean true if Map has '-' false if not
    * @example public static boolean hasBadEntries(string inputField)
    **/
    public static boolean hasBadEntries(Map<String,Object> mapObjret) {
        boolean hasValue = false;
        for (String field: FIELD_API) {
            if (String.valueOf(mapObjret.get(field)).contains('-')) {
                hasValue = true;
            }
        }
        return hasValue;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Method that validates if the user has permission to edit
    --------------------------------------------------------------------------------
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @Date Created: 2020-10-21
    * @param acchasIdLts - account has analyisis ids
    * @return boolean true if has permission to edit, false if not
    * @example validatePermToEdit(acchasIdLts)
    **/
    public static boolean validatePermToEdit(Set<String> acchasIdLts) {
        boolean hasPerm = true;
        for (String accHasId : acchasIdLts) {
            if (Arc_Gen_TabSet_service.getPermissionToEdit(accHasId) == 'false') {
                hasPerm = false;
                break;
            }
        }
        return hasPerm;
    }
}