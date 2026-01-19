public with sharing class DMT_UnderwritingFormController {

    public class LookupOption {
        @AuraEnabled public String value; // Id del Client (Cib_Client__c)
        @AuraEnabled public String label; // Nombre del Client (Cib_Client__r.Name)
        public LookupOption(String v, String l){
            value = v; label = l;
        }
    }

    @AuraEnabled
    public static Map<String, Object> getUnderwritingData(Id recordId) {

        Map<String, Object> result = new Map<String, Object>();

        Opportunity opp = [
            SELECT Id, Name, underwriting_agreement_type__c, deal_total_amount__c, 
                bbva_prtcp_tranche_amount__c, syndicated_loan_drawn_amount__c,
                gf_current_be_sold_mk_amount__c, operation_underwriting_per__c,
                gf_est_fee_cust_sycr_bp_amount__c, opening_fee_per__c, 
                risk_committee_aprvl_ind_type__c, signing_date__c,
                gf_mk_curr_rsk_synd_amount__c, gf_prort_sale_ord_sum_amount__c,
                gf_total_nominal_sold_amount__c, gf_total_sold_ord_stl_amount__c,
                gf_tl_sold_ord_not_stl_amount__c, underwriting_amount__c,
                gf_comt_not_settled_amount__c, gf_synd_fnl_primry_allc_amount__c,
                gf_prort_setl_order_tl_amount__c, risk_effective_date__c,
                gf_settlement_date__c, gf_oppy_credit_agree_sign_date__c,
                clan_syndicated_loan_id__c, gf_opportunity_end_year_id__c, DES_Date_Won_Lost__c,
                gf_oppy_undwr_approval_year_id__c, oppy_undwr_cmtee_approval_date__c,
                oppy_undwr_cmtee_rspse_type__c, DMT_HasGUMSProduct__c,
                bbva_participation_per__c, underwriting_fee_amount__c,
                gf_own_undwr_mk_rsk_fee_amount__c, gf_upfront_undwr_fees_amount__c,
                gf_tot_sold_order_fees_amount__c, oppy_product_ctrct_comt_date__c,
                gf_oppy_undwr_cmtee_comnt_desc__c
            FROM Opportunity 
            WHERE Id = :recordId
        ];

        result.put('opportunity', opp);

        // Picklists de Opportunity
        Map<String, List<Map<String, String>>> picklistValues = new Map<String, List<Map<String, String>>>();

        picklistValues.put('underwriting_agreement_type__c', 
            getPicklistOptions('Opportunity', 'underwriting_agreement_type__c'));
        picklistValues.put('risk_committee_aprvl_ind_type__c', 
            getPicklistOptions('Opportunity', 'risk_committee_aprvl_ind_type__c'));
        picklistValues.put('oppy_undwr_cmtee_rspse_type__c', 
            getPicklistOptions('Opportunity', 'oppy_undwr_cmtee_rspse_type__c'));

        result.put('picklistValues', picklistValues);

        // Sold_Order__c relacionados con la Opportunity
        List<Sold_Order__c> soldOrders = [
            SELECT Id,
                gf_loan_br_ctpty_id__c,
                gf_loan_br_ctpty_id__r.Name,
                gf_ctpty_sold_order_amount__c,
                gf_sold_ord_ctpty_setl_amount__c,
                gf_sold_order_settled_ind_type__c,
                Currency__c,
                gf_sold_orders_fees_bps_amount__c,
                gf_bbva_assur_prtcp_per__c,
                opportunity_id__c
            FROM Sold_Order__c
            WHERE opportunity_id__c = :recordId
            ORDER BY CreatedDate
        ];
        result.put('soldOrders', soldOrders);

        List<Map<String, String>> soldOrderCurrencyOptions =
            getPicklistOptions('Sold_Order__c', 'Currency__c');
        result.put('soldOrderCurrencyOptions', soldOrderCurrencyOptions);

        List<Map<String, String>> soldOrderSettledOptions =
        getPicklistOptions('Sold_Order__c', 'gf_sold_order_settled_ind_type__c');
        result.put('soldOrderSettledOptions', soldOrderSettledOptions);

        List<Map<String, String>> counterpartyOptions = new List<Map<String, String>>();
        for (Account acc : [
            SELECT Id, Name
            FROM Account
            WHERE Name != null
            LIMIT 200
        ]) {
            counterpartyOptions.add(new Map<String, String>{
                'label' => acc.Name,
                'value' => acc.Id
            });
        }
        result.put('soldOrderCounterpartyOptions', counterpartyOptions);

        return result;
    }

    private static List<Map<String, String>> getPicklistOptions(String objectApiName, String fieldApiName) {
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult describeSObjectResult = sobjectType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = describeSObjectResult.fields.getMap().get(fieldApiName).getDescribe();

        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            options.add(new Map<String, String>{
                'label' => entry.getLabel(),
                'value' => entry.getValue()
            });
        }
        return options;
    }

    @AuraEnabled
    public static void saveUnderwritingData(Id recordId,  Map<String, Object> updatedFields, List<Sold_Order__c> soldOrders, List<Id> idsToDelete) {
        // Allowed edit fields
        Set<String> allowedFields = new Set<String>{
            'underwriting_agreement_type__c',
            'deal_total_amount__c',
            'bbva_prtcp_tranche_amount__c',
            'syndicated_loan_drawn_amount__c',
            'operation_underwriting_per__c',
            'gf_est_fee_cust_sycr_bp_amount__c',
            'opening_fee_per__c',
            'risk_committee_aprvl_ind_type__c',
            'signing_date__c',
            'underwriting_amount__c',
            'gf_synd_fnl_primry_allc_amount__c',
            'risk_effective_date__c',
            'gf_settlement_date__c',
            'gf_oppy_credit_agree_sign_date__c',
            'clan_syndicated_loan_id__c',
            'DES_Date_Won_Lost__c',
            'oppy_undwr_cmtee_approval_date__c',
            'oppy_undwr_cmtee_rspse_type__c',
            'bbva_participation_per__c',
            'oppy_product_ctrct_comt_date__c',
            'gf_oppy_undwr_cmtee_comnt_desc__c'
        };

        if (updatedFields != null && !updatedFields.isEmpty()) {
            Opportunity oppToUpdate = new Opportunity(Id = recordId);

            for (String key : updatedFields.keySet()) {
                if (!allowedFields.contains(key)) {
                    continue;
                }

                Object value = updatedFields.get(key);

                // Treat empty strings as null to allow clearing fields
                if (value instanceof String && String.valueOf(value).trim() == '') {
                    value = null;
                }

                // Date conversion only when value is not null and is a String
                if (value != null && value instanceof String &&
                    (key == 'signing_date__c' || key == 'risk_effective_date__c' || key == 'gf_settlement_date__c' || key == 'gf_oppy_credit_agree_sign_date__c' ||
                     key == 'DES_Date_Won_Lost__c' || key == 'oppy_undwr_cmtee_approval_date__c' || key == 'oppy_product_ctrct_comt_date__c')) {
                    try {
                        value = Date.valueOf((String)value);
                    } catch (Exception e) {
                        DES_Exception_Utils.logException(e,'DMT_UnderwritingFormController', 'saveUnderwritingData', 'DMT', '');
                        throw new AuraHandledException('Invalid date format for field ' + key + ': ' + value);
                    }
                }

                // Assign even when null (so the field is cleared)
                oppToUpdate.put(key, value);
            }

            // Calculate underwriting_fee_amount__c if formula inputs changed
            Boolean shouldRecalcFee = updatedFields.containsKey('operation_underwriting_per__c') || updatedFields.containsKey('bbva_prtcp_tranche_amount__c');

            if (shouldRecalcFee) {
                Opportunity currentOpp = [
                    SELECT operation_underwriting_per__c, bbva_prtcp_tranche_amount__c
                    FROM Opportunity
                    WHERE Id = :recordId
                    LIMIT 1
                ];

                Decimal opUnderwriting = currentOpp.operation_underwriting_per__c;
                Decimal trancheAmount = currentOpp.bbva_prtcp_tranche_amount__c;

                if (updatedFields.containsKey('operation_underwriting_per__c')) {
                    Object value = updatedFields.get('operation_underwriting_per__c');
                    opUnderwriting = (value == null) ? null : Decimal.valueOf(String.valueOf(value));
                }
                if (updatedFields.containsKey('bbva_prtcp_tranche_amount__c')) {
                    Object value = updatedFields.get('bbva_prtcp_tranche_amount__c');
                    trancheAmount = (value == null) ? null : Decimal.valueOf(String.valueOf(value));
                }

                oppToUpdate.underwriting_fee_amount__c = (opUnderwriting != null && trancheAmount != null) ? (opUnderwriting / 10000) * trancheAmount : null;
            }

            update oppToUpdate;
        }

        if (idsToDelete != null && !idsToDelete.isEmpty()) {
            List<Sold_Order__c> toDelete = [
                SELECT Id 
                FROM Sold_Order__c 
                WHERE Id IN :idsToDelete
            ];
            if (!toDelete.isEmpty()) {
                delete toDelete;
            }
        }

        // 3) Insert/Update de Sold_Order__c
        if (soldOrders != null && !soldOrders.isEmpty()) {
            Integer rowIndex = 0;
            for (Sold_Order__c so : soldOrders) {
                rowIndex++;
                so.opportunity_id__c = recordId;

                List<String> missing = new List<String>();
                if (so.gf_ctpty_sold_order_amount__c == null) {
                    missing.add('Sold Order (amount in units)');
                }
                if (so.gf_sold_ord_ctpty_setl_amount__c == null) {
                    missing.add('Settled order');
                }

                if (!missing.isEmpty()) {
                    throw new AuraHandledException(
                        'Sold Order row ' + rowIndex +
                        ': required fields are missing: ' + String.join(missing, ', ')
                    );
                }
            }

        upsert soldOrders;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupOption> searchClientsFromLocal(String searchTerm) {
        String term = (searchTerm == null) ? '' : searchTerm.trim();
        if (term.length() < 2) return new List<LookupOption>();

        term = '%' + String.escapeSingleQuotes(term) + '%';

        List<Local_Client__c> locals = [
            SELECT Cib_Client__c, Cib_Client__r.Name
            FROM Local_Client__c
            WHERE Name LIKE :term
            ORDER BY Name
            LIMIT 50
        ];
        Map<Id, String> uniq = new Map<Id, String>();
        for (Local_Client__c lc : locals) {
            if (lc.Cib_Client__c != null && lc.Cib_Client__r != null) {
                uniq.put(lc.Cib_Client__c, lc.Cib_Client__r.Name);
            }
        }
        List<LookupOption> out = new List<LookupOption>();
        for (Id clientId : uniq.keySet()) {
            out.add(new LookupOption(String.valueOf(clientId), uniq.get(clientId)));
        }
        return out;
    }
}