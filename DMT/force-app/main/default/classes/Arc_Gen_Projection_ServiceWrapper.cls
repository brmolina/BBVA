/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Projection_ServiceWrapper
* @Author   aleksandar.dinkov.contractor@bbva.com
* @Date     Created: 21/05/2023
* @Group    ARCE
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 09-13-2024
* @Description Arc_Gen_Projection_ServiceWrapper
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:AvoidPublicFields, sf:LongVariable, sf:ShortVariable, sf:AvoidFieldNameMatchingTypeName, sf:AvoidFinalLocalVariable')
public with sharing class Arc_Gen_Projection_ServiceWrapper {
    /**
    * @Description: internalScenType
    */
    private String internalScenType;
    /**
    * @Description: projectionsList
    */
    private List<sObject> projectionsList;
    /**
    * @Description: ffssIds
    */
    private Set<String> ffssIds;
    /**
    * @Description: serviceMessage Structure
    */
    private static arce.Arc_Gen_CustomServiceMessages serviceMessages = new arce.Arc_Gen_CustomServiceMessages();
    /**
    * @Description: Map<String, String> scenarioMapping
    */
    private final static Map<String, String> SCENARIO_MAPPING = new Map<String, String>{ 'Base Case' => 'BASE_MODIFICATION', 'Up' => 'UPSIDE_MODIFICATION', 'Down' => 'DOWNSIDE_MODIFICATION' };
    /**
    * @Description: Literal value: 5
    */
    final static String FIVE_VALUE = '5';
    /**
    * @Description: message
    */
    public List<arce.Arc_Gen_GlobalMessage.Message> messageList = new List<arce.Arc_Gen_GlobalMessage.Message>();
    /**
    * @Description: request
    */
    public Request request { get; set; }

    /**
    *-------------------------------------------------------------------------------
    * @description Wrapper used to describe the request that will receive the service.
    *-------------------------------------------------------------------------------
    **/
    public Arc_Gen_Projection_ServiceWrapper(String scenType, String ahaId, Set<String> finStatemIds) {
        this.internalScenType = scenType;
        this.projectionsList = Arc_Gen_Projection_Data.getProjScenarioData(ahaId, scenType);
        this.ffssIds = finStatemIds;
        final Request req = new Request();
        req.riskAssessmentId = Arc_Gen_Projection_Data.getRiskAssByAhaId(ahaId).Name;
        req.participantId = getParticipantId(ahaId);
        req.jsonInput = genJsonInput();
        this.request = req;
    }

    /**
    * Empty constructor
    */
    public Arc_Gen_Projection_ServiceWrapper() {
    }

    /**
    * @description getParticipantId
    * @author aleksandar.dinkov.contractor@bbva.com
    * @return String customerNumber
    **/
    private String getParticipantId(String ahaId) {
        String customerNumber = '';
        try {
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ ahaId })[0];
            final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(accHasAnalysis);
            final arce.Arc_Gen_Account_Wrapper accWrapper = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<Id>{ clientId }).get(clientId);
            customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(accWrapper.accNumber);
        } catch (Exception ex) {
            addMessage(String.valueOf(serviceMessages.CODE_500), ex.getMessage(), ex.getStackTraceString());
        }
        return customerNumber;
    }

    /**
    * @description addMessage
    * @author aleksandar.dinkov.contractor@bbva.com
    * @param String error
    * @param String description
    * @param String detailedMessage
    **/
    public void addMessage(String errorCode, String description, String detailedMessage) {
        System.debug('ERROR:\n' + errorCode + '\n' + description + '\n' + detailedMessage);
        final arce.Arc_Gen_GlobalMessage.Message message = new arce.Arc_Gen_GlobalMessage.Message();
        message.errorCode = errorCode;
        message.description = description;
        message.detailedMessage = detailedMessage;
        this.messageList.add(message);
    }

    /**
    * @description getJsonInput
    * @author aleksandar.dinkov.contractor@bbva.com
    * @return String serialized ProjectionJsonWrapper object
    **/
    private String genJsonInput() {
        String returnValue = '';
        try {
            ProjectionJsonWrapper inputJson = new ProjectionJsonWrapper();
            if ('Base Case' == internalScenType && !ffssIds.isEmpty()) {
                final ScenarioType scenType = new ScenarioType();
                scenType.id = 'BASE';
                inputJson.scenarioType = scenType;
                for (String id : ffssIds) {
                    final Statement statement = new Statement();
                    statement.id = id;
                    final StatementType stmType = new StatementType();
                    stmType.id = 'FINANCIAL_STATEMENT';
                    statement.statementType = stmType;
                    inputJson.statements.add(statement);
                }
            } else {
                inputJson = genProjectionsJson();
            }
            returnValue = JSON.serialize(inputJson, true);
            final Map<String, String> replacementKeys = new Map<String, String>{ 'currencyX' => 'currency', 'numberX' => 'number' };
            returnValue = replaceJsonKeys(returnValue, replacementKeys);
        } catch (Exception ex) {
            addMessage(String.valueOf(serviceMessages.CODE_500), ex.getMessage(), ex.getStackTraceString());
        }
        return returnValue;
    }

    /**
    * @description genProjectionsJson
    * @author aleksandar.dinkov.contractor@bbva.com
    * @return ProjectionJsonWrapper populated ProjectionJsonWrapper object.
    **/
    private ProjectionJsonWrapper genProjectionsJson() {
        final List<arce__Projections__mdt> mappingMdtList = Arc_Gen_Projection_Data.getAllProjectionsMdt();
        // Nodo principal del JSON
        final ProjectionJsonWrapper jsonObj = new ProjectionJsonWrapper();

        // Nodo scenarioType
        final ScenarioType scenType = new ScenarioType();
        scenType.id = SCENARIO_MAPPING.get(internalScenType);
        jsonObj.scenarioType = scenType;

        // Nodo statements
        for (SObject obj : projectionsList) {
            final Statement statement = new Statement();
            statement.id = String.valueOf(obj.get('arce__Projection_Id__c'));
            statement.currencyX = String.valueOf(obj.get('arce__Statement_Currency__c'));

            // Nodo statementType
            final StatementType stmType = new StatementType();
            stmType.id = 'PROJECTION_STATEMENT';
            statement.statementType = stmType;

            // Nodo financialStatementType
            final FinancialStatementType fsType = new FinancialStatementType();
            fsType.id = String.valueOf(obj.get('arce__FinancialStatement_Type__c'));
            statement.financialStatementType = fsType;

            // Nodo period
            final Period period = new Period();
            period.unit = 'MONTHS';
            period.numberX = 12;
            period.startDate = String.valueOf(obj.get('arce__Period_StartDate__c'));
            period.endDate = String.valueOf(obj.get('arce__Period_EndDate__c'));
            // PeriodType periodType =  new PeriodType(); 
            // periodType.id = 'ANNUAL';
            // period.periodType = periodType;
            statement.period = period;

            // Nodo calculations
            final Calculations calc = new Calculations();

            // Nodo specificRatiosMagnitudes - Se mapea desde el Custom Metadata Type "Projections"
            for (arce__Projections__mdt mdtObj : mappingMdtList) {
                final SpecificRatiosMagnitudes srm = new SpecificRatiosMagnitudes();
                srm.id = mdtObj.arce__id__c;
                SRM.description = mdtObj.Label;
                // Se asigna el calculation tipe MODIFICATION a las key asumptions "5".
                if (mdtObj.arce__Table_ID__c == FIVE_VALUE) {
                    final CalculationType calcType = new CalculationType();
                    calcType.id = 'MODIFICATION';
                    srm.calculationType = calcType;
                }
                final TotalAmount totalAmount = new TotalAmount();
                if (String.isNotBlank(mdtObj.arce__Base_field__c)) {
                    totalAmount.amount = Double.valueOf(obj.get(mdtObj.arce__Base_field__c));
                } else {
                    totalAmount.amount = Double.valueOf(obj.get(mdtObj.arce__Map_field__c));
                }
                totalAmount.currencyX = String.valueOf(obj.get('arce__Statement_Currency__c'));
                totalAmount.unit = 'UNITS';
                srm.totalAmount = totalAmount;
                srm.percentage = mdtObj.arce__Percentage_Map__c == null ? 0.0 : Double.valueOf(obj.get(mdtObj.arce__Percentage_Map__c));
                calc.specificRatiosMagnitudes.add(srm);
            }
            statement.calculations = calc;
            jsonObj.statements.add(statement);
        }
        return jsonObj;
    }

    /**
    * @Description: Iterates over a map of old keys (reserved apex words, unusable as wrapper params) to new keys
    * (usually we append "_x" to the original key) and does a find and replace on all of them.
    * This method is “safer” than String.replace() because we first reformat the JSON into a known good format so that we only replace the initial key.
    * This prevents us from accidentally replacing a match for the key in the middle of the data.
    * @param String data: inputJson string.
    * @param Map<String,String> replacements: map of existing key to replacement key.
    * Example: Map<String, String> replacements = new Map<String, String> {'currency' => 'currencyX', 'number' => 'numberX'};
    * @return String formattedJSON
    */
    public static String replaceJsonKeys(String data, Map<String, String> replacements) {
        // Regex to match the start of the line and the key surrounded by quotes and ending with a colon
        final String regexFormat = '(?m)^\\s*"{0}"\\s*:';
        // Replacement format of the new key surrounded by quotes and ending with a colon
        final String replacementFormat = '"{0}" :';
        // Since our JSON can come in formatted however the endpoint wants, we need to format it to a standard we know and can handle
        String formattedJSON = JSON.serializePretty(JSON.deserializeUntyped(data));
        // Iterate over all the keys we want to replace
        for (String key : replacements.keySet()) {
            // Generate our regex based on the key
            final String regex = String.format(regexFormat, new List<String>{ key });
            // Generate our replacement
            final String replacement = String.format(replacementFormat, new List<String>{ replacements.get(key) });
            // Find all and replace
            formattedJSON = formattedJSON.replaceAll(regex, replacement);
        }
        return formattedJSON;
    }

    /**
    * @Description: wrapper class ProjectionJsonWrapper
    */
    public class ProjectionJsonWrapper {
        /**
        * @Description: wrapper field scenarioType
        */
        public ScenarioType scenarioType;
        /**
        * @Description: wrapper field statements
        */
        public List<Statement> statements = new List<Statement>();
    }

    /**
    * @Description: wrapper class ScenarioType
    */
    public class ScenarioType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class Statement
    */
    public class Statement {
        /**
        * @Description: wrapper field id
        */
        public String id;
        /**
        * @Description: wrapper field currency
        */
        public String currencyX;
        /**
        * @Description: wrapper field statementType
        */
        public StatementType statementType;
        /**
        * @Description: wrapper field financialStatementType
        */
        public FinancialStatementType financialStatementType;
        /**
        * @Description: wrapper field period
        */
        public Period period;
        /**
        * @Description: wrapper field calculations
        */
        public Calculations calculations;
    }

    /**
    * @Description: wrapper class FinancialStatementType
    */
    public class FinancialStatementType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class StatementType
    */
    public class StatementType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class Period
    */
    public class Period {
        /**
        * @Description: wrapper field unit
        */
        public String unit;
        /**
        * @Description: wrapper field number
        */
        public Integer numberX;
        /**
        * @Description: wrapper field periodType
        */
        public PeriodType periodType;
        /**
        * @Description: wrapper field startDate
        */
        public String startDate;
        /**
        * @Description: wrapper field endDate
        */
        public String endDate;
    }

    /**
    * @Description: wrapper class Period
    */
    public class Calculations {
        /**
        * @Description: wrapper field specificRatiosMagnitudes
        */
        public List<SpecificRatiosMagnitudes> specificRatiosMagnitudes = new List<SpecificRatiosMagnitudes>();
        /**
        * @Description: wrapper field accountingAccounts
        */
        public List<AccountingAccounts> accountingAccounts = new List<AccountingAccounts>();
    }

    /**
    * @Description: wrapper class SpecificRatiosMagnitudes
    */
    public class SpecificRatiosMagnitudes {
        /**
        * @Description: wrapper field id
        */
        public String id;
        /**
        * @Description: wrapper field description
        */
        public String description;
        /**
        * @Description: wrapper field calculationType
        */
        public CalculationType calculationType;
        /**
        * @Description: wrapper field totalAmount
        */
        public TotalAmount totalAmount;
        /**
        * @Description: wrapper field percentage
        */
        public Double percentage;
    }

    /**
    * @Description: wrapper class AccountingAccounts
    */
    public class AccountingAccounts {
        /**
        * @Description: wrapper field id
        */
        public String id;
        /**
        * @Description: wrapper field calculationType
        */
        public CalculationType calculationType;
        /**
        * @Description: wrapper field amount
        */
        public Amount amount;
    }

    /**
    * @Description: wrapper class TotalAmount
    */
    public class TotalAmount {
        /**
        * @Description: wrapper field amount
        */
        public Double amount;
        /**
        * @Description: wrapper field currency
        */
        public String currencyX;
        /**
        * @Description: wrapper field unit
        */
        public String unit;
    }

    /**
    * @Description: wrapper class Amount
    */
    public class Amount {
        /**
        * @Description: wrapper field amount
        */
        public Double amount;
        /**
        * @Description: wrapper field currency
        */
        public String currencyX;
    }

    /**
    * @Description: wrapper class PeriodType
    */
    public class PeriodType {
        /**
        * @Description: wrapper field id
        */
        public String id;
    }

    /**
    * @Description: wrapper class CalculationType
    */
    public class CalculationType {
        /**
        * @Description: wrapper field id
        */
        public String id;

    }

    /**
    * @description wrapper class Request
    **/
    public class Request {
        /**
        * @Description: wrapper field riskAssessmentId
        */
        public String riskAssessmentId { get; set; }

        /**
        * @Description: wrapper field participantId
        */
        public String participantId { get; set; }

        /**
        * @Description: wrapper field jsonInput
        */
        public String jsonInput { get; set; }

    }

}