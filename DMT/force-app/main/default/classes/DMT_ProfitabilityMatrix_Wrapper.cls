@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_ProfitabilityMatrix_Wrapper {

    private static final String MSG_FIELD_INCOMPLETED = 'You must fill in the minimum and maximum fields, not just one of them.';
    private static final String MSG_FIELD_RATING_ERROR = 'Max rating must be higher \n than min selected.';
    private static final String MSG_INVALID_DATE_FORMAT = 'Invalid date format for overridefield: ';
    private static final String MSG_INVALID_DECIMAL_FORMAT = 'Invalid decimal format for overridefield: ';
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
    * @description check inputs are valid
    * @author BBVA DMT | 18-03-2025 
    * @param omniMap 
    * @return String 
    **/
    public static void validateInputsRequest(Map<String, Object> omniMap) {

        String xMIN = cleanNullString(omniMap.get('minX'));
        String xMAX = cleanNullString(omniMap.get('maxX'));
        String yMIN = cleanNullString(omniMap.get('minY'));
        String yMAX = cleanNullString(omniMap.get('maxY'));
        String ratingCatalog =JSON.serialize(omniMap.get('catalogRating'));
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
    * @description create request to profitability test with data from Omnistudio map
    * @author BBVA DMT | 18-03-2025 
    * @param omniMap 
    * @return String 
    **/
    public static String createRequest(Map<String, Object> omniMap) {

    String xMIN = cleanNullString(omniMap.get('minX'));
    String xMAX = cleanNullString(omniMap.get('maxX'));
    String yMIN = cleanNullString(omniMap.get('minY'));
    String yMAX = cleanNullString(omniMap.get('maxY'));

    // validate unified inputs (they can be decimal or rating strings)
    validateInputsRequest(omniMap);

        final User userLogin = DMT_User_Selector.getLoginUser();
        final String federationId = userLogin.federationIdentifier;

        AssumptionRequest request = new AssumptionRequest();
        request.assumptionIn = new AssumptionIn();
        request.assumptionIn.audit = new Audit();
        request.assumptionIn.audit.opportunityId = (String) omniMap.get('oppId');
        request.assumptionIn.audit.opportunityVersion = (String) omniMap.get('version');
        request.assumptionIn.audit.productId = (String) omniMap.get('prodId');
        request.assumptionIn.audit.origin = 'Salesforce';
        request.assumptionIn.audit.auditUser=federationId;
        

        request.assumptionIn.assumption = new Assumption();
        request.assumptionIn.assumption.axisX = (String) omniMap.get('axisX');
        request.assumptionIn.assumption.axisY = (String) omniMap.get('axisY');
        request.assumptionIn.assumption.axisCentral = (String) omniMap.get('axisCentral');

        
        // Handle X: either decimals or rating strings
        if(!String.isBlank(xMIN) && !String.isBlank(xMAX)){
            if(isNumericString(xMIN) && isNumericString(xMAX)){
                Decimal minXDec = Decimal.valueOf(xMIN);
                Decimal maxXDec = ((Decimal.valueOf(xMIN) + (Decimal.valueOf(xMAX))*9));
                request.assumptionIn.assumption.minX = minXDec.toPlainString();
                validateRangeMax(cleanNullString(omniMap.get('axisX_Id')), maxXDec);
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
                validateRangeMax(cleanNullString(omniMap.get('axisY_Id')), maxYDec);
                request.assumptionIn.assumption.maxY = maxYDec.toPlainString();
            } else {
                // treat as rating strings
                request.assumptionIn.assumption.minY = yMIN;
                request.assumptionIn.assumption.maxY = yMAX;
            }
        }

        if (omniMap.containsKey('overrideFields') && 
            omniMap.get('overrideFields') != null && 
            !String.isBlank(String.valueOf(omniMap.get('overrideFields'))) && 
            omniMap.get('overrideFields') instanceof Map<String, Object>) {
    
                System.debug('DEBUG OFields ' + String.valueOf(omniMap.get('overrideFields')));
                request = addOverrideFields(request, omniMap);
        } 
        

        return JSON.serialize(request,true);
    }

    /**
    * @description create request to profitability test with data from Omnistudio map with fields override
    * @author BBVA DMT | 18-03-2025 
    * @param omniMap 
    * @return String 
    **/
    public static AssumptionRequest addOverrideFields(AssumptionRequest request,Map<String, Object> omniMap) {
   
            Map<String,Object> ofFromOmni = (Map<String,Object>) omniMap.get('overrideFields');

            request.assumptionIn.overrideField = new OverrideField();
            request.assumptionIn.overrideField.profitabilityIn = new ProfitabilityIn();
            request.assumptionIn.overrideField.profitabilityIn.opportunity = createOpportunityOverride(ofFromOmni);
            request.assumptionIn.overrideField.profitabilityIn.product = createProductOverrides(ofFromOmni);

        return request;
    }


    /**
    * @description add opp fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param ofFromOmni 
    * @return OpportunityOverride 
    **/
    private static OpportunityOverride createOpportunityOverride(Map<String, Object> ofFromOmni) {
        OpportunityOverride opportunity = new OpportunityOverride();
        opportunity.entific = cleanNullString(String.valueOf(ofFromOmni.get('entificNew')));
        opportunity.booking = cleanNullString(String.valueOf(ofFromOmni.get('bookingNew')));
        opportunity.counterpart = cleanNullString(String.valueOf(ofFromOmni.get('clientTypeNew')));
        opportunity.clientRating = cleanNullString(String.valueOf(ofFromOmni.get('intClientRatingNew')));
        opportunity.externalClientRating = cleanNullString(String.valueOf(ofFromOmni.get('extClientRatingNew')));
        opportunity.scoring = cleanNullString(String.valueOf(ofFromOmni.get('ScoringNew')));
        return opportunity;
    }
    
    /**
    * @description add product fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param ofFromOmni 
    * @return List<ProductOverride> 
    **/
    private static List<ProductOverride> createProductOverrides(Map<String, Object> ofFromOmni) {
        List<ProductOverride> productOverrides = new List<ProductOverride>();
        ProductOverride product = new ProductOverride();
    
        product.initDate = parseDate(ofFromOmni,'startDateNew');
        product.endDate = parseDate(ofFromOmni,'endDateNew');
        product.countryRisk = cleanNullString(String.valueOf(ofFromOmni.get('countryRiskNew')));
        product.countryRating = cleanNullString(String.valueOf(ofFromOmni.get('countryRatingNew')));
        product.currencyId = cleanNullString(String.valueOf(ofFromOmni.get('currencyNew')));
    
        product.amortization = createAmortization(ofFromOmni);
        productOverrides.add(product);
    
        return productOverrides;
    }
    
    /**
    * @description add amortization fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param ofFromOmni 
    * @return Amortization 
    **/
    private static Amortization createAmortization(Map<String, Object> ofFromOmni) {
        Amortization amortization = new Amortization();
        amortization.amortizationType = cleanNullString(String.valueOf(ofFromOmni.get('amortizationTypeNew')));
        amortization.paymentFrequency = cleanNullString(String.valueOf(ofFromOmni.get('paymentFrequencyNew')));
        amortization.payments = createPayments(ofFromOmni);
        return amortization;
    }
    
    /**
    * @description add payments fields override to request
    * @author BBVA DMT | 21-05-2025 
    * @param ofFromOmni 
    * @return List<Payment> 
    **/
    private static List<Payment> createPayments(Map<String, Object> ofFromOmni) {
        List<Payment> payments = new List<Payment>();
        Payment payment = new Payment();
        payment.paymentDate = parseDate(ofFromOmni, 'paymentDateNew');
        payment.nominalAmount = parseDecimal(ofFromOmni, 'nominalAmountNew');
        payment.nominalFb = parseDecimal(ofFromOmni, 'nominalFbNew');
        payment.spreadAmount = parseDecimal(ofFromOmni, 'spreadAmountNew');
        payment.spreadFbAmount = parseDecimal(ofFromOmni, 'spreadFbNew');
        payment.feesUpfront = parseDecimal(ofFromOmni, 'nonaccrualfeeNew');
        payment.feesPeriodic = parseDecimal(ofFromOmni, 'accrualfeeNew');

        payments.add(payment);
        return payments;
    }

    private static Date parseDate(Map<String, Object> mapOverride, String overridefield) {
        // Check if the map contains the key and if the value is not null
      
    if (mapOverride.containsKey(overridefield) && !String.isBlank(cleanNullString(mapOverride.get(overridefield)))) {
        Object dateValueObj = mapOverride.get(overridefield);
        if (dateValueObj != null && dateValueObj instanceof String) {
            String dateValue = (String) dateValueObj;
            if (!String.isBlank(dateValue)) {
                try {
                    return Date.valueOf(dateValue);
                } catch (Exception e) {
                    throw new CustomException(MSG_INVALID_DATE_FORMAT + overridefield + '. Value: ' + dateValue ,e);
                }
            }
        }
    }
    // Returns null if the field does not exist, is null, or is empty
    return null;
    }

    // Helper method to convert values to Decimal
    private static Decimal parseDecimal(Map<String, Object> mapoverride, String overridefield) {
        if (mapoverride.containsKey(overridefield) && !String.isBlank(cleanNullString(mapoverride.get(overridefield))) && mapoverride.get(overridefield)!= null) {
            try {
                return (Decimal) mapoverride.get(overridefield);
            } catch (Exception e) {
                throw new CustomException(MSG_INVALID_DECIMAL_FORMAT + overridefield ,e);
            }
        }
        return null;
    }

    /**
    * @description clean map from omnistudio, return null if value is null, 'null' or empty string
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