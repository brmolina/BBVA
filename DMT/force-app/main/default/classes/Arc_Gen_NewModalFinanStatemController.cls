/*------------------------------------------------------------------
* @File Name: Arc_Gen_NewModalFinanStatemController.cls
* @Author:        ARCE Team
* @Group:      	  ARCE - BBVA Bancomer
* @Description:   Controller to modal Arc_Gen_NewModalFinanStatem.
* @Changes :
* Methods to get and process FinancialStatemnt from ASO

*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        10/12/2023     ARCE TEAM   							Creación.
-----------------------------------------------------------------------------------------*/
@SuppressWarnings('PMD.ExcessiveParameterList, PMD.ExcessivePublicCount')
public with sharing class Arc_Gen_NewModalFinanStatemController {
    /**
    * @Description Literal string value "text" used to describe field type.
    */
    private static final String STRING_VALUE_TEXT = 'text';
    /** ----------------------------------------------------------------------------------------------------
    * @Description False literal.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String FALSE_LITERAL = 'false';
    /** ----------------------------------------------------------------------------------------------------
    * @Description Label for Rating.
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String RATING_LABEL = 'Rating';

    /** ----------------------------------------------------------------------------------------------------
    * @Description literal for Rating.
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String RATING_LITERAL = 'rating';
    /** ----------------------------------------------------------------------------------------------------
    * @Description Label for Pre Rating.
    * ---------------------------------------------------------------------------------------------------- **/
    public static final String PRERATING_LABEL = 'Pre-Rating';
    /** ----------------------------------------------------------------------------------------------------
    * @Description value for Pre Rating.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String PRERATING_VALUE = 'Prerating';
    /**
    * @Description Value of the "Valid" picklist entry of the ffss_valid_type field.
    */
    private static final String FFSS_VALID_TYPE = '1';
    /**
    * @Description Value of metadata of rating corp
    */
    private static final String RATING_TYPE_CORP = 'RatingTypeByModel';
    /**
    * @Description Value of corp
    */
    private static final String CORP_VALUE = 'Corp';
    /**
    * @Description Value  of metadata of rating ifis
    */
    private static final String RATING_TYPE_IFIS = 'RatingTypeByModel';
    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description get Dynamic Columns
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.contractor@bbva.com
    * @Date     Created: 2023-12-13
    * @param isRaip - Boolean
    * @return String - wrapper with the result of the operation
    * @example dynamicColumnsRTC(isRaip) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String dynamicColumnsRTC() {
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_SortableEEFF');

        final Boolean sortable = configs.isEmpty() ? false : Boolean.valueOf(configs[0].arce__Value1__c);
        final JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartArray();
        if(sortable) {
            Arc_Gen_ModalFinanStatemController.writeNewCol(gen, null, 25, 'arce__Order__c', 'phone', null, true);
        }
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Type, 100, 'arce__ffss_submitted_type__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Date, 100, 'arce__financial_statement_end_date__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Period, 82, 'arce__economic_month_info_number__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Certification, 130, 'arce__ffss_certification_type__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Applicable, 100, 'arce__ffss_apply_for_rating_type__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_AdjustedType, 90, 'arce__ffss_adjusted_type__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, 'Id', 100, 'shortId', STRING_VALUE_TEXT, null, null);
        gen.writeEndArray();

        return gen.getAsString();
    }

    /**
    *-------------------------------------------------------------------------------
    * @description method that draw the table of financial statements.
    *--------------------------------------------------------------------------------
    * @author isabel.ascaso.contractor@bbva.com
    * @date 2019-04-11
    * @param varRecord recordId of the account_has_analysis.
    * @param isFinancialRAIP
    * @param isRAIP
    * @param ratingToolSelect
    * @param requestedPage Page number to be requested from service, if null web service fetch all FFSS at once, without pagination.
    * @return Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper
    **/
    @AuraEnabled
    public static Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper fetchFinancialStatements(String varRecord, Boolean isFinancialRAIP, String ratingToolSelect, Integer requestedPage) {
        try {
            final Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper wrapper = new Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper();
            final String ratingTool = ratingToolSelect == null ? Arc_Gen_RatingAsIndepProcess_service.getRatingIdSelIrp(varRecord) : ratingToolSelect;
            if(isFinancialRAIP) {
                final Set<String> preselectedFFSS = new Set<String>();
                for(arce__Account_has_Analysis__c aHa : arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{varRecord})) {
                    preselectedFFSS.add(aHa.arce__ffss_for_rating_id__r.arce__financial_statement_id__c);
                }
                wrapper.preselected = preselectedFFSS;
            }
            final Arc_Gen_Balance_Tables_service.SetupFFSSHeadersWrapper setupWrapper = Arc_Gen_Balance_Tables_service.setupFFSSHeadersRTC(varRecord, false, ratingTool, requestedPage);
            wrapper.pagination = setupWrapper.pagination;
            wrapper.ffssList = setupWrapper.ffssList;
            wrapper.ffssListLabel = Arc_Gen_Balance_Tables_Service.translatePicklistValues(wrapper.ffssList);
            // Get label for "Valid" value of ffss_valid_type field
            final List<Schema.PicklistEntry> picklistEntries = arce__Financial_Statements__c.arce__ffss_valid_type__c.getDescribe().getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.getValue() == FFSS_VALID_TYPE) {
                    wrapper.validLabel = entry.getLabel();
                }
            }
            System.debug('fetchFinancialStatements  wrapper.ffssList ' +  wrapper.ffssList.size());
            return wrapper;
        } catch (Exception ex) {
            final AuraHandledException auraEx = Arc_Gen_ModalFinanStatemController.financialStatementExceptionHandling(ex);
            throw auraEx; // NOSONAR
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method Split the arce configuration information
    *--------------------------------------------------------------------------------
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @Date 2023/08/18
    * @param arceConfigName - String with the Configuration Name
    * @return Configuration value splited
    * @example Arc_Gen_ModalFinanStatemController.getSplittedMdtValue(arceConfigName)
    *--------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<String> getSplittedMdtValue(String arceConfigName) {
        return Arc_Gen_AnalysisWizard_Service.getSplittedMdtValue(arceConfigName);
    }
    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Helper method for checkRatingType.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 20/09/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example checkRatingType(wfValues, ratings);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static void addToWfValue(List<Arc_Gen_RatingAsIndepProcess_controller.WfValue> wfValues, List<String> ratings) {
        for (String current : ratings) {
            if(current.equalsIgnoreCase(RATING_LABEL)) {
                wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(RATING_LABEL, RATING_LABEL));
            } else if (current.equalsIgnoreCase(PRERATING_VALUE)) {
                wfValues.add(new Arc_Gen_RatingAsIndepProcess_controller.WfValue(PRERATING_VALUE, PRERATING_LABEL));
            }
        }
    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description save EEFF
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.contractor@bbva.com
    * @Date     Created: 2022-01-05
    * @param List<arce__Financial_Statements__c> fflist
    * @param List<arce__Financial_Statements__c> draft
    * @param String selectedRows
    * @return List<arce__Financial_Statements__c>
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static List<arce__Financial_Statements__c> saveEEFF(List<arce__Financial_Statements__c> fflist, List<arce__Financial_Statements__c> draft, String selectedRows) {
        return Arc_Gen_ModalFinanStatemController.saveEEFF(fflist, draft, selectedRows);
    }


    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description save EEFF
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   isabel.ascaso.contractor@bbva.com
    * @Date     Created: 2022-01-05
    * @param String recordId accHasAnalysisId
    * @param List<arce__Financial_Statements__c> fflist
    * @param List<String> financialIdList
    * @param Boolean isRAIP
    * @param Boolean isFinancialRAIP
    * @param String ratingToolSelect
    * @param String selectedRows
    * @return Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Arc_Gen_Balance_Tables_service.ratiosAndRatingResponse callEngineFinancialState(String recordId, List<arce__Financial_Statements__c> fflist, List<String> financialIdList, Boolean isRAIP, Boolean isFinancialRAIP, String ratingToolSelect, String selectedRows) {
        final List<arce__Financial_Statements__c> updatedEEFF = Arc_Gen_ModalFinanStatemController.saveEEFF(fflist, fflist, selectedRows);
        return Arc_Gen_ModalFinanStatemController.callEngineFinancialState(recordId, updatedEEFF, financialIdList, isRAIP, isFinancialRAIP, ratingToolSelect, null);
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Check in RatingTypeByModel arceconfig if is rating avaiable.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 20/09/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example checkRatingType(analysisId, modelSelec);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Boolean isRating(String modelSelec, String ratingSys) {
        Boolean isRating = false;
        String ratingMeta;
        if(ratingSys == CORP_VALUE) {
            ratingMeta = RATING_TYPE_CORP;
        } else {
            ratingMeta = RATING_TYPE_IFIS;
        }
        final List<arce__Arce_Config__mdt> configs = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(ratingMeta);

        if (!configs.isEmpty() && configs[0].arce__Value1__c != FALSE_LITERAL && String.isNotBlank(modelSelec)) {
            final String woutFlow = modelSelec.replaceAll('[iacIAC]+rpsubsidiary|[IAC]+RPSUBSIDIARY|[iacIAC]+rpgroup|[IAC]+RPGROUP|[iacIAC]+rp|[IAC]+RP','');
            final String configWf = configs[0].arce__Value1__c;
            for (String current : configWf.split(';')) {
                final List<String> keyValue = current.split(':');
                if (woutFlow.equals(keyValue[0])) {
                    final List<String> ratingList = current.split(',');
                    for (String rat : ratingList) {
                        if(rat == RATING_LITERAL) {
                            isRating = true;
                        }
                    }
                }
            }
        } else {
            isRating = true;
        }

        return isRating;
    }

    /**
    *---------------------------------------------------------------------------------------------------------------------
    * @Description Check in RatingTypeByModel arceconfig if is rating avaiable.
    *---------------------------------------------------------------------------------------------------------------------
    * @Date 20/09/2021
    * @author saimasimilianno.jordana.contractor@bbva.com
    * @return List<WfValue>
    * @example checkRatingType(analysisId, modelSelec);
    *---------------------------------------------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static Map<String,String> getVariablesButton(String analysisId) {
        final Map<String,String> attributesMap = new Map<String,String>();
        final List<arce__Account_has_Analysis__c> lstAccHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAllAccFromArce(analysisId);
        System.debug(analysisId);
        System.debug(lstAccHasAnalysis);

        if(!lstAccHasAnalysis.isEmpty()) {
            attributesMap.put('modlSlctd', lstAccHasAnalysis[0].arce__RAR_rating_tool_id__c);
            attributesMap.put('accHasAnalysisId', lstAccHasAnalysis[0].Id);

            final Boolean rating = isRating(lstAccHasAnalysis[0].arce__RAR_rating_tool_id__c, 'Corp');
            attributesMap.put('ratingType', rating == true ? 'Rating' : 'Pre-Rating');
        }

        return attributesMap;
    }
}