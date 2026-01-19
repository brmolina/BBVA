/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PersistenceQualitative_Service
* @Author   José Luis García Díaz   joseluis.garcia4.contractor@bbva.com
* @Date     Created: 08/05/2020
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class that interfaces with the qualitative blocks service to persist
* qualitative variables.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-08 joseluis.garcia4.contractor@bbva.com
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_PersistenceQualitative_Service {
    /**
    * @Description: Name of the service to be called.
    */
    public static final String SERVICE_NAME = 'qualitativeBlocks';

    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper used to return the results from the variable persistence.
    *-------------------------------------------------------------------------------
    **/
    global class VariablePersistenceResult {
        /**
        * @Description: Code returned by the service.
        */
        global String serviceCode { get; set; }
        /**
        * @Description: Response returned by the service.
        */
        global String serviceMessage { get; set; }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper used to describe a qualitative variable in the same format
    * as required by the service.
    *-------------------------------------------------------------------------------
    **/
    public class QualitativeVariableWrapper {
        /**
        * @Description: Unique identification of the qualitative variable in the rating model.
        */
        public String id { get; set; }
        /**
        * @Description: Value of the variable used within the rating.
        */
        public String value { get; set; }
        /**
        * @Description: Specifies if the data is a block or a factor within a rating model.
        */
        public String variableType { get; set; }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper used to describe the parameters to be provided to the service.
    *-------------------------------------------------------------------------------
    **/
    private class QualitativeBlocksParamSet {
        /**
        * @Description: Unique risk assessment identifier.
        */
        public String riskAssessmentId { get; set; }
        /**
        * @Description: Unique participant identifier.
        */
        public String participantId { get; set; }
        /**
        * @Description: Unique identification of the qualitative block (the same ID as the risk
        * assessment will be used).
        */
        public String qualitativeBlockId { get; set; }
        /**
        * @Description: JSON object to be provided to the service in the request body.
        */
        public String jsonIn { get; set; }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor to avoid SonarQube warning.
    *-------------------------------------------------------------------------------
    **/
    private Arc_Gen_PersistenceQualitative_Service() { }  // NOPMD

    /**
    *-------------------------------------------------------------------------------
    * @description Persists the qualitative variables of the fields filled in the
    * Account_has_Analysis__c record.
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 08/05/2020
    * @param arce__Account_has_Analysis__c ahaObject - AHA object the variables with the variables to be persisted.
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Service response.
    **/
    global static VariablePersistenceResult persistVariablesOfAnalysis(arce__Account_has_Analysis__c ahaObject) {
        // Get variables that need to be persisted.
        final List<QualitativeVariableWrapper> variablesToPersist = getVariablesToPersist(ahaObject);

        // Get all the information about the AHA.
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper ahaFullObject = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(new List<String> { ahaObject.Id })[0];

        // Call service.
        final arce.Arc_Gen_ServiceAndSaveResponse resp = persistQualitativeVariables(ahaFullObject.ahaObj.Name, ahaFullObject.accWrapperObj.accNumber, variablesToPersist);

        // Return response.
        final VariablePersistenceResult result = new VariablePersistenceResult();
        result.serviceCode = resp.serviceCode;
        result.serviceMessage = resp.serviceMessage;
        return result;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Gets the list of variables to persist from the provided AHA.
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 08/05/2020
    * @param arce__Account_has_Analysis__c ahaObject - AHA object the variables with the variables to be persisted.
    * @return List<QualitativeVariableWrapper> - The variables to be persisted.
    **/
    private static List<QualitativeVariableWrapper> getVariablesToPersist(arce__Account_has_Analysis__c ahaObject) {
        final Map<String, arce.Arc_Gen_PersistenceQualitative_Data.QualitativeVariableDefinition> variablesByApiName =
            arce.Arc_Gen_PersistenceQualitative_Data.getQualitativeVariablesDefinition();
        final List<QualitativeVariableWrapper> variablesToPersist = new List<QualitativeVariableWrapper>();

        for (String fieldApiName : ahaObject.getPopulatedFieldsAsMap().keySet()) {
            if (variablesByApiName.containsKey(fieldApiName)) {
                final arce.Arc_Gen_PersistenceQualitative_Data.QualitativeVariableDefinition variableDef =
                    variablesByApiName.get(fieldApiName);

                final QualitativeVariableWrapper variableToPersist = new QualitativeVariableWrapper();
                variableToPersist.id = variableDef.id;
                variableToPersist.variableType = variableDef.type;
                variableToPersist.value = ahaObject.get(fieldApiName) == null ? '' : String.valueOf(ahaObject.get(fieldApiName));
                variablesToPersist.add(variableToPersist);
            }
        }

        return variablesToPersist;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Calls the qualitativeBlocks persistence service to save the provided qualitative
    * variables of an ARCE.
    *-------------------------------------------------------------------------------
    * @author joseluis.garcia4.contractor@bbva.com
    * @date 08/05/2020
    * @param String riskAssessmentId - Risk assessment ID.
    * @param String customerNumber - Participant ID.
    * @param List<QualitativeVariableWrapper> variablesToPersist - List of variables to be persisted.
    * @return arce.Arc_Gen_ServiceAndSaveResponse - Wrapper that contains the response of the called service.
    **/
    private static arce.Arc_Gen_ServiceAndSaveResponse persistQualitativeVariables(String riskAssessmentId,
            String customerNumber, List<QualitativeVariableWrapper> variablesToPersist) {
        final arce.Arc_Gen_ServiceAndSaveResponse serviceAndSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();

        if (variablesToPersist.isEmpty()) {
            serviceAndSaveResp.serviceCode = '200';
            serviceAndSaveResp.serviceMessage = 'No variables persisted';
        } else {
            // Set service parameters.
            final Map<String, Object> outerVarMap = new Map<String, Object>();
            outerVarMap.put('qualitativeVariables', variablesToPersist);

            final QualitativeBlocksParamSet serviceParams = new QualitativeBlocksParamSet();
            serviceParams.riskAssessmentId = riskAssessmentId;
            serviceParams.participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(customerNumber);
            serviceParams.qualitativeBlockId = riskAssessmentId;
            serviceParams.jsonIn = JSON.serialize(outerVarMap);

            // Call service.
            final String jsonInput = JSON.serialize(serviceParams);
            final arce.Arc_Gen_getIASOResponse.serviceResponse response = arce.Arc_Gen_getIASOResponse.calloutIASO(SERVICE_NAME, jsonInput);
            serviceAndSaveResp.serviceCode = response.serviceCode;
            serviceAndSaveResp.serviceMessage = response.serviceMessage;
        }

        return serviceAndSaveResp;
    }
}