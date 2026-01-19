/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingAsIndepProcess_test
* @Author   eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2020-03-11
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper class for Arc_Gen_Balance_Tables_service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-13 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |2020-03-26 juanignacio.hita.contractor@bbva.com 
*             Refactoring
* |2020-04-14 mariohumberto.ramirez.contractor@bbva.com
*             Added checkEeffPreviousValid method
* |2020-05-26 joseluis.garcia4.contractor@bbva.com
*             Throws exception if no FFSS are returned from the service.
* |2020-06-09 cesaroctavio.villanueva.cebal@bbva.com
*		      Added transformation of leveraged variables according to magnitude and currency from financial statement
* |2020-06-24 juanmanuel.perez.ortiz.contractor@bbva.com
*		      Add logic to delete previous rating variables
* |2020-06-15 juanignacio.hita.contractor@bbva.com
*		      Add non mandatory percentage and unexisting balances getPercentFromMap method
* |2020-07-02 javier.soto.carrascosa@bbva.com
*		      Fix logic of valid in rating
* |2020-07-07 juanignacio.hita.contractor@bbva.com
*		      Added validation before call to rating engine
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-10-21 joseluis.garcia4.contractor@bbva.com
*             Calculates both arce__ffss_auditor_opinion_type__c and arce__ffss_auditor_qlfn_type__c fields.
* |2021-01-05 joseluis.garcia4.contractor@bbva.com
*             Truncates auditor opinion description coming from service so it complies with SF field length limit.
* |2021-04-19 saimassimilianno.jordana.contractor@bbva.com
*             Corrected bug when audit object is not informed the application does not crash.
              Created buildFFSS method to avoid complexity sonar issue
