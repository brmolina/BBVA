public with sharing class DMT_SelectClientsInLineService {
    private static final String LOG_PREFIX = '[DMT_SelectClientsInLineService]';
    private static final String DEFAULT_PAGE = '1';
    private static final String DEFAULT_PAGE_SIZE = '200';

    @AuraEnabled
    public static Map<String, Object> loadDatasource(Id recordId, String clientPosition) {
        Map<String, Object> response = new Map<String, Object>();
        List<Map<String, Object>> selectedRows = new List<Map<String, Object>>();
        String effectivePage = DEFAULT_PAGE;
        String effectivePageSize = DEFAULT_PAGE_SIZE;

        logStep('getDatasource.start', new Map<String, Object>{
            'recordId' => recordId,
            'clientPositionIn' => clientPosition,
            'pageIn' => effectivePage,
            'pageSizeIn' => effectivePageSize
        });

        if (recordId == null) {
            logStep('getDatasource.recordIdNull', null);
            return response;
        }

        try {
            Id accountId = DMT_HPG_MainTableCustomController.getAccountIdFromRecordId(recordId);
            String effectiveClientPosition = String.isBlank(clientPosition) ? 'Y' : clientPosition;
            response.put('accountId', accountId);
            response.put('groupSfId', accountId);
            response.put('clientPosition', effectiveClientPosition);

            String sobjectName = recordId.getSObjectType().getDescribe().getName();
            logStep('getDatasource.context', new Map<String, Object>{
                'sobjectName' => sobjectName,
                'accountId' => accountId,
                'effectiveClientPosition' => effectiveClientPosition
            });

            if (sobjectName == 'DMT_Line__c') {
                    DMT_Line__c line = [
                        SELECT Id, Client__c, Line_Id__c, Status__c, Closed__c, CurrencyIsoCode, Booking_Geography__c, Client_Type__c,
                          DMT_line_template_type__c,
                           Custom_Association__c, Custom_Association__r.g_customer_id__c
                    FROM DMT_Line__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];

                logStep('getDatasource.lineLoaded', new Map<String, Object>{
                    'lineId' => line.Id,
                    'lineClient' => line.Client__c,
                    'lineIdExternal' => line.Line_Id__c,
                    'lineStatus' => line.Status__c,
                    'booking' => line.Booking_Geography__c,
                    'lineClientType' => line.Client_Type__c,
                    'lineTemplateType' => line.DMT_line_template_type__c,
                    'customAssociationId' => line.Custom_Association__c
                });

                response.put('lineId', line.Id);
                response.put('externallineId', line.Line_Id__c);
                response.put('lineStatus', line.Status__c);
                response.put('lineClosed', line.Closed__c);
                response.put('currency', line.CurrencyIsoCode);
                response.put('booking', line.Booking_Geography__c);
                response.put('lineclienttype', line.Client_Type__c);
                response.put('lineTemplateType', line.DMT_line_template_type__c);
                response.put('canEditSelection', canEditLineSelection(line));

                if (line.Custom_Association__c != null) {
                    List<Custom_Association_Client__c> rows = [
                        SELECT Id, Name, Alpha_Code_Client__c, g_entific_Id__c, DMT_Term__c,
                               DMT_Amount__c, DMT_FDAmount__c, DMT_DVPAmount__c,
                               DMT_ClientRating__c, DMT_ClientStarCode__c, DMT_ClientContracts__c,
                               DMT_Client_Rating_Date__c, CurrencyIsoCode
                        FROM Custom_Association_Client__c
                        WHERE Custom_Association__c = :line.Custom_Association__c
                        ORDER BY Name ASC
                    ];

                    logStep('getDatasource.customAssociationClients', new Map<String, Object>{
                        'rowsSize' => rows.size(),
                        'mainHolderFromCA' => line.Custom_Association__r.g_customer_id__c
                    });

                    for (Custom_Association_Client__c row : rows) {
                        Map<String, Object> mapped = mapAssociationClient(row, line.Custom_Association__r.g_customer_id__c);
                        selectedRows.add(mapped);
                    }
                }
            }

            if (accountId != null) {
                Account contextAccount = [
                    SELECT Id, DES_Group_Code__c
                    FROM Account
                    WHERE Id = :accountId
                    LIMIT 1
                ];
                response.put('groupId', contextAccount.DES_Group_Code__c);
                logStep('getDatasource.groupContext', new Map<String, Object>{
                    'accountId' => contextAccount.Id,
                    'groupCode' => contextAccount.DES_Group_Code__c
                });
            }

            Map<String, Object> pageResult = getAvailableClientsPageInternal(accountId, effectiveClientPosition, effectivePage, effectivePageSize);
            List<Map<String, Object>> availableClients = toMapList(pageResult.get('availableClients'));
            if (availableClients.isEmpty() && !selectedRows.isEmpty() && effectivePage == '1') {
                logStep('getDatasource.availableClientsFallbackFromSelectedRows', new Map<String, Object>{
                    'selectedRowsSize' => selectedRows.size(),
                    'reason' => 'serviceRowsEmpty'
                });
                availableClients = cloneRowList(selectedRows);
            }
            response.put('availableClients', availableClients);
            response.put('page', pageResult.get('page'));
            response.put('totalPages', pageResult.get('totalPages'));
            response.put('totalElements', pageResult.get('totalElements'));
            response.put('pageSize', pageResult.get('pageSize'));

            response.put('priorselectedRows', selectedRows);
            response.put('selectedRows', cloneRowList(selectedRows));
            response.put('returnedDate', DMT_HPG_Utils.lastDate());

            logStep('getDatasource.end', new Map<String, Object>{
                'availableClientsSize' => availableClients.size(),
                'selectedRowsSize' => selectedRows.size(),
                'mainHolder' => selectedRows.isEmpty() ? null : selectedRows[0].get('mainHolder')
            });

            return response;
        } catch (Exception e) {
            logStep('getDatasource.error', new Map<String, Object>{
                'message' => e.getMessage(),
                'stack' => e.getStackTraceString()
            });
            throw e;
        }
    }

    @AuraEnabled
    public static Map<String, Object> applySelection(Map<String, Object> records) {
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> selectedRows = toMapList(records.get('selectedRows'));
        Map<String, Object> recentRow = toMap(records.get('recentRow'));

        if (recentRow.isEmpty()) {
            result.put('responseRS', selectedRows);
            return result;
        }

        String clientType = stringValue(recentRow.get('clientType'));
        if (clientType == 'client') {
            String customerId = stringValue(recentRow.get('customerId'));
            Integer index = indexOfCustomer(selectedRows, customerId);
            if (index >= 0) {
                selectedRows.remove(index);
            } else {
                selectedRows.add(recentRow);
            }
        } else {
            for (Map<String, Object> child : toMapList(recentRow.get('clients'))) {
                String customerId = stringValue(child.get('customerId'));
                if (indexOfCustomer(selectedRows, customerId) < 0) {
                    selectedRows.add(child);
                }
            }
        }

        result.put('responseRS', selectedRows);
        return result;
    }

    @AuraEnabled
    public static Map<String, Object> applyInputField(Map<String, Object> records, Map<String, Object> inputField) {
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> selectedRows = toMapList(records.get('selectedRows'));

        String customerId = stringValue(inputField.get('customerId'));
        String context = stringValue(inputField.get('context'));
        Object value = inputField.get('value');

        for (Map<String, Object> row : selectedRows) {
            if (stringValue(row.get('customerId')) == customerId) {
                row.put(context, value);
                break;
            }
        }

        result.put('fullRows', selectedRows);
        return result;
    }

    @AuraEnabled
    public static Map<String, Object> saveSelection(
        Id lineId,
        String mainHolderAlphaCode,
        String currencyLine,
        String groupId,
        Id groupSfId,
        String externallineId,
        List<Object> selectedRows
    ) {
        Map<String, Object> result = new Map<String, Object>();
        logStep('saveSelection.start', new Map<String, Object>{
            'lineId' => lineId,
            'mainHolderAlphaCode' => mainHolderAlphaCode,
            'currencyLine' => currencyLine,
            'groupId' => groupId,
            'groupSfId' => groupSfId,
            'externallineId' => externallineId,
            'selectedRowsSize' => selectedRows == null ? 0 : selectedRows.size()
        });
        try {
            if (!canEditLineSelection(lineId)) {
                result.put('error', 'This line cannot be edited with your current permissions and line status.');
                result.put('success', false);
                return result;
            }

            DMT_HPG_MainTableCustomController.saveCustomAssociation(
                lineId,
                mainHolderAlphaCode,
                currencyLine,
                groupId,
                groupSfId,
                externallineId
            );
            DMT_HPG_MainTableCustomController.saveLineClients(selectedRows, lineId);
            DMT_HPG_MainTableCustomController.saveLineClientFields(selectedRows, lineId);

            result.put('error', 'OK');
            result.put('success', true);
            logStep('saveSelection.end', result);
        } catch (Exception e) {
            result.put('error', e.getMessage());
            result.put('success', false);
            logStep('saveSelection.error', new Map<String, Object>{
                'message' => e.getMessage(),
                'stack' => e.getStackTraceString()
            });
        }

        return result;
    }

    private static Boolean canEditLineSelection(Id lineId) {
        if (lineId == null) {
            return false;
        }

        DMT_Line__c line = [
            SELECT Id, Status__c, Closed__c, DMT_line_template_type__c
            FROM DMT_Line__c
            WHERE Id = :lineId
            LIMIT 1
        ];
        return canEditLineSelection(line);
    }

    private static Boolean canEditLineSelection(DMT_Line__c line) {
        if (line == null) {
            return false;
        }

        String statusValue = String.valueOf(line.Status__c);
        if (statusValue == DMT_Constants.DRAFT) {
            return true;
        }

        Boolean isApproval = statusValue == DMT_Constants.APPROVAL;
        Boolean isClosedWon = statusValue == DMT_Constants.CLOSED && String.valueOf(line.Closed__c) == DMT_Constants.WON;
        Boolean isReadyToCloseOp = statusValue == DMT_Constants.READYTOCLOSE && String.valueOf(line.DMT_line_template_type__c) == 'OP';

        if (!(isApproval || isClosedWon || isReadyToCloseOp)) {
            return false;
        }

        List<DMT_TeamMember__c> teamMembers = [
            SELECT Id, AccessLevel__c, DMT_ApprovalEdit__c
            FROM DMT_TeamMember__c
            WHERE Line__c = :line.Id AND User__c = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (teamMembers.isEmpty()) {
            return false;
        }

        DMT_TeamMember__c member = teamMembers[0];
        Boolean hasEditAccess = member.AccessLevel__c == 'Edit' || member.AccessLevel__c == 'All';
        return hasEditAccess && member.DMT_ApprovalEdit__c == true;
    }

    private static Map<String, Object> mapAssociationClient(
        Custom_Association_Client__c row,
        String mainHolder
    ) {
        Map<String, Object> mapped = new Map<String, Object>();
        mapped.put('customerId', row.Alpha_Code_Client__c);
        mapped.put('customerName', row.Name);
        mapped.put('countryIfoId', row.g_entific_Id__c);
        mapped.put('term', row.DMT_Term__c);
        mapped.put('amount', row.DMT_Amount__c);
        mapped.put('amountFD', row.DMT_FDAmount__c);
        mapped.put('amountDVP', row.DMT_DVPAmount__c);
        mapped.put('updSmsclInternalRatgType', row.DMT_ClientRating__c);
        mapped.put('customerCounterpartiesCodesDesc', row.DMT_ClientStarCode__c);
        mapped.put('operationMitigantDesc', row.DMT_ClientContracts__c);
        mapped.put('currentRatingToolDate', row.DMT_Client_Rating_Date__c == null ? null : String.valueOf(row.DMT_Client_Rating_Date__c));
        mapped.put('currency', row.CurrencyIsoCode);
        mapped.put('mainHolder', mainHolder);
        return mapped;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAvailableClientsPage(Id accountId, String clientPosition, String page, String pageSize) {
        String effectiveClientPosition = String.isBlank(clientPosition) ? 'Y' : clientPosition;
        String effectivePage = String.isBlank(page) ? DEFAULT_PAGE : page;
        String effectivePageSize = String.isBlank(pageSize) ? DEFAULT_PAGE_SIZE : pageSize;
        return getAvailableClientsPageInternal(accountId, effectiveClientPosition, effectivePage, effectivePageSize);
    }

    private static Map<String, Object> getAvailableClientsPageInternal(Id accountId, String clientPosition, String page, String pageSize) {
        Map<String, Object> pageResult = new Map<String, Object>{
            'availableClients' => new List<Map<String, Object>>(),
            'page' => 1,
            'totalPages' => 1,
            'totalElements' => 0,
            'pageSize' => toInteger(pageSize, Integer.valueOf(DEFAULT_PAGE_SIZE))
        };

        List<Map<String, Object>> availableClients = new List<Map<String, Object>>();
        if (accountId == null) {
            logStep('getAvailableClients.accountIdNull', new Map<String, Object>{
                'clientPosition' => clientPosition,
                'page' => page,
                'pageSize' => pageSize
            });
            pageResult.put('availableClients', availableClients);
            return pageResult;
        }

        logStep('getAvailableClients.start', new Map<String, Object>{
            'accountId' => accountId,
            'clientPosition' => clientPosition,
            'page' => page,
            'pageSize' => pageSize
        });

        Object rawResponse = DMT_HPG_MainTableCustomController.fetchClientInitialData(
            'tcm',
            accountId,
            new List<String>(),
            DMT_HPG_Utils.lastDate(),
            clientPosition,
            page,
            pageSize,
            ''
        );

        Map<String, Object> responseMap = toMap(rawResponse);
        List<Map<String, Object>> serviceRows = toMapList(responseMap.get('data'));
        Map<String, Object> pagination = toMap(responseMap.get('pagination'));

        logStep('getAvailableClients.fetchInitialData', new Map<String, Object>{
            'responseKeys' => responseMap == null ? null : responseMap.keySet(),
            'success' => responseMap == null ? null : responseMap.get('success'),
            'errorMessage' => responseMap == null ? null : responseMap.get('errorMessage'),
            'serviceRowsSize' => serviceRows.size(),
            'firstCustomerId' => serviceRows.isEmpty() ? null : stringValue(serviceRows[0].get('customerId')),
            'pagination' => pagination
        });

        for (Map<String, Object> row : serviceRows) {
            Map<String, Object> mapped = new Map<String, Object>();
            mapped.put('customerId', row.get('customerId'));
            mapped.put('customerName', row.get('customerName'));
            mapped.put('countryIfoId', row.get('countryIfoId'));
            mapped.put('groupId', row.get('groupId'));
            mapped.put('subGroupId', row.get('subGroupId'));
            mapped.put('updSmsclInternalRatgType', row.get('updSmsclInternalRatgType'));
            mapped.put('customerCounterpartiesCodesDesc', row.get('customerCounterpartiesCodesDesc'));
            mapped.put('operationMitigantDesc', row.get('operationMitigantDesc'));
            mapped.put('currentRatingToolDate', row.get('currentRatingToolDate'));
            mapped.put('ratingValidityStartDate', row.get('ratingValidityStartDate'));
            mapped.put('scaleLastUpdDate', row.get('scaleLastUpdDate'));
            mapped.put('ffssRegulatoryRatingDate', row.get('ffssRegulatoryRatingDate'));
            mapped.put('smsclInternalRatgType', row.get('smsclInternalRatgType'));
            mapped.put('term', null);
            mapped.put('amount', null);
            mapped.put('amountFD', null);
            mapped.put('amountDVP', null);
            availableClients.add(mapped);
        }

        Integer pageNumber = toInteger(pagination.get('page'), toInteger(page, 1));
        Integer totalPages = toInteger(pagination.get('totalPages'), 1);
        Integer totalElements = toInteger(pagination.get('totalElements'), availableClients.size());
        Integer effectivePageSize = toInteger(pagination.get('pageSize'), toInteger(pageSize, Integer.valueOf(DEFAULT_PAGE_SIZE)));

        logStep('getAvailableClients.end', new Map<String, Object>{
            'availableClientsSize' => availableClients.size(),
            'page' => pageNumber,
            'totalPages' => totalPages,
            'totalElements' => totalElements,
            'pageSize' => effectivePageSize
        });

        pageResult.put('availableClients', availableClients);
        pageResult.put('page', pageNumber);
        pageResult.put('totalPages', totalPages);
        pageResult.put('totalElements', totalElements);
        pageResult.put('pageSize', effectivePageSize);
        return pageResult;
    }

    private static void logStep(String step, Object payload) {
        System.debug(LoggingLevel.WARN, LOG_PREFIX + '[' + step + '] ' + safePayload(payload));
    }

    private static String safePayload(Object payload) {
        String raw;
        try {
            raw = payload == null ? 'null' : JSON.serialize(payload);
        } catch (Exception ex) {
            raw = String.valueOf(payload);
        }

        Integer maxLen = 2500;
        if (raw != null && raw.length() > maxLen) {
            return raw.substring(0, maxLen) + '...(truncated)';
        }
        return raw;
    }

    private static List<Map<String, Object>> toMapList(Object source) {
        List<Map<String, Object>> output = new List<Map<String, Object>>();
        if (source == null) {
            return output;
        }

        List<Object> inputList = (List<Object>) source;
        for (Object item : inputList) {
            output.add(toMap(item));
        }
        return output;
    }

    private static List<Map<String, Object>> cloneRowList(List<Map<String, Object>> source) {
        List<Map<String, Object>> clone = new List<Map<String, Object>>();
        for (Map<String, Object> row : source) {
            clone.add(toMap(row));
        }
        return clone;
    }

    private static Map<String, Object> toMap(Object source) {
        if (source == null) {
            return new Map<String, Object>();
        }
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(source));
    }

    private static Integer indexOfCustomer(List<Map<String, Object>> rows, String customerId) {
        for (Integer i = 0; i < rows.size(); i++) {
            if (stringValue(rows[i].get('customerId')) == customerId) {
                return i;
            }
        }
        return -1;
    }

    private static String stringValue(Object input) {
        return input == null ? null : String.valueOf(input);
    }

    private static Integer toInteger(Object value, Integer defaultValue) {
        if (value == null) {
            return defaultValue;
        }

        try {
            return Integer.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return defaultValue;
        }
    }
}