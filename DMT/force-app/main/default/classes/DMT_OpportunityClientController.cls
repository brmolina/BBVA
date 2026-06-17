/**
 * @description Controller for DMT Opportunity Client resolution.
 * Resolves client context (subsidiary vs group) and merges
 * Salesforce record data with original values from multiple sources.
 */
public without sharing class DMT_OpportunityClientController {

    @TestVisible private static final String CLIENT_TYPE_SUBSIDIARY    = 'Subsidiary';
    @TestVisible private static final String CLIENT_TYPE_PROSPECT_SUB  = 'Prospect_Subsidiary';
    @TestVisible private static final String CLIENT_TYPE_PROSPECT_GROUP = 'Prospect_Group';

    // TODO: migrate to Custom Metadata (DMT_Override_Setting__mdt)
    @TestVisible private static final String OVERRIDE_GROUP_CODE  = 'GXXXXXXXXXXXXXX';
    @TestVisible private static final String OVERRIDE_CUSTOMER_ID = 'ES0182XXXXXXXXX';

    // DMT Client fields — add here once, both queries pick it up
    private static final List<String> DMT_CLIENT_FIELDS = new List<String>{
        'Id', 'Alpha_Code_Client__c', 'Custom_Association__c',
        'g_upd_lmscl_internal_ratg_type__c',
        'DMT_Scoring__c', 'External_Rating__c',
        'DMT_External_Rating_SP__c',
        'DMT_External_Rating_Moodys__c',
        'DMT_External_Rating_Fitch__c',
        'DMT_MDE_Opportunity__r.DMT_Threshold_Type__c',
        'DMT_Industry__c',
        'DMT_Leveraged_Lending__c',
        'DMT_CAMN__c',
        'Counterpart__c',
        'SCRA__c',
        'AVC_Check__c',
        'European_Bank_Check__c',
        'DMT_Sector__c',
        'DMT_Subsector__c',
        'DMT_Activity__c',
        'DMT_Sector_Head__c'
    };

    private static final String KEY_INTERNAL_RATING_TYPE    = 'g_upd_lmscl_internal_ratg_type__c';
    private static final String KEY_EXTERNAL_RATING_TYPE    = 'External_Rating__c';
    private static final String KEY_SP_EXTERNAL_RATING_TYPE = 'DMT_External_Rating_SP__c';
    private static final String KEY_MOODYS_EXTERNAL_RATING_TYPE = 'DMT_External_Rating_Moodys__c';
    private static final String KEY_FITCH_EXTERNAL_RATING_TYPE  = 'DMT_External_Rating_Fitch__c';
    private static final String KEY_COUNTERPART  = 'Counterpart__c';
    private static final String KEY_SECTOR       = 'DMT_Sector__c';
    private static final String KEY_SUBSECTOR    = 'DMT_Subsector__c';
    private static final String KEY_DMT_ACTIVITY = 'DMT_Activity__c';

    private static final Map<String, String> SEGMENT_TO_COUNTERPART = new Map<String, String>{
        '00001' => 'Sov',
        '00002' => 'Pub Inst',
        '00003' => 'SME',
        '00004' => '',
        '00005' => 'Corporates',
        '00006' => 'Fin Inst-B'
    };

    // ─── Main Borrower Data (called when user picks a new main borrower in LWC) ───

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getMainHolderData(Id opportunityId, String alphaCode) {
        if (opportunityId == null || String.isBlank(alphaCode)) {
            throw new AuraHandledException('opportunityId and alphaCode are required');
        }
        try {
            Opportunity opp = findOpportunityById(opportunityId);

            // ── Resolve clientId and customerId ────────────────────────────────────
            List<Local_Client__c> localClients = [
                SELECT Id, Cib_Client__c
                FROM Local_Client__c
                WHERE Alpha_code__c = :alphaCode
                WITH USER_MODE
                LIMIT 1
            ];
            if (localClients.isEmpty()) {
                throw new AuraHandledException('No Local Client found for alpha code: ' + alphaCode);
            }
            String clientId   = localClients[0].Cib_Client__c;
            String customerId = (opp.Account.DES_Group_Code__c == OVERRIDE_GROUP_CODE)
                ? OVERRIDE_CUSTOMER_ID
                : alphaCode;

            // ── Ensure association exists ──────────────────────────────────────────
            List<Custom_Association_Opportunity__c> assocList = [
                SELECT Id
                FROM Custom_Association_Opportunity__c
                WHERE Opportunity__c = :opportunityId
                WITH USER_MODE
                LIMIT 1
            ];
            Custom_Association_Opportunity__c assoc;
            if (assocList.isEmpty()) {
                assoc = new Custom_Association_Opportunity__c(
                    Opportunity__c  = opportunityId,
                    g_customer_id__c = alphaCode
                );
                insert as user assoc;
            } else {
                assoc = assocList[0];
            }

            // ── Call HPG service first so we can pre-populate the record if needed ─
            Map<String, Object> buildOriginalResult = buildOriginalRecord(clientId, customerId, opp);
            Map<String, Object> originalRecord      = (Map<String, Object>) buildOriginalResult.get('originalRecord');

            // ── Find or build (in-memory) DMT_Opportunity_Client__c ───────────────
            // If the record does not exist yet (brand-new main borrower selected before
            // saving), build an unsaved instance pre-populated with HPG values so that
            // the form is immediately rendered. The actual insert happens via
            // saveOpportunityClients on save. The LWC deletes this record on cancel.
            DMT_Opportunity_Client__c dmtClient = findDmtClient(
                'Alpha_Code_Client__c = :alphaCode AND Custom_Association__c = :associationId',
                new Map<String, Object>{ 'alphaCode' => alphaCode, 'associationId' => assoc.Id }
            );

            if (dmtClient == null) {
                String segmentCode = opp.Account?.DES_Segment__c;

                Map<String, Object> sectorObj    = originalRecord.get(KEY_SECTOR)       instanceof Map<String, Object>
                    ? (Map<String, Object>) originalRecord.get(KEY_SECTOR)    : null;
                Map<String, Object> subsectorObj = originalRecord.get(KEY_SUBSECTOR)    instanceof Map<String, Object>
                    ? (Map<String, Object>) originalRecord.get(KEY_SUBSECTOR) : null;
                Map<String, Object> activityObj  = originalRecord.get(KEY_DMT_ACTIVITY) instanceof Map<String, Object>
                    ? (Map<String, Object>) originalRecord.get(KEY_DMT_ACTIVITY) : null;

                dmtClient = new DMT_Opportunity_Client__c(
                    Alpha_Code_Client__c              = alphaCode,
                    DMT_MDE_Opportunity__c            = opportunityId,
                    Custom_Association__c             = assoc.Id,
                    Counterpart__c                    = SEGMENT_TO_COUNTERPART.containsKey(segmentCode)
                                                            ? SEGMENT_TO_COUNTERPART.get(segmentCode) : '',
                    g_upd_lmscl_internal_ratg_type__c = (String) originalRecord.get(KEY_INTERNAL_RATING_TYPE),
                    External_Rating__c                = (String) originalRecord.get(KEY_EXTERNAL_RATING_TYPE),
                    DMT_External_Rating_SP__c         = (String) originalRecord.get(KEY_SP_EXTERNAL_RATING_TYPE),
                    DMT_External_Rating_Moodys__c     = (String) originalRecord.get(KEY_MOODYS_EXTERNAL_RATING_TYPE),
                    DMT_External_Rating_Fitch__c      = (String) originalRecord.get(KEY_FITCH_EXTERNAL_RATING_TYPE),
                    DMT_Sector__c                     = sectorObj    != null ? (String) sectorObj.get('value')    : null,
                    DMT_Subsector__c                  = subsectorObj != null ? (String) subsectorObj.get('value') : null,
                    DMT_Activity__c                   = activityObj  != null ? (String) activityObj.get('value')  : null
                );
            }

            Map<String, Object> currentRecord = buildCurrentRecord(dmtClient);
            Map<String, Object> recordData    = mergeRecords(currentRecord, originalRecord);

            return new Map<String, Object>{
                'alphaCode'           => alphaCode,
                'mainBorrower'        => dmtClient,
                'recordData'          => recordData,
                'originalrecord'      => originalRecord,
                'clientId'            => clientId,
                'customerId'          => customerId,
                'hpgData'             => buildOriginalResult.get('hpgData'),
                'serviceError'        => buildOriginalResult.get('serviceError'),
                'serviceErrorMessage' => buildOriginalResult.get('serviceErrorMessage')
            };

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            logException(ex, 'getMainHolderData');
            throw new AuraHandledException('Error fetching main borrower data: ' + ex.getMessage());
        }
    }

    // ─── Main Entry Point ────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOpportunityClientContext(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required');
        }
        try {
            Opportunity opp        = findOpportunityById(opportunityId);
            String      clientType = opp.Account?.DES_Client_Type__c;

            // Classify the account into one of four buckets:
            //   Subsidiary        → real subsidiary, alpha code from Local_Client__c
            //   Prospect_Subsidiary → prospect subsidiary, alpha code from Account.g_customer_id__c
            //   Prospect_Group    → prospect group, alpha code from Account.g_customer_id__c
            //   (anything else)   → standard group, alpha code from Custom_Association_Opportunity__c
            Boolean isSubsidiary      = (clientType == CLIENT_TYPE_SUBSIDIARY);
            Boolean isProspectSub     = (clientType == CLIENT_TYPE_PROSPECT_SUB);
            Boolean isProspectGroup   = (clientType == CLIENT_TYPE_PROSPECT_GROUP);
            Boolean isSubsidiaryLike  = isSubsidiary || isProspectSub;

            // Group code used only for the OVERRIDE check — prospect types have no group code,
            // so we fall back to DES_Group_Code__c (will be blank, override won't fire).
            String accountGroupCode = isSubsidiaryLike
                ? opp.Account.DES_Subsidiary_Group_Code__c
                : opp.Account.DES_Group_Code__c;

            Map<String, Object> clientInfo;
            if (isSubsidiaryLike) {
                clientInfo = resolveSubsidiaryClient(opp);
            } else if (isProspectGroup) {
                clientInfo = resolveProspectGroupClient(opp);
            } else {
                clientInfo = resolveGroupClient(opportunityId);
            }

            String customerId = (accountGroupCode == OVERRIDE_GROUP_CODE)
                ? OVERRIDE_CUSTOMER_ID
                : (String) clientInfo.get('customerId');
            String clientId   = (String) clientInfo.get('clientId');

            DMT_Opportunity_Client__c dmtClient = (DMT_Opportunity_Client__c) clientInfo.get('dmtOpportunityClient');

            // Build priorRows: all clients associated to this opportunity (group only)
            List<Map<String, Object>> priorRows           = new List<Map<String, Object>>();
            String                    mainBorrowerAlphaCode = (String) clientInfo.get('mainHolderAlphaCode');
            List<DMT_Opportunity_Client__c> allClients    = (List<DMT_Opportunity_Client__c>) clientInfo.get('allOpportunityClients');

            if (allClients != null) {
                for (DMT_Opportunity_Client__c oc : allClients) {
                    priorRows.add(new Map<String, Object>{
                        'customerId' => oc.Alpha_Code_Client__c,
                        'mainHolder' => mainBorrowerAlphaCode
                    });
                }
            }

            // When no main borrower is assigned yet (group/prospect-group only), skip
            // service calls and return early. The LWC hides the form until the user picks one.
            if (dmtClient == null && !isSubsidiaryLike) {
                return new Map<String, Object>{
                    'isSubsidiary'  => isSubsidiaryLike,
                    'hasMainHolder' => false,
                    'recordData'    => new Map<String, Object>(),
                    'opportunity'   => opp,
                    'priorRows'     => priorRows,
                    'mainHolder'    => null
                };
            }

            Map<String, Object> currentRecord      = buildCurrentRecord(dmtClient);
            Map<String, Object> buildOriginalResult = buildOriginalRecord(clientId, customerId, opp);
            Map<String, Object> recordData          = mergeRecords(
                currentRecord,
                (Map<String, Object>) buildOriginalResult.get('originalRecord')
            );

            return new Map<String, Object>{
                'isSubsidiary'        => isSubsidiaryLike,
                'hasMainHolder'       => true,
                'comparisonAccount'   => buildOriginalResult.get('comparisonAccount'),
                'recordData'          => recordData,
                'hpgData'             => buildOriginalResult.get('hpgData'),
                'serviceError'        => buildOriginalResult.get('serviceError'),
                'serviceErrorMessage' => buildOriginalResult.get('serviceErrorMessage'),
                'opportunity'         => opp,
                'searchDate'          => buildOriginalResult.get('searchDate'),
                'priorRows'           => priorRows,
                'mainHolder'          => dmtClient
            };

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            logException(ex, 'getOpportunityClientContext');
            throw new AuraHandledException(
                'Error fetching client: ' + ex.getMessage() + ex.getStackTraceString()
            );
        }
    }

    // ─── Client Resolution ───────────────────────────────────────────────────────

    private static Map<String, Object> resolveSubsidiaryClient(Opportunity opp) {
        // For Prospect_Subsidiary the alpha code lives on the Account itself.
        // For a real Subsidiary it comes from the linked Local_Client__c record.
        Boolean isProspect = (opp.Account?.DES_Client_Type__c == CLIENT_TYPE_PROSPECT_SUB);
        Local_Client__c subsidiaryClient = isProspect ? null : findLocalClientByAccount(opp.AccountId);

        DMT_Opportunity_Client__c dmtClient = findDmtClient(
            'DMT_MDE_Opportunity__c = :opportunityId',
            new Map<String, Object>{ 'opportunityId' => opp.Id }
        );

        return new Map<String, Object>{
            'customerId'           => isProspect ? opp.Account.g_customer_id__c : subsidiaryClient?.Alpha_code__c,
            'clientId'             => opp.AccountId,
            'dmtOpportunityClient' => dmtClient
        };
    }

    private static Map<String, Object> resolveGroupClient(Id opportunityId) {
        List<Custom_Association_Opportunity__c> assocList = [
            SELECT Id, g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];

        if (assocList.isEmpty() || String.isBlank(assocList[0].g_customer_id__c)) {
            return new Map<String, Object>{
                'hasMainHolder'        => false,
                'customerId'           => null,
                'clientId'             => null,
                'dmtOpportunityClient' => null,
                'allOpportunityClients' => findAllDmtClientsByOpportunity(opportunityId),
                'mainHolderAlphaCode'  => null
            };
        }

        Custom_Association_Opportunity__c assoc     = assocList[0];
        String                            alphaCode = assoc.g_customer_id__c;

        DMT_Opportunity_Client__c dmtClient = findDmtClient(
            'Alpha_Code_Client__c = :alphaCode AND Custom_Association__c = :associationId',
            new Map<String, Object>{ 'alphaCode' => alphaCode, 'associationId' => assoc.Id }
        );

        if (dmtClient == null) {
            return new Map<String, Object>{
                'hasMainHolder'        => false,
                'customerId'           => null,
                'clientId'             => null,
                'dmtOpportunityClient' => null,
                'allOpportunityClients' => findAllDmtClientsByOpportunity(opportunityId),
                'mainHolderAlphaCode'  => null
            };
        }

        Local_Client__c localClient = findLocalClientByAlphaCodeOrFail(alphaCode);

        return new Map<String, Object>{
            'hasMainHolder'        => true,
            'customerId'           => dmtClient.Alpha_Code_Client__c,
            'clientId'             => localClient.Cib_Client__c,
            'custAssociation'      => assoc,
            'dmtOpportunityClient' => dmtClient,
            'localClient'          => localClient,
            'allOpportunityClients' => findAllDmtClientsByOpportunity(opportunityId),
            'mainHolderAlphaCode'  => alphaCode
        };
    }

    // ─── Prospect_Group: alpha code comes from Account.g_customer_id__c ────────
    // No Local_Client__c lookup needed. The dmtClient is found by opportunity,
    // same as Subsidiary.
    private static Map<String, Object> resolveProspectGroupClient(Opportunity opp) {
        String alphaCode = opp.Account?.g_customer_id__c;

        DMT_Opportunity_Client__c dmtClient = findDmtClient(
            'DMT_MDE_Opportunity__c = :opportunityId',
            new Map<String, Object>{ 'opportunityId' => opp.Id }
        );

        return new Map<String, Object>{
            'customerId'           => alphaCode,
            'clientId'             => opp.AccountId,
            'dmtOpportunityClient' => dmtClient
        };
    }

    // ─── Record Data ─────────────────────────────────────────────────────────────

    /**
     * @description Flat map of current SF values — one entry per field.
     * Add new fields here.
     */
    private static Map<String, Object> buildCurrentRecord(DMT_Opportunity_Client__c dmtClient) {
        Map<String, Object> current = new Map<String, Object>();
        current.put(KEY_INTERNAL_RATING_TYPE,    dmtClient?.g_upd_lmscl_internal_ratg_type__c);
        current.put('DMT_Scoring__c',            dmtClient?.DMT_Scoring__c);
        current.put('DMT_Threshold_Type__c',     dmtClient?.DMT_MDE_Opportunity__r.DMT_Threshold_Type__c);
        current.put('DMT_Industry__c',           dmtClient?.DMT_Industry__c);
        current.put('DMT_Leveraged_Lending__c',  dmtClient?.DMT_Leveraged_Lending__c);
        current.put('DMT_CAMN__c',               dmtClient?.DMT_CAMN__c);
        current.put(KEY_COUNTERPART,             dmtClient?.Counterpart__c);
        current.put('SCRA__c',                   dmtClient?.SCRA__c);
        current.put('AVC_Check__c',              dmtClient?.AVC_Check__c);
        current.put('European_Bank_Check__c',    dmtClient?.European_Bank_Check__c);
        current.put(KEY_SECTOR,                  dmtClient?.DMT_Sector__c);
        current.put(KEY_SUBSECTOR,               dmtClient?.DMT_Subsector__c);
        current.put(KEY_DMT_ACTIVITY,            dmtClient?.DMT_Activity__c);
        current.put('DMT_Sector_Head__c',        dmtClient?.DMT_Sector_Head__c);
        current.put(KEY_EXTERNAL_RATING_TYPE,    String.isBlank(dmtClient?.External_Rating__c) ? 'NR' : dmtClient.External_Rating__c);
        current.put(KEY_SP_EXTERNAL_RATING_TYPE,     dmtClient?.DMT_External_Rating_SP__c);
        current.put(KEY_MOODYS_EXTERNAL_RATING_TYPE, dmtClient?.DMT_External_Rating_Moodys__c);
        current.put(KEY_FITCH_EXTERNAL_RATING_TYPE,  dmtClient?.DMT_External_Rating_Fitch__c);
        return current;
    }

    /**
     * @description Flat map of original (HPG) values — one entry per field.
     * Add new fields here with the applicable source (HPG, opp, dmtClient…).
     */
    private static Map<String, Object> buildOriginalRecord(
        String clientId,
        String customerId,
        Opportunity opp
    ) {
        Boolean serviceError        = false;
        String  serviceErrorMessage = null;
        Map<String, Object> hpgData           = null;
        Map<String, Object> comparisonAccount = null;
        Map<String, Object> original          = new Map<String, Object>();
        String lastDate;

        try {
            lastDate = DMT_HPG_Utils.lastDate();

            hpgData = DMT_HPG_Utils.getCustomerHPGS(
                new Map<String, Object>{ 'clientId' => clientId, 'lastDate' => lastDate, 'customerId' => customerId },
                new Map<String, Object>(),
                null
            );

            // Propagate HPG-internal service errors and return early so the client
            // does not receive an empty 'original' map that looks like valid data.
            if (hpgData != null && hpgData.get('serviceError') instanceof String) {
                serviceError        = true;
                serviceErrorMessage = (String) hpgData.get('serviceError');
                return new Map<String, Object>{
                    'originalRecord'      => original,
                    'hpgData'             => hpgData,
                    'comparisonAccount'   => comparisonAccount,
                    'serviceError'        => serviceError,
                    'serviceErrorMessage' => serviceErrorMessage,
                    'searchDate'          => lastDate
                };
            }

            comparisonAccount = DMT_Opportunity_Utils.getComparisonAccount(
                new Map<String, Object>{ 'oppAccountId' => opp.AccountId },
                new Map<String, Object>(),
                null
            );

            DMT_HPG_GlobalPosition.Data customerHpg = hpgData != null
                ? (DMT_HPG_GlobalPosition.Data) hpgData.get('CustomerHPG')
                : null;

            original.put(KEY_INTERNAL_RATING_TYPE,    customerHpg?.updLmsclInternalRatgType);
            original.put('currentRatingToolDate',      customerHpg?.currentRatingToolDate);
            original.put(KEY_EXTERNAL_RATING_TYPE,     customerHpg?.unifiedExtRatgLtFcType);
            original.put(KEY_COUNTERPART,              SEGMENT_TO_COUNTERPART.get(opp?.Account.DES_Segment__c));
            original.put(KEY_SECTOR,    new Map<String, Object>{ 'value' => customerHpg?.assetAllocationSectorType, 'label' => customerHpg?.assetAllcSectorDesc });
            original.put(KEY_SUBSECTOR, new Map<String, Object>{ 'value' => customerHpg?.assetAllocationSubSecType,  'label' => customerHpg?.aaSubSectorDesc });
            original.put(KEY_DMT_ACTIVITY, new Map<String, Object>{ 'value' => customerHpg?.assetAllocationActvyType, 'label' => customerHpg?.aaActivityDesc });
            original.put(KEY_SP_EXTERNAL_RATING_TYPE,     customerHpg?.spLtRatingLcType);
            original.put(KEY_MOODYS_EXTERNAL_RATING_TYPE, customerHpg?.moodysLtRatingLcType);
            original.put(KEY_FITCH_EXTERNAL_RATING_TYPE,  customerHpg?.fitchLtRatingLcType);

        } catch (Exception ex) {
            logException(ex, 'buildOriginalRecord');
            serviceError        = true;
            serviceErrorMessage = ex.getMessage() + ' | ' + ex.getStackTraceString();
        }

        return new Map<String, Object>{
            'originalRecord'      => original,
            'hpgData'             => hpgData,
            'comparisonAccount'   => comparisonAccount,
            'serviceError'        => serviceError,
            'serviceErrorMessage' => serviceErrorMessage,
            'searchDate'          => lastDate
        };
    }

    /**
     * @description Merges current and original into recordData.
     * Each key gets { currentValue, originalValue }.
     * If currentValue is null, falls back to originalValue.
     */
    private static Map<String, Object> mergeRecords(
        Map<String, Object> currentRecord,
        Map<String, Object> originalRecord
    ) {
        Map<String, Object> recordData = new Map<String, Object>();
        Set<String> allKeys = new Set<String>();
        allKeys.addAll(currentRecord.keySet());
        allKeys.addAll(originalRecord.keySet());

        for (String key : allKeys) {
            Object  currentValue  = currentRecord.get(key);
            Object  originalValue = originalRecord.get(key);
            Boolean hasNoCurrent  = currentValue == null && originalValue != null;

            recordData.put(key, new Map<String, Object>{
                'currentValue'  => hasNoCurrent ? originalValue : currentValue,
                'originalValue' => hasNoCurrent ? null : originalValue
            });
        }
        return recordData;
    }

    // ─── Query Helpers ───────────────────────────────────────────────────────────

    private static List<DMT_Opportunity_Client__c> findAllDmtClientsByOpportunity(Id opportunityId) {
        return [
            SELECT Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opportunityId
            WITH USER_MODE
        ];
    }

    private static DMT_Opportunity_Client__c findDmtClient(
        String whereClause,
        Map<String, Object> binds
    ) {
        String soql =
            'SELECT ' + String.join(DMT_CLIENT_FIELDS, ', ') +
            ' FROM DMT_Opportunity_Client__c' +
            ' WHERE ' + whereClause +
            ' LIMIT 1';
        List<DMT_Opportunity_Client__c> results = Database.queryWithBinds(
            soql, binds, AccessLevel.SYSTEM_MODE
        );
        return results.isEmpty() ? null : results[0];
    }

    private static Opportunity findOpportunityById(Id opportunityId) {
        List<Opportunity> results = [
            SELECT Id, AccountId,
                   Account.DES_Client_Type__c,
                   Account.DES_Subsidiary_Group_Code__c,
                   Account.DES_Group_Code__c,
                   Account.RecordType.DeveloperName,
                   Account.g_customer_id__c,
                   Account.DES_Segment__c
            FROM Opportunity
            WHERE Id = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];
        if (results.isEmpty()) {
            throw new AuraHandledException('Opportunity not found: ' + opportunityId);
        }
        return results[0];
    }

    private static Local_Client__c findLocalClientByAlphaCodeOrFail(String alphaCode) {
        List<Local_Client__c> results = [
            SELECT Id, Alpha_code__c, Cib_Client__c
            FROM Local_Client__c
            WHERE Alpha_code__c = :alphaCode
            WITH USER_MODE
            LIMIT 1
        ];
        if (results.isEmpty()) {
            throw new AuraHandledException('No Local Client for alpha code: ' + alphaCode);
        }
        return results[0];
    }

    private static Local_Client__c findLocalClientByAccount(Id accountId) {
        List<Local_Client__c> results = [
            SELECT Id, Alpha_code__c
            FROM Local_Client__c
            WHERE Cib_Client__c = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    @TestVisible private static final String STAGE_READY_TO_CLOSE = 'Ready to close';

    // ─── Save Client Form Data ────────────────────────────────────────────────────
    //
    // Atomically updates three objects in a single transaction:
    //   1. DMT_Opportunity_Client__c — all form fields
    //   2. Passport__c               — mark as obsolete (if one exists)
    //   3. Opportunity               — DMT_Threshold_Type__c always;
    //                                  DMT_Is_Change_in_Ready_to_close__c only when stage is Ready to close
    //
    // If any DML fails the Savepoint is rolled back and nothing is committed.

    @AuraEnabled(cacheable=false)
    public static void saveClientFormData(
        Id opportunityId,
        Id dmtClientId,
        String stageName,
        Map<String, Object> fieldValues
    ) {
        if (opportunityId == null || dmtClientId == null || fieldValues == null) {
            throw new AuraHandledException('opportunityId, dmtClientId and fieldValues are required');
        }

        Savepoint sp = Database.setSavepoint();
        try {
            // ── 1. DMT_Opportunity_Client__c ──────────────────────────────────────
            DMT_Opportunity_Client__c dmtClient = new DMT_Opportunity_Client__c(Id = dmtClientId);
            dmtClient.g_upd_lmscl_internal_ratg_type__c = (String)  fieldValues.get('g_upd_lmscl_internal_ratg_type__c');
            dmtClient.DMT_Scoring__c                    = fieldValues.get('DMT_Scoring__c') != null
                                                            ? Decimal.valueOf(String.valueOf(fieldValues.get('DMT_Scoring__c')))
                                                            : null;
            dmtClient.External_Rating__c               = (String)  fieldValues.get('External_Rating__c');
            dmtClient.DMT_External_Rating_SP__c        = (String)  fieldValues.get('DMT_External_Rating_SP__c');
            dmtClient.DMT_External_Rating_Moodys__c    = (String)  fieldValues.get('DMT_External_Rating_Moodys__c');
            dmtClient.DMT_External_Rating_Fitch__c     = (String)  fieldValues.get('DMT_External_Rating_Fitch__c');
            dmtClient.DMT_Industry__c                  = (String)  fieldValues.get('DMT_Industry__c');
            dmtClient.DMT_Leveraged_Lending__c         = (String)  fieldValues.get('DMT_Leveraged_Lending__c');
            dmtClient.DMT_CAMN__c                      = (String)  fieldValues.get('DMT_CAMN__c');
            dmtClient.Counterpart__c                   = (String)  fieldValues.get('Counterpart__c');
            dmtClient.SCRA__c                          = (String)  fieldValues.get('SCRA__c');
            dmtClient.AVC_Check__c                     = fieldValues.get('AVC_Check__c') == true;
            dmtClient.European_Bank_Check__c           = fieldValues.get('European_Bank_Check__c') == true;
            dmtClient.DMT_Sector__c                    = (String)  fieldValues.get('DMT_Sector__c');
            dmtClient.DMT_Subsector__c                 = (String)  fieldValues.get('DMT_Subsector__c');
            dmtClient.DMT_Activity__c                  = (String)  fieldValues.get('DMT_Activity__c');
            dmtClient.DMT_Sector_Head__c               = (String)  fieldValues.get('DMT_Sector_Head__c');
            update as user dmtClient;

            // ── 2. Passport__c — mark existing record as obsolete if present ──────
            List<Passport__c> passports = [
                SELECT Id
                FROM Passport__c
                WHERE Opportunity__c = :opportunityId
                WITH USER_MODE
                LIMIT 1
            ];
            if (!passports.isEmpty()) {
                passports[0].DMT_Is_Obsoleted_Passport_Save__c = true;
                update as user passports[0];
            }

            // ── 3. Opportunity ────────────────────────────────────────────────────
            Opportunity opp = new Opportunity(Id = opportunityId);
            opp.DMT_Threshold_Type__c = (String) fieldValues.get('DMT_Threshold_Type__c');
            opp.DMT_Is_Change_in_Ready_to_close__c = stageName == STAGE_READY_TO_CLOSE;
            
            update as user opp;

        } catch (Exception ex) {
            Database.rollback(sp);
            logException(ex, 'saveClientFormData');
            throw new AuraHandledException('Error saving client form data: ' + ex.getMessage());
        }
    }



    private static void logException(Exception ex, String methodName) {
        DES_Exception_Utils.logException(ex, 'DMT_OpportunityClientController', methodName, 'DMT', '');
    }
}