* |2021-04-16 ronald.pisco.contractor@bbva.com
*							Modified setFFSSToAnalysis, add if with update to ARCE record
* |2021-04-21 ivan.cons@bbva.com
*             Get auditor name from ffss service response
* |2021-09-20 otiliaramona.veres.contractor@bbva.com
*             Added new certificates 'PROFORMA', 'PRO_FORMA_MERGER' and 'PRO_FORMA_ACQUISITION'
* |2021-09-20 amunguia.contractor@bbva.com
*             The response is processed to retrieve the fields: auditComment, closed by and confirmed by.
* |2021-09-20 juanignacio.hita.contractor@bbva.com
*             Adds ratingTool param that is used in irp wizard with pre step triage configured. supresses ExcessiveParameterList pmd rule
* |2021-11-15 otiliaramona.veres.contractor@bbva.com
*             The arce__economic_period_type_id__c field that is used in the header of the Financial Risk tables has been added
* |2021-11-30 juanignacio.hita.contractor@bbva.com
*             Changes filterAdjustedTypeFFSS method, applied in filter of table preview
* |2022-05-10 francisco.munoz.torres.contractor@bbva.com
*             Abbreviate the field arce__ffss_auditor_opinion_comment__c
* |2023-05-19 joseluis.miralles.contractor@bbva.com
*             The CurrencyIsoCOde field that is used in Projections has been added
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.ExcessiveParameterList, sf:TooManyMethods, sf:TooManyFields, sf:ExcessiveClassLength,PMD.ExcessiveClassLength, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity')
public class Arc_Gen_Balance_Tables_helper {
    /**
        * @Description: Maximum number of valid financial statements
    */
    static final Integer NUM_MAX_EEFF = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c) ? 100 : 1;
    /**
        * @Description: String with value "Consolidated" for submitted type ffss
    */
    static final string FFSS_TYPE_CONSOL = '1';
    /**
        * @Description: String with value "Individual" for submitted type ffss
    */
    static final string FFSS_TYPE_INDIV = '2';
    /**
        * @Description: Adjusted type ffss
    */
    static final string FFSS_ADJUSTEDTYPE = '1';
    /**
        * @Description: Non adjusted type ffss
    */
    static final string FFSS_NO_ADJUSTEDTYPE = '2';
    /**
        * @Description: Non adjusted type ffss
    */
    static final string FFSS_CT_AUDITED = 'AUDITED';
    /**
        * @Description: Non adjusted type ffss
    */
    static final string FFSS_CT_FISCAL = 'FISCAL';
    /**
        * @Description: Non adjusted type ffss
    */
    static final string FFSS_CT_TREGISTRY = 'TRADE_REGISTRY';
    /**
        * @Description: Certification type ffss
    */
    static final string PROFORMA = 'PROFORMA';
    /**
        * @Description: Certification type ffss
    */
    static final string PRO_FORMA_MERGER = 'PRO_FORMA_MERGER';
    /**
        * @Description: Certification type ffss
    */
    static final string PRO_FORMA_ACQUISITION = 'PRO_FORMA_ACQUISITION';
    /**
        * @Description: Non adjusted type ffss
    */
    static final string FFSS_VALID = '1';
    /**
        * @Description: Non valid ffss
    */
    static final string FFSS_NOT_VALID = '2';
    /**
        * @Description: Maximum number of valid financial statements
    */
    static final Integer MAX_EEFF = 1;
    /**
        * @Description: Name of financial statements custom metadata for add months
    */
    static final String FFSS_END_DATE = 'FinancialStatementEndDate';
    /**
    * @Description: Name of a field to get
    */
    static final String CURRENCY_FIELD = 'CurrencyIsoCode';
    /**
    * @Description: type ANCHOR
    */
    static final String ANCHOR = 'ANCHOR';
    /**
    * @Description: Structure of the response
    */
    /**
    * @description Retrieves the IRP flow custom interface.
    * @return The IRP flow custom interface.
    */
    private static String strTriageCnf {
        get {
            return Test.isRunningTest() ? JSON.serialize(new List<String>{'PRE','Arc_GBL_IRPFlowCustom'}) : Arc_Gen_RatingAsIndepProcess_controller.getIRPTriageStepConfig();
        }
    }

    /**
    * @description Retrieves the IRP flow custom interface.
    * @return The IRP flow custom interface.
    */
    private static Arc_Gen_IRPFlowCustom_Interface irpFlowCustom {
        get {
            final Arc_Gen_IRPFlowCustom_Interface impl = null;

            if (strTriageCnf != null) {
                final List<Object> lstConfigStep = (List<Object>) JSON.deserializeUntyped(strTriageCnf);
                impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow((String) lstConfigStep[1]);
            }
            return impl;
        }
    }
    public class Response {
        /**
        * @Description: List of businessAgent
        */
        public List<BusinessAgent> businessAgents {get; set;}
        /**
        * @Description: String with comments
        */
        public String comments {get; set;}
        /**
        * @Description: Period with period
        */
        public Period period {get; set;}
    }
    /**
    * @Description: Structure of the Period
    */
    public class Period {
        /** @Description: Structure with periodType */
        public PeriodType periodType {get; set;}
    }
    /**
    * @Description: Structure of the PeriodType
    */
    public class PeriodType {
        /** @Description: String with id */
        public String id {get; set;}
    }
    /**
    * @Description: businessAgent Structure
    */
    private class BusinessAgent {
        /**
        * @Description: String with id
        */
        public String id {get; set;}
        /**
        * @Description: ActionType structure
        */
        public ActionType actionType {get; set;}
        /**
        * @Description: datetime with updateDate
        */
        public DateTime updateDate {get; set;}
    }
    /**
        * @Description: ActionType structure
        */
    private class ActionType {
        /**
        * @Description: String with id
        */
        public String id {get; set;}
    }

    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		12/03/2020
    * @author	eduardoefrain.hernandez.contractor@bbva.com
    */
    @testVisible
    private Arc_Gen_Balance_Tables_helper() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the response of the financial Statements service
    *--------------------------------------------------------------------------------
    * @author  Efraín Hernandez Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @date    11/03/2020
    * @param String analysisId - Standard Id of the ARCE analysis
    * @param arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp -
    * @param arce.Arc_Gen_getIASOResponse.serviceResponse response -
    * @param Boolean translateVal
    * @param arce.Arc_Gen_Account_Wrapper accountInfo
    * @return arce.Arc_Gen_ServiceAndSaveResponse
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupFFSSHeaders(String analysisId) {
    **/
    public static List<arce__Financial_Statements__c> processFinancialStatements(String analysisId, arce.Arc_Gen_getIASOResponse.serviceResponse response, Boolean translateVal,arce.Arc_Gen_Account_Wrapper accountInfo, String ratingSelected, String proposalFolderId) {
        final Map<String, Object> serviceResponse = response.serviceResponse;
        List<Object> listServiceResp = (List<Object>) serviceResponse.get('data');
        final List<arce__Account_has_Analysis__c> lstAccHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {analysisId});
        
        
        if (listServiceResp.isEmpty()) {
            throw new Arc_Gen_Balance_Tables_service.NoFinancialStatementDataException(Arc_Gen_Balance_Tables_service.NoFinancialStatementReason.NO_FFSS_EMPTY_LIST);
        }

        List<arce__Financial_Statements__c> ffssList = buildFinancialStatements(analysisId, listServiceResp, lstAccHasAnalysis, ratingSelected, proposalFolderId);

        ffssList = applyConfiguration(ffssList, lstAccHasAnalysis[0], ratingSelected);
        ffssList = validateFsByClientType(accountInfo, ffssList);

        if (translateVal) {
            translatePicklistValues(ffssList);
        }

        Arc_Gen_Sort_Sobs.descending(ffssList, arce__Financial_Statements__c.arce__financial_statement_end_date__c);
        return ffssList;
    }

    /**
    * @description Builds the financial statements list from the service response.
    * @param recordId The ID of the record.
    * @param listServiceResp The list of service response data.
    * @param lstAccHasAnalysis The list of account analysis data.
    * @param ratingSelected The selected rating.
    * @return The list of financial statements.
    */
    private static List<arce__Financial_Statements__c> buildFinancialStatements(String recordId, List<Object> listServiceResp, List<arce__Account_has_Analysis__c> lstAccHasAnalysis, String ratingSelected,String proposalFolderId) {
        final List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        final Integer auditOpMaxLen = arce__Financial_Statements__c.arce__ffss_auditor_opinion_desc__c.getDescribe().getLength();
        final Arc_Gen_IRPFlowCustom_Interface impl = irpFlowCustom;

        for (Integer i = 0; i < listServiceResp.size(); i++) {
            final Map<String, Object> ffssMap = (Map<String, Object>) listServiceResp[i];
            final arce__Financial_Statements__c ffss = buildFFSS(recordId, ffssMap, auditOpMaxLen, impl, ratingSelected, proposalFolderId);

            if (checkMatrixCustomer(ffss, lstAccHasAnalysis[0])) {
                ffssList.add(ffss);
            }
        }
        return ffssList;
    }

        /**
    * @description Applies the configuration to the financial statements list.
    * @param ffssList The list of financial statements.
    * @param accHasAnalysis The account analysis data.
    * @param ratingSelected The selected rating.
    * @return The list of financial statements with applied configuration.
    */
    private static List<arce__Financial_Statements__c> applyConfiguration(List<arce__Financial_Statements__c> ffssList, arce__Account_has_Analysis__c accHasAnalysis, String ratingSelected) {
        final Arc_Gen_IRPFlowCustom_Interface impl = irpFlowCustom;
        List<arce__Financial_Statements__c> ffssListReturn = new List<arce__Financial_Statements__c>();
        if (impl != null && String.isNotBlank(ratingSelected)) {
            ffssListReturn = impl.validateFSForRating(ffssList, ratingSelected);
        } else {
            ffssListReturn = validateFSForRatingInit(accHasAnalysis, ffssList);
        }

        return ffssListReturn;
    }


    /**
    *-------------------------------------------------------------------------------
    * @description Method that process the response of the financial Statements service
    *--------------------------------------------------------------------------------
    * @author  Efraín Hernandez Rendón - eduardoefrain.hernandez.contractor@bbva.com
    * @date    11/03/2020
    * @param String analysisId - Standard Id of the ARCE analysis
    * @param arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp -
    * @param arce.Arc_Gen_getIASOResponse.serviceResponse response -
    * @param Boolean translateVal
    * @param arce.Arc_Gen_Account_Wrapper accountInfo
    * @return arce.Arc_Gen_ServiceAndSaveResponse
    * 		if OK serviceCode = 200, other case controller will format serviceCode and
    * 		if not OK serviceCode = 'Error - MessageError' to be displayed to user
    * 		Exceptions calling WS will return 'Error calling service'
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse setupFFSSHeaders(String analysisId) {
    **/
    public static List<arce__Financial_Statements__c> processFinancialStatementsRTC(String analysisId, arce.Arc_Gen_getIASOResponse.serviceResponse response,
                                                                                Boolean translateVal,arce.Arc_Gen_Account_Wrapper accountInfo,
                                                                                String ratingSelected) {
        // Get response from service.
        final Map<String, Object> serviceResponse = response.serviceResponse;
        List<Object> listServiceResp = (List<Object>)serviceResponse.get('data');
        // Check if any financial statement.
        if (listServiceResp.isEmpty()) {
            throw new Arc_Gen_Balance_Tables_service.NoFinancialStatementDataException(Arc_Gen_Balance_Tables_service.NoFinancialStatementReason.NO_FFSS_EMPTY_LIST);
        }

        final String strTriageCnf = Test.isRunningTest() ? JSON.serialize(new List<String>{'PRE','Arc_GBL_IRPFlowCustom'}) : Arc_Gen_RatingAsIndepProcess_controller.getIRPTriageStepConfig();
        Arc_Gen_IRPFlowCustom_Interface impl = null;
        if (strTriageCnf != null) {
            final List<Object> lstConfigStep = (List<Object>) JSON.deserializeUntyped(strTriageCnf);
            impl = Arc_Gen_GenericUtilitiesInterface.getIRPStepFlow((String) lstConfigStep[1]);
        }
        final Boolean isRaipCorp = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c);
        //Bolean to kwnow if have an anchor
        Boolean isAnchor = false;

        List<Object> listOrdered = new List<Object>();
        Object ffssAnchor = getCorpFfss(listServiceResp);
        if(ffssAnchor != null) {
            listOrdered.add(ffssAnchor);
            isAnchor = true;
        }

        //Remove the anchor element so that it does not repeat
        if(isAnchor) {
            for (Integer i = 0; i < listServiceResp.size(); i++) {
                final Map<String, Object> ffssMap = (Map<String, Object>) listServiceResp[i];
                final Map<String, Object> anchorMap = (Map<String, Object>) ffssAnchor;
                if((String) ffssMap.get('id') == (String) anchorMap.get('id')) {
                    listServiceResp.remove(i);
                    break;
                }
            }
        }

        listOrdered.addAll(listServiceResp);

        final Integer auditorOpMaxLength = arce__Financial_Statements__c.arce__ffss_auditor_opinion_desc__c.getDescribe().getLength();
        final List<arce__Account_has_Analysis__c> lstAccHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {analysisId});
        List<arce__Financial_Statements__c> ffssList = new List<arce__Financial_Statements__c>();
        for (Integer i = 0; i < listOrdered.size(); i++) {
            // Deconstruct service response into maps.
            final Map<String, Object> ffssMap = (Map<String, Object>) listOrdered[i];

            final arce__Financial_Statements__c ffss = buildFFSS(analysisId, ffssMap, auditorOpMaxLength, impl, ratingSelected, null);

            if (checkMatrixCustomer(ffss, lstAccHasAnalysis[0])) {
                ffssList.add(ffss);
            }
        }
        ffssList = applyFSForRatingInit(ffssList, isAnchor);

        ffssList = validateFsByClientType(accountInfo, ffssList); // If client type is prospect, sets all financial statements as no valid.
        // Translate picklist values if applicable.
        if (translateVal) {
            translatePicklistValues(ffssList);
        }
        Arc_Gen_Sort_Sobs.descending(ffssList, arce__Financial_Statements__c.arce__financial_statement_end_date__c);
        return ffssList;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description return one Object ffss anchor
    *--------------------------------------------------------------------------------
    * @author  isabel.ascaso.contractor@bbva.com
    * @date    15/09/2023
    * @param accInfo List<Object> listServiceResp
    * @param lstFfss Object
    */
    public static Object getCorpFfss(List<Object> listServiceResp) {
        final Map<String, Object> ffssReturn = arce.Arc_Gen_ffssAutomaticCorporate.automaticFFSSOnlyAnchor(listServiceResp);
        Object ffss;
        System.debug(LoggingLevel.INFO, 'Arc_Gen_ffssAutomaticCorporate::getCorpFfss ffssReturn ' + ffssReturn);
        System.debug(LoggingLevel.INFO, 'Arc_Gen_ffssAutomaticCorporate::getCorpFfss ffssReturn.get(ANCHOR) ' + ffssReturn.get(ANCHOR));
        if(ffssReturn.get(ANCHOR) != null) {
            ffss = ffssReturn.get(ANCHOR);
        }
        System.debug(LoggingLevel.INFO, 'Arc_Gen_ffssAutomaticCorporate::getCorpFfss ffssReturn ' + ffss);
        return ffss;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Validates if client type is prospect, sets all financial statements as no valid.
    *--------------------------------------------------------------------------------
    * @author  aleksandar.dinkov.contractor@bbva.com
    * @date    25/10/2022
    * @param accInfo arce.Arc_Gen_Account_Wrapper
    * @param lstFfss List<arce__Financial_Statements__c>
    */
    public static List<arce__Financial_Statements__c> validateFsByClientType(arce.Arc_Gen_Account_Wrapper accInfo, List<arce__Financial_Statements__c> lstFfss) {
        for (arce__Financial_Statements__c ffss : lstFfss) {
            if (accInfo.isProspect) {
                ffss.arce__ffss_valid_type__c = FFSS_NOT_VALID;
            }
        }
        return lstFfss;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description build FFSS to show in table.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    19/04/2021
    * @param recordId id of  Account has Analysis Id or proposal folder
    * @param servResp Map of response
    */
    public static arce__Financial_Statements__c buildFFSS (String recordId, Map<String, Object> servResp, Integer auditorOp, Arc_Gen_IRPFlowCustom_Interface impl, String ratingSelected, String proposalFolderId) {

        final Map<String, Object> ffssType = (Map<String, Object>) servResp.get('financialStatementType');
        final Map<String, Object> certification = (Map<String, Object>) servResp.get('certification');
        final Map<String, Object> period = (Map<String, Object>) servResp.get('period');
        final Response respEEFF = (Response) JSON.deserialize(JSON.serialize(servResp), Response.class);
        final Integer auditorOpComMaxLength = arce__Financial_Statements__c.arce__ffss_auditor_opinion_comment__c.getDescribe().getLength();

        Map<String, Object> auditorMap = new Map<String, Object>();
        if (servResp.containsKey('audit')) {
            final Map<String, Object> auditMap = (Map<String, Object>) servResp.get('audit');
            final Object audit = (Object) auditMap.get('auditor');
            auditorMap = (Map<String, Object>) audit;
        }

        // Build FS object.
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c();
        ffss.arce__account_has_analysis_id__c = recordId;
        ffss.arce__SP2_Proposal_Folder__c = proposalFolderId;
        
        ffss.arce__financial_statement_id__c = (String) servResp.get('id');
        ffss.arce__economic_month_info_number__c = String.valueOf(period.get('number'));
        ffss.arce__ffss_submitted_type__c = getSubmittedTypeFromId(ffssType.get('id'));
        ffss.arce__ffss_adjusted_type__c = getAdjustedType(servResp.get('adjustedIndicator'));
        if (servResp.containsKey('employeesNumber')) {
            try {
                ffss.arce__employees_number__c = Double.valueOf(servResp.get('employeesNumber').ToString());
                ffss.arce__employees_number_formatted__c = Integer.valueOf(servResp.get('employeesNumber').ToString());  
            } catch (Exception e) {
                ffss.arce__employees_number__c = null;
            }
        }
        ffss.arce__ffss_certification_type__c = (String) certification.get('certificationType');
        ffss.arce__financial_statement_end_date__c = date.valueOf((String)period.get('endDate'));
        ffss.arce__economic_period_type_id__c = respEEFF.period.periodType?.id;
        ffss.arce__ffss_auditor_opinion_comment__c = respEEFF.comments == null?null:respEEFF.comments.abbreviate(auditorOpComMaxLength);
        ffss.arce__Order__c = '';
        ffss.CurrencyIsoCode = (String) servResp.get('currency');
        if (!auditorMap.isEmpty()) {
            ffss.arce__ffss_auditor_opinion_desc__c = ((String)auditorMap.get('opinion')).abbreviate(auditorOp);
            ffss.arce__ffss_auditor_opinion_type__c = getHasQualification(auditorMap.get('hasQualification'));
            ffss.arce__ffss_auditor_qlfn_type__c = getAuditorQualification(ffss.arce__ffss_certification_type__c, ffss.arce__ffss_auditor_opinion_type__c);
            ffss.arce__ffss_auditor_name__c = (String)(auditorMap.get('name'));
        }
        if(respEEFF.businessAgents != null) {
            for(BusinessAgent bAgent : respEEFF.businessAgents) {
                if(bAgent.actionType.id == 'CONFIRMED') {
                    ffss.arce__ffss_confirmed_by__c = bAgent.id;
                } else {
                    ffss.arce__ffss_closed_by__c = bAgent.id;
                }
            }
        }
        return ffss;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets the value of the "Has qualification" field.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    21/10/2020
    * @param serviceValue Value as obtained from the FFSS details service
    */
    private static String getHasQualification(Object serviceValue) {
        String retValue;
        if (serviceValue == null) {
            retValue = 'N';
        } else {
            final Boolean boolVal = (Boolean) serviceValue;
            retValue = boolVal ? 'S' : 'N';
        }

        return retValue;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Gets the value of the "Auditor qualification" field.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    21/10/2020
    * @param certType Certification type of FFSS
    * @param hasQulf Has qualification value
    */
    private static String getAuditorQualification(String certType, String hasQulf) {
        String auditorQulf;
        if (certType == FFSS_CT_AUDITED && hasQulf == 'S') {
            auditorQulf = '1';
        } else if (certType == FFSS_CT_AUDITED && hasQulf == 'N') {
            auditorQulf = '2';
        } else {
            auditorQulf = '3';
        }

        return auditorQulf;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Transforms values of picklist fields into labels. This method is intended to
    * be called on lists of financial statements to be returned into the front-end so they are
    * displayed.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     27/02/2020
    * @param ffssList List of record to have their picklist field values translated into labels.
    **/
    public static void translatePicklistValues(List<arce__Financial_Statements__c> ffssList) {
        if (ffssList == null || ffssList.isEmpty()) {
            return;
        }

        // Note: Let's assume all records have the same fields populated.
        final Map<String, Object> fieldMap = ffssList[0].getPopulatedFieldsAsMap();
        final Schema.DescribeSObjectResult objDescribe = ffssList[0].getSObjectType().getDescribe();
        final Map<String, Schema.SObjectField> fieldDefType = objDescribe.fields.getMap();

        // Build translation maps (a translation map maps picklist values to labels).
        final Map<String, Map<String, String>> traslationMapsByFieldName = new Map<String, Map<String, String>>();
        for (String fieldName : fieldMap.keySet()) {
            final Schema.DescribeFieldResult fieldDescribe =
                fieldDefType.get(fieldName).getDescribe();

            if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST && fieldName != CURRENCY_FIELD) {
                final List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                final Map<String, String> valueToLabelMap = new Map<String, String>();

                for (Schema.PicklistEntry entry : picklistEntries) {
                    valueToLabelMap.put(entry.getValue(), entry.getLabel());
                }

                traslationMapsByFieldName.put(fieldName, valueToLabelMap);
            }
        }

        // Translate the fields for all records on the list.
        for (String fieldName : traslationMapsByFieldName.keySet()) {
            for (arce__Financial_Statements__c ffss : ffssList) {
                final Map<String, String> valueToLabelMap = traslationMapsByFieldName.get(fieldName);
                final String fieldValue = String.valueOf(ffss.get(fieldName));
                if (valueToLabelMap.containsKey(fieldValue)) {
                    final String label = valueToLabelMap.get(fieldValue);
                    ffss.put(fieldName, label);
                }
            }
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description getSubmittedTypeFromId
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    26/03/2020
    * @param   Object id
    * @param   return 2 if single or 1
    **/
    private static String getSubmittedTypeFromId(Object id) {
        return (String) id == 'SINGLE' ? '2' : '1';
    }
    /**
    *-------------------------------------------------------------------------------
    * @description getAdjustedType
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    26/03/2020
    * @param   Object adjustedIndicator
    * @param   return 2 if adjustedIndicator or 1
    **/
    private static String getAdjustedType(Object adjustedIndicator) {
        return (Boolean) adjustedIndicator ? '1' : '2';
    }
    /**
    *-------------------------------------------------------------------------------
    * @description getFfssValidType
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date    26/03/2020
    * @param   Boolean ffssValidForRating
    * @param   return 2 if ffssValidForRating or 1
    **/
    public static String getFfssValidType(Boolean ffssValidForRating) {
        return ffssValidForRating ? '1' : '2';
    }
    /**
    *-------------------------------------------------------------------------------
    * @description saves the information about the financial statement used for rating
    * into the analysis.
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     09/03/2020
    * @param arce__Account_has_Analysis__c account_has_analysis
    * @param List validFFSS List of FFSS that are valid for rating
    * @param resp Response from the ratios engine
    * @param arce__Financial_Statements__c chosenFS : valid ffss chosen
    * @return saveRatingFfss(analyzedClient, validFFSS, resp, chosenFS);
    * @example saveRatingFfss(analyzedClient, validFFSS, resp, chosenFS);
    **/
    public static void saveRatingFfss(arce__Account_has_Analysis__c analyzedClient, List<arce__Financial_Statements__c> validFFSS, Arc_Gen_Balance_Tables_service.RatiosAndRatingResponse resp, arce__Financial_Statements__c chosenFS) {
        final Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();
        String ffssValidId = null;
        if (validFFSS.isEmpty()) {
            arce__Financial_Statements__c emptyFS = dataAccess.getEmptyFinancialStatements();
            setFFSSToAnalysis(analyzedClient.Id,emptyFS.Id);
            setFFSSToAccHasAnalysis(analyzedClient.Id, emptyFS);
            resp.fsServiceId = emptyFS.arce__financial_statement_id__c;
        } else {
            final List<arce__rating_variables_detail__c> varRatingList = dataAccess.getRatingVariables(analyzedClient.Id);
            Map<Id, arce__rating_variables_detail__c> varRatMap = new Map<Id, arce__rating_variables_detail__c>();
            for(arce__rating_variables_detail__c varRat : varRatingList) {
                varRatMap.put(varRat.arce__rating_id__c,varRat);
            }
            dataAccess.deletePrevious(varRatingList);
            dataAccess.deleteRatingRecords(varRatMap.keySet());
            final String ratingRecord = Arc_Gen_Balance_Tables_data.insertNewRecord(new arce__rating__c());
            ffssValidId = chosenFS.Id;
            setFFSSToAnalysis(analyzedClient.Id, ffssValidId);
            setRatingVariables(ratingRecord, analyzedClient.Id);
            setRatingToFS(chosenFS, ratingRecord);
            setLeverageVariables(analyzedClient.Id, chosenFS);
            setFFSSToAccHasAnalysis(analyzedClient.Id, chosenFS);
            resp.fsServiceId = chosenFS.arce__financial_statement_id__c;
        }
        resp.ratingValidatedFS = ffssValidId;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description assign FFSS to analysis
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param String ffssValidId valid ffss
    * @param String analysisId accountHasAnalysis Id
    * @return void (update accHasAnalysis)
    * @example public static void setFFSSToAnalysis(String analysisId,String ffssValidId) {
    **/
    private static void setFFSSToAnalysis(String analysisId,String ffssValidId) {
        final Arc_Gen_Balance_Tables_data locator = new Arc_Gen_Balance_Tables_data();
        List<arce__Account_has_Analysis__c> analysis = new List<arce__Account_has_Analysis__c>();
        analysis = locator.getAccountHasAnalysis(analysisId);
        if(!analysis.isEmpty()) {
            analysis[0].arce__ffss_for_rating_id__c = ffssValidId;
            analysis[0].arce__rating_scale_type__c = '2';
        }
        locator.updateRecords(analysis);
        if(analysis[0].arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c == arce.Arc_Gen_Constants.SUBPROCESS_RATING && analysis[0].arce__Financial_Statements__r.size() > 0) {
            final arce__Analysis__c arceToUpdate = new arce__Analysis__c(id = analysis[0].arce__Analysis__c,
            arce__analysis_risk_expiry_date__c = analysis[0].arce__Financial_Statements__r.get(0).arce__financial_statement_end_date__c.addMonths(Integer.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(FFSS_END_DATE)[0].arce__Value1__c)));
            arce.Arc_Gen_ArceAnalysis_Data.updateArce(new List<arce__Analysis__c>{arceToUpdate});
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description assign rating data
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param String parentId parent of the record
    * @param String analysisId  id of analysis
    * @return void (update arce__rating_variables_detail__c)
    * @example public static void setRatingVariables(String parentId,String analysisId) {
    **/
    private static void setRatingVariables(String parentId,String analysisId) {
        final Arc_Gen_Balance_Tables_data locator = new Arc_Gen_Balance_Tables_data();
        final List<arce__rating_variables_detail__c> varList = new List<arce__rating_variables_detail__c>();
        for(Integer i = 0; i <= 2; i++) {
            final arce__rating_variables_detail__c variable = new arce__rating_variables_detail__c();
            variable.arce__rating_id__c = parentId;
            variable.arce__account_has_analysis_id__c = analysisId;
            varList.add(variable);
        }
        locator.insertRecords(varList);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description assign rating to ffss
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param arce__Financial_Statements__c ffssValid
    * @param String ratingId  id of the rating
    * @return void (update ffss)
    * @example public static void setRatingToFS(arce__Financial_Statements__c ffssValid,String ratingId) {
    **/
    private static void setRatingToFS(arce__Financial_Statements__c ffssValid,String ratingId) {
        final Arc_Gen_Balance_Tables_data locator = new Arc_Gen_Balance_Tables_data();
        ffssValid.arce__rating_id__c = ratingId;
        locator.updateRecord(ffssValid);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description validate FFSS
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param arce__Financial_Statements__c ffss to check
    * @return Bool (true if FinancialStatement is valid)
    * @example private static Boolean validateFSForRating(arce__Financial_Statements__c ffss) {
    **/
    public static Boolean validateFSForRating(arce__Financial_Statements__c ffss) {
        Boolean validate;
        final Boolean isRaipCorp = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c);
        final String period = ffss.arce__economic_month_info_number__c;
        final Date endDate = ffss.arce__financial_statement_end_date__c;
        final String certification = ffss.arce__ffss_certification_type__c;

        if ((period == '12' && endDate.monthsBetween(Date.today()) >= 0 && endDate.monthsBetween(Date.today()) <= 20 && isRaipCorp &&(certification == FFSS_CT_AUDITED || certification == FFSS_CT_FISCAL || certification == FFSS_CT_TREGISTRY)) || (period == '12' && endDate.monthsBetween(Date.today()) < 20 &&  !isRaipCorp && (certification == FFSS_CT_AUDITED || certification == FFSS_CT_FISCAL || certification == FFSS_CT_TREGISTRY || certification == PRO_FORMA_MERGER || certification == PROFORMA || certification == PRO_FORMA_MERGER || certification == PRO_FORMA_ACQUISITION))) {
            validate = true;
        } else {
            validate = false;
        }

        return validate;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description validate FFSS list
    *--------------------------------------------------------------------------------
    * @author   ARCE TEAM
    * @date     08/11/2021
    * @param    arce__Account_has_Analysis__c aha
    * @param    List<arce__Financial_Statements__c>
    * @return   List<arce__Financial_Statements__c>
    * @example  List<arce__Financial_Statements__c> lst = validateFSForRatingInit(aha, lstFfss);
    **/
    public static List<arce__Financial_Statements__c> validateFSForRatingInit(arce__Account_has_Analysis__c aha, List<arce__Financial_Statements__c> lstFfss) {
        final List<arce__Financial_Statements__c> ffssListActive = new List<arce__Financial_Statements__c>();
        Integer validateUnique = 0;
        for (arce__Financial_Statements__c ffss : lstFfss) {
            ffss.arce__ffss_valid_type__c = getFfssValidType(validateFSForRating(ffss));
            if (ffss.arce__ffss_valid_type__c == FFSS_VALID) {
                validateUnique++;
            }
            ffssListActive.add(ffss);
        }
        if (validateUnique > NUM_MAX_EEFF) {
            final arce__Financial_Statements__c ffssValid = validationFFSSRating(aha, new List<arce__Financial_Statements__c>(lstFfss));
            for (arce__Financial_Statements__c ffss : ffssListActive) {
                if (ffss.arce__financial_statement_id__c == ffssValid.arce__financial_statement_id__c) {
                    ffss.arce__ffss_valid_type__c = FFSS_VALID;
                } else {
                    ffss.arce__ffss_valid_type__c = FFSS_NOT_VALID;
                }
            }
        }
        return ffssListActive;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description apply FFSS list
    *--------------------------------------------------------------------------------
    * @author   ARCE TEAM
    * @date     08/11/2021
    * @param    arce__Account_has_Analysis__c aha
    * @param    List<arce__Financial_Statements__c>
    * @return   List<arce__Financial_Statements__c>
    * @example  List<arce__Financial_Statements__c> lst = applyFSForRatingInit(aha, lstFfss);
    **/
    public static List<arce__Financial_Statements__c> applyFSForRatingInit(List<arce__Financial_Statements__c> lstFfss, Boolean isAnchor) {
        for (arce__Financial_Statements__c ffss : lstFfss) {
            if(isAnchor && lstFfss.indexOf(ffss) == 0) {
                ffss.arce__ffss_apply_for_rating_type__c = '1';
            } else {
                ffss.arce__ffss_apply_for_rating_type__c = '2';
            }
        }

        return lstFfss;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description sets the variables to make the Test Leverage
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param analysisId recordId of the account_has_analysis
    * @param FinancialStatement to be updated
    * @return void
    * @example public static void setLeverageVariables(String analysisId,arce__Financial_Statements__c validFS) {
    **/
    private static void setLeverageVariables(String analysisId,arce__Financial_Statements__c validFS) {
        final Arc_Gen_Balance_Tables_data locator = new Arc_Gen_Balance_Tables_data();
        final arce__Account_has_Analysis__c analyzedClient = locator.getAccountHasAnalysis(analysisId)[0];
        final String unitSelected = analyzedClient.arce__ffss_for_rating_id__r.arce__magnitude_unit_type__c;
        final double divFactor = getDivFactor(unitSelected);
        Arc_Gen_TestLeverage_data locatorCR = new Arc_Gen_TestLeverage_data();
        final double convertionRate = Double.valueOf(locatorCR.getCurrency(analyzedClient.arce__ffss_for_rating_id__r.currencyIsoCode).get('ConversionRate'));
        final List<arce__Table_Content_per_Analysis__c> variablesList = locator.getLeverageVariables(analysisId,validFS.arce__financial_statement_id__c);
        for(arce__Table_Content_per_Analysis__c item : variablesList) {
            switch on item.arce__Data_Collection_Id__r.arce__collection_code_term__c {
                when 'totalRevenues' {
                    analyzedClient.arce__total_revenues_local_amount__c = (item.arce__table_content_value__c*convertionRate)/divFactor;
                }
                when 'totalAssets' {
                    analyzedClient.arce__total_asset_local_amount__c = (item.arce__table_content_value__c*convertionRate)/divFactor;
                }
                when 'grossFinancialDebt' {
                    analyzedClient.arce__gross_financial_debt_local_amount__c = (item.arce__table_content_value__c*convertionRate)/divFactor;
                }
                when 'ebitda' {
                    analyzedClient.arce__ebitda_interest_local_number__c = (item.arce__table_content_value__c*convertionRate)/divFactor;
                }
                when 'netFinancialDebt' {
                    analyzedClient.arce__debt_comt_not_disb_local_amount__c = item.arce__table_content_value__c;
                }
            }
        }
        locator.updateRecord(analyzedClient);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Return the multiplication factor to convert the unit selected in units
    * --------------------------------------------------------------------------------------
    * @Author   César Octavio Villanueva Ceballos  cesaroctavio.villanueva.cebal@bbva.com
    * @Date     Created: 09/06/2020
    * @param unitSelected - unit selected in combo box
    * @return divFactor - factor of divition to convert the unit selected in units
    * @example getDivFactor(unitSelected)
    * --------------------------------------------------------------------------------------
    **/
    public static Double getDivFactor(String unitSelected) {
        Double divFactor = 1;
        switch on unitSelected {
            when '1' {
                divFactor = 1000000;
            }
            when '2' {
                divFactor = 1000;
            }
            when '3' {
                divFactor = 1;
            }
        }
        return divFactor;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description check if FFSS exist previously
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param List<arce__Financial_Statements__c> ffss for new records
    * @param String analysisId accountHasAnalysis Id
    * @return List<arce__Financial_Statements__c> (only news)
    * @example public static List<arce__Financial_Statements__c> getNewRecordsOnly(List<arce__Financial_Statements__c> newFFSS,String analysisId) {
    **/
    public static List<arce__Financial_Statements__c> getNewRecordsOnly(List<arce__Financial_Statements__c> newFFSS,String analysisId) {
        final Arc_Gen_Balance_Tables_data locator = new Arc_Gen_Balance_Tables_data();
        List<arce__Financial_Statements__c> onlyNewFFSS = new List<arce__Financial_Statements__c>();
        final List<arce__Financial_Statements__c> oldFFSS = locator.getExistentFinancialStatements(analysisId);
        if (oldFFSS.isEmpty()) {
            onlyNewFFSS = newFFSS;
        } else {
            for(arce__Financial_Statements__c newFS : newFFSS) {
                Boolean existent = false;
                for(arce__Financial_Statements__c oldFS : oldFFSS) {
                    if(newFS.arce__financial_statement_id__c == oldFS.arce__financial_statement_id__c && newFS.arce__account_has_analysis_id__c == oldFS.arce__account_has_analysis_id__c) {
                        existent = true;
                    }
                }
                if(!existent) {
                    onlyNewFFSS.add(newFS);
                }
            }
        }
        return onlyNewFFSS;
    }
    /**
    *--------------------------------------------------------------------------------------
    * @description Set the data of the choosen ffss in the account has analysis object
    *--------------------------------------------------------------------------------------
    * @author  mariohumberto.ramirez.contractor@bbva.com
    * @date     23/10/2019
    * @param recordId - Id of the account has analysis data
    * @param chosenFS - arce__Financial_Statements__c object
    * @return void
    * @example setFFSSToAccHasAnalysis(recordId,chosenFS)
    *--------------------------------------------------------------------------------------
    **/
    private static void setFFSSToAccHasAnalysis(String recordId, arce__Financial_Statements__c chosenFS) {
        final Arc_Gen_Balance_Tables_data locator = new Arc_Gen_Balance_Tables_data();
        final arce__Account_has_Analysis__c acchasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId})[0];
        acchasAn.arce__magnitude_unit_type__c = chosenFS.arce__magnitude_unit_type__c;
        acchasAn.arce__ffss_submitted_type__c = chosenFS.arce__ffss_submitted_type__c;
        acchasAn.arce__currency_id__c = chosenFS.arce__magnitude_unit_type__c == null ? null : chosenFS.CurrencyIsoCode;
        locator.updateRecord((arce__Account_has_Analysis__c)acchasAn);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description retrieve percentage from map when percentage is optional
    *--------------------------------------------------------------------------------
    * @author  ARCE TEAM
    * @date     11/04/2019
    * @param Map<String, Object> elemntMap
    * @return Decimal
    * @example getPercentFromMap(elemntMap)
    **/
    public static Decimal getPercentFromMap(Map<String, Object> elemntMap) {
        return elemntMap.get('percentage') == null ? null : Decimal.valueOf(String.valueOf(elemntMap.get('percentage')));
    }
    /**
    * @description copy table content per analysis records to acc has analysis
    *--------------------------------------------------------------------------------
    * @author  mariohumberto.ramirez.contractor@bbva.com
    * @date    2020-04-14
    * @param List<arce__Financial_Statements__c> ffss
    * @return arce__Financial_Statements__c record
    * @example public static arce__Financial_Statements__c checkEeffPreviousValid(List<arce__Financial_Statements__c> ffss) {
    **/
    public static List<arce__Financial_Statements__c> checkEeffPreviousValid(List<arce__Financial_Statements__c> ffssToProcess, arce__Financial_Statements__c finStateValidObj) {
        List<arce__Financial_Statements__c> fsPrevYearLts = new List<arce__Financial_Statements__c>();
        if (String.isNotBlank(finStateValidObj.Id)) {
            for (arce__Financial_Statements__c fs: ffssToProcess) {
                if (fs.Id != finStateValidObj.Id && fs.arce__economic_month_info_number__c == '12' && finStateValidObj.arce__financial_statement_end_date__c.year() - 1 == fs.arce__financial_statement_end_date__c.year()) {
                    fs.arce__previous_valid__c = true;
                    fsPrevYearLts.add(fs);
                }
            }
        }
        return fsPrevYearLts;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Check if a cliente (AHA) is matrix and filter the individual subsidiary type
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   arce__Financial_Statements__c ffss
    * @param   arce__Account_has_Analysis__c accHas
    * @return  Boolean
    * @example Boolean val = Arc_Gen_Balance_Tables_helper.checkMatrixCustomer(ffss, accHas);
    **/
    public static Boolean checkMatrixCustomer(arce__Financial_Statements__c ffss, arce__Account_has_Analysis__c accHas) {
        Boolean retValue = true;
        if (accHas.arce__main_subsidiary_ind_type__c == true) {
            retValue = ffss.arce__ffss_submitted_type__c == FFSS_TYPE_INDIV ? true : false;
        }
        return retValue;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Validation of the financial statements before call the rating engine
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   arce__Account_has_Analysis__c
    * @param   List<arce__Financial_Statements__c> financial statements selected for valid
    * @return  List<arce__Financial_Statements__c> return a list with one valid financial statement
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.validationFFSSRating(accAha, selectedFfssList);
    **/
    public static arce__Financial_Statements__c validationFFSSRating(arce__Account_has_Analysis__c accAha, List<arce__Financial_Statements__c> selectedFFSS) {
        final Boolean isHolding = accAha.arce__main_subsidiary_ind_type__c;
        if(selectedFFSS.size() > MAX_EEFF) {
            // If the customer is matrix type
            if (isHolding) {
                filterGlobal(selectedFFSS);
            } else {
                // Filtering of the financial statements for select the consolidated submit type
                filterConsolidatedFFSS(selectedFFSS);
                if (selectedFFSS.size() > MAX_EEFF) {
                    filterGlobal(selectedFFSS);
                }
            }
        }
        return selectedFFSS[0];
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that groups all the filters applied in the financial statements.
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  List<arce__Financial_Statements__c> list of financial statements filtered
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.filterGlobal(ffssList);
    **/
    public static void filterGlobal(List<arce__Financial_Statements__c> ffssList) {
        filterCertificationType(ffssList);
        if (ffssList.size() > MAX_EEFF) {
            orderDescDateFFSS(ffssList);
            if (ffssList.size() > MAX_EEFF) {
                final List<arce__Financial_Statements__c> ffssDateFiltered = filterSameEndDate(ffssList);
                if (!ffssDateFiltered.isEmpty()) {
                    ffssList.clear();
                    ffssList.addAll(ffssDateFiltered);
                    filterAdjustedTypeFFSS(ffssList);
                }
            }
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that return the financial statements with the same date of the ffss list
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  List<arce__Financial_Statements__c> list of financial statements with same dates
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.filterSameEndDate(ffssList);
    **/
    public static List<arce__Financial_Statements__c> filterSameEndDate(List<arce__Financial_Statements__c> ffssList) {
        List<arce__Financial_Statements__c> ffssSameDate = new List<arce__Financial_Statements__c>();
        List<Id> ffssIdTemp = new List<Id>();
        for (Integer i = 0; i < (ffssList.size() - 1); i++) {
            final Date ffssEndDate = ffssList[i].arce__financial_statement_end_date__c;
            if (ffssList[0].arce__financial_statement_end_date__c == ffssEndDate && ffssList[i + 1].arce__financial_statement_end_date__c == ffssEndDate) {
                if (!ffssIdTemp.contains(ffssList[i].Id)) {
                    ffssSameDate.add(ffssList[i]);
                    ffssIdTemp.add(ffssList[i].Id);
                }
                ffssSameDate.add(ffssList[i + 1]);
                ffssIdTemp.add(ffssList[i + 1].Id);
            }
        }
        return ffssSameDate;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Sorts the list of financial statements by end date
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  void
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.orderDescDateFFSS(ffssList);
    **/
    public static void orderDescDateFFSS(List<arce__Financial_Statements__c> ffssList) {
        Boolean swapped = false;
        do {
            swapped = false;
            for (Integer i = 0; i < (ffssList.size() - 1); i++) {
                if (ffssList[i].arce__financial_statement_end_date__c < ffssList[i + 1].arce__financial_statement_end_date__c) {
                    swap(ffssList, i, i + 1);
                    swapped = true;
                }
            }
        } while (swapped == true);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Swap method for sort algorithm orderDescDateFFSS method
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  void
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.orderDescDateFFSS(ffssList);
    **/
    public static void swap(List<arce__Financial_Statements__c> inArray, Integer idx, Integer jdx) {
        final List<arce__Financial_Statements__c> inArrayTemp = new List<arce__Financial_Statements__c>();
        inArrayTemp.addAll(inArray);
        inArrayTemp[idx] = inArray[jdx];
        inArrayTemp[jdx] = inArray[idx];
        inArray.clear();
        inArray.addAll(inArrayTemp);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Group by type of certification and filtering, giving priority to Audit, Fiscal and Trade Registry
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  void
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.orderDescDateFFSS(ffssList);
    **/
    public static void filterCertificationType(List<arce__Financial_Statements__c> ffssList) {
        List<arce__Financial_Statements__c> ffssAudited = new List<arce__Financial_Statements__c>();
        List<arce__Financial_Statements__c> ffssFiscal = new List<arce__Financial_Statements__c>();
        List<arce__Financial_Statements__c> ffssTRegistry = new List<arce__Financial_Statements__c>();
        List<arce__Financial_Statements__c> ffssRestantes = new List<arce__Financial_Statements__c>();

        for(arce__Financial_Statements__c ffss : ffssList) {
            if (ffss.arce__ffss_certification_type__c == FFSS_CT_AUDITED) {
                ffssAudited.add(ffss);
            } else if (ffss.arce__ffss_certification_type__c == FFSS_CT_FISCAL) {
                ffssFiscal.add(ffss);
            } else if (ffss.arce__ffss_certification_type__c == FFSS_CT_TREGISTRY) {
                ffssTRegistry.add(ffss);
            } else {
                ffssRestantes.add(ffss);
            }
        }
        ffssList.clear();
        ffssList.addAll(ffssAudited.isEmpty() ? (ffssFiscal.isEmpty() ? (ffssTRegistry.isEmpty() ? ffssRestantes : ffssTRegistry) : ffssFiscal) : ffssAudited);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Filter all the consolidated submitted type of the list financial statements
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  void
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.filterConsolidatedFFSS(ffssList);
    **/
    public static void filterConsolidatedFFSS(List<arce__Financial_Statements__c> ffssList) {
        List<arce__Financial_Statements__c> ffssConsolidated = new List<arce__Financial_Statements__c>();
        for (arce__Financial_Statements__c ffss : ffssList) {
            if (ffss.arce__ffss_submitted_type__c == FFSS_TYPE_CONSOL) {
                ffssConsolidated.add(ffss);
            }
        }
        if (!ffssConsolidated.isEmpty()) {
            ffssList.clear();
            ffssList.addAll(ffssConsolidated);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Filter all the adjusted type of financial statements.
    * There are two way usage this method, the first returns complete list with the change the validate status.
    * In the second option, it's inteded for receive two eeff only. Overwriting ffssList param with the adjusted eeff unique.
    *--------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    2020-06-24
    * @param   List<arce__Financial_Statements__c> list of financial statements
    * @return  List<arce__Financial_Statements__c>
    * @example List<arce__Financial_Statements__c> lstRet = Arc_Gen_Balance_Tables_helper.filterAdjustedTypeFFSS(ffssList);
    **/
    public static List<arce__Financial_Statements__c> filterAdjustedTypeFFSS(List<arce__Financial_Statements__c> ffssList) {
        final List<arce__Financial_Statements__c> ffssAdjustedRet = new List<arce__Financial_Statements__c>();
        final List<arce__Financial_Statements__c> ffssAdjustedType = new List<arce__Financial_Statements__c>();
        final Boolean isRaipCorp = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIPSelectWorkflow')[0].arce__Value1__c);
        if (!isRaipCorp) {
            // Existe un EEFF ajustado y otro no ajustado, nos quedaremos con el ajustado
            Boolean existAdjusted = false;
            for (arce__Financial_Statements__c ffss : ffssList) {
                if (ffss.arce__ffss_adjusted_type__c == FFSS_ADJUSTEDTYPE) {
                    ffssAdjustedType.add(ffss);
                    existAdjusted = ffss.arce__ffss_valid_type__c == FFSS_VALID && !existAdjusted ? true : existAdjusted;
                }
                ffssAdjustedRet.add(ffss);
            }
            // If there is a valid adjusted eeff and another unadjusted, only the adjusted eeff is valid.
            for (arce__Financial_Statements__c ffss : ffssAdjustedRet) {
                if (existAdjusted && ffss.arce__ffss_valid_type__c == FFSS_VALID && ffss.arce__ffss_adjusted_type__c == FFSS_NO_ADJUSTEDTYPE) {
                    ffss.arce__ffss_valid_type__c = FFSS_NOT_VALID;
                }
            }
            ffssList.clear();
            ffssList.addAll(ffssAdjustedType);
        } else {
            ffssAdjustedRet.addAll(ffssList);
        }
        return ffssAdjustedRet;
    }

}