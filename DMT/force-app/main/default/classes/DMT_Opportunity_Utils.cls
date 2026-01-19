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

                if (!validateDateRanges(rowsBuffer, initialDateVar, maturityDateVar, result)) {
                    return result;
                }
            }

            result.put('validationPassed', true);

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
        return drawnAmount > 0 || undrawnAmount > 0;
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

            // Skip INIT and END rows
            if (initRow || endRow) {
                continue;
            }

            if (paymentDate < initialDate) {
                result.put('validationPassed', false);
                result.put('errorMessage', Label.dmt_cl_PaymentDateEarlierInit_Text);
                return false;
            }
            if (paymentDate > maturityDate) {
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
                    result.put('errorMessage','Currency,Commercial Risk, Political Risk and Liquidation Perdiod is required to save the real guarantees.');
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

        String bookingGeography = getBranchbyEntity(opp.DMT_Entity__c, opp.DES_Client_Country__c);
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
            oli.gf_maturity_date__c = System.today().addMonths(12);
            oli.gf_initial_date__c = System.today();
            oli.g_currency_id__c  = opp.DMT_Currency__c;
            oli.Quantity = 1;
            oli.g_branch_id__c = bookingGeography;
            oli.PricebookEntryId = mapIoProduct2ToPBE.get(oli.Product2Id);
            oli.DMT_TXT_ProductNameOLI__c = mapIdToPricebookEntry.get(mapIoProduct2ToPBE.get(oli.Product2Id)).Product2.Name;
            oli.gf_payment_frequency__c = PAYMENTFREQUENCY;
            oli.gf_amortization_type__c = AMORTIZATIONTYPE;
            oli.customer_cib_ind_type__c = 'CIB';
            oli.product_scope_type__c = 'CIB';
            oli.origin_country_name__c = opp.Entific__c;
            oli.entity_role_type__c = 'Bookrunner';
            oppLineItemsToInsert.add(oli);
        }

        if (!oppLineItemsToInsert.isEmpty()) {
            insert oppLineItemsToInsert;
        }

        result.put('created', true);
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

    
    public virtual class DMT_Opportunity_Tenor_Exception extends Exception {}

}