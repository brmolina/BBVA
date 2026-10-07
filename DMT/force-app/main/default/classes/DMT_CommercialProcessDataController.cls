public with sharing class DMT_CommercialProcessDataController {

    @AuraEnabled(cacheable=false)
    public static Opportunity getCommercialProcessData(Id opportunityId) {
        return [
            SELECT Id,
                DES_Countries__c,
                gf_comm_offer_moppy_ind_type__c,
                DES_Description_rich__c,
                DES_Expected_Probability__c,
                DES_Cross_border__c,
                DMT_Credentials__c,
                DES_Comments__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=false)
    public static void saveCommercialProcessData(Id opportunityId, Map<String, Object> fieldValues, List<Map<String, Object>> lineItems) {
        Savepoint sp = Database.setSavepoint();
        try {
            // 1. Save line items first
            if (lineItems != null && !lineItems.isEmpty()) {
                List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
                for (Map<String, Object> item : lineItems) {
                    Id itemId = (Id) item.get('Id');
                    if (itemId == null) continue;
                    OpportunityLineItem oli      = new OpportunityLineItem(Id = itemId);
                    oli.deferred_fee_amount__c                = (Decimal) item.get('deferred_fee_amount__c');
                    oli.no_deferred_fee_amount__c             = (Decimal) item.get('no_deferred_fee_amount__c');
                    oli.undrawn_fee_next_12m_amount__c        = (Decimal) item.get('undrawn_fee_next_12m_amount__c');
                    oli.pre_net_margin_next_12m_amount__c     = (Decimal) item.get('pre_net_margin_next_12m_amount__c');
                    oli.periodic_fee_amount__c                = (Decimal) item.get('periodic_fee_amount__c');
                    oli.fee_next_12m_amount__c                = (Decimal) item.get('fee_next_12m_amount__c');
                    oli.pre_oppy_revenue_next_12m_amount__c   = (Decimal) item.get('pre_oppy_revenue_next_12m_amount__c');
                    oli.funding_cost_per__c                   = (Decimal) item.get('funding_cost_per__c');
                    oli.credit_drawn_next_12m_per__c          = (Decimal) item.get('credit_drawn_next_12m_per__c');
                    oli.pre_gross_margin_next_12m_per__c      = (Decimal) item.get('pre_gross_margin_next_12m_per__c');
                    toUpdate.add(oli);
                }
                if (!toUpdate.isEmpty()) {
                    update toUpdate;
                }
            }

            // 2. Save opportunity fields
            Opportunity opp = new Opportunity(Id = opportunityId);
            for (String fieldName : fieldValues.keySet()) {
                putFieldValue(opp, fieldName, fieldValues.get(fieldName));
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
            Database.rollback(sp);
            throw new AuraHandledException(e.getDmlMessage(0));
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<OpportunityLineItem> getOppLineItems(Id opportunityId) {
        return [
            SELECT Id,
                   Name,
                   deferred_fee_amount__c,
                   no_deferred_fee_amount__c,
                   undrawn_fee_next_12m_amount__c,
                   pre_net_margin_next_12m_amount__c,
                   periodic_fee_amount__c,
                   fee_next_12m_amount__c,
                   pre_oppy_revenue_next_12m_amount__c,
                   funding_cost_per__c,
                   credit_drawn_next_12m_per__c,
                   pre_gross_margin_next_12m_per__c,
                   g_currency_id__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            ORDER BY gf_group_priority_opportunity_id__c 
        ];
    }

    /**
     * @description Puts a value into an SObject field with automatic type coercion.
     *              Converts String values to Decimal/Integer when the target field requires it.
     */
    private static void putFieldValue(SObject record, String fieldName, Object value) {
        if (value == null) {
            record.put(fieldName, null);
            return;
        }
        // List → semicolon-separated String (multipicklist)
        if (value instanceof List<Object>) {
            List<String> parts = new List<String>();
            for (Object item : (List<Object>) value) {
                if (item != null) parts.add(String.valueOf(item));
            }
            record.put(fieldName, parts.isEmpty() ? null : String.join(parts, ';'));
            return;
        }
        Schema.SObjectField sField = record.getSObjectType().getDescribe().fields.getMap().get(fieldName);
        if (sField != null && value instanceof String) {
            String strVal = (String) value;
            Schema.DisplayType dt = sField.getDescribe().getType();
            if (dt == Schema.DisplayType.DOUBLE || dt == Schema.DisplayType.PERCENT || dt == Schema.DisplayType.CURRENCY) {
                record.put(fieldName, String.isBlank(strVal) ? null : Decimal.valueOf(strVal));
                return;
            } else if (dt == Schema.DisplayType.INTEGER) {
                record.put(fieldName, String.isBlank(strVal) ? null : Integer.valueOf(strVal));
                return;
            }
        }
        record.put(fieldName, value);
    }
}