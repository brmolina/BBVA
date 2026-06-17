/**
* @description Test class for Arc_Gen_Triage_helper.
*/
@SuppressWarnings('PMD.CyclomaticComplexity')
@isTest
private class Arc_Gen_Triage_helper_Test {
    /**
    * @description Make test data for test methods.
    */
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        Arc_UtilitysDataTest_tst.enableBypass();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceAnalysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        arceAnalysis.arce__Stage__c = '2';
        insert arceAnalysis;

        final arce__Account_has_Analysis__c accHasAn = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceAnalysis.Id, groupAccount.accId, null);
        accHasAn.arce__group_asset_header_type__c = '1';
        insert accHasAn;
    }

    /**
    * @description Validates the helper constructor instantiates successfully.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_Triage_helper helper = new Arc_Gen_Triage_helper();
        Test.stopTest();

        Assert.isNotNull(helper, 'Constructor should create an instance');
    }

    /**
    * @description Validates static string constants match their expected values.
    */
    @isTest static void testConstantsNotNull() {
        Test.startTest();
        final String fs = Arc_Gen_Triage_helper.FINANCIAL_STATEMENT;
        final String ep = Arc_Gen_Triage_helper.ECONOMIC_PART;
        final String consol = Arc_Gen_Triage_helper.CONSOLIDATED;
        final String trueText = Arc_Gen_Triage_helper.TRUE_TEXT;
        final String falseText = Arc_Gen_Triage_helper.FALSE_TEXT;
        Test.stopTest();

        Assert.isTrue(
            'financialStatement' == fs && 'economicGroupParticipants' == ep &&
            'CONSOLIDATED' == consol && 'true' == trueText && 'false' == falseText,
            'All static string constants should match their expected values'
        );
    }

    /**
    * @description Validates TriageParameters wrapper fields are accessible and assignable.
    */
    @isTest static void testTriageParametersFields() {
        Test.startTest();
        final Arc_Gen_Triage_helper.TriageParameters params = new Arc_Gen_Triage_helper.TriageParameters();
        params.eventType = 'NEW';
        params.riskAssessmentId = 'RA001';
        params.participantId = 'P001';
        params.participationType = 'GROUP';
        params.businessAgentId = 'BA001';
        params.bankId = '0182';
        params.branchId = 'B001';
        params.branchLevel = '1';
        params.financialStatementId = 'FS001';
        Test.stopTest();

        Assert.isTrue('NEW' == params.eventType && 'RA001' == params.riskAssessmentId, 'TriageParameters eventType and riskAssessmentId should be correctly set');
    }

    /**
    * @description Validates TriageResponse wrapper fields are accessible and assignable.
    */
    @isTest static void testTriageResponseFields() {
        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse resp = new Arc_Gen_Triage_helper.TriageResponse();
        resp.response = new arce.Arc_Gen_ServiceAndSaveResponse();
        resp.clientsNotInScope = new List<String>{'client1'};
        resp.groupInScope = 'true';
        resp.riskSegment = 'ENTERPRISES';
        Test.stopTest();

        Assert.isTrue('true' == resp.groupInScope && 'ENTERPRISES' == resp.riskSegment, 'TriageResponse groupInScope and riskSegment should be correctly set');
    }

    /**
    * @description Validates TriageRetrievedData wrapper fields are accessible and assignable.
    */
    @isTest static void testTriageRetrievedDataFields() {
        Test.startTest();
        final Arc_Gen_Triage_helper.TriageRetrievedData data = new Arc_Gen_Triage_helper.TriageRetrievedData();
        data.participantId = 'P001';
        data.participantType = 'GROUP';
        data.isInScope = true;
        data.riskSegment = 'ENTERPRISES';
        data.analysisModelType = 'MODEL1';
        data.ratingToolId = 'RT001';
        data.cyclicitySectorAxis = 'CYC1';
        data.ratingModelType = 'RMT001';
        data.bankId = '0182';
        data.branchId = 'BR001';
        data.template = '1';
        data.ffssId = 'FS001';
        data.ffssCurrency = 'EUR';
        data.ffssUnits = 'MILLIONS';
        data.periodUnit = 'MONTHS';
        data.periodNumber = 12;
        data.periodType = 'ANNUAL';
        data.ffssEndDate = Date.today();
        data.ffssType = 'AUDITED';
        data.salesAmount = 1000000;
        data.salesCurrency = 'EUR';
        data.primaryAnalysisType = '1';
        Test.stopTest();

        Assert.isTrue('P001' == data.participantId && data.isInScope == true, 'TriageRetrievedData participantId and isInScope should be correctly set');
    }

    /**
    * @description Validates genCtrlMap returns a populated map from control objects.
    */
    @isTest static void testGenCtrlMapWithControls() {
        final List<Object> controls = new List<Object>();
        final Map<String, Object> control1 = new Map<String, Object>{
            'id' => 'CT016',
            'description' => 'Test control',
            'isValid' => true
        };
        controls.add(control1);

        Test.startTest();
        final Map<String, Map<String, String>> result = Arc_Gen_Triage_helper.genCtrlMap(controls);
        Test.stopTest();

        Assert.isTrue(result.containsKey('CT016'), 'Map should contain CT016 key');
    }

    /**
    * @description Validates genCtrlMap returns empty map for null input.
    */
    @isTest static void testGenCtrlMapNull() {
        Test.startTest();
        final Map<String, Map<String, String>> result = Arc_Gen_Triage_helper.genCtrlMap(null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Map should be empty for null controls');
    }

    /**
    * @description Validates cntrlErr returns response unchanged when no errors present.
    */
    @isTest static void testCntrlErrNoErrors() {
        final Map<String, Map<String, String>> contMap = new Map<String, Map<String, String>>();
        final Arc_Gen_Triage_helper.TriageResponse triageResp = new Arc_Gen_Triage_helper.TriageResponse();

        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse result = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        Test.stopTest();

        Assert.isNotNull(result.response, 'Response should be initialized');
    }

    /**
    * @description Validates cntrlErr sets saveStatus to CT016 when control isValid is true.
    */
    @isTest static void testCntrlErrCT016() {
        final Map<String, String> controlData = new Map<String, String>{
            'isValid' => 'true',
            'description' => 'Triage control error'
        };
        final Map<String, Map<String, String>> contMap = new Map<String, Map<String, String>>{
            'CT016' => controlData
        };
        final Arc_Gen_Triage_helper.TriageResponse triageResp = new Arc_Gen_Triage_helper.TriageResponse();

        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse result = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        Test.stopTest();

        Assert.areEqual('CT016', result.response.saveStatus, 'Save status should be CT016 when isValid=true');
    }

    /**
    * @description Validates cntrlErr sets saveStatus to errAsync when ERROR control isValid is false.
    */
    @isTest static void testCntrlErrAsyncError() {
        final Map<String, String> controlData = new Map<String, String>{
            'isValid' => 'false',
            'description' => 'Async error'
        };
        final Map<String, Map<String, String>> contMap = new Map<String, Map<String, String>>{
            'ERROR' => controlData
        };
        final Arc_Gen_Triage_helper.TriageResponse triageResp = new Arc_Gen_Triage_helper.TriageResponse();

        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse result = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        Test.stopTest();

        Assert.areEqual('errAsync', result.response.saveStatus, 'Save status should be errAsync when isValid=false');
    }

    /**
    * @description Validates getFromWrp extracts AHA records from wrappers.
    */
    @isTest static void testGetFromWrpReturnsList() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper wrp = new arce.Arc_Gen_Account_Has_Analysis_Wrapper();
        wrp.ahaObj = aha;
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> wrappers = new List<arce.Arc_Gen_Account_Has_Analysis_Wrapper>{wrp};

        Test.startTest();
        final List<arce__Account_has_Analysis__c> result = Arc_Gen_Triage_helper.getFromWrp(wrappers);
        Test.stopTest();

        Assert.isTrue(result.size() == 1 && aha.Id == result[0].Id, 'Should return exactly one AHA with the correct Id');
    }

    /**
    * @description Validates getObjectFromJson returns the value for a given key.
    */
    @isTest static void testGetObjectFromJsonValidKey() {
        final Map<String, Object> jsonMap = new Map<String, Object>{
            'name' => 'TestValue'
        };

        Test.startTest();
        final Object result = Arc_Gen_Triage_helper.getObjectFromJson(jsonMap, 'name');
        Test.stopTest();

        Assert.areEqual('TestValue', (String)result, 'Should return the value for the key');
    }

    /**
    * @description Validates getMapFromObject casts object to Map correctly.
    */
    @isTest static void testGetMapFromObjectValid() {
        final Map<String, Object> innerMap = new Map<String, Object>{'inner' => 'value'};
        final Object mapObj = (Object)innerMap;

        Test.startTest();
        final Map<String, Object> result = Arc_Gen_Triage_helper.getMapFromObject(mapObj);
        Test.stopTest();

        Assert.areEqual('value', result.get('inner'), 'Should return the inner map value');
    }

    /**
    * @description Validates getPortfolioValue returns '1' for SOVEREIGNS.
    */
    @isTest static void testGetPortfolioValueSovereigns() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('SOVEREIGNS');
        Test.stopTest();

        Assert.areEqual('1', result, 'SOVEREIGNS should map to 1');
    }

    /**
    * @description Validates getPortfolioValue returns '2' for FINANCIAL_INSTITUTIONS.
    */
    @isTest static void testGetPortfolioValueFinInst() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('FINANCIAL_INSTITUTIONS');
        Test.stopTest();

        Assert.areEqual('2', result, 'FINANCIAL_INSTITUTIONS should map to 2');
    }

    /**
    * @description Validates getPortfolioValue returns '9' for ENTERPRISES.
    */
    @isTest static void testGetPortfolioValueEnterprises() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('ENTERPRISES');
        Test.stopTest();

        Assert.areEqual('9', result, 'ENTERPRISES should map to 9');
    }

    /**
    * @description Validates getPortfolioValue returns '8' for SMALL_OR_MEDIUM_SIZE_COMPANIES.
    */
    @isTest static void testGetPortfolioValueSme() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('SMALL_OR_MEDIUM_SIZE_COMPANIES');
        Test.stopTest();

        Assert.areEqual('8', result, 'SMALL_OR_MEDIUM_SIZE_COMPANIES should map to 8');
    }

    /**
    * @description Validates getPortfolioValue returns '4' for SPECIALIZED_LENDING.
    */
    @isTest static void testGetPortfolioValueSpecLending() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('SPECIALIZED_LENDING');
        Test.stopTest();

        Assert.areEqual('4', result, 'SPECIALIZED_LENDING should map to 4');
    }

    /**
    * @description Validates getPortfolioValue returns '6' for REAL_ESTATE_DEVELOPERS.
    */
    @isTest static void testGetPortfolioValueRealEstate() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('REAL_ESTATE_DEVELOPERS');
        Test.stopTest();

        Assert.areEqual('6', result, 'REAL_ESTATE_DEVELOPERS should map to 6');
    }

    /**
    * @description Validates getPortfolioValue returns '11' for WITHOUT_SALES.
    */
    @isTest static void testGetPortfolioValueWithoutSales() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getPortfolioValue('WITHOUT_SALES');
        Test.stopTest();

        Assert.areEqual('11', result, 'WITHOUT_SALES should map to 11');
    }

    /**
    * @description Validates getTemplateSector returns 's-01' for template 1.
    */
    @isTest static void testGetTemplateSectorTemplate1() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getTemplateSector('1');
        Test.stopTest();

        Assert.areEqual('s-01', result, 'Template 1 should map to s-01');
    }

    /**
    * @description Validates getTemplateSector returns 's-02' for template 2.
    */
    @isTest static void testGetTemplateSectorTemplate2() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getTemplateSector('2');
        Test.stopTest();

        Assert.areEqual('s-02', result, 'Template 2 should map to s-02');
    }

    /**
    * @description Validates getTemplateSector returns empty string for unknown template.
    */
    @isTest static void testGetTemplateSectorUnknown() {
        Test.startTest();
        final String result = Arc_Gen_Triage_helper.getTemplateSector('99');
        Test.stopTest();

        Assert.areEqual('', result, 'Unknown template should return empty string');
    }

    /**
    * @description Validates the callback behavior of closeArce.
    */
    @isTest static void testCloseArceCallback() {
        final arce__Analysis__c analysis = [SELECT Id, Name, arce__Stage__c, arce__wf_status_id__c, arce__triageStatus__c, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c LIMIT 1];
        String exceptionMessage;

        Test.startTest();
        try {
            Arc_Gen_Triage_helper.closeArce(analysis, 'errAsync', 'callback');
        } catch (NullPointerException ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        final arce__Analysis__c result = [SELECT arce__Stage__c, arce__triageStatus__c FROM arce__Analysis__c WHERE Id = :analysis.Id];
        Assert.isTrue(
            exceptionMessage != null && '3' == result.arce__Stage__c && '3' == result.arce__triageStatus__c,
            'Callback closeArce should currently raise the null-pointer path after persisting the finished status'
        );
    }

    /**
    * @description Validates closeArce closes the analysis and sets triage status 3 for errAsync.
    */
    @isTest static void testCloseArceCalloutErrAsync() {
        final arce__Analysis__c analysis = [SELECT Id, Name, arce__Stage__c, arce__wf_status_id__c,
            arce__triageStatus__c, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_Triage_helper.closeArce(analysis, 'errAsync', 'callout');
        Test.stopTest();

        final arce__Analysis__c result = [SELECT arce__Stage__c, arce__triageStatus__c FROM arce__Analysis__c WHERE Id = :analysis.Id];
        Assert.isTrue('3' == result.arce__Stage__c && '3' == result.arce__triageStatus__c, 'Stage and triage status should both be 3 for errAsync');
    }

    /**
    * @Description Validates setupTriageService parses a full participant payload and persists the mapped AHA fields.
    */
    @isTest static void testSetupTriageServiceCalloutPersistsMappedFields() {
        final arce__Analysis__c analysis = [
            SELECT Id, arce__Group__c, arce__anlys_wkfl_sub_process_type__c
            FROM arce__Analysis__c
            LIMIT 1
        ];
        final Account matchingClient = Arc_UtilitysDataTest_tst.crearCuenta('Matching Client', null, analysis.arce__Group__c, '01085387');
        insert matchingClient;

        final arce__Account_has_Analysis__c matchingAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analysis.Id, matchingClient.Id, null);
        insert matchingAha;

        final String encryptedParticipantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient('01085387');
        final Map<String, Object> data = buildSetupTriageServiceData(
            new List<Object>(),
            new List<Object>{ buildParticipant(encryptedParticipantId, true, true) }
        );

        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse response = Arc_Gen_Triage_helper.setupTriageService(analysis, data, 'callout');
        Test.stopTest();

        final arce__Account_has_Analysis__c updatedAha = [
            SELECT arce__Portfolio_class_type__c,
                arce__customer_arce_scope_type__c,
                arce__analysis_model_entity_type__c,
                arce__analysis_template_id__c,
                arce__anlys_wkfl_cnsld_ffss_type__c,
                arce__RAR_rating_tool_id__c
            FROM arce__Account_has_Analysis__c
            WHERE Id = :matchingAha.Id
        ];
        Assert.isTrue(
            response != null && response.groupInScope == 'true' &&
            updatedAha.arce__Portfolio_class_type__c == '9' &&
            updatedAha.arce__customer_arce_scope_type__c == '1' &&
            updatedAha.arce__analysis_model_entity_type__c == 'MODEL1' &&
            updatedAha.arce__analysis_template_id__c == '1' &&
            updatedAha.arce__anlys_wkfl_cnsld_ffss_type__c == Arc_Gen_Triage_helper.PRIMARY_ANLYS_TYPE_BOTTOM_UP_VALUE &&
            updatedAha.arce__RAR_rating_tool_id__c == 'RT001',
            'setupTriageService should parse triage data and persist the mapped participant fields'
        );
    }

    /**
    * @Description Validates setupTriageService closes the analysis when controls report an async error.
    */
    @isTest static void testSetupTriageServiceAsyncErrorClosesAnalysis() {
        final arce__Analysis__c analysis = [
            SELECT Id, arce__Stage__c, arce__wf_status_id__c, arce__triageStatus__c
            FROM arce__Analysis__c
            LIMIT 1
        ];
        final Map<String, Object> data = buildSetupTriageServiceData(
            new List<Object>{ buildControl('ERROR', 'Async error', false) },
            new List<Object>()
        );

        Test.startTest();
        Arc_Gen_Triage_helper.setupTriageService(analysis, data, 'callout');
        Test.stopTest();

        final arce__Analysis__c updatedAnalysis = [
            SELECT arce__Stage__c, arce__wf_status_id__c, arce__triageStatus__c
            FROM arce__Analysis__c
            WHERE Id = :analysis.Id
        ];
        Assert.isTrue(
            updatedAnalysis.arce__Stage__c == '3' &&
            updatedAnalysis.arce__wf_status_id__c == '10' &&
            updatedAnalysis.arce__triageStatus__c == '3',
            'setupTriageService should close the analysis when the async control fails'
        );
    }

    /**
    * @Description Validates setupTriageService callback mode throws an invalid-parameters exception when required participant data is missing.
    */
    @isTest static void testSetupTriageServiceCallbackMissingDataThrowsException() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Map<String, Object> data = buildSetupTriageServiceData(
            new List<Object>(),
            new List<Object>{ buildParticipant('encryptedParticipantId', true, false) }
        );
        String exceptionMessage;

        Test.startTest();
        try {
            Arc_Gen_Triage_helper.setupTriageService(analysis, data, 'callback');
        } catch (Arc_Gen_AsyncTriage_helper.InvalidParametersException ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(
            exceptionMessage != null && exceptionMessage.contains('period-unit-id') && exceptionMessage.contains('totalRevenues-amount'),
            'setupTriageService callback should fail when required participant data is missing'
        );
    }

    /**
    * @description Helper method to build the setup triage service data structure for testing.
    */
    private static Map<String, Object> buildSetupTriageServiceData(List<Object> controls, List<Object> participants) {
        return new Map<String, Object>{
            'controls' => controls,
            Arc_Gen_Triage_helper.ECONOMIC_PART => participants
        };
    }

    /**
    * @description Helper method to build a control map for testing.
    */
    private static Map<String, Object> buildControl(String controlId, String description, Boolean isValid) {
        return new Map<String, Object>{
            'id' => controlId,
            'description' => description,
            'isValid' => isValid
        };
    }

    /**
    * @description Helper method to build a participant map for testing, with options to include required financial statement data.
    */
    private static Map<String, Object> buildParticipant(String participantId, Boolean isInScope, Boolean includeRequiredData) {
        return new Map<String, Object>{
            'id' => participantId,
            'isInScope' => isInScope,
            'riskSegment' => 'ENTERPRISES',
            'participantType' => new Map<String, Object>{
                'id' => Label.Cls_arce_PathGroup
            },
            'analysisModelType' => new Map<String, Object>{
                'id' => 'MODEL1'
            },
            'rating' => new Map<String, Object>{
                'tool' => new Map<String, Object>{
                    'id' => 'RT001'
                },
                'cyclicitySectorAxis' => 'LOW',
                'modelType' => new Map<String, Object>{
                    'id' => 'MODELTYPE1'
                }
            },
            'bank' => new Map<String, Object>{
                'id' => '0001',
                'branch' => new Map<String, Object>{
                    'id' => '0002'
                }
            },
            'template' => '1',
            Arc_Gen_Triage_helper.FINANCIAL_STATEMENT => buildFinancialStatement(includeRequiredData),
            'primaryAnalysisType' => Arc_Gen_Triage_helper.PRIMARY_ANLYS_TYPE_BOTTOM_UP_TEXT
        };
    }

    /**
    * @description Helper method to build a financial statement map for testing, with options to include required data fields.
    */
    private static Map<String, Object> buildFinancialStatement(Boolean includeRequiredData) {
        return new Map<String, Object>{
            'id' => 'FFSS001',
            'currency' => includeRequiredData ? 'EUR' : null,
            'unit' => 'MILLIONS',
            'period' => new Map<String, Object>{
                'unit' => includeRequiredData ? 'MONTHS' : null,
                'number' => 12,
                'periodType' => new Map<String, Object>{
                    'id' => 'ANNUAL'
                },
                'endDate' => String.valueOf(Date.today())
            },
            'financialStatementType' => new Map<String, Object>{
                'id' => 'AUDITED'
            },
            'totalRevenues' => new Map<String, Object>{
                'amount' => includeRequiredData ? 1500.50 : null,
                'currency' => includeRequiredData ? 'EUR' : null
            }
        };
    }

    /**
    * @description Validates closeArce sets triage status 4 for non-errAsync status.
    */
    @isTest static void testCloseArceNotErrAsync() {
        final arce__Analysis__c analysis = [SELECT Id, Name, arce__Stage__c, arce__wf_status_id__c,
            arce__triageStatus__c, arce__anlys_wkfl_sub_process_type__c FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        Arc_Gen_Triage_helper.closeArce(analysis, 'NotArce', 'callout');
        Test.stopTest();

        final arce__Analysis__c result = [SELECT arce__triageStatus__c FROM arce__Analysis__c WHERE Id = :analysis.Id];
        Assert.areEqual('4', result.arce__triageStatus__c, 'Triage status should be 4 for non-errAsync');
    }

    /**
    * @description Validates primary analysis type constants (BOTTOM_UP, TOP_DOWN) are correct.
    */
    @isTest static void testPrimaryAnalysisTypeConstants() {
        Test.startTest();
        final String buValue = Arc_Gen_Triage_helper.PRIMARY_ANLYS_TYPE_BOTTOM_UP_VALUE;
        final String tdValue = Arc_Gen_Triage_helper.PRIMARY_ANLYS_TYPE_TOP_DOWN_VALUE;
        final String buText = Arc_Gen_Triage_helper.PRIMARY_ANLYS_TYPE_BOTTOM_UP_TEXT;
        final String tdText = Arc_Gen_Triage_helper.PRIMARY_ANLYS_TYPE_TOP_DOWN_TEXT;
        Test.stopTest();

        Assert.isTrue(
            '1' == buValue && '2' == tdValue && 'BOTTOM_UP' == buText && 'TOP_DOWN' == tdText,
            'All primary analysis type constants should match expected values'
        );
    }

    /**
    * @description Validates cntrlErr sets NotArce when CT016 isValid is false.
    */
    @isTest static void testCntrlErrCT016NotValid() {
        final Map<String, String> controlData = new Map<String, String>{
            'isValid' => 'false',
            'description' => 'Not ARCE'
        };
        final Map<String, Map<String, String>> contMap = new Map<String, Map<String, String>>{
            'CT016' => controlData
        };
        final Arc_Gen_Triage_helper.TriageResponse triageResp = new Arc_Gen_Triage_helper.TriageResponse();

        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse result = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        Test.stopTest();

        Assert.areEqual('NotArce', result.response.saveStatus, 'Save status should be NotArce when CT016 isValid=false');
    }

    /**
    * @description Validates cntrlErr sets ERROR when ERROR isValid is true.
    */
    @isTest static void testCntrlErrAsyncErrorValid() {
        final Map<String, String> controlData = new Map<String, String>{
            'isValid' => 'true',
            'description' => 'Error occurred'
        };
        final Map<String, Map<String, String>> contMap = new Map<String, Map<String, String>>{
            'ERROR' => controlData
        };
        final Arc_Gen_Triage_helper.TriageResponse triageResp = new Arc_Gen_Triage_helper.TriageResponse();

        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse result = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        Test.stopTest();

        Assert.areEqual('ERROR', result.response.saveStatus, 'Save status should be ERROR when isValid=true');
    }

    /**
    * @description Validates genCtrlMap populates multiple controls.
    */
    @isTest static void testGenCtrlMapMultipleControls() {
        final List<Object> controls = new List<Object>();
        controls.add(new Map<String, Object>{'id' => 'CT016', 'description' => 'Control1', 'isValid' => true});
        controls.add(new Map<String, Object>{'id' => 'ERROR', 'description' => 'Control2', 'isValid' => false});

        Test.startTest();
        final Map<String, Map<String, String>> result = Arc_Gen_Triage_helper.genCtrlMap(controls);
        Test.stopTest();

        Assert.isTrue(result.size() == 2, 'Map should contain exactly two control entries');
    }

    /**
    * @description Validates getFromWrp returns empty list for empty input.
    */
    @isTest static void testGetFromWrpEmptyInput() {
        Test.startTest();
        final List<arce__Account_has_Analysis__c> result = Arc_Gen_Triage_helper.getFromWrp(new List<arce.Arc_Gen_Account_Has_Analysis_Wrapper>());
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty list for empty wrapper input');
    }

    /**
    * @description Validates getObjectFromJson returns null for missing key.
    */
    @isTest static void testGetObjectFromJsonMissingKey() {
        final Map<String, Object> jsonMap = new Map<String, Object>{'name' => 'TestValue'};

        Test.startTest();
        final Object result = Arc_Gen_Triage_helper.getObjectFromJson(jsonMap, 'nonexistent');
        Test.stopTest();

        Assert.isNull(result, 'Should return null for missing key');
    }

    /**
    * @description Validates TriageRetrievedData wrapper ratingToolId and template fields.
    */
    @isTest static void testTriageRetrievedDataAdditionalFields() {
        Test.startTest();
        final Arc_Gen_Triage_helper.TriageRetrievedData data = new Arc_Gen_Triage_helper.TriageRetrievedData();
        data.ratingToolId = 'RT001';
        data.template = 'T001';
        data.salesAmount = 5000000;
        data.salesCurrency = 'USD';
        data.primaryAnalysisType = '2';
        Test.stopTest();

        Assert.isTrue('RT001' == data.ratingToolId && 'T001' == data.template && 5000000 == data.salesAmount, 'Additional TriageRetrievedData fields should be correctly set');
    }

    /**
    * @description Validates cntrlErr handles groupInScope false to trigger CT016 path.
    */
    @isTest static void testCntrlErrGroupNotInScope() {
        final Map<String, Map<String, String>> contMap = new Map<String, Map<String, String>>();
        final Arc_Gen_Triage_helper.TriageResponse triageResp = new Arc_Gen_Triage_helper.TriageResponse();
        triageResp.groupInScope = 'false';

        Test.startTest();
        final Arc_Gen_Triage_helper.TriageResponse result = Arc_Gen_Triage_helper.cntrlErr(contMap, triageResp);
        Test.stopTest();

        Assert.isNotNull(result.response, 'Response should be initialized when group is not in scope');
    }
}