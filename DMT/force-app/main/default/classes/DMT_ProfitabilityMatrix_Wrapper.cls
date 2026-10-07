@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_ProfitabilityMatrix_Wrapper {

    private static final String MSG_FIELD_INCOMPLETED = 'You must fill in the minimum and maximum fields, not just one of them.';
    private static final String MSG_FIELD_RATING_ERROR = 'Max rating must be higher \n than min selected.';
    private static final String MSG_INVALID_DATE_FORMAT = 'Invalid date format for overridefield: ';
    private static final String MSG_INVALID_DECIMAL_FORMAT = 'Invalid decimal format for overridefield: ';
    private static final String MSG_INVALID_OVERRIDE_FIELDS = 'Invalid overrideFields format.';
    private static final String MSG_ERROR_PATTERN = 'Error validating input pattern for field ';
    private static final String AXIS_EXTERNAL_ID_FEES_UPFRONT = '3';
    private static final String AXIS_EXTERNAL_ID_SPREAD_DRAWN = '4';
    private static final String AXIS_EXTERNAL_ID_FEES_PERIODIFICABLE = '7';
    private static final String AXIS_EXTERNAL_ID_SPREAD_UNDRAWN = '8';
    private static final String AXIS_EXTERNAL_ID_FEES = '3';
    private static final String AXIS_EXTERNAL_ID_SPREAD = '4';
    private static final Decimal AXIS_RANGE_MAX_THRESHOLD = 1000;
    protected Data data; 

    public class CustomException extends Exception {}

    public class AssumptionRequest {
        
        public AssumptionIn assumptionIn;
        
    }

    public class AssumptionIn {
        public Audit audit;
        public Assumption assumption;
        public OverrideField overrideField;
    }

    public class Audit {
        public String opportunityId;
        public String opportunityVersion;
        public String productId;
        public String origin;
        public String auditUser;
    }

    public class Assumption {
        public String axisX;
        public String axisY;
        public String axisCentral;
        public String minX;
        public String maxX;
        public String minY;
        public String maxY;
    }

    //Override configuration variables

    public class OverrideField {
        public ProfitabilityIn profitabilityIn;
    }

    public class ProfitabilityIn {
        public OpportunityOverride opportunity;
        public List<ProductOverride> product;
    }

    public class OpportunityOverride {
        public String entific;
        public String booking;
        public String counterpart;
        public String clientRating;
        public String externalClientRating;
        public String scoring;
    }

    public class ProductOverride {
        public Date initDate;
        public Date endDate;
        public String countryRisk;
        public String countryRating;
        public String currencyId;
        public Amortization amortization;
    }

    public class Amortization {
        public String amortizationType;
        public String paymentFrequency;
        public List<Payment> payments;
    }

    public class Payment {
        public Date paymentDate;
        public Decimal nominalAmount;
        public Decimal nominalFb;
        public Decimal spreadAmount;
        public Decimal spreadFbAmount;
        public Decimal feesUpfront;
        public Decimal feesPeriodic;
    }

    //Result
    public class Data {
        public Audit audit;
        public Assumption assumption;
        public List<AssumptionResult> assumptionResult;
    }

    public class AssumptionResult {
        public String valueAxisX;
        public String valueAxisY;
        public String valueAxisCentral;
    }

    /**
    * @description parsea Json a DMT_ProfitabilityMatrix_Wrapper
    * @author BBVA DMT | 18-03-2025 
    * @param json 
    * @return DMT_ProfitabilityMatrix_Wrapper 
    **/
    public static DMT_ProfitabilityMatrix_Wrapper parseResponse(String json) {
        return (DMT_ProfitabilityMatrix_Wrapper) System.JSON.deserialize(json, DMT_ProfitabilityMatrix_Wrapper.class);
    }

    /**
    * @description Checks that the profitability request inputs are valid.
    * @author BBVA DMT | 18-03-2025 
    * @param inputMap request data received from the LWC or a legacy caller
    * @return String 
    **/
    public static void validateInputsRequest(Map<String, Object> inputMap) {

        String xMIN = cleanNullString(inputMap.get('minX'));
        String xMAX = cleanNullString(inputMap.get('maxX'));
        String yMIN = cleanNullString(inputMap.get('minY'));
        String yMAX = cleanNullString(inputMap.get('maxY'));
        String ratingCatalog =JSON.serialize(inputMap.get('catalogRating'));
        // check if one of min/max is provided without the other
        Boolean checkXInputCompleted = ( !String.isBlank(xMIN) && String.isBlank(xMAX)) || ( String.isBlank(xMIN) && !String.isBlank(xMAX));
        Boolean checkYInputCompleted = ( !String.isBlank(yMIN) && String.isBlank(yMAX)) || ( String.isBlank(yMIN) && !String.isBlank(yMAX));

        if( checkXInputCompleted || checkYInputCompleted ){
            throw new CustomException(MSG_FIELD_INCOMPLETED);
        }
        // X axis rating validation
        if(!String.isBlank(xMIN) && !String.isBlank(xMAX) && (!isNumericString(xMIN) || !isNumericString(xMAX))) {
            if(!String.isBlank(ratingCatalog)){
                if(validateRatingMax(xMIN,xMAX,ratingCatalog)){
                    throw new CustomException(MSG_FIELD_RATING_ERROR);
                }
            }
        }

        // Y axis rating validation
        if(!String.isBlank(yMIN) && !String.isBlank(yMAX) && (!isNumericString(yMIN) || !isNumericString(yMAX))) {
            if(!String.isBlank(ratingCatalog)){
                if(validateRatingMax(yMIN,yMAX,ratingCatalog)){
                    throw new CustomException(MSG_FIELD_RATING_ERROR);
                }
            }
        }

    }

    /**
    * @description return true if selected min & max ratings are wrong
    * @author BBVA DMT | 15-04-2025 
    * @param minValue the min input value selected
    * @param maxValue  the max input value selected
    * @param ratingCatalog  catalog rating values with order ( Lower numbers indicate higher rating)
    * @return Boolean flag indicating if min < max
    **/
    public static Boolean validateRatingMax(String minValue, String maxValue,String ratingCatalog ) {

        List<Object> listOfObjects = (List<Object>) JSON.deserializeUntyped(ratingCatalog);
       
        Map<String,Integer> mapRatingOrderByValue = new Map<String,Integer>();
        for(Object obj : listOfObjects){
            Map<String, Object> castedMap = (Map<String, Object>) obj;
            mapRatingOrderByValue.put(String.valueOf(castedMap.get('value')),Integer.valueOf(castedMap.get('orden')));
        }

        if(mapRatingOrderByValue.get(minValue) < mapRatingOrderByValue.get(maxValue)){
            return true;
        }
        return false;
    }

    
    /**
    * @description Creates the Profitability Matrix service request from the LWC request map.
    * @author BBVA DMT | 18-03-2025 
    * @param inputMap request data from dmt_profitabilityTestMain
    * @return String 
    **/
    public static String createRequest(Map<String, Object> inputMap) {

    String xMIN = cleanNullString(inputMap.get('minX'));
    String xMAX = cleanNullString(inputMap.get('maxX'));
    String yMIN = cleanNullString(inputMap.get('minY'));
    String yMAX = cleanNullString(inputMap.get('maxY'));

    // validate unified inputs (they can be decimal or rating strings)
    validateInputsRequest(inputMap);

        final User userLogin = DMT_User_Selector.getLoginUser();
        final String federationId = userLogin.federationIdentifier;

        AssumptionRequest request = new AssumptionRequest();
        request.assumptionIn = new AssumptionIn();
        request.assumptionIn.audit = new Audit();
        request.assumptionIn.audit.opportunityId = (String) inputMap.get('oppId');
        request.assumptionIn.audit.opportunityVersion = (String) inputMap.get('version');
        request.assumptionIn.audit.productId = (String) inputMap.get('prodId');
        request.assumptionIn.audit.origin = 'Salesforce';
        request.assumptionIn.audit.auditUser=federationId;
        

        request.assumptionIn.assumption = new Assumption();
        request.assumptionIn.assumption.axisX = (String) inputMap.get('axisX');
        request.assumptionIn.assumption.axisY = (String) inputMap.get('axisY');
        request.assumptionIn.assumption.axisCentral = (String) inputMap.get('axisCentral');

        
        // Handle X: either decimals or rating strings
        if(!String.isBlank(xMIN) && !String.isBlank(xMAX)){
            if(isNumericString(xMIN) && isNumericString(xMAX)){
                Decimal minXDec = Decimal.valueOf(xMIN);
                Decimal maxXDec = ((Decimal.valueOf(xMIN) + (Decimal.valueOf(xMAX))*9));
                request.assumptionIn.assumption.minX = minXDec.toPlainString();
                validateRangeMax(cleanNullString(inputMap.get('axisX_Id')), maxXDec);
                request.assumptionIn.assumption.maxX = maxXDec.toPlainString();
            } else {
                // treat as rating strings
                request.assumptionIn.assumption.minX = xMIN;
                request.assumptionIn.assumption.maxX = xMAX;
            }
        }

        // Handle Y: either decimals or rating strings
        if(!String.isBlank(yMIN) && !String.isBlank(yMAX)){
            if(isNumericString(yMIN) && isNumericString(yMAX)){
                Decimal minYDec = Decimal.valueOf(yMIN);
                Decimal maxYDec = ((Decimal.valueOf(yMIN) + (Decimal.valueOf(yMAX))*9));
                request.assumptionIn.assumption.minY = minYDec.toPlainString();
                validateRangeMax(cleanNullString(inputMap.get('axisY_Id')), maxYDec);
                request.assumptionIn.assumption.maxY = maxYDec.toPlainString();
            } else {
                // treat as rating strings
                request.assumptionIn.assumption.minY = yMIN;
                request.assumptionIn.assumption.maxY = yMAX;
            }
        }

        // The FlexCard/Omni flow supplied a native Apex map, while an object sent by an LWC can
        // reach Apex with a different runtime map representation. Always normalize the value and
        // build the service's required override structure, even when there are no override values.
        request = addOverrideFields(request, inputMap);
        

        return JSON.serialize(request,true);
    }

    /**
        * @description Adds the normalized LWC/legacy override values to the service request.
    * @author BBVA DMT | 18-03-2025 
        * @param inputMap request map containing overrideFields
    * @return String 
    **/
        public static AssumptionRequest addOverrideFields(AssumptionRequest request,Map<String, Object> inputMap) {
            Map<String,Object> overrideFields = normalizeOverrideFields(inputMap.get('overrideFields'));

            request.assumptionIn.overrideField = new OverrideField();
            request.assumptionIn.overrideField.profitabilityIn = new ProfitabilityIn();
            request.assumptionIn.overrideField.profitabilityIn.opportunity = createOpportunityOverride(overrideFields);
            request.assumptionIn.overrideField.profitabilityIn.product = createProductOverrides(overrideFields);

        return request;
    }

    /**
    * @description Normalizes overrideFields received from either the legacy Omni map or an LWC.
    * Native Apex maps use the fast path; only non-native LWC representations require JSON
    * normalization. Null or blank values become an empty map so the service structure is retained.
    * @param rawOverrideFields raw overrideFields value from the request
    * @return Map<String, Object> normalized override values
    **/
    private static Map<String, Object> normalizeOverrideFields(Object rawOverrideFields) {
        if (rawOverrideFields == null || String.isBlank(String.valueOf(rawOverrideFields))) {
            return new Map<String, Object>();
        }
        if (rawOverrideFields instanceof Map<String, Object>) {
            return (Map<String, Object>) rawOverrideFields;
        }

        Object normalized;
        try {
            if (rawOverrideFields instanceof String) {
                normalized = JSON.deserializeUntyped((String) rawOverrideFields);
            } else {
                normalized = JSON.deserializeUntyped(JSON.serialize(rawOverrideFields));
            }
        } catch (JSONException e) {
            throw new CustomException(MSG_INVALID_OVERRIDE_FIELDS, e);
        }

        if (!(normalized instanceof Map<String, Object>)) {
            throw new CustomException(MSG_INVALID_OVERRIDE_FIELDS);
        }
        return (Map<String, Object>) normalized;
    }


    /**
    * @description add opp fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param overrideFields normalized override values
    * @return OpportunityOverride 
    **/
    private static OpportunityOverride createOpportunityOverride(Map<String, Object> overrideFields) {
        OpportunityOverride opportunity = new OpportunityOverride();
        opportunity.entific = cleanNullString(overrideFields.get('entificNew'));
        opportunity.booking = cleanNullString(overrideFields.get('bookingNew'));
        opportunity.counterpart = cleanNullString(overrideFields.get('clientTypeNew'));
        opportunity.clientRating = cleanNullString(overrideFields.get('intClientRatingNew'));
        opportunity.externalClientRating = cleanNullString(overrideFields.get('extClientRatingNew'));
        opportunity.scoring = cleanNullString(overrideFields.get('ScoringNew'));
        return opportunity;
    }
    
    /**
    * @description add product fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param overrideFields normalized override values
    * @return List<ProductOverride> 
    **/
    private static List<ProductOverride> createProductOverrides(Map<String, Object> overrideFields) {
        List<ProductOverride> productOverrides = new List<ProductOverride>();
        ProductOverride product = new ProductOverride();
    
        product.initDate = parseDate(overrideFields,'startDateNew');
        product.endDate = parseDate(overrideFields,'endDateNew');
        product.countryRisk = cleanNullString(overrideFields.get('countryRiskNew'));
        product.countryRating = cleanNullString(overrideFields.get('countryRatingNew'));
        product.currencyId = cleanNullString(overrideFields.get('currencyNew'));
    
        product.amortization = createAmortization(overrideFields);
        productOverrides.add(product);
    
        return productOverrides;
    }
    
    /**
    * @description add amortization fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param overrideFields normalized override values
    * @return Amortization 
    **/
    private static Amortization createAmortization(Map<String, Object> overrideFields) {
        Amortization amortization = new Amortization();
        amortization.amortizationType = cleanNullString(overrideFields.get('amortizationTypeNew'));
        amortization.paymentFrequency = cleanNullString(overrideFields.get('paymentFrequencyNew'));
        amortization.payments = createPayments(overrideFields);
        return amortization;
    }
    
    /**
    * @description add payments fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param overrideFields normalized override values
    * @return List<Payment> 
    **/
    private static List<Payment> createPayments(Map<String, Object> overrideFields) {
        List<Payment> payments = new List<Payment>();
        Payment payment = new Payment();
        payment.paymentDate = parseDate(overrideFields, 'paymentDateNew');
        payment.nominalAmount = parseDecimal(overrideFields, 'nominalAmountNew');
        payment.nominalFb = parseDecimal(overrideFields, 'nominalFbNew');
        payment.spreadAmount = parseDecimal(overrideFields, 'spreadAmountNew');
        payment.spreadFbAmount = parseDecimal(overrideFields, 'spreadFbNew');
        payment.feesUpfront = parseDecimal(overrideFields, 'nonaccrualfeeNew');
        payment.feesPeriodic = parseDecimal(overrideFields, 'accrualfeeNew');

        payments.add(payment);
        return payments;
    }

    private static Date parseDate(Map<String, Object> mapOverride, String overridefield) {
        Object rawValue = mapOverride.get(overridefield);
        String dateValue = cleanNullString(rawValue);
        if (String.isBlank(dateValue)) {
            return null;
        }
        if (rawValue instanceof Date) {
            return (Date) rawValue;
        }
        try {
            return Date.valueOf(dateValue);
        } catch (TypeException e) {
            throw new CustomException(MSG_INVALID_DATE_FORMAT + overridefield + '. Value: ' + dateValue, e);
        }
    }

    // LWC numbers can arrive with different Apex runtime types; parse their string value safely.
    private static Decimal parseDecimal(Map<String, Object> mapoverride, String overridefield) {
        String decimalValue = cleanNullString(mapoverride.get(overridefield));
        if (String.isBlank(decimalValue)) {
            return null;
        }
        try {
            return Decimal.valueOf(decimalValue);
        } catch (TypeException e) {
            throw new CustomException(MSG_INVALID_DECIMAL_FORMAT + overridefield, e);
        }
    }

    /**
    * @description Cleans an input value, returning null when it is null, 'null', or blank.
    * @author BBVA DMT | 17-09-2025 
    * @param value 
    * @return String 
    **/
    private static String cleanNullString(Object value) {
    if (value == null){ return null;}
    String strValue = String.valueOf(value);
    if (strValue == null){ return null;}
    strValue = strValue.trim();
    if (strValue.equalsIgnoreCase('null') || String.isEmpty(strValue)){
        return null;
    }
    try {
        Pattern p = Pattern.compile('^\\{\\s*[^\\}]+\\s*\\}$');
        Matcher m = p.matcher(strValue);
        if (m.matches()){
            return null;
        }
    } catch (Exception e) {
        throw new CustomException(MSG_ERROR_PATTERN);
    }
    return strValue;
}

    // Helper to check if a string can be parsed to Decimal
    private static Boolean isNumericString(String s){
        if(String.isBlank(s)) return false;
        try{
            Decimal.valueOf(s);
            return true;
        } catch(Exception e){
            return false;
        }
    }

    public static Boolean validateRangeMax(String axisExternalId, Decimal maxValue ) {
        if(!String.isBlank(axisExternalId) && 
        (axisExternalId == AXIS_EXTERNAL_ID_FEES || axisExternalId == AXIS_EXTERNAL_ID_SPREAD ||axisExternalId == AXIS_EXTERNAL_ID_FEES_UPFRONT || axisExternalId == AXIS_EXTERNAL_ID_SPREAD_DRAWN ||
         axisExternalId == AXIS_EXTERNAL_ID_FEES_PERIODIFICABLE || axisExternalId == AXIS_EXTERNAL_ID_SPREAD_UNDRAWN) &&
        maxValue >= AXIS_RANGE_MAX_THRESHOLD){
            throw new CustomException('The values provided for the selected axis are outside the allowed range. Please verify the data.');
        }
        return true;
    }
    
}