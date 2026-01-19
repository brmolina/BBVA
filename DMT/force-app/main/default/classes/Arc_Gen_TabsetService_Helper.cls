/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TabsetService_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 24/06/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Helper class that manages the tabs to be shown in the ARCE.
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-07-16 mariohumberto.ramirez.contractor@bbva.com
*             Add new method hideDynFormSection.
* |2019-07-23 mariohumberto.ramirez.contractor@bbva.com
*             Add new JSON param DevTemplate
* |2019-07-29 mariohumberto.ramirez.contractor@bbva.com
*             Add new method changeArceStateHelper.
*             Add new constants PREPARING_ANALYSIS, ARCE_PREPARED, CONTRASTING_ANALYSIS, IN_PREPARATION
*             IN_SANCTION
* |2019-08-07 mariohumberto.ramirez.contractor@bbva.com
*             Deleted method generateWrapperTabSet.
*             Change method generateListWrapperTab in order to use the completeness calculation
*             class that has by default the dynamic form component.
*             Add new constant "ONE"
* |2019-08-23 mariohumberto.ramirez.contractor@bbva.com
*             Deleted method hideDynFormSection.
* |2019-10-03 mariohumberto.ramirez.contractor@bbva.com
*             Fixed param to call getRatingStatus method from arce.Arc_Gen_AccHasAnalysis_Data class
* |2019-10-25 mariohumberto.ramirez.contractor@bbva.com
*             Added new method update2zerohidenTypologies
* |2019-12-18 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add new static variables and modified changeArceStateHelper method
* |2020-01-20 juanmanuel.perez.ortiz.contractor@bbva.com
*             Modified logic in policies tab visibility in method called generateListWrapperTabget
* |2020-01-20 mariohumberto.ramirez.contractor@bbva.com
*             Added new method OutstandingFromTabClient()
* |2020-03-30 eduardoefrain.hernandez.contractor@bbva.com
*             Add setWrapperToConvert method
* |2020-03-30 mariohumberto.ramirez.contractor@bbva.com
*             Change reference to tabDevName instead tabName in the method generateListWrapperTab
* |2020-04-28 javier.soto.carrascosa@bbva.com
*             Add sanction condition in changeArceStateHelper method
* |2020-05-27 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic to hide policies tab in chrome group
* |2020-05-28 cesaroctavio.villanueva.cebal@bbva.com
*             Removed Project Finance from deprecated typologies
* |2020-05-28 ricardo.almanza.contractor@bbva.com
*             Completion Financial Risk
* |2020-06-02 cesaroctavio.villanueva.cebal@bbva.com
*             Added update to subsidiaries in case the magnitude unit is updated
* |2020-06-09 cesaroctavio.villanueva.cebal@bbva.com
*             Removed limit update
* |2020-06-22 mariohumberto.ramirez.contractor@bbva.com
*             Added validateVisibility method
* |2020-06-22 javier.soto.carrascosa@bbva.com
*             Modified logic to read from td/bu indicator
*             Add validateVisibility method
* |2020-08-12 antonio.munoz.perez.contractor@bbva.com
*             TOP DOWN Completion validations
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-26 joseluis.garcia4.contractor@bbva.com
*             Handle empty TDBU indicator for historical ARCEs.
* |2021-01-21 saimassimilianno.jordana.contractor@bbva.com
*              Modified all getAccountInfoById calls to return the correct accountWrapper if customAccount exists.
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*             Change references to Arc_Gen_RatingGlobal_* classes.
* |2021-04-12 brauliobaruchs.sanpedro.contractor@bbva.com
*             Add type product politics in list TYPO_DEPRECATED
* |2021-04-22 juanignacio.hita.contractor@bbva.com
*             Remove TP_0006 in TYPO_DEPRECATED constant
* |2021-05-27 juanignacio.hita.contractor@bbva.com
*             Add condition in generateListWrapperTab method for the tab 500 shows always.
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_TabsetService_Helper {
    /**
        * @Description: string with the value of ready status for response
    */
    static final string RESP_READY = 'Ready';
    /**
        * @Description: string with the value of preparing analysis status
    */
    static final string PREPARING_ANALYSIS = '02';
    /**
        * @Description: string with the value of preparing analysis status
    */
    static final string PENDING_SANCTION = '08';
    /**
        * @Description: string with the value of preparing analysis status
    */
    static final string ARCE_PREPARED = '03';
    /**
        * @Description: string with value of contrasting analysis status
    */
    static final string CONTRASTING_ANALYSIS = '04';
    /**
        * @Description: string with value of contrasting analysis status
    */
    static final string IN_PREPARATION = '1';
    /**
        * @Description: string with value of contrasting analysis status
    */
    static final string IN_SANCTION = '2';
    /**
        * @Description: integer with value 1
    */
    static final integer ONE = 1;
    /**
        * @Description: List of String with the dev name of the typologies to depecrate
    */
    static final List<String> TYPO_DEPRECATED = new List<String>{'TP_0001', 'TP_0004', 'TP_0009', 'TP_0013', 'TP_0015', 'TP_0016'};
    /**
        * @Description: List of string with the name of some fields in arce__limits_exposure__c object
    */
    static final List<string> IMPORTS_FIELDS = new List<string>{'arce__current_approved_amount__c','arce__curr_apprv_uncommited_amount__c',
            'arce__curr_approved_commited_amount__c','arce__current_formalized_amount__c','arce__outstanding_amount__c',
            'arce__current_proposed_amount__c','arce__last_approved_amount__c'};
    /**
        * @Description: internal code to know if the unit have been change
    */
    static final string SAME_UNIT = 'SameUnit';
    /**
        * @Description: List of string with the name of some fields in arce__limits_exposure__c object
    */
    static final List<string> FIELD_API_NAMES = new List<string>{'arce__current_approved_amount__c','arce__curr_apprv_uncommited_amount__c',
            'arce__curr_approved_commited_amount__c','arce__current_formalized_amount__c','arce__outstanding_amount__c',
            'arce__current_proposed_amount__c','arce__last_approved_amount__c'};
    /**
        * @Description: List of string with the name of some fields in arce__limits_exposure__c object
    */
    static final List<string> FIELD_API_NAMES_GR = new List<string>{'arce__current_formalized_amount__c','arce__outstanding_amount__c',
            'arce__current_proposed_local_amount__c','arce__last_approved_amount__c'};

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 24/06/2019
    * @param void
    * @return void
    * @example Arc_Gen_TabsetService_Helper serviceHelper = new Arc_Gen_TabsetService_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_TabsetService_Helper() {

    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Wrapper that contain a map with the result of each tab
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 07/08/2019
    * @param void
    * @return void
    * @example CompletionResult completion = new CompletionResult()
    * ----------------------------------------------------------------------------------------------------
    **/
    public class CompletionResult {
        /**
        * @Description: Map with the id of the tab and value the wrapper "TabInfoCompletion"
        */
        final private Map<String, TabCompletionInfo> resultCompletion = new Map<String, TabCompletionInfo>();
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Wrapper that contain the percent information of the tab
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 07/08/2019
    * @param void
    * @return void
    * @example TabCompletionInfo completion = new TabCompletionInfo()
    * ----------------------------------------------------------------------------------------------------
    **/
    public class TabCompletionInfo {
        /**
        * @Description: Integer percentage of the complete fields
        */
        private Integer percentComplete {get; set;}
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return a list of wrappertabset with the info of each tab
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 24/06/2019
    * @param recordId - Id of the current account has analisys object
    * @param sector - object with the information of the sector
    * @return a list of wrappertabset with the info of each tab
    * @example generateListWrapperTab(recordId, sector)
    * -----------------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TabSet_controller.WrapperTabSet> generateListWrapperTab(Id recordId, arce__Sector__c sector) {
        final List<Arc_Gen_TabSet_controller.WrapperTabSet> listWrapper = new List<Arc_Gen_TabSet_controller.WrapperTabSet>();
        integer totalPercent = 0;
        integer maxPercent = 0;
        final System.Type objType = Type.forName('dyfr.Dynamic_Form_Completion');
        final dyfr.Form_Completion_Interface formClass = (dyfr.Form_Completion_Interface)objType.newInstance();
        final arce__Account_has_Analysis__c accHasRelation = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final List<arce__Account_has_Analysis__c> ratingStatus = arce.Arc_Gen_AccHasAnalysis_Data.getRatingStatus(new List<Id>{recordId});
        for( Arc_Gen_Sector_Data.SectorWrapper value : Arc_Gen_Sector_Data.getSectionsFromSector(sector)) {
            Arc_Gen_TabSet_controller.WrapperTabSet wrapperTabSet = new Arc_Gen_TabSet_controller.WrapperTabSet();
            switch on value.tabDevName{
                when '100' {
                    final Boolean nonOrphan = accHasRelation.arce__Analysis__r.arce__analysis_customer_relation_type__c == '01';
                    final Boolean isGroup = accHasRelation.arce__group_asset_header_type__c == '1';
                    final Boolean isBottomUp = accHasRelation.arce__anlys_wkfl_cnsld_ffss_type__c == '1' || String.isEmpty(accHasRelation.arce__anlys_wkfl_cnsld_ffss_type__c); // Allow for historical ARCEs
                    updateWrapperTabSet(wrapperTabSet, value, true, getPercentCompletion(recordId, value.templateDevName, formClass));
                    totalPercent += wrapperTabSet.percent;
                    maxPercent = nonOrphan && isGroup && isBottomUp ? maxPercent + 300 : maxPercent + 400;
                    listWrapper.add(wrapperTabSet);
                }
                when '300' {
                    updateWrapperTabSet(wrapperTabSet, value, true, getPercentCompletion(recordId, value.templateDevName, formClass));
                    totalPercent += wrapperTabSet.percent;
                    maxPercent += 100;
                    listWrapper.add(wrapperTabSet);
                }
                when '400' {
                    updateWrapperTabSet(wrapperTabSet, value, true, getPercentCompletion(recordId, value.templateDevName, formClass));
                    totalPercent += wrapperTabSet.percent;
                    maxPercent += 100;
                    listWrapper.add(wrapperTabSet);
                }
                when '500' {
                    final Boolean isVisible = accHasRelation.arce__Analysis__r.arce__Stage__c == arce.Arc_Gen_Constants.STAGE_FINALIZED ? true : validateVisibility(accHasRelation, totalPercent, maxPercent, ratingStatus[0]);
                    updateWrapperTabSet(wrapperTabSet, value, isVisible, 0);
                    listWrapper.add(wrapperTabSet);
                }
                when else {
                    updateWrapperTabSet(wrapperTabSet, value, true, 0);
                    listWrapper.add(wrapperTabSet);
                }
            }
        }
        return listWrapper;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Update Arc_Gen_TabSet_controller.WrapperTabSet object.
    * -----------------------------------------------------------------------------------------------
    * @Author   aleksandar.dinkov.contractor@bbva.com
    * @Date     2022/04/22
    * @param Arc_Gen_TabSet_controller.WrapperTabSet wrapperTabSet
    * @param Arc_Gen_Sector_Data.SectorWrapper value
    * @param Boolean isVisible
    * @param Integer percent
    * @example updateWrapperTabSet(wrapperTabSet, value, true, 0);
    * -----------------------------------------------------------------------------------------------
    **/
    public static void updateWrapperTabSet(Arc_Gen_TabSet_controller.WrapperTabSet wrapperTabSet, Arc_Gen_Sector_Data.SectorWrapper value, Boolean isVisible, Integer percent) {
        wrapperTabSet.nameTemplate = value.templateDevName;
        wrapperTabSet.nameSection = value.tabName;
        wrapperTabSet.isVisible = isVisible;
        wrapperTabSet.percent = percent;
        wrapperTabSet.devTemplate = value.tabDevName;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return an Integer with the percent value of a tab or the percent sum
    * of subtabs
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 07/08/2019
    * @param recordId - Id of the current account has analisys object
    * @param templateDevName - developer name of the template
    * @param formClass - dyfr completion class
    * @return an integer with the completeness info
    * @example getPercentCompletion(recordId, templateDevName, formClass)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Integer getPercentCompletion(Id recordId, String templateDevName, dyfr.Form_Completion_Interface formClass) {
        final String retJSON = formClass.getInfoCompletion(recordId, 'dyfr__Important__c', templateDevName, null, null);
        CompletionResult completionInfo = new CompletionResult();
        completionInfo = (CompletionResult) JSON.deserialize(retJSON, CompletionResult.class);
        final Set<String> setTabIds = completionInfo.resultCompletion.keySet();
        final List<String> tabIds = new List<String>(setTabIds);
        Integer percent = 0;
        if (tabIds.size() == ONE) {
            percent = completionInfo.resultCompletion.get(tabIds[0]).percentComplete;
        } else if (tabIds.size() > ONE) {
            integer sumPercent = 0;
            for (String tabId: tabIds) {
                sumPercent += completionInfo.resultCompletion.get(tabId).percentComplete;
            }
            percent = sumPercent;
        }
        return percent;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that change the status of an Arce Analysis
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 29/07/2019
    * @param recordId - Id of the current account has analisys object
    * @return true/false
    * @example changeArceStateHelper(recordId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static Boolean changeArceStateHelper(Id recordId) {
        Boolean statusChange = false;
        final arce__Account_has_Analysis__c relationData = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final List<arce__Analysis__c> arceAnalysisData = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<Id>{relationData.arce__Analysis__c});
        if (arceAnalysisData[0].arce__wf_status_id__c == ARCE_PREPARED && arceAnalysisData[0].arce__Stage__c == IN_PREPARATION) {
            arce.Arc_Gen_ArceAnalysis_Data.changeStatusArce(relationData, arceAnalysisData[0], PREPARING_ANALYSIS);
            statusChange = true;
        } else if (arceAnalysisData[0].arce__Stage__c == IN_SANCTION) {
            // Map to next state when in sanction.
            final Map<String, String> nextStateMap = new Map<String, String>();
            nextStateMap.put(ARCE_PREPARED, CONTRASTING_ANALYSIS);
            nextStateMap.put(PENDING_SANCTION, PENDING_SANCTION);
            nextStateMap.put(arce.Arc_Gen_Constants.STATUS_DECIDINGCOMMITTEEWDELEGATION, arce.Arc_Gen_Constants.STATUS_DECIDINGCOMMITTEEWDELEGATION);
            nextStateMap.put(arce.Arc_Gen_Constants.STATUS_SCHEDULECOMMITTEE, arce.Arc_Gen_Constants.STATUS_SCHEDULECOMMITTEE);

            if (nextStateMap.containsKey(arceAnalysisData[0].arce__wf_status_id__c)) {
                arce.Arc_Gen_ArceAnalysis_Data.changeStatusArce(relationData, arceAnalysisData[0], nextStateMap.get(arceAnalysisData[0].arce__wf_status_id__c));
                statusChange = true;
            }
        }
        return statusChange;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that update to zero the hiden typologies if is necesary
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 25/10/2019
    * @param recordId - Id of the current account has analisys object
    * @return void
    * @example update2zerohidenTypologies(recordId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static void update2zerohidenTypologies(Id recordId) {
        integer aux = 0;
        List<arce__limits_exposures__c> policiesTableData = arce.Arc_Gen_LimitsExposures_Data.getExposureByDevName(new List<Id>{recordId}, TYPO_DEPRECATED);
        for (arce__limits_exposures__c policieTable: policiesTableData) {
            for (integer i = 0; i < IMPORTS_FIELDS.size(); i++) {
                if (Double.valueOf(policieTable.get(IMPORTS_FIELDS[i])) > 0) {
                    aux++;
                }
            }
        }
        if (aux > 0) {
            for (arce__limits_exposures__c policieTable: policiesTableData) {
                policieTable.arce__current_approved_amount__c = 0;
                policieTable.arce__curr_apprv_uncommited_amount__c = 0;
                policieTable.arce__curr_approved_commited_amount__c = 0;
                policieTable.arce__current_formalized_amount__c = 0;
                policieTable.arce__outstanding_amount__c = 0;
                policieTable.arce__current_proposed_amount__c = 0;
                policieTable.arce__last_approved_amount__c = 0;
            }
            arce.Arc_Gen_LimitsExposures_Data.updateExposureData(policiesTableData);
        }
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - get outstanding amount to show in the carrousel
    * -----------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 28/01/2020
    * @param recordId - Id of the current account has analisys object
    * @return String with the message to show in the carrousel
    * @example getOutstandingFromTabClient(recordId)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String getOutstandingFromTabClient(Id recordId) {
        final arce__Account_has_Analysis__c accHasRel = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasRelation(recordId);
        final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHasRel);
        final Map<Id, arce.Arc_Gen_Account_Wrapper> mapWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{clientId});
        return String.valueOf(mapWrapper.get(clientId).outstanding) + ' ' + mapWrapper.get(clientId).currencyType;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets the needed data to convert the limits table units
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 26/03/2020
    * @param arce__Account_has_Analysis__c accHasAnalysis - Account has analysis record
    * @param Boolean isGroup - Indicates if the record is a group or a client
    * @return Map<String, Object> - A map with the possible values: status => SameUnit,Ready,Error  response => List<sObject>
    * @example public Map<String, Object> setWrapperToConvert(accHasAnalysis, isGroup)
    **/
    public static Map<String, Object> setWrapperToConvert(arce__Account_has_Analysis__c accHasAnalysis, Boolean isGroup) {
        Map<String, Object> response = new Map<String, Object>();
        final arce.Arc_Gen_GenericUtilities.ConversionWrapper wrapperConversion = new arce.Arc_Gen_GenericUtilities.ConversionWrapper();
        wrapperConversion.objData = accHasAnalysis;
        if (wrapperConversion.objData.get('arce__magnitude_unit_type__c') == wrapperConversion.objData.get('arce__prev_magnitude_unit_type__c')) {
            response.put('status', SAME_UNIT);
        } else {
            wrapperConversion.fieldNames = FIELD_API_NAMES;
            wrapperConversion.actualData = 'arce__magnitude_unit_type__c';
            wrapperConversion.previousData = 'arce__prev_magnitude_unit_type__c';
            wrapperConversion.objDataLts = arce.Arc_Gen_LimitsExposures_Data.getExposureData(new List<Id>{accHasAnalysis.Id});
            response = arce.Arc_Gen_GenericUtilities.convertUnits(wrapperConversion);
            updateData(response);
            if(isGroup) {
                wrapperConversion.fieldNames = FIELD_API_NAMES_GR;
                wrapperConversion.objDataLts = arce.Arc_Gen_AccHasAnalysis_Data.accHasAnByArce(new List<String>{accHasAnalysis.arce__Analysis__c});
                response = arce.Arc_Gen_GenericUtilities.convertUnits(wrapperConversion);
                if (response.get('response') != null) {
                    response.put('response',iterateChromes((List<sObject>)response.get('response')));
                    updateData(response);
                }
            } else {
                arce__Account_has_Analysis__c accHasAn = (arce__Account_has_Analysis__c)wrapperConversion.objData;
                accHasAn.arce__prev_magnitude_unit_type__c = accHasAn.arce__magnitude_unit_type__c;
                response.put('accHasAn', accHasAn);
                arce.Arc_Gen_AccHasAnalysis_Data.upsertObjects(new List<arce__Account_has_Analysis__c>{accHasAn});
            }
        }
        Return response;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that call an update for a list of sObject
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 26/03/2020
    * @param Map<String, Object> response - response of arce.Arc_Gen_GenericUtilities.convertUnits method
    * @return void
    * @example updateData(Map<String, Object> response)
    **/
    private static void updateData(Map<String, Object> response) {
        final arce.Arc_Gen_RatingGlobal_data dataAccess = new arce.Arc_Gen_RatingGlobal_data();
        List<sObject> objToUpdate = new List<sObject>();
        if(response.get('status') == 'Ready') {
            objToUpdate = (List<sObject>)response.get('response');
            dataAccess.updateRecords(objToUpdate);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that iterates the account has analysis list and sets the previous magnitude field
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 26/03/2020
    * @param List<arce__Account_has_Analysis__c> - List of Account Has Analysis object
    * @return List<arce__Account_has_Analysis__c> - Returns the same list but modified
    * @example public List<arce__Account_has_Analysis__c> iterateChromes(accHasAnList)
    **/
    private static List<arce__Account_has_Analysis__c> iterateChromes(List<arce__Account_has_Analysis__c> accHasAnList) {
        List<arce__Account_has_Analysis__c> updatedList = new List<arce__Account_has_Analysis__c>();
        for(arce__Account_has_Analysis__c aha : accHasAnList) {
            aha.arce__prev_magnitude_unit_type__c = aha.arce__magnitude_unit_type__c;
            updatedList.add(aha);
        }
        Return updatedList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description method that manage the visibility of the policie tab
    *-------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 26/06/2020
    * @param accHasRelation - Account Has Analysis object
    * @param totalPer - integer with total percent
    * @param maxPer - integer with maxPer
    * @param ratingStat - Account Has Analysis object
    * @return true/false
    * @example validateVisibility(accHasRelation, totalPer, maxPer, ratingStat)
    *-------------------------------------------------------------------------------
    **/
    private static Boolean validateVisibility(arce__Account_has_Analysis__c accHasRelation, Integer totalPer, Integer maxPer, arce__Account_has_Analysis__c ratingStat) {
        Boolean isVisible;
        final Boolean nonOrphan = accHasRelation.arce__Analysis__r.arce__analysis_customer_relation_type__c == '01';
        final Boolean isGroup = accHasRelation.arce__group_asset_header_type__c == '1';
        final Boolean isBottomUp = accHasRelation.arce__anlys_wkfl_cnsld_ffss_type__c == '1' || String.isEmpty(accHasRelation.arce__anlys_wkfl_cnsld_ffss_type__c); // Allow for historical ARCEs
        if (nonOrphan && isGroup && isBottomUp) {
            isVisible = totalPer == maxPer ? true : false;
        } else {
            isVisible = (totalPer == maxPer && (ratingStat.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c == '2' || ratingStat.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c == '3'));
        }
        return isVisible;
    }
}