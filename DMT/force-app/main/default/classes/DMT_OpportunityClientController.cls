public with sharing class DMT_OpportunityClientController {
    @TestVisible
    private static final String CLIENT_TYPE_SUBSIDIARY = 'Subsidiary';
    @TestVisible
    private static final String CLIENT_TYPE_PROSPECT_SUB = 'Prospect_Subsidiary';
    @TestVisible
    private static final String CLIENT_TYPE_PROSPECT_GROUP = 'Prospect_Group';

    @TestVisible
    private static final String STAGE_READY_TO_CLOSE = 'Ready to close';

    @TestVisible
    private static final String OVERRIDE_GROUP_CODE = 'GXXXXXXXXXXXXXX';
    @TestVisible
    private static final String OVERRIDE_CUSTOMER_ID = 'ES0182XXXXXXXXX';

    private static final List<String> DMT_CLIENT_FIELDS = new List<String>{
        'Id',
        'Alpha_Code_Client__c',
        'Custom_Association__c',
        'g_upd_lmscl_internal_ratg_type__c',
        'DMT_Scoring__c',
        'External_Rating__c',
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
        'DMT_Sector_Head__c',
        'DMT_Guarantor_Name_Fiscal_ID__c'
    };

    private static final String KEY_INTERNAL_RATING_TYPE = 'g_upd_lmscl_internal_ratg_type__c';
    private static final String KEY_EXTERNAL_RATING_TYPE = 'External_Rating__c';
    private static final String KEY_SP_EXTERNAL_RATING_TYPE = 'DMT_External_Rating_SP__c';
    private static final String KEY_MOODYS_EXTERNAL_RATING_TYPE = 'DMT_External_Rating_Moodys__c';
    private static final String KEY_FITCH_EXTERNAL_RATING_TYPE = 'DMT_External_Rating_Fitch__c';
    private static final String KEY_COUNTERPART = 'Counterpart__c';
    private static final String KEY_SECTOR = 'DMT_Sector__c';
    private static final String KEY_SUBSECTOR = 'DMT_Subsector__c';
    private static final String KEY_DMT_ACTIVITY = 'DMT_Activity__c';
    private static final String KEY_CAMN = 'DMT_CAMN__c';

    private static final String CAMN_CATALOG_CODE = 'A521';

    private static final Map<String, String> SEGMENT_TO_COUNTERPART = new Map<String, String>{
        '00001' => 'Sov',
        '00002' => 'Pub Inst',
        '00003' => 'SME',
        '00004' => '',
        '00005' => 'Corporates',
        '00006' => 'Fin Inst-B'
    };

    private static Map<String, Map<String, String>> a521ByNormalizedName;

    // ─── Main Borrower Data (called when user picks a new main borrower in LWC) ───
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getMainHolderData(Id opportunityId, String alphaCode, Map<String, Object> originalRecordTable) {
        if (opportunityId == null || String.isBlank(alphaCode)) {
            throw new AuraHandledException('opportunityId and alphaCode are required');
        }
        try {
            Opportunity opp = findOpportunityById(opportunityId);

            // ── Resolve clientId and customerId ────────────────────────────────────
            // Accounts are resolved directly; Alpha Code is stored in Account.g_customer_id__c.
            String clientId = resolveClientId(opp, alphaCode);
            String customerId = (opp.Account.DES_Group_Code__c == OVERRIDE_GROUP_CODE)
                ? OVERRIDE_CUSTOMER_ID
                : alphaCode;

            // ── Ensure association exists ──────────────────────────────────────────
            Custom_Association_Opportunity__c assoc = findOrCreateAssociation(opportunityId, alphaCode);

            // ── Call HPG service first so we can pre-populate the record if needed ─
            Map<String, Object> buildOriginalResult = buildOriginalRecord(clientId, customerId, opp, originalRecordTable);
            Map<String, Object> originalRecord = (Map<String, Object>) buildOriginalResult.get('originalRecord');

            // ── Find or build (in-memory) DMT_Opportunity_Client__c ───────────────
            // If the record does not exist yet (brand-new main borrower selected before
            // saving), build an unsaved instance pre-populated with HPG values so that
            // the form is immediately rendered. The actual insert happens via
            // saveOpportunityClients on save. The LWC deletes this record on cancel.
            DMT_Opportunity_Client__c dmtClient = findDmtClientByAssociation(alphaCode, assoc.Id);
            if (dmtClient == null) {
                dmtClient = buildDmtClientFromOriginal(opportunityId, alphaCode, assoc.Id, opp, originalRecord);
            }

            Map<String, Object> currentRecord = buildCurrentRecord(dmtClient);
            Map<String, Object> recordData = mergeRecords(currentRecord, originalRecord);

            return new Map<String, Object>{
                'alphaCode' => alphaCode,
                'mainBorrower' => dmtClient,
                'recordData' => recordData,
                'originalrecord' => originalRecord,
                'clientId' => clientId,
                'customerId' => customerId,
                'hpgData' => buildOriginalResult.get('hpgData'),
                'serviceError' => buildOriginalResult.get('serviceError'),
                'serviceErrorMessage' => buildOriginalResult.get('serviceErrorMessage')
            };
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            logException(ex, 'getMainHolderData');
            throw new AuraHandledException('Error fetching main borrower data: ' + ex.getMessage());
        }
    }

    /**
     * @description Builds an unsaved DMT_Opportunity_Client__c pre-populated with HPG values.
     */
    private static DMT_Opportunity_Client__c buildDmtClientFromOriginal(
        Id opportunityId,
        String alphaCode,
        Id associationId,
        Opportunity opp,
        Map<String, Object> originalRecord
    ) {
        String segmentCode = opp.Account?.DES_Segment__c;
        System.debug('Log: segmentCode=' + segmentCode);
        Map<String, Object> sectorObj = asMap(originalRecord.get(KEY_SECTOR));
        Map<String, Object> subsectorObj = asMap(originalRecord.get(KEY_SUBSECTOR));
        Map<String, Object> activityObj = asMap(originalRecord.get(KEY_DMT_ACTIVITY));
        Map<String, Object> camnObj = asMap(originalRecord.get(KEY_CAMN));

                System.debug('Log: SEGMENT_TO_COUNTERPART' + (SEGMENT_TO_COUNTERPART.containsKey(segmentCode)
                ? SEGMENT_TO_COUNTERPART.get(segmentCode)
                : ''));
        return new DMT_Opportunity_Client__c(
            Alpha_Code_Client__c = alphaCode,
            DMT_MDE_Opportunity__c = opportunityId,
            Custom_Association__c = associationId,
            Counterpart__c = SEGMENT_TO_COUNTERPART.containsKey(segmentCode)
                ? SEGMENT_TO_COUNTERPART.get(segmentCode)
                : '',
            g_upd_lmscl_internal_ratg_type__c = (String) originalRecord.get(KEY_INTERNAL_RATING_TYPE),
            External_Rating__c = (String) originalRecord.get(KEY_EXTERNAL_RATING_TYPE),
            DMT_External_Rating_SP__c = (String) originalRecord.get(KEY_SP_EXTERNAL_RATING_TYPE),
            DMT_External_Rating_Moodys__c = (String) originalRecord.get(KEY_MOODYS_EXTERNAL_RATING_TYPE),
            DMT_External_Rating_Fitch__c = (String) originalRecord.get(KEY_FITCH_EXTERNAL_RATING_TYPE),
            DMT_Sector__c = sectorObj != null ? (String) sectorObj.get('value') : '',
            DMT_Subsector__c = subsectorObj != null ? (String) subsectorObj.get('value') : '',
            DMT_Activity__c = activityObj != null ? (String) activityObj.get('value') : '',
            DMT_CAMN__c = camnObj != null ? (String) camnObj.get('value') : '',
            DMT_Scoring__c = originalRecord.get('totalRatingScoreNumber') != null
                ? Decimal.valueOf(String.valueOf(originalRecord.get('totalRatingScoreNumber')))
                      .setScale(2, RoundingMode.HALF_UP)
                : 0
        );
    }

    // ─── Main Entry Point ────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getOpportunityClientContext(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('opportunityId is required');
        }
        try {
            Opportunity opp = findOpportunityById(opportunityId);
            String clientType = opp.Account?.DES_Client_Type__c;
            String recordType = opp.Account?.RecordType?.DeveloperName;

            // Classify the account into one of four buckets:
            //   Subsidiary          → real subsidiary (DES_Client_Type__c), alpha code from Account.g_customer_id__c
            //   Prospect_Subsidiary → prospect subsidiary (RecordType.DeveloperName), alpha code from Account.g_customer_id__c
            //   Prospect_Group      → prospect group (RecordType.DeveloperName), alpha code from Account.g_customer_id__c
            //   (anything else)     → standard group, alpha code from DMT_Custom_Association_Opportunity__c
            Boolean isSubsidiary = (clientType == CLIENT_TYPE_SUBSIDIARY);
            Boolean isProspectSub = (recordType == CLIENT_TYPE_PROSPECT_SUB);
            Boolean isSubsidiaryLike = isSubsidiary || isProspectSub;

            // Group code used only for the OVERRIDE check — prospect types have no group code,
            // so we fall back to DES_Group_Code__c (will be blank, override won't fire).
            String accountGroupCode = isSubsidiaryLike
                ? opp.Account.DES_Subsidiary_Group_Code__c
                : opp.Account.DES_Group_Code__c;

            Map<String, Object> clientInfo;
            if (isSubsidiaryLike) {
                clientInfo = resolveSubsidiaryClient(opp);
            } else {
                // Standard group and prospect group share the same association-based flow.
                // resolveAssociationClient resolves clientId per account type internally.
                clientInfo = resolveAssociationClient(opp);
            }

            String customerId = (accountGroupCode == OVERRIDE_GROUP_CODE)
                ? OVERRIDE_CUSTOMER_ID
                : (String) clientInfo.get('customerId');
            String clientId = (String) clientInfo.get('clientId');
            DMT_Opportunity_Client__c dmtClient = (DMT_Opportunity_Client__c) clientInfo.get('dmtOpportunityClient');

            // Build priorRows: all clients associated to this opportunity (group only)
            List<Map<String, Object>> priorRows = new List<Map<String, Object>>();
            String mainBorrowerAlphaCode = (String) clientInfo.get('mainHolderAlphaCode');
            List<DMT_Custom_Association_ClientOpportunity__c> allClients = (List<DMT_Custom_Association_ClientOpportunity__c>) clientInfo.get('allOpportunityClients');
            if (allClients != null) {
                for (DMT_Custom_Association_ClientOpportunity__c oc : allClients) {
                    priorRows.add(new Map<String, Object>{
                        'customerId' => oc.DMT_g_customer_id__c,
                        'mainHolder' => mainBorrowerAlphaCode
                    });
                }
            }

            Map<String, Object> currentRecord = buildCurrentRecord(dmtClient);
            Map<String, Object> buildOriginalResult = buildOriginalRecord(clientId, customerId, opp, null);
            Map<String, Object> recordData = mergeRecords(
                currentRecord,
                (Map<String, Object>) buildOriginalResult.get('originalRecord')
            );

            return new Map<String, Object>{
                'isSubsidiary' => isSubsidiaryLike,
                'customerId' => customerId,
                'clientId' => clientId,
                'hasMainHolder' => true,
                'comparisonAccount' => buildOriginalResult.get('comparisonAccount'),
                'recordData' => recordData,
                'hpgData' => buildOriginalResult.get('hpgData'),
                'serviceError' => buildOriginalResult.get('serviceError'),
                'serviceErrorMessage' => buildOriginalResult.get('serviceErrorMessage'),
                'opportunity' => opp,
                'searchDate' => buildOriginalResult.get('searchDate'),
                'priorRows' => priorRows,
                'mainHolder' => dmtClient
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

    // ─── Public API for Opportunity Clone ────────────────────────────────────────
    /**
     * @description Resolves the reference client Id to compare against `localClient`
     * when cloning an Opportunity. For subsidiary-like accounts (Subsidiary or
     * Prospect_Subsidiary) the reference is the Opportunity's AccountId. For
     * association-based accounts (standard/prospect group) it is the resolved
     * main holder client Id (via DMT_Custom_Association_Opportunity__c.DMT_g_customer_id__c
     * and resolveClientId()). Returns null if no association/main holder is found.
     */
    public static Id resolveMainHolderClientId(Id opportunityId) {
        Opportunity opp = findOpportunityById(opportunityId);
        String clientType = opp.Account?.DES_Client_Type__c;
        String recordType = opp.Account?.RecordType?.DeveloperName;
        Boolean isSubsidiaryLike = (clientType == CLIENT_TYPE_SUBSIDIARY) || (recordType == CLIENT_TYPE_PROSPECT_SUB);

        if (isSubsidiaryLike) {
            return opp.AccountId;
        }

        List<Custom_Association_Opportunity__c> assocList = [
            SELECT g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];
        if (assocList.isEmpty() || String.isBlank(assocList[0].g_customer_id__c)) {
            return null;
        }

        Id mainHolderClientId = resolveClientId(opp, assocList[0].g_customer_id__c);
        return mainHolderClientId;
    }

    // ─── Client Resolution ───────────────────────────────────────────────────────
    private static Map<String, Object> resolveSubsidiaryClient(Opportunity opp) {
        DMT_Opportunity_Client__c dmtClient = findDmtClient(
            'DMT_MDE_Opportunity__c = :opportunityId',
            new Map<String, Object>{ 'opportunityId' => opp.Id }
        );

        return new Map<String, Object>{
            'customerId' => opp.Account?.g_customer_id__c,
            'clientId' => opp.AccountId,
            'dmtOpportunityClient' => dmtClient
        };
    }

    /**
     * @description Resolves the main borrower for an association-based account
    * (standard group or prospect group). Both flows resolve the Account directly,
    * with Alpha Code stored in Account.g_customer_id__c.
     */
    private static Map<String, Object> resolveAssociationClient(Opportunity opp) {
        Id opportunityId = opp.Id;

        List<Custom_Association_Opportunity__c> assocList = [
            SELECT Id, g_customer_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];
        if (assocList.isEmpty() || String.isBlank(assocList[0].g_customer_id__c)) {
            return emptyClientInfo(opportunityId);
        }

        Custom_Association_Opportunity__c assoc = assocList[0];
        String alphaCode = assoc.g_customer_id__c;
        DMT_Opportunity_Client__c dmtClient = findDmtClientByAssociation(alphaCode, assoc.Id);
        if (dmtClient == null) {
            return emptyClientInfo(opportunityId);
        }

        return new Map<String, Object>{
            'customerId' => alphaCode,
            'clientId' => resolveClientId(opp, alphaCode),
            'dmtOpportunityClient' => dmtClient,
            'allOpportunityClients' => findAllDmtClientsByOpportunity(opportunityId),
            'mainHolderAlphaCode' => alphaCode
        };
    }

    /**
     * @description Resolves the clientId for an association-based account (group flows).
     * Both prospect and standard groups use the Account Id directly.
     */
    private static String resolveClientId(Opportunity opp, String alphaCode) {
        return opp.AccountId;
    }

    /**
     * @description Standard "no main borrower yet" payload for association-based accounts.
     */
    private static Map<String, Object> emptyClientInfo(Id opportunityId) {
        return new Map<String, Object>{
            'customerId' => null,
            'clientId' => null,
            'dmtOpportunityClient' => null,
            'allOpportunityClients' => findAllDmtClientsByOpportunity(opportunityId),
            'mainHolderAlphaCode' => null
        };
    }

    // ─── Record Data ───────────────────────────────────────────────────────────────
    /**
     * @description Flat map of current SF values — one entry per field.
     * Add new fields here.
     */
    private static Map<String, Object> buildCurrentRecord(DMT_Opportunity_Client__c dmtClient) {
        Map<String, Object> current = new Map<String, Object>();
        current.put(KEY_INTERNAL_RATING_TYPE, dmtClient?.g_upd_lmscl_internal_ratg_type__c);
        current.put('DMT_Scoring__c', dmtClient?.DMT_Scoring__c);
        // Double safe-navigation: dmtClient may be an in-memory record whose
        // DMT_MDE_Opportunity__r relationship was never populated (new main borrower).
        current.put('DMT_Threshold_Type__c', dmtClient?.DMT_MDE_Opportunity__r?.DMT_Threshold_Type__c);
        current.put('DMT_Industry__c', dmtClient?.DMT_Industry__c);
        current.put('DMT_Leveraged_Lending__c', dmtClient?.DMT_Leveraged_Lending__c);
        current.put(KEY_CAMN, dmtClient?.DMT_CAMN__c);
        current.put(KEY_COUNTERPART, dmtClient?.Counterpart__c);
        current.put('SCRA__c', dmtClient?.SCRA__c);
        current.put('AVC_Check__c', dmtClient?.AVC_Check__c);
        current.put('European_Bank_Check__c', dmtClient?.European_Bank_Check__c);
        current.put(KEY_SECTOR, dmtClient?.DMT_Sector__c);
        current.put(KEY_SUBSECTOR, dmtClient?.DMT_Subsector__c);
        current.put(KEY_DMT_ACTIVITY, dmtClient?.DMT_Activity__c);
        current.put('DMT_Sector_Head__c', dmtClient?.DMT_Sector_Head__c);
        current.put('DMT_Guarantor_Name_Fiscal_ID__c', dmtClient?.DMT_Guarantor_Name_Fiscal_ID__c);
        current.put(
            KEY_EXTERNAL_RATING_TYPE,
            String.isBlank(dmtClient?.External_Rating__c) ? 'NR' : dmtClient.External_Rating__c
        );
        current.put(KEY_SP_EXTERNAL_RATING_TYPE, dmtClient?.DMT_External_Rating_SP__c);
        current.put(KEY_MOODYS_EXTERNAL_RATING_TYPE, dmtClient?.DMT_External_Rating_Moodys__c);
        current.put(KEY_FITCH_EXTERNAL_RATING_TYPE, dmtClient?.DMT_External_Rating_Fitch__c);
        return current;
    }

    /**
     * @description Flat map of original (HPG) values — one entry per field.
     * Add new fields here with the applicable source (HPG, opp, dmtClient…).
     */
    private static Map<String, Object> buildOriginalRecord(
        String clientId,
        String customerId,
        Opportunity opp,
        Map<String, Object> originalRecordTable
    ) {
        Boolean serviceError = false;
        String serviceErrorMessage = null;
        DMT_HPG_GlobalPosition.Data hpgData = null;
        Map<String, Object> comparisonAccount = null;
        Map<String, Object> original = new Map<String, Object>();
        String lastDate;

        try {
            lastDate = DMT_HPG_Utils.lastDate();

            Object response;
            if ((originalRecordTable == null || originalRecordTable.isEmpty()) && lastDate != null && clientId != null && customerId != null) {

                response = DMT_HPG_MainTableCustomController.fetchClientInitialData('selectedTab', clientId, new List<String>(), lastDate, 'Y/N', '1', '5000', customerId);

                // Propagate HPG-internal service errors and return early so the client
                // does not receive an empty 'original' map that looks like valid data.
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(response));
                if (responseMap != null && responseMap.get('serviceError') instanceof String) {
                    serviceError = true;
                    serviceErrorMessage = (String) responseMap.get('serviceError');
                    return new Map<String, Object>{
                        'originalRecord' => original,
                        'hpgData' => responseMap,
                        'comparisonAccount' => comparisonAccount,
                        'serviceError' => serviceError,
                        'serviceErrorMessage' => serviceErrorMessage,
                        'searchDate' => lastDate
                    };
                }

                if (responseMap != null) {
                    List<Object> dataList = (List<Object>) responseMap.get('data');
                    if (dataList != null && !dataList.isEmpty()) {
                        for (Object item : dataList) {
                            Map<String, Object> entry = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(item));
                            if (customerId.equals(entry.get('customerId'))) {
                        hpgData = (DMT_HPG_GlobalPosition.Data) JSON.deserialize(
                                    JSON.serialize(item),
                            DMT_HPG_GlobalPosition.Data.class
                        );
                                break;
                            }
                        }
                    }
                }
            } else {
                hpgData = (DMT_HPG_GlobalPosition.Data) JSON.deserialize(
                    JSON.serialize(originalRecordTable),
                    DMT_HPG_GlobalPosition.Data.class
                );
            }

            comparisonAccount = DMT_Opportunity_Utils.getComparisonAccount(
                new Map<String, Object>{ 'oppAccountId' => opp.AccountId },
                new Map<String, Object>(),
                null
            );

            DMT_HPG_GlobalPosition.Data customerHpg = hpgData;
            original.put(KEY_INTERNAL_RATING_TYPE, customerHpg?.updLmsclInternalRatgType);
            original.put('currentRatingToolDate', customerHpg?.currentRatingToolDate);
            original.put(KEY_EXTERNAL_RATING_TYPE, customerHpg?.unifiedExtRatgLtFcType);
            original.put(KEY_COUNTERPART, SEGMENT_TO_COUNTERPART.get(opp?.Account.DES_Segment__c));
            original.put(
                KEY_SECTOR,
                String.isBlank(customerHpg?.assetAllocationSectorType)
                    ? null
                    : new Map<String, Object>{
                          'value' => customerHpg.assetAllocationSectorType,
                          'label' => customerHpg.assetAllcSectorDesc
                      }
            );
            original.put(
                KEY_SUBSECTOR,
                String.isBlank(customerHpg?.assetAllocationSubSecType)
                    ? null
                    : new Map<String, Object>{
                          'value' => customerHpg.assetAllocationSubSecType,
                          'label' => customerHpg.aaSubSectorDesc
                      }
            );
            original.put(
                KEY_DMT_ACTIVITY,
                String.isBlank(customerHpg?.assetAllocationActvyType)
                    ? null
                    : new Map<String, Object>{
                          'value' => customerHpg.assetAllocationActvyType,
                          'label' => customerHpg.aaActivityDesc
                      }
            );
            // CAMBIO A521: Ahora se busca por name (descripción) en el catálogo A521, ignorando el código de HPG.
            original.put(KEY_CAMN, resolveCamnFromCatalog(customerHpg?.activityMinimumLevelCodeDesc));
            original.put(KEY_SP_EXTERNAL_RATING_TYPE, customerHpg?.spLtRatingLcType);
            original.put(KEY_MOODYS_EXTERNAL_RATING_TYPE, customerHpg?.moodysLtRatingLcType);
            original.put(KEY_FITCH_EXTERNAL_RATING_TYPE, customerHpg?.fitchLtRatingLcType);
            original.put('totalRatingScoreNumber', customerHpg?.totalRatingScoreNumber);
            original.put('DMT_Scoring__c', customerHpg?.totalRatingScoreNumber != null
                ? Decimal.valueOf(String.valueOf(customerHpg.totalRatingScoreNumber))
                      .setScale(2, RoundingMode.HALF_UP)
                : null);
        } catch (Exception ex) {
            logException(ex, 'buildOriginalRecord');
            serviceError = true;
            serviceErrorMessage = ex.getMessage() + ' | ' + ex.getStackTraceString();
        }

        return new Map<String, Object>{
            'originalRecord' => original,
            'hpgData' => hpgData,
            'comparisonAccount' => comparisonAccount,
            'serviceError' => serviceError,
            'serviceErrorMessage' => serviceErrorMessage,
            'searchDate' => lastDate
        };
    }

    // CAMBIO A521: nuevo — busca el name de HPG dentro del catálogo A521 y devuelve {value,label} del catálogo, o null si no hay match..
    private static Map<String, Object> resolveCamnFromCatalog(String hpgDesc) {
        if (String.isBlank(hpgDesc)) {
            return null;
        }
        Map<String, String> match = getA521ByName().get(normalizeCamnName(hpgDesc));
        if (match == null) {
            return new Map<String, Object>{
                'value' => hpgDesc,
                'label' => hpgDesc,
                'compareValue' => hpgDesc
            };
        }
        return new Map<String, Object>{
            'value' => match.get('value'),
            'label' => match.get('value') + ' / ' + hpgDesc,
            'compareValue' => hpgDesc
        };
    }

    // CAMBIO A521: cache lazy del catálogo A521 indexado por name normalizado (mayúsculas + trim)
    private static Map<String, Map<String, String>> getA521ByName() {
        if (a521ByNormalizedName == null) {
            a521ByNormalizedName = new Map<String, Map<String, String>>();
            List<Map<String, String>> a521Values = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode(CAMN_CATALOG_CODE);
            if (a521Values != null) {
                for (Map<String, String> opt : a521Values) {
                    String key = normalizeCamnName(opt.get('name'));
                    if (String.isNotBlank(key)) {
                        a521ByNormalizedName.put(key, opt);
                    }
                }
            }
        }
        return a521ByNormalizedName;
    }

    private static String normalizeCamnName(String s) {
        return s == null ? null : s.trim().toUpperCase();
    }

    /**
     * @description Merges current and original into recordData.
     * Each key gets { currentValue, originalValue }.
     * If currentValue is null, falls back to originalValue.
     * A null currentValue is emitted as '' so the serialized JSON keeps the
     * { currentValue: '' } shape instead of collapsing to {} (Apex drops null fields).
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
            Object currentValue = currentRecord.get(key);
            Object originalValue = originalRecord.get(key);

            Object effectiveCurrentValue = (key == 'currentRatingToolDate')
                ? originalValue
                : (currentValue == null ? '' : currentValue);

            recordData.put(key, new Map<String, Object>{
                'currentValue' => effectiveCurrentValue,
                'originalValue' => originalValue
            });
        }
        return recordData;
    }

    // ─── Query Helpers ───────────────────────────────────────────────────────────
    private static Custom_Association_Opportunity__c findOrCreateAssociation(
        Id opportunityId,
        String alphaCode
    ) {
        List<Custom_Association_Opportunity__c> assocList = [
            SELECT Id
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];
        if (!assocList.isEmpty()) {
            return assocList[0];
        }

        Custom_Association_Opportunity__c assoc = new Custom_Association_Opportunity__c(
            Opportunity__c = opportunityId,
            g_customer_id__c = alphaCode
        );
        insert as user assoc;
        return assoc;
    }

    private static List<DMT_Custom_Association_ClientOpportunity__c> findAllDmtClientsByOpportunity(Id opportunityId) {
        return [
            SELECT DMT_g_customer_id__c
            FROM DMT_Custom_Association_ClientOpportunity__c
            WHERE DMT_Custom_Association_Opportunity__r.Opportunity__c = :opportunityId
            WITH USER_MODE
        ];
    }

    private static DMT_Opportunity_Client__c findDmtClientByAssociation(String alphaCode, Id associationId) {
        return findDmtClient(
            'Alpha_Code_Client__c = :alphaCode AND Custom_Association__c = :associationId',
            new Map<String, Object>{ 'alphaCode' => alphaCode, 'associationId' => associationId }
        );
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
            soql,
            binds,
            AccessLevel.SYSTEM_MODE
        );
        return results.isEmpty() ? null : results[0];
    }

    private static Opportunity findOpportunityById(Id opportunityId) {
        List<Opportunity> results = [
            SELECT
                Id,
                AccountId,
                Entific__c,
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

    private static Map<String, Object> asMap(Object value) {
        return value instanceof Map<String, Object> ? (Map<String, Object>) value : null;
    }

    private static String str(Map<String, Object> values, String key) {
        return (String) values.get(key);
    }

    private static Boolean isTrue(Map<String, Object> values, String key) {
        return values.get(key) == true;
    }

    private static Decimal toDecimal(Object value) {
        return value != null ? Decimal.valueOf(String.valueOf(value)) : null;
    }

    private static Decimal toScaledDecimal(Object value) {
        Decimal d = toDecimal(value);
        return d != null ? d.setScale(2, RoundingMode.HALF_UP) : null;
    }

    private static void applyFormFields(DMT_Opportunity_Client__c client, Map<String, Object> formFields) {
        client.g_upd_lmscl_internal_ratg_type__c = str(formFields, 'g_upd_lmscl_internal_ratg_type__c');
        // NOTE: form values are unscaled on purpose (already formatted by the LWC),
        // unlike the HPG-sourced scoring which is rounded to 2 decimals.
        client.DMT_Scoring__c = toDecimal(formFields.get('DMT_Scoring__c'));
        client.External_Rating__c = str(formFields, 'External_Rating__c');
        client.DMT_External_Rating_SP__c = str(formFields, 'DMT_External_Rating_SP__c');
        client.DMT_External_Rating_Moodys__c = str(formFields, 'DMT_External_Rating_Moodys__c');
        client.DMT_External_Rating_Fitch__c = str(formFields, 'DMT_External_Rating_Fitch__c');
        client.DMT_Industry__c = str(formFields, 'DMT_Industry__c');
        client.DMT_Leveraged_Lending__c = str(formFields, 'DMT_Leveraged_Lending__c');
        client.DMT_CAMN__c = str(formFields, 'DMT_CAMN__c');
        client.Counterpart__c = str(formFields, 'Counterpart__c');
        client.SCRA__c = str(formFields, 'SCRA__c');
        client.AVC_Check__c = isTrue(formFields, 'AVC_Check__c');
        client.European_Bank_Check__c = isTrue(formFields, 'European_Bank_Check__c');
        client.DMT_Sector__c = str(formFields, 'DMT_Sector__c');
        client.DMT_Subsector__c = str(formFields, 'DMT_Subsector__c');
        client.DMT_Activity__c = str(formFields, 'DMT_Activity__c');
        client.DMT_Sector_Head__c = str(formFields, 'DMT_Sector_Head__c');
        client.DMT_Guarantor_Name_Fiscal_ID__c = str(formFields, 'DMT_Guarantor_Name_Fiscal_ID__c');
    }

    public static void applyHpgFields(DMT_Opportunity_Client__c client, Map<String, Object> hpgFields) {
        client.DMT_Activity__c = str(hpgFields, 'assetAllocationActvyType');
        client.DMT_Sector__c = str(hpgFields, 'assetAllocationSectorType');
        client.DMT_Subsector__c = str(hpgFields, 'assetAllocationSubSecType');
        client.DMT_CAMN__c = str(hpgFields, 'activityMinimumLevelCode');
        client.DMT_External_Rating_Fitch__c = str(hpgFields, 'fitchLtRatingLcType');
        client.DMT_External_Rating_Moodys__c = str(hpgFields, 'moodysLtRatingLcType');
        client.DMT_External_Rating_SP__c = str(hpgFields, 'spLtRatingLcType');
        client.External_Rating__c = str(hpgFields, 'unifiedExtRatgLtFcType');
        client.g_upd_lmscl_internal_ratg_type__c = str(hpgFields, 'updLmsclInternalRatgType');
        client.DMT_Scoring__c = toScaledDecimal(hpgFields.get('totalRatingScoreNumber'));
    }

    // Financial fields carried over from the previous main borrower to the new one.
    // This list is used BOTH in the SELECT and in the copy, so they never go out of sync.
    private static final List<String> FINANCIAL_FIELDS_TO_CARRY = new List<String>{
        'DMT_comments__c',
        'Current_FY_Cash_Management_amount__c',
        'Current_FY_Client_Resources_amount__c',
        'Current_FY_Corp_Synd_Lending_amount__c',
        'Current_FY_Credit_Equity_amount__c',
        'Current_FY_DCM_amount__c',
        'Current_FY_ECM_M_A_Amount__c',
        'Current_FY_FX_CCS_amount__c',
        'Current_FY_GTF_amount__c',
        'Current_FY_Rates_amount__c',
        'Current_FY_Securities_Services_amount__c',
        'Current_FY_Str_Trade_Finance_amount__c',
        'Current_FY_Structured_Finance_amount__c',
        'Current_FY_Working_Capital_amount__c',
        'Debt_EBITDA_Current_Year_number__c',
        'Debt_EBITDA_Last_Year_number__c',
        'Debt_EBITDA_Next_Year_1_number__c',
        'Debt_EBITDA_Next_Year_2_number__c',
        'Debt_EBITDA_Next_Year_number__c',
        'EBIT_Current_Year_number__c',
        'EBIT_Last_Year_number__c',
        'EBIT_Next_Year_1_number__c',
        'EBIT_Next_Year_2_number__c',
        'EBIT_Next_Year_number__c',
        'EBITDA_Current_Year_number__c',
        'EBITDA_Last_Year_number__c',
        'EBITDA_Next_Year_1_number__c',
        'EBITDA_Next_Year_2_number__c',
        'EBITDA_Next_Year_number__c',
        'Free_Cash_Flow_Current_Year_number__c',
        'Free_Cash_Flow_Last_Year_number__c',
        'Free_Cash_Flow_Next_Year_1_number__c',
        'Free_Cash_Flow_Next_Year_2_number__c',
        'Free_Cash_Flow_Next_Year_number__c',
        'Geographical_Footprint_desc__c',
        'gf_co_list_tcfd_ind_type__c',
        'gf_customer_sustnbl_strg_desc__c',
        'gf_esg_score_close_ope_name__c',
        'gf_kpi_trans_fees_2ya_amount__c',
        'gf_kpi_trans_fees_cyr_amount__c',
        'gf_kpi_trans_fees_ly_amount__c',
        'gf_kpi_trans_fees_nxy_amount__c',
        'gf_paris_agreement_ind_type__c',
        'gf_xb_cust_ope_revenue_2ya_per__c',
        'gf_xb_cust_ope_revenue_cyr_per__c',
        'gf_xb_cust_ope_revenue_ly_per__c',
        'gf_xb_cust_ope_revenue_nxy_per__c',
        'Industry_Overview_desc__c',
        'Net_Debt_EBITDA_Current_Year_number__c',
        'Net_Debt_EBITDA_Last_Year_number__c',
        'Net_Debt_EBITDA_Next_Year_1_number__c',
        'Net_Debt_EBITDA_Next_Year_2_number__c',
        'Net_Debt_EBITDA_Next_Year_number__c',
        'Net_Income_Current_Year_number__c',
        'Net_Income_Last_Year_number__c',
        'Net_Income_Next_Year_1_number__c',
        'Net_Income_Next_Year_2_number__c',
        'Net_Income_Next_Year_number__c',
        'Next_FY_Cash_Management_amount__c',
        'Next_FY_Client_Resources_amount__c',
        'Next_FY_Corp_Synd_Lending_amount__c',
        'Next_FY_Credit_Equity_amount__c',
        'Next_FY_DCM_amount__c',
        'Next_FY_ECM_M_A_amount__c',
        'Next_FY_FX_CCS_amount__c',
        'Next_FY_GTF_amount__c',
        'Next_FY_Rates_amount__c',
        'Next_FY_Securities_Services_amount__c',
        'Next_FY_Str_Trade_Finance_amount__c',
        'Next_FY_Structured_Finance_amount__c',
        'Next_FY_Working_Capital_amount__c',
        'Other_Relevant_Ratios_desc__c',
        'Past2_FY_Cash_Management_amount__c',
        'Past2_FY_Client_Resources_amount__c',
        'Past2_FY_Corp_Synd_Lending_amount__c',
        'Past2_FY_Credit_Equity_amount__c',
        'Past2_FY_DCM_amount__c',
        'Past2_FY_ECM_M_A_Amount__c',
        'Past2_FY_FX_CCS_amount__c',
        'Past2_FY_GTF_amount__c',
        'Past2_FY_Rates_amount__c',
        'Past2_FY_Securities_Services_amount__c',
        'Past2_FY_Str_Trade_Finance_amount__c',
        'Past2_FY_Structured_Finance_amount__c',
        'Past2_FY_Working_Capital_amount__c',
        'Past_FY_Cash_Management_amount__c',
        'Past_FY_Client_Resources_amount__c',
        'Past_FY_Corp_Synd_Lending_amount__c',
        'Past_FY_Credit_Equity_amount__c',
        'Past_FY_DCM_amount__c',
        'Past_FY_ECM_M_A_Amount__c',
        'Past_FY_FX_CCS_amount__c',
        'Past_FY_GTF_amount__c',
        'Past_FY_Rates_amount__c',
        'Past_FY_Securities_Services_amount__c',
        'Past_FY_Str_Trade_Finance_amount__c',
        'Past_FY_Structured_Finance_amount__c',
        'Past_FY_Working_Capital_amount__c',
        'Relationship_Status_desc__c',
        'Revenues_Current_Year_number__c',
        'Revenues_Last_Year_number__c',
        'Revenues_Next_Year_1_number__c',
        'Revenues_Next_Year_2_number__c',
        'Revenues_Next_Year_number__c',
        'DMT_cca__c',
        'DMT_cta__c',
        'DMT_positioning__c',
        'DMT_tri__c',
        'DMT_tri_Engagement_Plan__c'
    };

    private static DMT_Opportunity_Client__c queryClientFinancials(Id opportunityId, String alphaCode) {
        if (String.isBlank(alphaCode)) return null;
        String soql =
            'SELECT ' + String.join(FINANCIAL_FIELDS_TO_CARRY, ', ') +
            ' FROM DMT_Opportunity_Client__c' +
            ' WHERE DMT_MDE_Opportunity__c = :opportunityId' +
            ' AND Alpha_Code_Client__c = :alphaCode' +
            ' WITH USER_MODE LIMIT 1';
        List<DMT_Opportunity_Client__c> rows = Database.query(soql);
        return rows.isEmpty() ? null : rows[0];
    }

    private static void copyFinancialFields(DMT_Opportunity_Client__c source, DMT_Opportunity_Client__c target) {
        if (source == null || target == null) return;
        for (String f : FINANCIAL_FIELDS_TO_CARRY) {
            target.put(f, source.get(f));
        }
    }

    @AuraEnabled(cacheable=false)
    public static void saveMainBorrowerFields(
        Id opportunityId,
        Id dmtClientId,
        String stageName,
        Map<String, Object> fieldValues
    ) {
        Savepoint sp = Database.setSavepoint();
        try {
            DMT_Opportunity_Client__c dmtClient = new DMT_Opportunity_Client__c(Id = dmtClientId);
            applyFormFields(dmtClient, fieldValues);
            update as user dmtClient;

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

            Opportunity opp = new Opportunity(Id = opportunityId);
            opp.DMT_Threshold_Type__c = (String) fieldValues.get('DMT_Threshold_Type__c');
            opp.DMT_Is_Change_in_Ready_to_close__c = stageName == STAGE_READY_TO_CLOSE;
            update as user opp;
        } catch (Exception ex) {
            Database.rollback(sp);
            logException(ex, 'saveMainBorrowerFields');
            throw new AuraHandledException('Error saving client fields: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static void saveMainBorrowerWithClients(
        Id opportunityId,
        Id dmtClientId,
        String stageName,
        Map<String, Object> fieldValues,
        String mainBorrower,
        List<Object> selectedClients
    ) {
        List<Custom_Association_Opportunity__c> association = [
            SELECT Id, g_customer_id__c, Group__c, gf_customer_group_id__c
            FROM Custom_Association_Opportunity__c
            WHERE Opportunity__c = :opportunityId
            WITH USER_MODE
            LIMIT 1
        ];

        // Capture the previous main borrower BEFORE overwriting it.
        String previousMainBorrower = association.isEmpty() ? null : association[0].g_customer_id__c;

        if (!association.isEmpty()) {
            if (association[0].g_customer_id__c != mainBorrower) {
                association[0].g_customer_id__c = mainBorrower;
                update as user association[0];
            }
        } else {
            Custom_Association_Opportunity__c newAssoc = new Custom_Association_Opportunity__c(
                Opportunity__c = opportunityId,
                g_customer_id__c = mainBorrower
            );
            insert as user newAssoc;
        }

        List<DMT_Opportunity_Client__c> existingRecords = [
            SELECT Id, Alpha_Code_Client__c
            FROM DMT_Opportunity_Client__c
            WHERE DMT_MDE_Opportunity__c = :opportunityId
            WITH USER_MODE
        ];

        Id associationId = association.isEmpty() ? null : association[0].Id;

        List<DMT_Custom_Association_ClientOpportunity__c> existingSecondaries = associationId == null
            ? new List<DMT_Custom_Association_ClientOpportunity__c>()
            : [
                SELECT Id, DMT_g_customer_id__c, DMT_gf_customer_group_id__c, DMT_g_entific_id__c
                FROM DMT_Custom_Association_ClientOpportunity__c
                WHERE DMT_Custom_Association_Opportunity__c = :associationId
                WITH USER_MODE
            ];

        Set<String> existingAlphaCodes = new Set<String>();
        for (DMT_Opportunity_Client__c rec : existingRecords) {
            existingAlphaCodes.add(rec.Alpha_Code_Client__c);
        }

        Set<String> existingSecondaryAlphaCodes = new Set<String>();
        Map<String, DMT_Custom_Association_ClientOpportunity__c> existingSecondaryByAlpha = new Map<String, DMT_Custom_Association_ClientOpportunity__c>();
        for (DMT_Custom_Association_ClientOpportunity__c rec : existingSecondaries) {
            if (rec.DMT_g_customer_id__c != null) {
                existingSecondaryAlphaCodes.add(rec.DMT_g_customer_id__c);
                existingSecondaryByAlpha.put(rec.DMT_g_customer_id__c, rec);
            }
        }

        // Previous borrower's financial data, only if it actually changed.
        DMT_Opportunity_Client__c previousMainBorrowerData =
            (String.isNotBlank(previousMainBorrower) && previousMainBorrower != mainBorrower)
                ? queryClientFinancials(opportunityId, previousMainBorrower)
                : null;

        // Alpha codes present in selectedClients (to detect which ones are removed).
        Set<String> selectedAlphaCodes = new Set<String>();
        List<DMT_Opportunity_Client__c> toUpsert = new List<DMT_Opportunity_Client__c>();
        List<DMT_Custom_Association_ClientOpportunity__c> toInsertSecondary = new List<DMT_Custom_Association_ClientOpportunity__c>();
        List<DMT_Custom_Association_ClientOpportunity__c> toUpdateSecondary = new List<DMT_Custom_Association_ClientOpportunity__c>();

        Savepoint sp = Database.setSavepoint();
        try {
            for (Object obj : selectedClients) {
                Map<String, Object> clientMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                String alphaCode = (String) clientMap.get('customerId');
                if (String.isBlank(alphaCode)) continue;
                selectedAlphaCodes.add(alphaCode);

                Boolean isMainBorrower = alphaCode.equals(mainBorrower);

                if (isMainBorrower) {
                    // Reutilizar el registro existente (update) en vez de crear uno nuevo
                    DMT_Opportunity_Client__c dmtClient = dmtClientId != null
                        ? new DMT_Opportunity_Client__c(Id = dmtClientId)
                        : new DMT_Opportunity_Client__c(DMT_MDE_Opportunity__c = opportunityId);
                    applyFormFields(dmtClient, fieldValues);
                    copyFinancialFields(previousMainBorrowerData, dmtClient);
                    dmtClient.Alpha_Code_Client__c = alphaCode;
                    toUpsert.add(dmtClient);
                    // Main Borrower también en DMT_Custom_Association_ClientOpportunity__c (igual que en Lines)
                    if (!existingSecondaryAlphaCodes.contains(alphaCode)) {
                        DMT_Custom_Association_ClientOpportunity__c mainAsParticipant = new DMT_Custom_Association_ClientOpportunity__c();
                        mainAsParticipant.DMT_Custom_Association_Opportunity__c = associationId;
                        mainAsParticipant.DMT_g_customer_id__c = alphaCode;
                        mainAsParticipant.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                        mainAsParticipant.DMT_g_entific_id__c = (String) clientMap.get('countryIfoId');
                        toInsertSecondary.add(mainAsParticipant);
                    } else {
                        DMT_Custom_Association_ClientOpportunity__c existing = existingSecondaryByAlpha.get(alphaCode);
                        if (existing != null && existing.DMT_g_entific_id__c == null) {
                            existing.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                            existing.DMT_g_entific_id__c = (String) clientMap.get('countryIfoId');
                            toUpdateSecondary.add(existing);
                        }
                    }
                } else if (!existingSecondaryAlphaCodes.contains(alphaCode)) {
                    DMT_Custom_Association_ClientOpportunity__c secClient = new DMT_Custom_Association_ClientOpportunity__c();
                    secClient.DMT_Custom_Association_Opportunity__c = associationId;
                    secClient.DMT_g_customer_id__c = alphaCode;
                    secClient.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                    secClient.DMT_g_entific_id__c = (String) clientMap.get('countryIfoId');
                    toInsertSecondary.add(secClient);
                } else {
                    DMT_Custom_Association_ClientOpportunity__c existing = existingSecondaryByAlpha.get(alphaCode);
                    if (existing != null && existing.DMT_g_entific_id__c == null) {
                        existing.DMT_gf_customer_group_id__c = association[0].gf_customer_group_id__c;
                        existing.DMT_g_entific_id__c = (String) clientMap.get('countryIfoId');
                        toUpdateSecondary.add(existing);
                    }
                }
            }

            List<DMT_Custom_Association_ClientOpportunity__c> toDeleteSecondary = new List<DMT_Custom_Association_ClientOpportunity__c>();
            for (DMT_Custom_Association_ClientOpportunity__c rec : existingSecondaries) {
                if (rec.DMT_g_customer_id__c == null || !selectedAlphaCodes.contains(rec.DMT_g_customer_id__c)) {
                    toDeleteSecondary.add(rec);
                }
            }

            if (!toUpsert.isEmpty()) {
                upsert as user toUpsert;
            }
            if (!toInsertSecondary.isEmpty()) {
                insert as user toInsertSecondary;
            }
            if (!toUpdateSecondary.isEmpty()) {
                update as user toUpdateSecondary;
            }
            if (!toDeleteSecondary.isEmpty()) {
                delete toDeleteSecondary;
            }

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

            Opportunity opp = new Opportunity(Id = opportunityId);
            opp.DMT_Threshold_Type__c = (String) fieldValues.get('DMT_Threshold_Type__c');
            opp.DMT_Is_Change_in_Ready_to_close__c = stageName == STAGE_READY_TO_CLOSE;
            update as user opp;
        } catch (Exception ex) {
            Database.rollback(sp);
            logException(ex, 'saveMainBorrowerWithClients');
            throw new AuraHandledException('Error saving client form data: ' + ex.getMessage());
        }
    }

    private static void logException(Exception ex, String methodName) {
        DES_Exception_Utils.logException(ex, 'DMT_OpportunityClientController', methodName, 'DMT', '');
    }
}