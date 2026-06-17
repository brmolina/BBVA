/**-------------------------------------------------------------------------------------------
* @Name     DMT_Opportunity_Utils
* @Author   Juan Ramírez <jjuandavid.ramirez.jaramillo.contractor@bbva.com>
* @Date     Created: 2025-04-06
* --------------------------------------------------------------------------------------------
* @Description Clase para agrupar utilidades y funciones para el manejo de Oportunidades    
* --------------------------------------------------------------------------------------------
*/

public with sharing class DMT_Opportunity_Utils {
    public static final Map<String, String> localeFormats = new Map<String, String> {
        'en_US' => '#,###.00',
        'es_ES' => '#.###,00',
        'es_CO' => '#.###,00',
        'es_PE' => '#.###,00'
    };

    FINAL STATIC STRING AMORTIZATIONTYPE = 'Bullet';
    FINAL STATIC STRING PAYMENTFREQUENCY = 'Monthly';

    public class InputWrapper {
        @InvocableVariable
        public Decimal amount;

        @InvocableVariable
        public String fromCurrency;

        @InvocableVariable
        public String toCurrency;
    }
    public class OutputWrapper {
        @InvocableVariable
        public Decimal convertedAmount;
    }
    
    public static Map<String, Object> getOpportunityProductsMinAndMaxDates(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

        try {
            // Obtener Record Id
            Id recordId = (inputMap.containsKey('recordId') && inputMap.get('recordId') instanceof Id) ? (Id) inputMap.get('recordId') : null;

            //Si alguna de estas dos variables no existe, se retorna un error
            if (recordId == null || String.isBlank(recordId)) {
                throw new DTM_Currency_Exception('recordId no está presentes o es inválido, por lo tanto no se puede ejecutar la operación');
            }

            List<OpportunityLineItem> lstOppLineItems = DMT_Opportunity_Selector.getOpportunityLineItems(recordId);
            
            Date minInitialDate;
            Date maxMaturityDate;

            for (OpportunityLineItem item : lstOppLineItems) {
                if (item.gf_initial_date__c != null) {
                    if (minInitialDate == null || item.gf_initial_date__c < minInitialDate) {
                        minInitialDate = item.gf_initial_date__c;
                    }
                }

                if (item.gf_maturity_date__c != null) {
                    if (maxMaturityDate == null || item.gf_maturity_date__c > maxMaturityDate) {
                        maxMaturityDate = item.gf_maturity_date__c;
                    }
                }
            }

            // Añadir los valores calculados al outMap
            outMap.put('minInitialDate', minInitialDate);
            outMap.put('maxMaturityDate', maxMaturityDate);
        } catch (Exception e) {
            // Logging centralizado
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Opportunity_Utils', 'getOpportunityProductsMinAndMaxDates', 'DMT', '');
            exceptionList.add(dmtEcx);
            outMap.putAll(copyInputToOutput(inputMap));
        }

        if(exceptionList.size() > 0){
            outMap.put('exceptionList', exceptionList);
            outMap.put('error', 'Error en la conversión');
        }

        return outMap;
    }

@AuraEnabled
public static Opportunity getOppLockUser(Id oppId) {
    return  [
        SELECT DMT_Opp_User_Lock__c, DMT_Opp_User_Lock__r.Name
        FROM Opportunity
        WHERE Id = :oppId
        LIMIT 1
    ];
}

    private static Map<String, Object> copyInputToOutput(Map<String, Object> inputMap) {
        Map<String, Object> result = new Map<String, Object>();
        for (String key : inputMap.keySet()) {
            if (key != 'recordId' && key != 'action') {
                result.put(key, inputMap.get(key));
            }
        }
        return result;
    }

    @InvocableMethod(label='Convert Currency' description='Converts a currency amount from one currency to another')
    public static List<OutputWrapper> convertCurrency(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();

        for (InputWrapper input : inputs) {
            OutputWrapper out = new OutputWrapper();
            try {
                out.convertedAmount = DMT_Currency.convert(input.amount, input.fromCurrency, input.toCurrency);
            } catch (Exception e) {
                // Optionally: log error or handle fallback
                out.convertedAmount = null;
                System.debug('Currency conversion failed: ' + e.getMessage());
            }
            results.add(out);
        }

        return results;
    }
    public virtual class DTM_Currency_Exception extends Exception {}

    public static Map<String, Object> validateTenorsFromRaw(List<Object> rawTenors) {
        return validateTenorsFromRaw(rawTenors, null, null);
    }
 
    public static Map<String, Object> validateTenorsFromRaw(List<Object> rawTenors, Date initialDate, Date maturityDate) {
        Map<String, Object> result = new Map<String, Object>();
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();
        rawTenors = cleanNumericDots(rawTenors);
        try {
            // Flags
            Boolean hasValidAmount = false;
            Boolean hasValidPayDate = true;
            Set<String> tenorDates = new Set<String>();
            Boolean hasDuplicateDates = false;

            // Buffer to validate ranges later
            List<Map<String,Object>> rowsBuffer = new List<Map<String,Object>>();
            Date minDate; // earliest payment date seen
            Date maxDate; // latest payment date seen
            Date initialDateVar = initialDate;
            Date maturityDateVar = maturityDate;

            // Loop each incoming row (tenor)
            for (Object rawItem : rawTenors) {
                Map<String, Object> tenorMap = (Map<String, Object>) rawItem;

                // true if at least ONE row has amount > 0
                if (validateAmounts(tenorMap)) {
                    hasValidAmount = true;
                }

                // Normalize/parse date first
                Date paymentDate = normalizeToDate(tenorMap.get('gf_tenor_date__c'));
                if (paymentDate == null) {
                    hasValidPayDate = false;
                    break;
                }

                // Duplicate check with normalized key
                String dateKey = String.valueOf(paymentDate);
                if (!tenorDates.add(dateKey)) {
                    hasDuplicateDates = true;
                    break;
                }

                // Detect INIT and END rows
                Boolean initRow = isInitRow(tenorMap);
                Boolean endRow = isEndRow(tenorMap);

                // If anchors are not provided, determine them based on the fixed rows.
                if (initialDateVar == null && initRow){
                    initialDateVar = paymentDate;
                }
                if (maturityDateVar == null && endRow) {
                    maturityDateVar = paymentDate;
                }

                // Track global min/max dates
                if (minDate == null || paymentDate < minDate) {
                    minDate = paymentDate;
                }
                if (maxDate == null || paymentDate > maxDate) {
                    maxDate = paymentDate;
                }

                // Store a small snapshot to validate ranges later.
                rowsBuffer.add(new Map<String, Object>{
                    'paymentDate' => paymentDate,
                    'isInit' => initRow,
                    'isEnd' => endRow
                });
            }

            // Validations
            if (!hasValidAmount) {
                return errorResult(result, Label.dmt_cl_DrawnOrUndrawnAmountRequired_Text);
            }
            if (!hasValidPayDate) {
                return errorResult(result, Label.dmt_cl_PaymentDateRequired_Text);
            }
            if (hasDuplicateDates) {
                return errorResult(result, Label.dmt_cl_DuplicatePaymentDates_Text);
            }

            // If anchors were not provided, use min/max seen
            if (initialDateVar == null) {
                initialDateVar = minDate;
            }
            if (maturityDateVar == null) {
                maturityDateVar = maxDate;
            }

            // equal anchors = duplicate date
            if (initialDateVar != null && maturityDateVar != null && initialDateVar == maturityDateVar) {
                return errorResult(result, Label.dmt_cl_DuplicatePaymentDates_Text);
            }

            // Range validations (only if there are both anchors)
            if (initialDateVar != null && maturityDateVar != null) {
                if (maturityDateVar < initialDateVar) {
                    return errorResult(result, Label.dmt_cl_MaturityDateEarlierInit_Text);
                }

                System.debug('===== DMT TENORS VALIDATION INPUT =====');
                System.debug('initialDate PARAM => ' + initialDate);
                System.debug('maturityDate PARAM => ' + maturityDate);
                System.debug('initialDateVar => ' + initialDateVar);
                System.debug('maturityDateVar => ' + maturityDateVar);
                System.debug('rawTenors => ' + JSON.serializePretty(rawTenors));
                System.debug('rowsBuffer => ' + JSON.serializePretty(rowsBuffer));

                if (!validateDateRanges(rowsBuffer, initialDateVar, maturityDateVar, result)) {
                    return result;
                }
            }

            result.put('validationPassed', true);

            result.put('DMT_Opportunity_Tenor__c', rawTenors);

        } catch (Exception e) {
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Opportunity_Utils', 'validateTenorsFromRaw', 'DMT', '');
            exceptionList.add(dmtEcx);
            result.put('exceptionList', exceptionList);
        }

        return result;
    }

    private static Boolean validateAmounts(Map<String, Object> tenorMap) {
        Decimal drawnAmount = parseDecimal(tenorMap.get('gj_nominal_amount_db__c'));
        Decimal undrawnAmount = parseDecimal(tenorMap.get('gf_nominal_amount_fb__c'));
        return drawnAmount >= 0 && undrawnAmount >= 0 && (drawnAmount > 0 || undrawnAmount > 0);
    }

    private static Date normalizeToDate(Object raw) {
        if (raw == null) {
            return null;
        }
        String stringValue = String.valueOf(raw).trim();
        if (stringValue == '') {
            return null;
        }

        // Cut ISO time part if present
        Integer tIdx = stringValue.indexOf('T');
        if (tIdx > 0) {
            stringValue = stringValue.substring(0, tIdx);
        }
        // If string looks like yyyy-MM-ddTHH.. or yyyy-MM-dd HH.., keep first 10
        if (stringValue.length() > 10 && stringValue.substring(4,5) == '-' && stringValue.substring(7,8) == '-') {
            stringValue = stringValue.substring(0, 10);
        }

        try {
            return Date.valueOf(stringValue);
        } catch (Exception e) {
            try {
                Datetime dt = Datetime.valueOf(stringValue);
                return Date.newInstance(dt.year(), dt.month(), dt.day());
            } catch (Exception ignore) {
                return null;
            }
        }
    }

    private static Boolean isInitRow(Map<String, Object> tenorMap) {
        return String.valueOf(tenorMap.get('__role')) == 'INIT' ||
                String.valueOf(tenorMap.get('Id')) == 'INIT' ||
                ((Boolean)tenorMap.get('lockDate') == true &&
                (Boolean)tenorMap.get('deleteDisabled') == true &&
                (Boolean)tenorMap.get('aviableItem') == false &&
                (Boolean)tenorMap.get('notEditable') == false);
    }

    private static Boolean isEndRow(Map<String, Object> tenorMap) {
        return String.valueOf(tenorMap.get('__role')) == 'END' ||
                String.valueOf(tenorMap.get('Id')) == 'END' ||
                ((Boolean)tenorMap.get('notEditable') == true &&
                (Boolean)tenorMap.get('aviableItem') == true &&
                (Boolean)tenorMap.get('editDisabled') == true &&
                (Boolean)tenorMap.get('deleteDisabled') == true);
    }

    private static Boolean validateDateRanges(List<Map<String,Object>> rowsBuffer, Date initialDate, Date maturityDate, Map<String,Object> result) {
        for (Map<String,Object> rowInfo : rowsBuffer) {
            Date paymentDate = (Date) rowInfo.get('paymentDate');
            Boolean initRow = (Boolean) rowInfo.get('isInit');
            Boolean endRow = (Boolean) rowInfo.get('isEnd');

            System.debug(
                'DMT VALIDATING TENOR RANGE => ' +
                'paymentDate=' + paymentDate +
                ' | initialDate=' + initialDate +
                ' | maturityDate=' + maturityDate +
                ' | initRow=' + initRow +
                ' | endRow=' + endRow +
                ' | rowInfo=' + JSON.serialize(rowInfo)
            );

            // Skip INIT and END rows
            if (initRow || endRow) {
                System.debug('DMT SKIPPED INIT/END ROW => ' + JSON.serialize(rowInfo));
                continue;
            }

            if (paymentDate < initialDate) {
                System.debug(
                    'DMT ERROR EARLIER THAN INITIAL => ' +
                    'paymentDate=' + paymentDate +
                    ' | initialDate=' + initialDate +
                    ' | maturityDate=' + maturityDate +
                    ' | rowInfo=' + JSON.serialize(rowInfo)
                );

                result.put('validationPassed', false);
                result.put('errorMessage', Label.dmt_cl_PaymentDateEarlierInit_Text);
                return false;
            }

            if (paymentDate > maturityDate) {
                System.debug(
                    'DMT ERROR LATER THAN MATURITY => ' +
                    'paymentDate=' + paymentDate +
                    ' | initialDate=' + initialDate +
                    ' | maturityDate=' + maturityDate +
                    ' | rowInfo=' + JSON.serialize(rowInfo)
                );

                result.put('validationPassed', false);
                result.put('errorMessage', Label.dmt_cl_PaymentDateLaterInit_Text);
                return false;
            }
        }

        return true;
    }

    private static Map<String, Object> errorResult(Map<String, Object> result, String label) {
        result.put('validationPassed', false);
        result.put('errorMessage', label);
        return result;
    }

    public static Decimal parseDecimal(Object value) {
        if (value == null) {
            return 0;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return 0;
        }
    }
     public static Map<String, Object> validateRealGuaratorsFromRaw(List<Object> rawGuarantors) {
        Map<String, Object> result = new Map<String, Object>();
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();
        System.debug('Raw guarantors received for validation: ' + JSON.serializePretty(rawGuarantors));
        try {
            Boolean hasCurrency = true;
            Boolean hasCR = true;
            Boolean hasPR = true;
            Boolean hasLiqPeriodToRealFinance = true;


            for (Object o : rawGuarantors) {
                Map<String, Object> guarantorsMap = (Map<String, Object>)o;
                if(guarantorsMap.containsKey('Id')){
                    if(guarantorsMap.get('Id') == '0' && ((!guarantorsMap.containsKey('External_Rating__c') && !guarantorsMap.containsKey('Internal_Rating__c') && !guarantorsMap.containsKey('Commercial_Percentage__c') && !guarantorsMap.containsKey('Political_Percentage__c') 
                    && !guarantorsMap.containsKey('CurrencyIsoCode') && !guarantorsMap.containsKey('Mitigant_Type__c') && !guarantorsMap.containsKey('Liquidation_Period__c')) || (String.isBlank(String.valueOf(guarantorsMap.get('Internal_Rating__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('External_Rating__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('Commercial_Percentage__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('Political_Percentage__c')))
                    && String.isBlank(String.valueOf(guarantorsMap.get('CurrencyIsoCode'))) && String.isBlank(String.valueOf(guarantorsMap.get('Mitigant_Type__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('Liquidation_Period__c')))))){
                        break;
                    }else if(guarantorsMap.get('Id') == '1' && ((!guarantorsMap.containsKey('External_Rating__c') && !guarantorsMap.containsKey('Internal_Rating__c') && !guarantorsMap.containsKey('Commercial_Percentage__c') && !guarantorsMap.containsKey('Political_Percentage__c') 
                    && !guarantorsMap.containsKey('CurrencyIsoCode') && !guarantorsMap.containsKey('Mitigant_Type__c') && !guarantorsMap.containsKey('Liquidation_Period__c')) || (String.isBlank(String.valueOf(guarantorsMap.get('Internal_Rating__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('External_Rating__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('Commercial_Percentage__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('Political_Percentage__c')))
                    && String.isBlank(String.valueOf(guarantorsMap.get('CurrencyIsoCode'))) && String.isBlank(String.valueOf(guarantorsMap.get('Mitigant_Type__c'))) && String.isBlank(String.valueOf(guarantorsMap.get('Liquidation_Period__c')))))){
                        break;
                    }
                    else{
                        String cr = String.valueOf(guarantorsMap.get('Commercial_Percentage__c'));
                        String pr = String.valueOf(guarantorsMap.get('Political_Percentage__c'));
                        String currencyField = String.valueOf(guarantorsMap.get('CurrencyIsoCode'));
                        String mitigantType = String.valueOf(guarantorsMap.get('Mitigant_Type__c'));
                        String liqPeriod = String.valueOf(guarantorsMap.get('Liquidation_Period__c'));
                        List<String> validValuesLabelReal = new List<String> {'Real > Cash','Real > Gold Bullion','Real > Debt securities',
                        'Real > Debt securities issued by central governments or central Banks','Real > Index equities and Index convertible bonds','Real > Securitisation'};
                        hasCurrency = currencyField != '' && currencyField != null;
                        hasCR = cr != '' && cr != null;
                        hasPR = pr != '' && cr != null;
                        if (validValuesLabelReal.contains(mitigantType)) {
                            hasLiqPeriodToRealFinance =  liqPeriod != '' &&  liqPeriod != null;
                        } 
                        if (!hasCurrency || !hasCR || !hasPR || !hasLiqPeriodToRealFinance) {
                            break;
                        }
                    }
                }
            }
            if (!hasCurrency || !hasCR || !hasPR || !hasLiqPeriodToRealFinance) {
                    result.put('validationPassed', false);
                    result.put('errorMessage','Currency,Commercial Risk and Political Risk is required to save the collateral guarantees.');

                    if(!hasLiqPeriodToRealFinance){
                        result.put('errorMessage','Currency,Commercial Risk, Political Risk and Liquidation Perdiod is required to save the collateral guarantees.');
                    }
                    return result;
            }
            /*if (!hasCurrency) {
                result.put('validationPassed', false);
                result.put('errorMessage','Currency is required to save the real guarantees.');
                return result;
            }
            if (!hasCR) {
                result.put('validationPassed', false);
                result.put('errorMessage', 'Commercial Risk is required to save the real guarantees.');
                return result;
            }
            if (!hasPR) {
                result.put('validationPassed', false);
                result.put('errorMessage', 'Political is required to save the real guarantees.');
                return result;
            }
            if (!hasLiqPeriodToRealFinance) {
                result.put('validationPassed', false);
                result.put('errorMessage', 'Liquidation Periodolitical is required to save the real guarantees with this Mitigant Type.');
                return result;
            }*/
            result.put('validationPassed', true);
        } catch (Exception e) {
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Opportunity_Utils', 'validateTenorsFromRaw', 'DMT', '');
            exceptionList.add(dmtEcx);
            result.put('exceptionList', exceptionList);
        }
        return result;
    }
public static Map<String, Object> createProductsOpportunity(List<Object> products, Object oppId) {
    Map<String, Object> result = new Map<String, Object>();
    try {
        Opportunity opp = DMT_Opportunity_Selector.getOpportunity(String.valueOf(oppId));
        Passport__c passport = DMT_Opportunity_Selector.getPassport(String.valueOf(oppId));
        List<String> listProduct2 = new List<String>();
        Set<Id> setProduct2Ids = new Set<Id>();

        for (Object o : (List<Object>)products) {
            String prodIdStr = String.valueOf(o);
            listProduct2.add(prodIdStr);
            try {
                setProduct2Ids.add((Id)prodIdStr);
            } catch (Exception e) {
                System.debug('Invalid product Id format: ' + prodIdStr);
            }
        }

        String bookingGeography = getBranchbyEntity(opp.DMT_Entity__c, opp.Entific__c);
        Map<Id, PricebookEntry> mapIdToPricebookEntry = 
            DMT_Opportunity_Selector.getStandardActivePBEs(
                setProduct2Ids,
                opp.CurrencyIsoCode
            );

        Map<Id, Id> mapIoProduct2ToPBE = new Map<Id, Id>();
        for (PricebookEntry pbe : mapIdToPricebookEntry.values()) {
            mapIoProduct2ToPBE.put(pbe.Product2Id, pbe.Id);
        }

        List<OpportunityLineItem> oppLineItemsToInsert = new List<OpportunityLineItem>();
        for (Object o : (List<Object>)products) {
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.Product2Id = String.valueOf(o);
            oli.OpportunityId = String.valueOf(oppId);
            oli.TotalPrice = 0;
            oli.gf_maturity_date__c = opp.DMT_DATE_Maturity_Date__c != null ? opp.DMT_DATE_Maturity_Date__c : Date.today().addMonths(12);
            oli.gf_initial_date__c = opp.DMT_DATE_Initial_Date__c != null ? opp.DMT_DATE_Initial_Date__c : Date.today();
            oli.g_currency_id__c  = opp.DMT_CurrencyText__c;
            oli.Quantity = 1;
            // Si DMT_branch_id_c__c es null o vacío, usar bookingGeography
            if (!String.isBlank(opp.DMT_branch_id_c__c)) {
                oli.g_branch_id__c = opp.DMT_branch_id_c__c;
            } else {
                oli.g_branch_id__c = bookingGeography;
            }
            oli.PricebookEntryId = mapIoProduct2ToPBE.get(oli.Product2Id);
            String productName = mapIdToPricebookEntry.get(mapIoProduct2ToPBE.get(oli.Product2Id)).Product2.Name;
            oli.DMT_TXT_ProductNameOLI__c = (productName != null && productName.length() > 50)
                ? productName.substring(0, 50)
                : productName;
            oli.gf_payment_frequency__c = PAYMENTFREQUENCY;
            oli.gf_amortization_type__c = AMORTIZATIONTYPE;
            oli.customer_cib_ind_type__c = 'CIB';
            oli.product_scope_type__c = 'CIB';
            oli.origin_country_name__c = opp.Entific__c;
            oli.entity_role_type__c = 'Bookrunner';
            oli.Funding_Curve__c = 'BBVA SA';
            oli.DMT_Sustainability_bonus_eligible__c = 'No';
            oli.Life_Funding_Type__c = 'Term';

            oppLineItemsToInsert.add(oli);
        }

        if (!oppLineItemsToInsert.isEmpty()) {
            insert oppLineItemsToInsert;
            if(passport != null){
                passport.DMT_Is_Obsoleted_Passport_Save__c = true;
                update passport;
            }
           
        }

        result.put('created', true);
        result.put('productId', oppLineItemsToInsert);
        return result;

    } catch (Exception e) {
        result.put('created', false);
        result.put('errorMessage', e.getMessage());
        return result;
    }
}

 public static String getBranchbyEntity(String entity, String clientCountry) {

            String entityPorDefecto ='ES0182-ES';
            List<DMT_Taxonomy_Relationship__c> taxonomyValues = DMT_Opportunity_Selector.getTaxonomyValuesByEntity(entity);
        
        if (taxonomyValues.isEmpty()) {
            return null;
        }
        
        if (taxonomyValues.size() == 1) {
            return taxonomyValues[0].DMT_Final_Taxonomy_Value__r.DMT_Value__c;
        } else{
            
            for (DMT_Taxonomy_Relationship__c rel : taxonomyValues) {
                String val = rel.DMT_Final_Taxonomy_Value__r.DMT_Value__c;
                
                String ultimosVal = (val != null && val.length() >= 2) ? val.substring(val.length() - 2) : '';
            
                if (ultimosVal == clientCountry ) {
                    return val;
                }
            }
        }

        return entityPorDefecto	;
        
        
    }
    public static List<Object> cleanNumericDots(List<Object> rawTenors) {
        
        List<Object> records = rawTenors;

        for (Object obj : records) {
            if (!(obj instanceof Map<String, Object>)) {
                continue;
            }   
            Map<String, Object> recordMap = (Map<String, Object>) obj;
                        system.debug(recordMap);

            for (String key : recordMap.keySet()) {
                
                Object value = recordMap.get(key);
                
                if (value instanceof String) {
                    String strValue = (String) value;
                    system.debug('Before Cleaned 1 KEY: ' + key);
                    system.debug('Before Cleaned 1: ' + strValue);
                    // Detecta números tipo 70.000 o 1.200.000
                    if (strValue != null 
                        && strValue.contains('.') 
                        && isSpanishThousandsFormat(strValue)) {
                        system.debug('Before Cleaned: ' + strValue);
                        String cleaned = strValue.replace('.', '');
                        system.debug('After Cleaned: ' + cleaned);
                        // Convertimos a Decimal
                        recordMap.put(key, Decimal.valueOf(cleaned));
                    }
                }

            }
        }
        
        return records;
    }
    
    
    private static Boolean isSpanishThousandsFormat(String value) {
        return Pattern.matches('^[0-9]{1,3}(\\.[0-9]{3})+$', value);
    }
    
    public virtual class DMT_Opportunity_Tenor_Exception extends Exception {}

    /**
     * @description
     * Encuentra la cuenta correcta con la que se debe comparar la información.
     *
     * Lógica:
     * - Si la cuenta de la oportunidad es de tipo Subsidiary, NO se compara contra sí misma, sino que se empieza revisando el padre.
     * - Si es Subgroup/Group/Supragroup, se empieza revisando la propia cuenta.
     * - Si la cuenta actual no tiene datos válidos, se sube por la jerarquía usando AMH_GBL_Account_Relationship__c con AMH_Vision__c = 'Riesgos'.
     * - Se devuelve la primera cuenta válida encontrada.
     */
    public static Map<String, Object> getComparisonAccount(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Map<String, Object> result = new Map<String, Object>();
        List<DES_Exceptions__b> exceptionList = new List<DES_Exceptions__b>();

        try {
            Id oppAccountId;

            if (inputMap != null && inputMap.containsKey('oppAccountId') && inputMap.get('oppAccountId') != null) {
                oppAccountId = (Id) String.valueOf(inputMap.get('oppAccountId'));
            }

            if (oppAccountId == null) {
                result.put('error', true);
                result.put('errorMessage', 'oppAccountId es null o es inválido');
                return result;
            }

            Account sourceAccount = [SELECT Id, Name, DES_Structure_Type__c FROM Account WHERE Id = :oppAccountId LIMIT 1];

            Id accountToCheckId;

            // Si la cuenta origen es subsidiaria, no se compara contra sí misma. Se empieza revisando el padre directo.
            if (isSubsidiaryType(sourceAccount.DES_Structure_Type__c)) {
                accountToCheckId = getParentAccountId(sourceAccount.Id);
            } else {
                // Para Subgroup/Group/Supragroup, se empieza revisando la propia cuenta.
                accountToCheckId = sourceAccount.Id;
            }

            Account comparisonAccount = findFirstValidComparisonAccount(accountToCheckId);

            if (comparisonAccount != null) {
                result.put('comparisonAccountId', comparisonAccount.Id);
                result.put('comparisonAccountName', comparisonAccount.Name);
                result.put('comparisonAccountType', comparisonAccount.DES_Structure_Type__c);
                result.put('foundComparisonAccount', true);
            } else {
                result.put('comparisonAccountId', null);
                result.put('comparisonAccountName', null);
                result.put('comparisonAccountType', null);
                result.put('foundComparisonAccount', false);
            }

            result.put('sourceAccountId', sourceAccount.Id);
            result.put('sourceAccountType', sourceAccount.DES_Structure_Type__c);

        } catch (Exception e) {
            DES_Exceptions__b dmtEcx = DES_Exception_Utils.logExceptionWithoutInsert(e, 'DMT_Opportunity_Utils', 'getComparisonAccount', 'DMT', '');
            exceptionList.add(dmtEcx);

            result.put('error', true);
            result.put('errorMessage', e.getMessage());
        }

        if (!exceptionList.isEmpty()) {
            result.put('exceptionList', exceptionList);
        }

        return result;
    }

    /**
     * @description
     * Busca la primera cuenta válida para comparación.
     *
     * Lógica:
     * - Construye la jerarquía ascendente desde la cuenta inicial.
     * - Recupera todas las cuentas de esa jerarquía en una sola query.
     * - Recorre la jerarquía en orden y devuelve la primera cuenta que tenga datos válidos.
     */
    private static Account findFirstValidComparisonAccount(Id startingAccountId) {
        if (startingAccountId == null) {
            return null;
        }

        // Se construye la cadena jerárquica completa.
        List<Id> hierarchyIds = getHierarchyChain(startingAccountId);

        if (hierarchyIds.isEmpty()) {
            return null;
        }

        // Mapa con todas las cuentas de la jerarquía 
        Map<Id, Account> accountById = new Map<Id, Account>([SELECT Id, Name, DES_Structure_Type__c, Other_Relevant_Ratios_desc__c, cstk_sust_indicators_comments__c, Geographical_Footprint_desc__c, Relationship_Status_desc__c,
                                                             Industry_Overview_desc__c, Qualitative_Assesment_of_X_Sell_Rev_desc__c, DMT_Basic_Financials_Required_Fields__c, DMT_Business_Plan_Required_Fields__c 
                                                             FROM Account WHERE Id IN :hierarchyIds]);

        // Se recorre la jerarquía en orden ascendente
        for (Id accountId : hierarchyIds) {
            Account currentAccount = accountById.get(accountId);

            if (hasComparisonData(currentAccount)) {
                return currentAccount;
            }
        }

        return null;
    }

    /**
     * @description
     * Construye la cadena jerárquica ascendente de cuentas a revisar.
     *
     * Lógica
     * - Si falta algún nivel, simplemente sube al siguiente padre disponible.
     */
    private static List<Id> getHierarchyChain(Id startingAccountId) {
        List<Id> hierarchyIds = new List<Id>();

        if (startingAccountId == null) {
            return hierarchyIds;
        }

        Set<Id> visitedAccountIds = new Set<Id>();
        Id currentAccountId = startingAccountId;

        while (currentAccountId != null && !visitedAccountIds.contains(currentAccountId)) {
            hierarchyIds.add(currentAccountId);
            visitedAccountIds.add(currentAccountId);

            currentAccountId = getParentAccountId(currentAccountId);
        }

        return hierarchyIds;
    }

    /**
     * @description
     * Devuelve el padre directo de una cuenta usando AMH_GBL_Account_Relationship__c y filtrando por AMH_Vision__c = 'Riesgos'.
     * Si hay varios padres, se prioriza (Subgroup > Group > Supragroup).
     */
    public static Id getParentAccountId(Id childAccountId) {
        if (childAccountId == null) {
            return null;
        }

        List<AMH_GBL_Account_Relationship__c> relationships = [SELECT AMH_Parent_Account__c, AMH_Parent_Account__r.DES_Structure_Type__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c = :childAccountId];

        Id subgroupId;
        Id groupId;
        Id supragroupId;

        for (AMH_GBL_Account_Relationship__c rel : relationships) {
            String type = rel.AMH_Parent_Account__r.DES_Structure_Type__c;

            if (type == 'Subgroup' && subgroupId == null) {
                subgroupId = rel.AMH_Parent_Account__c;
            } else if (type == 'Group' && groupId == null) {
                groupId = rel.AMH_Parent_Account__c;
            } else if (type == 'Supragroup' && supragroupId == null) {
                supragroupId = rel.AMH_Parent_Account__c;
            }
        }

        if (subgroupId != null) return subgroupId;
        if (groupId != null) return groupId;
        if (supragroupId != null) return supragroupId;

        return null;
    }

    /**
     * @description
     * Determina si una cuenta tiene datos suficientes para ser usada como cuenta de comparación.
     *
     * Lógica:
     * - Se compara si alguno de los 2 booleanos está a true o si alguno de los 6 text area tiene valor real.
     */
    public static Boolean hasComparisonData(Account acc) {
        if (acc == null) {
            return false;
        }

        return acc.DMT_Basic_Financials_Required_Fields__c == true || acc.DMT_Business_Plan_Required_Fields__c == true ||
               hasRealTextValue(acc.Other_Relevant_Ratios_desc__c) || hasRealTextValue(acc.cstk_sust_indicators_comments__c) ||
               hasRealTextValue(acc.Geographical_Footprint_desc__c) || hasRealTextValue(acc.Relationship_Status_desc__c) ||
               hasRealTextValue(acc.Industry_Overview_desc__c) || hasRealTextValue(acc.Qualitative_Assesment_of_X_Sell_Rev_desc__c);
    }

    /**
     * @description
     * Comprueba si un string tiene un valor real, es decir, no es null, no está vacío, no es solo espacios y no es 'N/A'.
     */
    private static Boolean hasRealTextValue(String value) {
        if (String.isBlank(value)) {
            return false;
        }

        String normalized = value.trim().toUpperCase();

        return normalized != 'N/A';
    }

    /**
     * @description
     * Comprueba si el tipo de estructura corresponde a una subsidiaria.
     */
    public static Boolean isSubsidiaryType(String structureType) {
        return !String.isBlank(structureType) && structureType == 'Subsidiary';
    }

    /**
     * @description
     * Bulkified, Async handler to clone Account X-Sells to newly created Opportunities.
     * Evaluates hierarchies up to 4 levels deep efficiently.
     * @param payload The Async Payload containing the target Opportunity IDs.
     */
    public static void handleOppXSellGeneration(DMT_OppXSellPayload payload) {
        if (payload == null || payload.opportunityIds == null || payload.opportunityIds.isEmpty()) {
            return;
        }

        // 1. Query Valid Opportunities
        List<Opportunity> validOpps = getValidOpportunitiesForXSell(payload.opportunityIds);
        if (validOpps.isEmpty()) {
            return;
        }

        Set<Id> startingAccIds = new Set<Id>();
        Set<String> entityCodes = new Set<String>();
        for (Opportunity opp : validOpps) {
            startingAccIds.add(opp.AccountId);
            entityCodes.add(opp.DMT_Entity__c);
        }

        // 2. Resolve Taxonomy Mapping
        Map<String, Set<String>> entityToH007Map = getTaxonomyH006ToH007Map(entityCodes);

        // 3. Build Account Hierarchy
        Set<Id> allHierarchyAccIds = new Set<Id>(startingAccIds);
        Map<Id, Id> childToParentMap = buildAccountHierarchyMap(startingAccIds, allHierarchyAccIds);

        // 4. Query all required Account Data (including DES_Structure_Type__c for base check)
        Map<Id, Account> allDataAccounts = new Map<Id, Account>([
            SELECT Id, DES_Structure_Type__c, DMT_Basic_Financials_Required_Fields__c, DMT_Business_Plan_Required_Fields__c,
                   Other_Relevant_Ratios_desc__c, cstk_sust_indicators_comments__c,
                   Geographical_Footprint_desc__c, Relationship_Status_desc__c,
                   Industry_Overview_desc__c, Qualitative_Assesment_of_X_Sell_Rev_desc__c
            FROM Account 
            WHERE Id IN :allHierarchyAccIds
            WITH SYSTEM_MODE
        ]);

        // 5. Determine Comparison Accounts
        Map<Id, Id> startAccToComparisonAcc = mapStartToComparisonAccounts(startingAccIds, childToParentMap, allDataAccounts);

        // 6. Query X-Sells
        Map<Id, List<DMT_X_Sell__c>> compAccToXSells = getComparisonAccountXSells(new Set<Id>(startAccToComparisonAcc.values()));

        // 7. Generate New X-Sells
        List<DMT_X_Sell__c> xsellsToInsert = generateOppXSells(validOpps, startAccToComparisonAcc, compAccToXSells, entityToH007Map);

        // 8. Commit
        if (!xsellsToInsert.isEmpty()) {
            Database.insert(xsellsToInsert, AccessLevel.SYSTEM_MODE);
        }
    }

    /**
     * @description Queries Opportunities that have the required fields to process X-Sells.
     * @param oppIds Set of Opportunity IDs to evaluate.
     * @return List of valid Opportunities.
     */
    private static List<Opportunity> getValidOpportunitiesForXSell(Set<Id> oppIds) {
        return [
            SELECT Id, AccountId, DMT_Entity__c 
            FROM Opportunity 
            WHERE Id IN :oppIds 
              AND DMT_Entity__c != null 
              AND AccountId != null
            WITH SYSTEM_MODE
        ];
    }

    /**
     * @description Maps Opportunity Entity Codes (H006) to allowed Booking Geographies (H007).
     * @param entityCodes Set of H006 values.
     * @return Map connecting H006 to a Set of valid H007 values.
     */
    private static Map<String, Set<String>> getTaxonomyH006ToH007Map(Set<String> entityCodes) {
        Map<String, Set<String>> entityToH007Map = new Map<String, Set<String>>();
        for (DMT_Taxonomy_Relationship__c rel : [
            SELECT DMT_Initial_Taxonomy_Value__r.DMT_Value__c, DMT_Final_Taxonomy_Value__r.DMT_Value__c
            FROM DMT_Taxonomy_Relationship__c
            WHERE DMT_Id_Catalog_Initial__c = 'H006'
              AND DMT_Id_Catalog_Final__c = 'H007'
              AND DMT_Final_Taxonomy_Value__r.DMT_Active__c = true
              AND DMT_Initial_Taxonomy_Value__r.DMT_Value__c IN :entityCodes
            WITH SYSTEM_MODE
        ]) {
            String h006 = rel.DMT_Initial_Taxonomy_Value__r.DMT_Value__c;
            String h007 = rel.DMT_Final_Taxonomy_Value__r.DMT_Value__c;
            
            if (!entityToH007Map.containsKey(h006)) {
                entityToH007Map.put(h006, new Set<String>());
            }
            entityToH007Map.get(h006).add(h007);
        }
        return entityToH007Map;
    }

    /**
     * @description Ascends the Account Hierarchy up to 4 levels and builds a mapping of Child to Parent.
     * @param startingAccIds The base Accounts from the Opportunities.
     * @param allHierarchyAccIds Set populated by reference with every Account ID found in the hierarchy.
     * @return Map of Child Account ID to Parent Account ID.
     */
    private static Map<Id, Id> buildAccountHierarchyMap(Set<Id> startingAccIds, Set<Id> allHierarchyAccIds) {
        Map<Id, Id> childToParentMap = new Map<Id, Id>();
        Set<Id> currentLevelIds = new Set<Id>(startingAccIds);

        for (Integer i = 0; i < 4; i++) {
            if (currentLevelIds.isEmpty()) {
                break;
            }
            
            List<AMH_GBL_Account_Relationship__c> rels = [
                SELECT AMH_Child_Account__c, AMH_Parent_Account__c, AMH_Parent_Account__r.DES_Structure_Type__c 
                FROM AMH_GBL_Account_Relationship__c 
                WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c IN :currentLevelIds
                WITH SYSTEM_MODE
            ];
            
            Map<Id, Id> bestParentMap = new Map<Id, Id>();
            for (Id childId : currentLevelIds) {
                Id subgroupId;
                Id groupId;
                Id supragroupId;
                
                for (AMH_GBL_Account_Relationship__c rel : rels) {
                    if (rel.AMH_Child_Account__c == childId) {
                        String type = rel.AMH_Parent_Account__r.DES_Structure_Type__c;
                        if (type == 'Subgroup' && subgroupId == null) {
                            subgroupId = rel.AMH_Parent_Account__c;
                        } else if (type == 'Group' && groupId == null) {
                            groupId = rel.AMH_Parent_Account__c;
                        } else if (type == 'Supragroup' && supragroupId == null) {
                            supragroupId = rel.AMH_Parent_Account__c;
                        }
                    }
                }
                
                Id bestParentId = subgroupId != null ? subgroupId : (groupId != null ? groupId : supragroupId);
                if (bestParentId != null) {
                    bestParentMap.put(childId, bestParentId);
                    allHierarchyAccIds.add(bestParentId);
                }
            }
            childToParentMap.putAll(bestParentMap);
            currentLevelIds = new Set<Id>(bestParentMap.values());
        }
        return childToParentMap;
    }

    /**
     * @description Matches the base Opportunity Account to the correct Comparison Account.
     * @param startingAccIds The base Accounts from the Opportunities.
     * @param childToParentMap The pre-built hierarchy relationships.
     * @param allDataAccounts The Account records queried with comparison fields.
     * @return Map of Base Account ID to its determined Comparison Account ID.
     */
    private static Map<Id, Id> mapStartToComparisonAccounts(Set<Id> startingAccIds, Map<Id, Id> childToParentMap, Map<Id, Account> allDataAccounts) {
        Map<Id, Id> startAccToComparisonAcc = new Map<Id, Id>();
        
        for (Id startAccId : startingAccIds) {
            Account baseAcc = allDataAccounts.get(startAccId);
            Id currentId = startAccId;
            
            if (baseAcc != null && isSubsidiaryType(baseAcc.DES_Structure_Type__c)) {
                currentId = childToParentMap.get(startAccId);
            }
            
            Id foundComparisonId = null;
            Set<Id> visited = new Set<Id>(); 
            
            while (currentId != null && !visited.contains(currentId)) {
                visited.add(currentId);
                Account dataAcc = allDataAccounts.get(currentId);
                
                if (hasComparisonData(dataAcc)) {
                    foundComparisonId = currentId;
                    break;
                }
                currentId = childToParentMap.get(currentId);
            }
            
            if (foundComparisonId != null) {
                startAccToComparisonAcc.put(startAccId, foundComparisonId);
            }
        }
        return startAccToComparisonAcc;
    }

    /**
     * @description Retrieves existing X-Sell records associated with the target Comparison Accounts.
     * @param comparisonAccIds Set of Account IDs serving as comparison anchors.
     * @return Map grouping Account IDs to their respective X-Sell records.
     */
    private static Map<Id, List<DMT_X_Sell__c>> getComparisonAccountXSells(Set<Id> comparisonAccIds) {
        Map<Id, List<DMT_X_Sell__c>> compAccToXSells = new Map<Id, List<DMT_X_Sell__c>>();
        comparisonAccIds.remove(null);
        
        if (comparisonAccIds.isEmpty()) {
            return compAccToXSells;
        }
        
        for (DMT_X_Sell__c xs : [
            SELECT Account__c, Booking_Geography__c, XSELL_Value_PY__c, XSELL_Value_CY__c, XSELL_Value_NY__c, XSELL_Value_NY1__c
            FROM DMT_X_Sell__c
            WHERE Account__c IN :comparisonAccIds
            WITH SYSTEM_MODE
        ]) {
            if (!compAccToXSells.containsKey(xs.Account__c)) {
                compAccToXSells.put(xs.Account__c, new List<DMT_X_Sell__c>());
            }
            compAccToXSells.get(xs.Account__c).add(xs);
        }
        return compAccToXSells;
    }

    /**
     * @description Generates new Opportunity X-Sell records cloned from the Comparison Accounts, filtered by Taxonomy.
     * @param validOpps List of target Opportunities.
     * @param startAccToComparisonAcc Mapping of the Opp's base Account to its Comparison Account.
     * @param compAccToXSells Source X-Sell records from the Comparison Accounts.
     * @param entityToH007Map Valid H007 Booking Geographies based on the Opp's Entity Code.
     * @return List of prepared DMT_X_Sell__c records ready for insert.
     */
    private static List<DMT_X_Sell__c> generateOppXSells(List<Opportunity> validOpps, Map<Id, Id> startAccToComparisonAcc, Map<Id, List<DMT_X_Sell__c>> compAccToXSells, Map<String, Set<String>> entityToH007Map) {
        List<DMT_X_Sell__c> xsellsToInsert = new List<DMT_X_Sell__c>();
        
        for (Opportunity opp : validOpps) {
            Id compAccId = startAccToComparisonAcc.get(opp.AccountId);
            if (compAccId == null) {
                continue;
            }
            
            List<DMT_X_Sell__c> accXSells = compAccToXSells.get(compAccId);
            if (accXSells == null || accXSells.isEmpty()) {
                continue;
            }
            
            Set<String> validH007Codes = entityToH007Map.get(opp.DMT_Entity__c);
            if (validH007Codes == null || validH007Codes.isEmpty()) {
                continue;
            }
            
            for (DMT_X_Sell__c xs : accXSells) {
                if (validH007Codes.contains(xs.Booking_Geography__c)) {
                    xsellsToInsert.add(new DMT_X_Sell__c(
                        Opportunity__c = opp.Id,
                        Booking_Geography__c = xs.Booking_Geography__c,
                        XSELL_Value_PY__c = xs.XSELL_Value_PY__c,
                        XSELL_Value_CY__c = xs.XSELL_Value_CY__c,
                        XSELL_Value_NY__c = xs.XSELL_Value_NY__c,
                        XSELL_Value_NY1__c = xs.XSELL_Value_NY1__c
                    ));
                }
            }
        }
        return xsellsToInsert;
    }

}