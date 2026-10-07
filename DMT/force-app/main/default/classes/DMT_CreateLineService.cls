/**
 * @description Apex replacement for the OmniStudio Integration Procedures "Create_Line"
 *              (bootstrap) and the Line-creation branch of "DealManagement_Screen"
 *              (isOpportunity != true), previously reached only via the DMT_MarcoGeneral
 *              FlexCard/PubSub bridge. Used by dmtNewLineModal to load creation
 *              parameters and to create a new DMT_Line__c record without depending on
 *              OmniStudio Cards.
 *
 *              Simplifications vs. the original DataRaptor chain (documented for future
 *              maintainers / sandbox validation):
 *              - Client country/business code is derived directly from the Account
 *                identified by originId (already known from the workspace context),
 *                instead of the original multi-object Local_Client__c/Group/Prospect
 *                DataRaptor fallback chain.
 */
public with sharing class DMT_CreateLineService {

    private static final String TAXONOMY_COUNTRY_CATALOG = 'CD07';
    private static final String TAXONOMY_ENTITY_CATALOG = 'h006';
    private static final String DMT_ACCESS_PERMISSION_SET = 'DMT_Access';
    private static final String DEFAULT_ORIGIN = 'Salesforce';
    private static final String DEFAULT_COUNTRY = 'ES';
    private static final String TREASURY_SETTLEMENT_RECORD_TYPE = 'TreasurySettlement';
    private static final String LINE_CODE_ORIGIN = 'ESCD';
    private static final String LINE_CODE_OPERATION_TYPE = 'LIN';
    private static final String DEFAULT_ENTIFIC = 'HO';

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getLineCreationParameters(Id clientId, String groupId, String recordTypeName) {
        try {
            if (clientId == null && String.isBlank(groupId)) {
                throw new AuraHandledException('clientId or groupId is required');
            }

            Account acc = clientId != null ? getAccount(clientId) : null;

            Boolean isSubsidiary = acc != null && acc.DES_Client_Type__c == 'Subsidiary';
            Boolean isProspect = isProspectAccount(acc);
            String desClientType = acc != null ? acc.DES_Client_Type__c : null;
            String generalClientCode = resolveGeneralClientCode(acc, groupId);
            String pais = resolveCountry(isSubsidiary, generalClientCode);

            List<String> roles = new List<String>();
            User currentUser = [SELECT DMT_User_Role__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (!String.isBlank(currentUser.DMT_User_Role__c)) {
                roles.addAll(DMT_Utils.splitString(currentUser.DMT_User_Role__c, ';'));
            }

            List<DMT_Creation_Line_Parameters__mdt> paramsCreation = getCreationParameters(
                roles,
                recordTypeName,
                isSubsidiary,
                groupId,
                clientId
            );

            String entificCode = (!isProspect && String.isNotBlank(generalClientCode) && generalClientCode.length() >= 2)
                ? generalClientCode.substring(0, 2)
                : pais;

            List<DMT_Creation_Line_Parameters__mdt> subsidiaryList = new List<DMT_Creation_Line_Parameters__mdt>();
            for (DMT_Creation_Line_Parameters__mdt p : paramsCreation) {
                if (p.DMT_Value__c == entificCode) {
                    subsidiaryList.add(p);
                }
            }

            List<DMT_Creation_Line_Parameters__mdt> paramsCreationFix =
                (isSubsidiary && !subsidiaryList.isEmpty()) ? subsidiaryList : paramsCreation;

            Set<String> allowedGeographies = new Set<String>();
            for (DMT_Creation_Line_Parameters__mdt p : paramsCreationFix) {
                if (String.isNotBlank(p.DMT_Value__c)) {
                    allowedGeographies.add(p.DMT_Value__c);
                }
            }

            List<Map<String, Object>> count = new List<Map<String, Object>>();
            if (!allowedGeographies.isEmpty()) {
                for (DMT_Taxonomy_Values__c tv : [
                    SELECT DMT_Value__c, DMT_Name_EN__c
                    FROM DMT_Taxonomy_Values__c
                    WHERE DMT_Catalog__c = :TAXONOMY_COUNTRY_CATALOG
                    AND DMT_Active__c = true
                    AND DMT_Value__c IN :allowedGeographies
                    WITH USER_MODE
                ]) {
                    count.add(new Map<String, Object>{ 'value' => tv.DMT_Value__c, 'label' => tv.DMT_Name_EN__c });
                }
            }

            Boolean hasBookingGeography =
                (!isSubsidiary && !count.isEmpty() && !paramsCreation.isEmpty()) ||
                (isSubsidiary && !subsidiaryList.isEmpty());

            List<PermissionSetAssignment> psAssignments = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = :DMT_ACCESS_PERMISSION_SET
                WITH USER_MODE
                LIMIT 1
            ];

            Map<String, Object> result = new Map<String, Object>();
            result.put('hasBookingGeography', hasBookingGeography);
            result.put('count', count);
            result.put('BookingGeography', count.isEmpty() ? '' : (String) count[0].get('value'));
            result.put('isProspect', isProspect);
            result.put('clientId', clientId);
            result.put('DES_Client_Type__c', desClientType);
            result.put('clientCode', generalClientCode);
            result.put('groupCode', groupId);
            result.put('countryIfoId', pais);
            // Default name suggestion, matches the original DataRaptor formula:
            // CONCAT("Line ", Account:Name, " ", YEAR(today)).
            result.put('lineName', (acc != null && String.isNotBlank(acc.Name))
                ? 'Line ' + acc.Name + ' ' + String.valueOf(Date.today().year())
                : '');
            result.put('RecordTypeName', recordTypeName);
            result.put('StartDate', Date.today());
            result.put('EndDate', Date.today().addYears(1));
            result.put('generalClientCode', generalClientCode);
            result.put('hasDMTAccessPS', !psAssignments.isEmpty());
            return result;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_CreateLineService', 'getLineCreationParameters', 'DMT', '');
            throw new AuraHandledException('Error loading line creation parameters: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Id createLine(
        String recordTypeName,
        String lineName,
        Date startDate,
        Date endDate,
        Id clientId,
        String bookingGeography,
        String generalClientCode,
        String countryIfoId
    ) {
        try {
            if (String.isBlank(recordTypeName)) {
                throw new AuraHandledException('recordTypeName is required');
            }

            Schema.RecordTypeInfo rtInfo = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get(recordTypeName);
            if (rtInfo == null) {
                throw new AuraHandledException('Invalid line record type: ' + recordTypeName);
            }

            String entity = new DMT_GetCreationParameters().getEntityValues(TAXONOMY_ENTITY_CATALOG, bookingGeography);
            String currencyCode = resolveCurrency(entity);

            String resolvedName = String.isBlank(lineName)
                ? recordTypeName + ' Line'
                : lineName;
            String lineId = getLineCode(bookingGeography);

            DMT_Line__c newLine = new DMT_Line__c(
                RecordTypeId = rtInfo.getRecordTypeId(),
                Name = resolvedName,
                Client__c = clientId,
                Line_Id__c = lineId,
                Client_Code__c = generalClientCode,
                Start_Date__c = startDate,
                End_Date__c = recordTypeName == TREASURY_SETTLEMENT_RECORD_TYPE ? resolveEndOfMonth(endDate) : endDate,
                Booking_Geography__c = bookingGeography,
                DMT_Client_Entific__c = bookingGeography,
                DMT_Entity__c = entity,
                DMT_Origin__c = DEFAULT_ORIGIN
            );

            if (String.isNotBlank(currencyCode)) {
                newLine.CurrencyIsoCode = currencyCode;
                newLine.Treasury_Currency__c = currencyCode;
                newLine.DvP_Currency__c = currencyCode;
                newLine.FD_Currency__c = currencyCode;
            }

            Database.insert(newLine, AccessLevel.USER_MODE);
            return newLine.Id;
        } catch (Exception e) {
            DES_Exception_Utils.logException(e, 'DMT_CreateLineService', 'createLine', 'DMT', '');
            throw new AuraHandledException('Error creating line: ' + e.getMessage());
        }
    }

    private static Account getAccount(Id clientId) {
        List<Account> accounts = [
            SELECT Id, Name, RecordTypeId, DES_Client_Type__c, DES_Group_Code__c, g_customer_id__c
            FROM Account
            WHERE Id = :clientId
            WITH USER_MODE
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0];
    }

    private static Boolean isProspectAccount(Account acc) {
        if (acc == null) {
            return false;
        }
        Map<String, Schema.RecordTypeInfo> rtByName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Id groupRtId = rtByName.containsKey('Prospect_Group') ? rtByName.get('Prospect_Group').getRecordTypeId() : null;
        Id subsidiaryRtId = rtByName.containsKey('Prospect_Subsidiary') ? rtByName.get('Prospect_Subsidiary').getRecordTypeId() : null;
        return acc.RecordTypeId == groupRtId || acc.RecordTypeId == subsidiaryRtId;
    }

    private static String resolveGeneralClientCode(Account acc, String groupId) {
        if (acc != null && String.isNotBlank(acc.g_customer_id__c)) {
            return acc.g_customer_id__c;
        }
        if (acc != null && String.isNotBlank(acc.DES_Group_Code__c)) {
            return acc.DES_Group_Code__c;
        }
        return groupId;
    }

    private static String resolveCountry(Boolean isSubsidiary, String generalClientCode) {
        if (isSubsidiary && String.isNotBlank(generalClientCode) && generalClientCode.length() >= 2) {
            return generalClientCode.substring(0, 2);
        }
        return DEFAULT_COUNTRY;
    }

    private static List<DMT_Creation_Line_Parameters__mdt> getCreationParameters(
        List<String> roles,
        String recordTypeName,
        Boolean isSubsidiary,
        String groupId,
        Id clientId
    ) {
        if (roles.isEmpty()) {
            return new List<DMT_Creation_Line_Parameters__mdt>();
        }
        String paramsJson = new DMT_GetCreationParameters().getCreationParametersList(
            roles,
            recordTypeName,
            isSubsidiary,
            groupId,
            clientId
        );
        if (String.isBlank(paramsJson)) {
            return new List<DMT_Creation_Line_Parameters__mdt>();
        }
        return (List<DMT_Creation_Line_Parameters__mdt>) JSON.deserialize(
            paramsJson,
            List<DMT_Creation_Line_Parameters__mdt>.class
        );
    }

    private static String resolveCurrency(String entity) {
        if (String.isBlank(entity)) {
            return null;
        }
        List<DMT_Taxonomy_Values__c> currencyEntity = [
            SELECT gf_catalog_atrb_val2_name__c
            FROM DMT_Taxonomy_Values__c
            WHERE DMT_Catalog__c = :TAXONOMY_ENTITY_CATALOG AND DMT_Value__c = :entity
            WITH USER_MODE
            LIMIT 1
        ];
        return currencyEntity.isEmpty() ? null : currencyEntity[0].gf_catalog_atrb_val2_name__c;
    }

    /**
     * @description Normalizes End_Date__c to the last day of the month of whatever endDate
     *              the user picked (e.g. 2026-09-14 -> 2026-09-30), matching the original
     *              IP behaviour of always storing a month-end line expiration date.
     */
    private static Date resolveEndOfMonth(Date endDate) {
        if (endDate == null) {
            return null;
        }
        Integer lastDay = Date.daysInMonth(endDate.year(), endDate.month());
        return Date.newInstance(endDate.year(), endDate.month(), lastDay);
    }
    private static String getLineCode(String bookingGeography) {
        Map<String, Object> request = new Map<String, Object>();
        request.put('origin', LINE_CODE_ORIGIN);
        request.put('operationType', LINE_CODE_OPERATION_TYPE);
        request.put('entific', String.isNotBlank(bookingGeography) ? bookingGeography : DEFAULT_ENTIFIC);

        DMT_OpportunityCodes.Wrapper response = DMT_OpportunityCodes.getOpportunityCode(request);
        return (response != null && response.data != null) ? response.data.opportunityId : null;
    }
}