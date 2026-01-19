/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_ModRenArce_Helper
  * @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
  * @Date     Created: 2020-08-04
  * @Group    ARCE
  * ------------------------------------------------------------------------------------------------
  * @Description Helper class to control all the modification and renovation logic of a ARCE
  * ------------------------------------------------------------------------------------------------
  * @Changes
  * |2020-08-04 mariohumberto.ramirez.contractor@bbva.com
  *             Class Creation
  * |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
  *             Added arce. namespace to all classes that are now in the arce-dependencies package
  * |2020-09-24 eduardoefrain.hernandez.contractor@bbva.com
  *             Update associateAccHasAn2Arce method parameters
  * |2020-10-13 eduardoefrain.hernandez.contractor@bbva.com
  *             Update error management
  * |2021-03-11 juanmanuel.perez.ortiz.contractor@bbva.com
  *             Add parameter 'data' in associateAccHasAn2Arce, compareStructures methods
  * |2021-08-06 juanignacio.hita.contractor@bbva.com
  *             Removes arce__last_approved_amount__c field in the initialization limits with zero value
  * |2021-10-28 francisco.munoz.torres.contractor@@bbva.com
  *             Check if isHolding map is null - GADRDCDE-2488
  * |2021-12-23 francisco.munoz.torres.contractor@bbva.com
  *             Creation of associateRecordsFFSS2AHA
  **/
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount')
public without sharing class Arc_Gen_ModRenArce_Helper implements Arc_Gen_ModRen_Interface {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-08-04
    * @param void
    * @return void
    * @example Arc_Gen_ModRenArce_Helper help = new Arc_Gen_ModRenArce_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ModRenArce_Helper() {

    }
    /**
    * @Description: String with the participant number
    */
    private static Boolean showErrorLog;
    /**
    * @Description: static logic that sets participantNumber
    */
    static {
        final List<arce__Arce_Config__mdt> showErrorsConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ShowTraceErrorLogs');
        showErrorLog = Boolean.valueOf(showErrorsConfig.get(0).arce__Value1__c);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description retrieves a wrapper (Arc_Gen_CloneWrapper) with all the objects
    *              copied from the ARCE to renew or modify.
    *-------------------------------------------------------------------------------
    * @date 04/05/2020
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @param String analysisId - Analysis Id
    * @param String modRenVar - Justificacion value for setting in ARCE name or Renovation code
    * @return Arc_Gen_CloneWrapper
    * @example  public static Arc_Gen_CloneWrapper getRelatedRecordsArce(String analysisId) {
    */
    public static Arc_Gen_CloneWrapper getRelatedRecordsArce(String analysisId, String modRenVar) {
        Arc_Gen_CloneWrapper responseWrap = new Arc_Gen_CloneWrapper();
        final Arc_Gen_ModRen_Interface classLocModRen = getModRenSelectedClass();
        try {
            responseWrap = classLocModRen.getRelatedRecordsArce(analysisId, modRenVar);
        } catch(Exception ex) {
            final String errorMsg = showErrorLog ? ex.getMessage() + arce.Arc_Gen_Constants.HYPHEN + ex.getStackTraceString() : Label.Arc_Gen_ApexCallError;
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
        return responseWrap;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description clone all the information stored in Arc_Gen_CloneWrapper
    *              and retrieves the cloned records
    *-------------------------------------------------------------------------------
    * @date 04/05/2020
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @param Arc_Gen_CloneWrapper records
    * @return Arc_Gen_CloneWrapper
    * @example  public static Arc_Gen_CloneWrapper cloneRecords(Arc_Gen_CloneWrapper records){
    */
    public static Arc_Gen_CloneWrapper cloneRecords(Arc_Gen_CloneWrapper records, String modRenVar) {
        Arc_Gen_CloneWrapper responseWrap = new Arc_Gen_CloneWrapper();
        final Arc_Gen_ModRen_Interface classLocModRen = getModRenSelectedClass();
        try {
            responseWrap = classLocModRen.cloneRecords(records, modRenVar);
        } catch(Exception ex) {
            final String errorMsg = showErrorLog ? ex.getMessage() + arce.Arc_Gen_Constants.HYPHEN + ex.getStackTraceString() : Label.Arc_Gen_ApexCallError;
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
        return responseWrap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description sets and associates all account has analysis records that
    *              were previously cloned to the object Analysis
    *-------------------------------------------------------------------------------
    * @date 2020-08-04
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param response - Arc_Gen_CloneWrapper
    * @param customerRelation - arce relation type
    * @param emptyFFSS - id of the empty ffss
    * @return List<arce__Account_has_Analysis__c> - account has analysis records
    * @example   associateAccHasAn2Arce(response, selectedSector)
    *-------------------------------------------------------------------------------
    */
    public static List<arce__Account_has_Analysis__c> associateAccHasAn2Arce(Arc_Gen_CloneWrapper response, String customerRelation, Boolean persistanceStatus, Map<String, String> data) {
        List<arce__Account_has_Analysis__c> accHasAnLts = new List<arce__Account_has_Analysis__c>();
        final Arc_Gen_ModRen_Interface classLocModRen = getModRenSelectedClass();
        try {
            accHasAnLts = classLocModRen.associateAccHasAn2Arce(response, customerRelation, persistanceStatus, data);
        } catch(Exception ex) {
            final String errorMsg = showErrorLog ? ex.getMessage() + arce.Arc_Gen_Constants.HYPHEN + ex.getStackTraceString() : Label.Arc_Gen_ApexCallError;
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
        return accHasAnLts;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description associates all previously cloned objects to all new account has analysis objects
    *-------------------------------------------------------------------------------
    * @date 2020-08-04
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param response - Arc_Gen_CloneWrapper
    * @param mapaha - Map<String,arce__Account_has_Analysis__c>
    * @param String modRenVar - Justificacion value for setting in ARCE name or Renovation code
    * @return List<arce__Account_has_Analysis__c> - account has analysis records
    * @example   associateRecords2AccHasAn(response, mapaha, modRenVar)
    *-------------------------------------------------------------------------------
    */
    public static String associateRecords2AccHasAn(Arc_Gen_CloneWrapper response, Map<String,arce__Account_has_Analysis__c> mapaha, String modRenVar) {
        final String arceId;
        final Arc_Gen_ModRen_Interface classLocModRen = getModRenSelectedClass();
        try {
            arceId = classLocModRen.associateRecords2AccHasAn(response, mapaha, modRenVar);
        } catch(Exception ex) {
            final String errorMsg = showErrorLog ? ex.getMessage() + arce.Arc_Gen_Constants.HYPHEN + ex.getStackTraceString() : Label.Arc_Gen_ApexCallError;
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
        return arceId;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description manage the traceability messagge
    *-------------------------------------------------------------------------------
    * @date 2020-08-04
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param arceId - id of the arce analysis
    * @param String modRenVar - Justificacion value for setting in ARCE name or Renovation code
    * @return void
    * @example   manageTraceability(arceId, modRenVar)
    *-------------------------------------------------------------------------------
    */
    public static void manageTraceability(String arceId, String modRenVar) {
        final Arc_Gen_ModRen_Interface classLocModRen = getModRenSelectedClass();
        try {
            classLocModRen.manageTraceability(arceId, modRenVar);
        } catch(Exception ex) {
            final String errorMsg = showErrorLog ? ex.getMessage() + arce.Arc_Gen_Constants.HYPHEN + ex.getStackTraceString() : Label.Arc_Gen_ApexCallError;
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Get account ids from group structure
    *-------------------------------------------------------------------------------
    * @date 05/05/2020
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @param  List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts
    * @return Map<Id,String>
    * @example public static String getAccountIdsFromGE(List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts) {
    */
    public static Map<Id,List<String>> getAccountIdsFromGE(List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts) {
        final Map<Id,List<String>> accIdsFromGE = new Map<Id,List<String>>();
        for (arce.Arc_Gen_Account_Wrapper accWrapper: accountsWrapLts) {
            accIdsFromGE.put(accWrapper.accId, new List<String>{accWrapper.Name,accWrapper.accNumber});
        }
        return accIdsFromGE;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method for comparing structure of previous analysis with group structure
    *-------------------------------------------------------------------------------
    * @date 05/05/2020
    * @author juanmanuel.perez.ortiz.contractor@bbva.com
    * @param  Map<Id,String> accIdsFromGE - Map of current account has analysis records
    * @param  Map<Id,String> prevArceAccIds - Map of previous account has analysis records
    * @param  String arceId - Id fro Analysis ARCE
    * @param  String emptyFFSS - Id for arce__financial_statement__c record
    * @return void
    * @example public static void compareStructures(Set<Id> accIdsFromGE, Map<Id,String> accIdsFromPreviousArce, String arceId) {
    */
    public static void compareStructures(Map<Id,List<String>> accIdsFromGE, Map<Id,String> prevArceAccIds, String arceId, Map<String, String> data) {
        final String isHolding = (String) data.get('isHolding');
        final String accountswraper = (String)data.get('accountswraper');
        final List<arce.Arc_Gen_Account_Wrapper> accountsWrapLts = (List<arce.Arc_Gen_Account_Wrapper>) JSON.deserialize(accountswraper, List<arce.Arc_Gen_Account_Wrapper>.Class);
        final Map<String, Boolean> mapIsHolding = (Map<String, Boolean>) JSON.deserialize(isHolding, Map<String, Boolean>.Class);
        String mName = ''; //Matrix Name
        String mDocNumber = ''; //Matrix CIF
        if(mapIsHolding == null) {
            mapIsHolding = new Map<String, Boolean>();
        }
        for (arce.Arc_Gen_Account_Wrapper acw : accountsWrapLts) {
            if (mapIsHolding.get(acw.accNumber) != null && mapIsHolding.get(acw.accNumber)) {
                mName = acw.Name;
                mDocNumber = acw.docNumber;
            }
        }
        final List < arce__rating_variables_detail__c > ratingVariables = new List <arce__rating_variables_detail__c> ();
        final List<arce__Account_has_Analysis__c> listNewAccHasAn = new List<arce__Account_has_Analysis__c>();
        //We compare if the accounts of the new group structure exist in the previous analysis
        for(Id accId : accIdsFromGE.keySet()) {
            //If not exist account id in the previous structure , create new account has analysis
            if(!prevArceAccIds.containsKey(accId)) {
                final Boolean holdingValue = mapIsHolding.get(accIdsFromGE.get(accId)[1]);
                final arce__Account_has_Analysis__c newAccHasAn = new arce__Account_has_Analysis__c();
                newAccHasAn.arce__Analysis__c = arceId;
                newAccHasAn.arce__Customer__c = accId;
                newAccHasAn.arce__InReview__c = false;
                newAccHasAn.arce__anlys_wkfl_sbanlys_status_type__c = '1';
                newAccHasAn.arce__analysis_template_id__c = '1';
                newAccHasAn.arce__group_asset_header_type__c = '2';
                newAccHasAn.arce__group_risk_detail_part_name__c = accIdsFromGE.get(accId)[0];
                newAccHasAn.arce__gf_matrix_house_name__c = Arc_Gen_NewAnalysis_Service.emptyIfNull(mName);
                newAccHasAn.arce__gf_matrix_house_cif_id__c = Arc_Gen_NewAnalysis_Service.emptyIfNull(mDocNumber);
                newAccHasAn.arce__main_subsidiary_ind_type__c = Arc_Gen_NewAnalysis_Service.getIsHolding(holdingValue);
                listNewAccHasAn.add(newAccHasAn);
            }
        }

        Arc_Gen_ModificationArce_Data.insertRecords(listNewAccHasAn);

        for (arce__Account_has_Analysis__c newAHAS:  listNewAccHasAn) {
            ratingVariables.add(arce.Arc_Gen_Rating_Var_detail_Data.setEmptyRatingVariable(newAHAS.Id));
        }
        //Insert new account has analysis rating variables
        arce.Arc_Gen_Rating_Var_detail_Data.insertRatingVariables(ratingVariables);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Associate Limits Exposure parent with childs
    *-------------------------------------------------------------------------------
    * @Date 12-06-2020
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param Arc_Gen_CloneWrapper records - wrapper with the records to update
    * @param mapaha - map with the relation info to update
    * @param modRenVar - renovation/Justification code
    * @return void
    * @example updateLimitsExposureData(records, mapaha, modRenVar)
    *-------------------------------------------------------------------------------
    */
    public static void updateLimitsExposureData(Arc_Gen_CloneWrapper records, Map<String,arce__Account_has_Analysis__c> mapaha, String modRenVar) {
        final Set<Id> accHasAnIdLts = new Set<Id>();
        Id idAha;
        for(arce__limits_exposures__c limExp: records.lsLimExp) {
            if(String.isNotBlank( limExp.arce__account_has_analysis_id__c)) {
                idAha = mapaha.get(limExp.arce__account_has_analysis_id__c ).id;
                limExp.arce__account_has_analysis_id__c = idAha;
                limExp.arce__last_approved_amount__c = limExp.arce__current_proposed_amount__c;
                limExp.arce__curr_approved_commited_amount__c = 0;
                limExp.arce__curr_apprv_uncommited_amount__c = 0;
                limExp.arce__current_formalized_amount__c = 0;
                limExp.arce__outstanding_amount__c = 0;
                limExp.arce__current_approved_amount__c = 0;
                if (modRenVar == arce.Arc_Gen_Constants.RENOVATION_CODE) {
                    limExp.arce__current_proposed_amount__c = 0;
                }
                accHasAnIdLts.add(idAha);
            }
        }
        arce.Arc_Gen_LimitsExposures_Data.updateExposureData(records.lsLimExp);
        associateRecords(accHasAnIdLts, records.lsLimExp, modRenVar);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Associate Limits Exposure parent with childs
    *-------------------------------------------------------------------------------
    * @Date 12-06-2020
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param accHasAnIdLts - id of the account has analysis object
    * @param limExpDataLts - Limit exposure records
    * @param modRenVar - renovacion/justification code
    * @return void
    * @example associateRecords(accHasAnIdLts, limExpDataLts, modRenVar)
    *-------------------------------------------------------------------------------
    */
    public static void associateRecords(Set<Id> accHasAnIdLts, List<arce__limits_exposures__c> limExpDataLts, String modRenVar) {
        final Map<Id,arce__limits_typology__c> limitTypoMap = Arc_Gen_LimitsTypologies_Data.getTypologyMap();
        final Map<Id,Map<String,arce__limits_exposures__c>> limExpStrucMap = arce.Arc_Gen_LimitsExposures_Data.getLimExpByAccHasMap(accHasAnIdLts, modRenVar);
        for (Id accHasId: accHasAnIdLts) {
            for (arce__limits_exposures__c limExp2: limExpDataLts) {
                final Boolean evTypologies = evaluateTypologies(limExp2.arce__Product_id__c,limExp2.arce__account_has_analysis_id__c,accHasId,limitTypoMap.get(limExp2.arce__limits_typology_id__c));
                if (String.isBlank(limExp2.arce__Product_id__c) && limitTypoMap.get(limExp2.arce__limits_typology_id__c).arce__risk_typology_level_type__c == '2' && limExp2.arce__account_has_analysis_id__c == accHasId) {
                    limExp2.arce__limits_exposures_parent_id__c = limExpStrucMap.get(accHasId).get(limitTypoMap.get(limExp2.arce__limits_typology_id__c).arce__risk_typology_parent_id__c).Id;
                } else if (evTypologies) {
                    limExp2.arce__limits_exposures_parent_id__c = limExpStrucMap.get(accHasId).get(limExp2.arce__limits_exposures_parent_id__r.arce__limits_typology_id__c).Id;
                }
            }
        }
        arce.Arc_Gen_LimitsExposures_Data.updateExposureData(limExpDataLts);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Evaluate typologie
    *-------------------------------------------------------------------------------
    * @Date 12-06-2020
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param productId - id of the product
    * @param acchasId1 - id of the acchasanalysis
    * @param acchasId2 - id of the acchasanalysis
    * @param typologie - Limit typology record
    * @return Boolean
    * @example evaluateTypologies(productId, acchasId1, acchasId2, typologie)
    *-------------------------------------------------------------------------------
    */
    public static Boolean evaluateTypologies(String productId, String acchasId1, String acchasId2, arce__limits_typology__c typologie) {
        return String.isNotBlank(productId) && acchasId1 == acchasId2 && typologie != null;
    }
    /**
    * ---------------------------------------------------------------------------------------------------
    * @Description - Method to find the class with the interface Arc_Gen_ModRen_Interface
    * ---------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 12-06-2020
    * @return   Arc_Gen_ModRen_Interface
    * @example getAccLocatorClass(getModRenSelectedClass)
    * ---------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_ModRen_Interface getModRenSelectedClass() {
        final List<arce__Arce_Config__mdt> lstArceConfig = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ModRenInterface');
        final System.Type objType = Type.forName(lstArceConfig.get(0).arce__Value1__c);
        final Arc_Gen_ModRen_Interface classLocModRen = (Arc_Gen_ModRen_Interface)objType.newInstance();
        return classLocModRen;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description associates all previously cloned FFSS objects to correct AHA
    *-------------------------------------------------------------------------------
    * @date 2021-12-22
    * @author francisco.munoz.torres.contractor@bbva.com
    * @param response - Arc_Gen_CloneWrapper
    * @param mapaha - Map<String,arce__Account_has_Analysis__c>
    * @param String modRenVar - Justificacion value for setting in ARCE name or Renovation code
    * @return List<arce__Account_has_Analysis__c> - account has analysis records
    * @example   associateRecordsFFSS2AHA(response, mapaha, modRenVar)
    *-------------------------------------------------------------------------------
    */
    public static void associateRecordsFFSS2AHA(Arc_Gen_CloneWrapper response, Map<String,arce__Account_has_Analysis__c> mapaha, String modRenVar) {
        final Arc_Gen_ModRen_Interface classLocModRen = getModRenSelectedClass();
        try {
            classLocModRen.associateRecordsFFSS2AHA(response, mapaha, modRenVar);
        } catch(Exception ex) {
            final String errorMsg = showErrorLog ? ex.getMessage() + arce.Arc_Gen_Constants.HYPHEN + ex.getStackTraceString() : Label.Arc_Gen_ApexCallError;
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(errorMsg);
        }
    }
}