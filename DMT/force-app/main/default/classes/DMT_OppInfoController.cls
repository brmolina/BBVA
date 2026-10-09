public with sharing class DMT_OppInfoController {

    private static final String STAGE_READY_TO_CLOSE = 'Ready to close';

    /**
     * @description Saves the Opportunity fields from dmt_opp_info component.
     * Updates the Opportunity record and related OpportunityLineItems when branch_id changes.
     * @param opportunityId The Id of the Opportunity to update
     * @param fieldValues Map of field names to their new values
     * @throws AuraHandledException if opportunityId is null or fieldValues is empty
     */
    @AuraEnabled(cacheable=false)
    public static void saveOpportunity(Id opportunityId, Map<String, Object> fieldValues) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required.');
        }
        if (fieldValues == null || fieldValues.isEmpty()) {
            throw new AuraHandledException('fieldValues cannot be empty.');
        }

        try {
            Opportunity opp = new Opportunity(Id = opportunityId);

            for (String fieldName : fieldValues.keySet()) {
                if (fieldName == 'DMT_Tenor__c' || fieldName == 'CloseDate') continue;
                opp.put(fieldName, fieldValues.get(fieldName));
            }

            Object closeDateValue = fieldValues.get('CloseDate');
            if (closeDateValue != null) {
                opp.CloseDate = Date.valueOf((String) closeDateValue);
            }

            Opportunity oppCurrent = [
                SELECT DMT_DATE_Initial_Date__c, StageName
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            Object tenorValue = fieldValues.get('DMT_Tenor__c');
            if (tenorValue != null && oppCurrent.DMT_DATE_Initial_Date__c != null) {
                Integer tenorMonths = Integer.valueOf(String.valueOf(tenorValue));
                opp.DMT_DATE_Maturity_Date__c = oppCurrent.DMT_DATE_Initial_Date__c.addMonths(tenorMonths);
            }

            opp.DMT_Is_Change_in_Ready_to_close__c = oppCurrent.StageName == STAGE_READY_TO_CLOSE;

            Object branchIdValue = fieldValues.get('DMT_branch_id_c__c');
            if (branchIdValue != null) {
                List<OpportunityLineItem> lineItems = [
                    SELECT Id, g_branch_id__c
                    FROM OpportunityLineItem
                    WHERE OpportunityId = :opportunityId
                ];

                if (!lineItems.isEmpty()) {
                    for (OpportunityLineItem item : lineItems) {
                        item.g_branch_id__c = (String) branchIdValue;
                    }
                    update lineItems;
                }
            }

            update opp;

            List<Passport__c> passports = [
                SELECT Id
                FROM Passport__c
                WHERE Opportunity__c = :opportunityId
                LIMIT 1
            ];
            if (!passports.isEmpty()) {
                passports[0].DMT_Is_Obsoleted_Passport_Save__c = true;
                update passports[0];
            }

        } catch (DmlException e) {
            DES_Exception_Utils.logException(e, 'DMT_OppInfoController', 'saveOpportunity', 'DMT', '');
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_OppInfoController', 'saveOpportunity', 'DMT', '');
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getOpportunityInfoContext(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required.');
        }

        try {

            Opportunity opp = [
                SELECT
                    Id,
                    Name,
                    DMT_Entity__c,
                    Entific__c,
                    CloseDate,
                    DMT_Tenor__c,
                    DMT_Opportunity_amount__c,
                    DMT_Capital_Action__c,
                    DMT_ContingentCommitments__c,
                    DMT_branch_id_c__c,
                    DMT_Booking_EFAN__c,
                    bbva_prtcp_tranche_amount__c,
                    DMT_CurrencyText__c,
                    DMT_Product_Area__c,
                    DMT_Confidential__c,
                    DMT_DATE_Maturity_Date__c,
                    DMT_DATE_Initial_Date__c,
                    DMT_CUR_Notional_Amount__c,
                    DMT_SPPI_File_Uploaded__c,
                    DMT_SPPI_Status__c,
                    DMT_SPPI_User__c,
                    DMT_Structured_GTB__c,
                    DMT_Clan_File_Status__c,
                    DMT_Clan_File_Id__c,
                    DMT_Booking_System_Code__c,
                    DMT_Defense_Due_Diligence__c,
                    DMT_Under_X_Selling_Monitoring__c,
                    DMT_NewClient__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            if (opp.Entific__c != null) {
                String label = buildCatalogLabel(opp.Entific__c, DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('CD07'));
                opp.Entific__c = label != null ? opp.Entific__c + ' - ' + label : opp.Entific__c;
            }

            if (opp.DMT_Entity__c != null) {
                String label = buildCatalogLabel(opp.DMT_Entity__c, DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('H006'));
                opp.DMT_Entity__c = label != null ? opp.DMT_Entity__c + ' - ' + label : opp.DMT_Entity__c;
            }

        
            Date maxMaturityDate = opp.DMT_DATE_Maturity_Date__c;

            Map<String, Object> oppMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(opp));
            oppMap.put('DMT_CUR_Notional_Amount__c', resolveFormattedAmount(opp.DMT_CUR_Notional_Amount__c, opp.DMT_CurrencyText__c, 'DMT_CUR_Notional_Amount__c'));
            oppMap.put('DMT_Opportunity_amount__c', resolveFormattedAmount(opp.DMT_Opportunity_amount__c, opp.DMT_CurrencyText__c, 'DMT_Opportunity_amount__c'));

            Map<String, Object> outMap = new Map<String, Object>();
            outMap.put('opportunity', oppMap);
            outMap.put('maxMaturityDate', maxMaturityDate != null ? String.valueOf(maxMaturityDate) : null);

            return outMap;

        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_OppInfoController', 'getOpportunityInfoContext', 'DMT', '');
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, String> getFormattedAmountsForCurrency(Id opportunityId, String currencyText) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required.');
        }
        try {
            List<OpportunityLineItem> oliList = [
                SELECT DMT_Deal_amount__c, bbva_prtcp_tranche_amount__c, g_currency_id__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
            ];

            Decimal totalDealAmount     = 0;
            Decimal totalNotionalAmount = 0;

            for (OpportunityLineItem oli : oliList) {
                Decimal oliDeal     = oli.DMT_Deal_amount__c             != null ? oli.DMT_Deal_amount__c             : 0;
                Decimal oliNotional = oli.bbva_prtcp_tranche_amount__c   != null ? oli.bbva_prtcp_tranche_amount__c   : 0;

                Decimal convertedDeal     = DMT_Currency.convert(oliDeal,     oli.g_currency_id__c, currencyText);
                Decimal convertedNotional = DMT_Currency.convert(oliNotional, oli.g_currency_id__c, currencyText);

                if (convertedDeal == null || convertedNotional == null) {
                    throw new AuraHandledException('Exchange rate not found for the currency pair: ' + oli.g_currency_id__c + ' to ' + currencyText);
                }

                totalDealAmount     += convertedDeal;
                totalNotionalAmount += convertedNotional;
            }

            totalDealAmount     = totalDealAmount.setScale(2, RoundingMode.HALF_UP);
            totalNotionalAmount = totalNotionalAmount.setScale(2, RoundingMode.HALF_UP);

            String notionalFormatted  = resolveFormattedAmount(totalNotionalAmount, currencyText, 'DMT_CUR_Notional_Amount__c');
            String oppAmountFormatted = resolveFormattedAmount(totalDealAmount,     currencyText, 'DMT_Opportunity_amount__c');

            return new Map<String, String>{
                'DMT_CUR_Notional_Amount__c' => notionalFormatted,
                'DMT_Opportunity_amount__c'  => oppAmountFormatted
            };
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_OppInfoController', 'getFormattedAmountsForCurrency', 'DMT', '');
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String resolveFormattedAmount(Decimal rawAmount, String currencyIso, String fieldName) {
        Decimal amount = rawAmount != null ? rawAmount : 0;

        Map<String, Object> convOut = new Map<String, Object>();
        DMT_Currency_Conversion_Utils.DMT_Multiple_Amount_Conversion(
            new Map<String, Object>{
                'action'   => 'output',
                'list'     => fieldName,
                'currency' => currencyIso,
                fieldName  => amount
            },
            convOut,
            null
        );

        Object convertedRaw = convOut.get(fieldName);
        Decimal converted = convertedRaw != null ? Decimal.valueOf(String.valueOf(convertedRaw)) : amount;

        String convertedStr = String.valueOf(converted);
        if (convertedStr.containsIgnoreCase('E')) {
            Map<String, Object> sciOut = new Map<String, Object>();
            DMT_Currency_Conversion_Utils.formatAmountScientificNotation(
                new Map<String, Object>{ 'arguments' => new List<Object>{ convertedStr } },
                sciOut,
                null
            );
            Object fixedVal = sciOut.get('result');
            converted = fixedVal != null ? Decimal.valueOf(String.valueOf(fixedVal)) : converted;
        }

        Map<String, Object> fmtOut = new Map<String, Object>();
        DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(
            new Map<String, Object>{ fieldName => converted },
            fmtOut,
            null
        );

        Object formatted = fmtOut.get(fieldName);
        return formatted != null ? String.valueOf(formatted) : String.valueOf(converted);
    }

    private static String buildCatalogLabel(String value, List<Map<String, String>> catalogEntries) {
        if (value == null || catalogEntries == null) return null;
        for (Map<String, String> entry : catalogEntries) {
            if (value == entry.get('value')) return entry.get('label');
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getPicklistOptions(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required.');
        }

        try {
            Map<String, List<Map<String, String>>> result = DMT_CatalogHelper.getAllTaxonomyCatalogValues();

            Opportunity opp = [
                SELECT DMT_Entity__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            if (!String.isBlank(opp.DMT_Entity__c)) {
                List<DMT_Taxonomy_Relationship__c> relationshipsBookingGeography = [
                    SELECT
                        Id,
                        DMT_Id_Catalog_Initial__c,
                        DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c,
                        DMT_Final_Taxonomy_Value__r.DMT_Value__c,
                        CreatedDate
                    FROM DMT_Taxonomy_Relationship__c
                    WHERE DMT_Id_Catalog_Initial__c = 'H006'
                        AND DMT_Id_Catalog_Final__c = 'H007'
                        AND DMT_Final_Taxonomy_Value__r.DMT_Active__c = true
                        AND DMT_Initial_Taxonomy_Value__r.DMT_Value__c = :opp.DMT_Entity__c
                    ORDER BY DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c, CreatedDate ASC
                ];

                List<Map<String, String>> bookingGeographyOptions = new List<Map<String, String>>();
                Set<String> addedValues = new Set<String>();
                for (DMT_Taxonomy_Relationship__c rel : relationshipsBookingGeography) {
                    String val = rel.DMT_Final_Taxonomy_Value__r.DMT_Value__c;
                    if (!addedValues.contains(val)) {
                        addedValues.add(val);
                        bookingGeographyOptions.add(new Map<String, String>{
                            'label' => rel.DMT_Final_Taxonomy_Value__r.DMT_Name_EN__c,
                            'value' => val
                        });
                    }
                }
                result.put('bookingGeographyOptions', bookingGeographyOptions);
            }

            // Booking EFAN options — same entity-filtered catalog as Booking Geography + 2 extra BBVA values
            List<Map<String, String>> bookingEFANOptions = new List<Map<String, String>>();
            if (result.containsKey('bookingGeographyOptions')) {
                bookingEFANOptions.addAll(result.get('bookingGeographyOptions'));
            }
            bookingEFANOptions.add(new Map<String, String>{ 'label' => 'BBVA SA - Italy (MENA)',  'value' => 'ES0182-IT-MENA' });
            bookingEFANOptions.add(new Map<String, String>{ 'label' => 'BBVA SA - US (Latam)',     'value' => 'ES0182-US-Latam' });
            result.put('bookingEFANOptions', bookingEFANOptions);

            // SPPI Test Status options — fixed values confirmed by business
            List<Map<String, String>> sppiStatusOptions = new List<Map<String, String>>{
                new Map<String, String>{ 'label' => 'Passed',                    'value' => 'Passed' },
                new Map<String, String>{ 'label' => 'Not Passed - NPC required', 'value' => 'Not Passed - NPC required' },
                new Map<String, String>{ 'label' => 'Pending',                   'value' => 'Pending' },
                new Map<String, String>{ 'label' => 'N/A',                       'value' => 'N/A' }
            };
            result.put('sppiStatusOptions', sppiStatusOptions);

            return result;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_OppInfoController', 'getPicklistOptions', 'DMT', '');
            throw new AuraHandledException(e.getMessage());
        }
    }
}