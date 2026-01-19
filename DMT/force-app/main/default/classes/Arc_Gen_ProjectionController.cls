/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ProjectionController
* @Author   joseluis.miralles.contractor@bbva.com
* @Date     Created: 22-05-2023
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Arc_Gen_ProjectionStandAlone.cmp Arc_Gen_Perspective_Projection.cmp
* ------------------------------------------------------------------------------------------------
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessiveParameterList, sf:LongVariable, sf:UseObjectForClearerAPI, sf:AvoidGetSetMethods')
public with sharing class Arc_Gen_ProjectionController {
    /**
    * @Description Literal string value "text" used to describe field type. 
    */
    private static final String STRING_VALUE_TEXT = 'text';
    /**
    * @Description String value used to describe callable class.
    */
    private static final String CALLABLE_CLASS_NAME = Test.isRunningTest() ? 'Arc_Gen_CallableFromCore_Mock' : 'arce.Arc_Gen_CallableFromCore';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor to avoid SonarQube warning.
    *-------------------------------------------------------------------------------
    **/
    private Arc_Gen_ProjectionController() { }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get columns in calculate projections EEFF list
    * ----------------------------------------------------------------------------------------------------
    * @Author   joseluis.miralles.contractor@bbva.com
    * @Date     Created: 22-05-2023
    * @param void
    * @return String
    * ----------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String getDynamicColumns(Boolean isRating) {
        final JSONGenerator gen = JSON.createGenerator(isRating);
        gen.writeStartArray();
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Date, 110, 'arce__financial_statement_end_date__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Period, 82, 'arce__economic_month_info_number__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Certification, null, 'arce__ffss_certification_type__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_Type, null, 'arce__ffss_submitted_type__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, System.Label.Lc_arce_AdjustedType, null, 'arce__ffss_adjusted_type__c', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, 'Id', 75, 'shortId', STRING_VALUE_TEXT, null, null);
        Arc_Gen_ModalFinanStatemController.writeNewCol(gen, 'Used', null, 'arce__Is_used_in_analisys__c', 'boolean', null, null);
        gen.writeEndArray();
        return gen.getAsString();
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get data from EEFF
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    varRecord
    * @param    isFinancialRAIP
    * @param    isRAIP
    * @param    ratingToolSelect
    * @param    requestedPage
    * @return   Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper
    * @example    Arc_Gen_ProjectionController.fetchFinancialStatements(varRecord,isFinancialRAIP,isRAIP,ratingToolSelect,requestedPage);
    */
    @AuraEnabled
    public static Arc_Gen_ModalFinanStatemController.FinancialStatementsFetchWrapper fetchFinancialStatements(String varRecord, Boolean isFinancialRAIP, Boolean isRAIP, String ratingToolSelect, Integer requestedPage) {
        try {
            return Arc_Gen_ModalFinanStatemController.fetchFinancialStatements(varRecord, isFinancialRAIP, isRAIP, ratingToolSelect, requestedPage);
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get projection data from each scenario
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId
    * @param    scenario
    * @param    isSimulation
    * @return   Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper
    * @example    Arc_Gen_ProjectionController.getScenarioData(recordId,scenario,isSimulation);
    */
    @AuraEnabled
    public static Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper getScenarioData(String recordId, string scenario, Boolean isSimulation, String proposalId) {
        try {
            Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper wrapper = new Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper();
            wrapper = Arc_Gen_Projection_Helper.getScenarioDataHelper(recordId, scenario, isSimulation, proposalId);
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author
    * @param    recordId
    * @param    scenario
    * @param    isSimulation
    * @return   Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper
    * @example  Arc_Gen_ProjectionController.getScenarioData(recordId,scenario,isSimulation);
    */
    @AuraEnabled
    public static List<String> callProjectionService(String scenarioType, String ahaId, List<String> financialStatemIds, String proposalId) {
        arce.Arc_Gen_Projection_ServiceWrapper serviceWrapper = new arce.Arc_Gen_Projection_ServiceWrapper();
        final List<String> errorsList = new List<String>();
        try {
            final Set<String> setListIds = new Set<String>(financialStatemIds);
            serviceWrapper = Arc_Gen_Projection_Service.callProjection(scenarioType, ahaId, setListIds, proposalId);
            for (arce.Arc_Gen_GlobalMessage.Message message : serviceWrapper.messageList) {
                errorsList.add(message.errorCode + ' ' + message.description + ' ' + message.detailedMessage);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
        return errorsList;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to update projection keyassumptions Data
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    editedValues
    * @param    scenario
    * @param    editCase
    * @param    projectionCriteria
    * @param    ahaId
    * @return   void
    * @example    Arc_Gen_ProjectionController.updateKeyAssumptions(editedValues,scenario,editCase,projectionCriteria,ahaId);
    */
    @AuraEnabled
    public static Map<String, List<String>> updateKeyAssumptions(String editedValues, string scenario, string editCase, string projectionCriteria, String ahaId, String unitsReal, String proposalId) {
        try {
            Map<String,List<String>> listValidationErrors = new Map<String,List<String>> ();
            Map<String, Map<String, Double>> mapJSProjecc = (Map<String, Map<String, Double>>)JSON.deserialize(editedValues, Map<String, Map<String, Double>>.class);
            listValidationErrors =   Arc_Gen_Projection_Helper.updateKeyAssumptionsHelper(mapJSProjecc, scenario, editCase, projectionCriteria, ahaId, unitsReal, proposalId);
            return listValidationErrors;
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get all scenarios simulation data
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId
    * @return   Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper
    * @example    Arc_Gen_ProjectionController.getSimulationData(recordId);
    */
    @AuraEnabled
    public static Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper getSimulationData(String recordId, String proposalId) {
        try {
            Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper wrapperContent = new Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper();
            wrapperContent = Arc_Gen_Projection_Helper.getSimulationDataHelper(recordId, proposalId);
            return wrapperContent;
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get all scenarios simulation data
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId
    * @param    scenario
    * @param    controlValue
    * @return   void
    * @example    Arc_Gen_ProjectionController.updateControlValues(recordId,scenario,controlValue);
    */
    @AuraEnabled
    public static void updateControlValues(String recordId, String scenario, Boolean controlValue, String proposalId) {
        try {
            Arc_Gen_Projection_Helper.updateControlValues(recordId, scenario, controlValue, proposalId);
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to update scenario Comment
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId
    * @param    scenario
    * @param    scenarioComment
    * @return   void
    * @example    Arc_Gen_ProjectionController.updateScenarioComment(recordId,scenario,scenarioComment);
    */
    @AuraEnabled
    public static void updateScenarioComment(String recordId, String scenario, String scenarioComment, String proposalId) {
        try {
            Arc_Gen_Projection_Helper.updateScenarioComment(recordId, scenario, scenarioComment, proposalId);
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to check projections control values
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author    joseluis.miralles.contractor@bbva.com
    * @param    recordId
    * @param    scenario
    * @param    isSimulation
    * @return   Arc_Gen_Projection_Helper.ControlrAnalysisWrapper
    * @example    Arc_Gen_ProjectionController.checkControlValues(recordId,scenario,isSimulation);
    */
    @AuraEnabled
    public static Arc_Gen_Projection_Helper.ControlrAnalysisWrapper checkControlValues(String recordId, String scenario, Boolean isSimulation, String proposalId) {
        try {
            Arc_Gen_Projection_Helper.ControlrAnalysisWrapper wrapperValues = new Arc_Gen_Projection_Helper.ControlrAnalysisWrapper();
            wrapperValues = Arc_Gen_Projection_Helper.checkControlValues(recordId, scenario, isSimulation, proposalId);
            return wrapperValues;
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to call standalone simulation for projections
    *--------------------------------------------------------------------------------
    * @date     01/04/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    recordId
    * @param    projectionId
    * @return   List<String>
    * @example  Arc_Gen_ProjectionController.callStandAlone(recordId,projectionId);
    */
    @AuraEnabled
    public static List<String> callStandAlone(String recordId, String projectionId) {
        arce.Arc_Gen_Projection_ServiceWrapper wrapperValues = new arce.Arc_Gen_Projection_ServiceWrapper();
        final List<String> errorsList = new List<String>();
        try {
            wrapperValues = Arc_Gen_Projection_Service.callProjectionRating(recordId, projectionId);
            for (arce.Arc_Gen_GlobalMessage.Message message : wrapperValues.messageList) {
                errorsList.add(message.errorCode + ' ' + message.description + ' ' + message.detailedMessage);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
        return errorsList;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to call standalone simulation for projections
    *--------------------------------------------------------------------------------
    * @date     01/04/2023
    * @author   joseluis.miralles.contractor@bbva.com
    * @param    recordId
    * @param    projectionId
    * @return   List<String>
    * @example  Arc_Gen_ProjectionController.callStandAlone(recordId,projectionId);
    */
    @AuraEnabled
    public static arce__Account_has_Analysis__c getAhaObject(String recordId) {
        return arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{recordId})[0];
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to call recalculateUnits
    *--------------------------------------------------------------------------------
    * @date     22/07/2024
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @param    ahaId
    * @return   List<String>
    * @example  Arc_Gen_ProjectionController.recalculateUnits(ahaId);
    */
    @AuraEnabled
    @future(callout=true)
    public static void recalculateUnits(String ahaId) {
        Callable callableFromCore = (Callable) Type.forName(CALLABLE_CLASS_NAME).newInstance();
        final String respJson = (String) callableFromCore.call('recalculateUnits', new Map<String, Object> {'ahaId' => ahaId});
        System.debug(LoggingLevel.INFO, 'recalculateUnits response: ' + respJson);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to call recalculateCurrency
    *--------------------------------------------------------------------------------
    * @date     22/07/2024
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @param    ahaId
    * @return   List<String>
    * @example  Arc_Gen_ProjectionController.recalculateCurrency(ahaId);
    */
    @AuraEnabled
    @future(callout=true)
    public static void recalculateCurrency(String ahaId) {
        Callable callableFromCore = (Callable) Type.forName(CALLABLE_CLASS_NAME).newInstance();
        final String respJson = (String) callableFromCore.call('recalculateCurrency', new Map<String, Object> {'ahaId' => ahaId});
        System.debug(LoggingLevel.INFO, 'recalculateCurrency response: ' + respJson);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description
    *--------------------------------------------------------------------------------
    * @date        01/04/2023
    * @author
    * @param    recordId
    * @param    scenario
    * @param    isSimulation
    * @return   Arc_Gen_Projection_Helper.TableContentPerAnalysisWrapper
    * @example  Arc_Gen_ProjectionController.getScenarioData(recordId,scenario,isSimulation);
    */
    @AuraEnabled
    public static List<String> callCloneProjection(String scenarioType, String ahaId, String proposalId) {
        arce.Arc_Gen_Projection_ServiceWrapper serviceWrapper = new arce.Arc_Gen_Projection_ServiceWrapper();
        final List<String> errorsList = new List<String>();
        try {
            serviceWrapper = Arc_Gen_Projection_Service.callCloneProjection(scenarioType, ahaId, proposalId);
            for (arce.Arc_Gen_GlobalMessage.Message message : serviceWrapper.messageList) {
                errorsList.add(message.errorCode + ' ' + message.description + ' ' + message.detailedMessage);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+ex);
        }
        return errorsList;
    }  
}