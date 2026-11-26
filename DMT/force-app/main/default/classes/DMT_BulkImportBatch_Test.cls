/**
 * @description Tests of DMT_BulkImportBatch. CIBGLOBALD-4851: products replacement, client codes, status rules (through
 * Draft and back), value checks and events.
 */
@isTest
public class DMT_BulkImportBatch_Test {

    // test data through DMT_UtilTestClass (DMT test architecture)
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();
    private static final String CUSTOMER_CODE = 'ES0182000125513';
    private static final String GROUP_CODE    = 'G0TEST4851GROUP';

    @TestSetup
    static void makeData() {
        // a subsidiary (customer code) and a group (group code), one insert. Structure Type is set here: the Account
        // trigger (AccountTriggerHandler) only fills it when one account is inserted alone, and an Other Products line
        // needs a Customer client (DES_Client_Type__c Subsidiary) to change status (flow DMT_OTHER_Line_Validations).
        insert new List<Account>{
            DMT_UTIL.buildAccount(new Map<Schema.SObjectField, Object>{
                Account.Name => 'Test Bulk Import Client', Account.g_customer_id__c => CUSTOMER_CODE, Account.DES_Group_Code__c => null,
                Account.DES_Structure_Type__c => 'Subsidiary'
            }),
            DMT_UTIL.buildAccount(new Map<Schema.SObjectField, Object>{
                Account.Name => 'Test Bulk Import Group', Account.DES_Group_Code__c => GROUP_CODE, Account.g_customer_id__c => null,
                Account.DES_Structure_Type__c => 'Group'
            })
        };
    }

    // ── LINES ────────────────────────────────────────────────────────────────

    @isTest
    static void testLinesImportCreatesRecords() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN001', 'Test Line One', CUSTOMER_CODE, 'ES'),
            buildLineRow('TESTLIN002', 'Test Line Two', CUSTOMER_CODE, 'ES')
        };

        Test.startTest();
            DMT_BulkImportBatch batch = new DMT_BulkImportBatch(units(rows), 'job-test-001', 'TreasurySettlement');
            Database.executeBatch(batch, 50);
        Test.stopTest();

        List<DMT_Line__c> created = [SELECT Id, Line_Id__c, Name, DMT_Origin__c, Status__c, Client__r.g_customer_id__c FROM DMT_Line__c WHERE Line_Id__c IN ('TESTLIN001', 'TESTLIN002')];
        Assert.areEqual(2, created.size(), 'Two lines should have been created');
        for (DMT_Line__c line : created) {
            Assert.areEqual('BulkImport', line.DMT_Origin__c, 'Origin should be BulkImport');
            Assert.areEqual('Draft', line.Status__c, 'New lines are created in Draft');
            Assert.areEqual(CUSTOMER_CODE, line.Client__r.g_customer_id__c, 'Client resolved from the customer code');
        }

        // AfterCreateLine flow must create the Passport for imported lines, same as for manually created ones
        Set<Id> createdIds = new Map<Id, DMT_Line__c>(created).keySet();
        List<Passport__c> passports = [SELECT Id FROM Passport__c WHERE DMT_Line__c IN :createdIds];
        Assert.areEqual(2, passports.size(), 'One Passport should have been created per imported line');
    }

    @isTest
    static void testLinesImportIsIdempotent() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN003', 'Test Line Three', CUSTOMER_CODE, 'ES')
        };

        // Both runs inside one startTest/stopTest — Apex only allows one pair per test method
        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units(rows), 'job-test-002a', 'TreasurySettlement'), 50);
            Database.executeBatch(new DMT_BulkImportBatch(units(rows), 'job-test-002b', 'TreasurySettlement'), 50);
        Test.stopTest();

        List<DMT_Line__c> result = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN003'];
        Assert.areEqual(1, result.size(), 'Upsert should not create duplicates');
    }

    // a client code that is neither a customer nor a group code rejects the row (was: line saved without client)
    @isTest
    static void testLinesImportRejectsUnknownClient() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN004', 'Test Line Four', 'NONEXISTENT_CLIENT', 'ES')
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units(rows), 'job-test-003', 'TreasurySettlement'), 50);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN004'], 'A line whose client is not found must not be created');
    }

    // Client_Code__c can be a group code
    @isTest
    static void testLinesImportResolvesGroupCode() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN006', 'Test Line Group', GROUP_CODE.toLowerCase(), 'ES')
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units(rows), 'job-test-006', 'TreasurySettlement'), 50);
        Test.stopTest();

        DMT_Line__c line = [SELECT Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN006'];
        Assert.areEqual(GROUP_CODE, line.Client__r.DES_Group_Code__c, 'Client resolved from the group code, case-insensitive');
    }

    // a new line needs Client_Code__c
    @isTest
    static void testLinesImportRejectsNewLineWithoutClientCode() {
        Map<String, Object> row = buildLineRow('TESTLIN007', 'Test Line No Client', CUSTOMER_CODE, 'ES');
        row.remove('Client_Code__c');

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units(new List<Map<String, Object>>{ row }), 'job-test-007', 'TreasurySettlement'), 50);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN007'], 'A new line without client code must not be created');
    }

    // existing line: a column not in the file is not touched, a blank cell clears the field,
    // the status is kept, and no client code is needed
    @isTest
    static void testLinesImportExistingLineOnlyWritesPresentColumns() {
        DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'Existing Line', DMT_Line__c.Line_Id__c => 'TESTLIN008',
            DMT_Line__c.Status__c => 'Draft', DMT_Line__c.DMT_Comments__c => 'Keep me',
            DMT_Line__c.g_line_status_type__c => 'PR',
            DMT_Line__c.First_Breakclause__c => '365', DMT_Line__c.Breakclause_Frequency__c => '365'
        });
        Map<String, Object> row = new Map<String, Object>{
            'Line_Id__c'            => 'TESTLIN008',
            'Name'                  => 'Existing Line Renamed',
            'g_line_status_type__c' => '',
            'First_Breakclause__c'  => '',
            'Breakclause_Frequency__c' => ''
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units(new List<Map<String, Object>>{ row }), 'job-test-008', 'TreasurySettlement'), 50);
        Test.stopTest();

        DMT_Line__c line = [SELECT Name, DMT_Comments__c, g_line_status_type__c, Status__c, First_Breakclause__c, Breakclause_Frequency__c
                            FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN008'];
        // blank break clause cells keep the values in Salesforce
        Assert.areEqual('365', line.First_Breakclause__c, 'A blank First_Breakclause__c keeps the value');
        Assert.areEqual('365', line.Breakclause_Frequency__c, 'A blank Breakclause_Frequency__c keeps the value');
        Assert.areEqual('Existing Line Renamed', line.Name, 'A column in the file is written');
        Assert.areEqual('Keep me', line.DMT_Comments__c, 'A column not in the file is not touched');
        Assert.isNull(line.g_line_status_type__c, 'A blank cell clears the field');
        Assert.areEqual('Draft', line.Status__c, 'An existing line keeps its status');
    }

    // Treasury Lines file values typed from the field describe; an invalid value rejects the row
    @isTest
    static void testLinesImportTypesTreasuryColumns() {
        Map<String, Object> valid = buildLineRow('TESTLIN009', 'Test Line Typed', CUSTOMER_CODE, 'ES');
        valid.putAll(new Map<String, Object>{
            'Start_Date__c' => '01/11/2026', 'Golden_Code__c' => 'A03642968', 'FD_Amount__c' => '1500000.50',
            'DvP_Amount__c' => '750000,00', 'Waiver__c' => 'TRUE', 'DMT_Client_Use__c' => 'Es string, puedes poner lo que quieras',
            'DMT_ID_User__c' => 'NOTAUSER', 'RecordType:RecordType:Name' => 'Treasury Line', 'DMT_Origin__c' => 'IFIt'
        });
        Map<String, Object> invalid = buildLineRow('TESTLIN010', 'Test Line Bad Date', CUSTOMER_CODE, 'ES');
        invalid.put('End_Date__c', 'next year');

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units(new List<Map<String, Object>>{ valid, invalid }), 'job-test-009', 'TreasurySettlement'), 50);
        Test.stopTest();

        DMT_Line__c line = [SELECT Start_Date__c, Golden_Code__c, FD_Amount__c, DvP_Amount__c, Waiver__c, DMT_Client_Use__c, DMT_Origin__c
                            FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN009'];
        Assert.areEqual(Date.newInstance(2026, 11, 1), line.Start_Date__c, 'dd/mm/yyyy date');
        Assert.areEqual('A03642968', line.Golden_Code__c, 'Golden code saved');
        Assert.areEqual(1500000.50, line.FD_Amount__c, 'Decimal with a point');
        Assert.areEqual(750000.00, line.DvP_Amount__c, 'Decimal with a comma');
        Assert.isTrue(line.Waiver__c, 'Checkbox TRUE');
        Assert.areEqual('Es string, puedes poner lo que quieras', line.DMT_Client_Use__c, 'Text with a comma');
        Assert.areEqual('BulkImport', line.DMT_Origin__c, 'Origin is always BulkImport');
        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN010'], 'An invalid date rejects the row');
    }

    // ── PROCESS: products ──────────────────────────────────

    // existing line, products only: all its Risk Line Terms and Line Product Items are replaced by the
    // file rows; the line is not updated
    @isTest
    static void testProcessReplacesProductsOfExistingLine() {
        DMT_Line__c line = DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'Replace Products Line', DMT_Line__c.Line_Id__c => 'TESTLIN011', DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        insert new List<SObject>{
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{ DMT_Risk_Line_Term__c.DMT_Line__c => line.Id }),
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{ DMT_Risk_Line_Term__c.DMT_Line__c => line.Id }),
            DMT_UTIL.buildLineProductItem(new Map<Schema.SObjectField, Object>{
                DMT_Line_Product_Item__c.Line__c => line.Id, DMT_Line_Product_Item__c.Product_Code_Value__c => 'OLD1'
            })
        };
        Map<String, Object> unit = buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN011' }, false,
            new List<Object>{ buildTermFileRow('Derivatives', '100000', '0', '365') },
            new List<Object>{ buildItemFileRow('DERI'), buildItemFileRow('CCSW') });

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-011', 'TreasurySettlement'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> terms = [SELECT DMT_Risk_Type__c, DMT_Amount__c FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id];
        Assert.areEqual(1, terms.size(), 'The two old terms are replaced by the file row');
        Assert.areEqual('Derivatives', terms[0].DMT_Risk_Type__c, 'Term risk type from the file');
        Assert.areEqual(100000, terms[0].DMT_Amount__c, 'Term amount typed from the file');
        Assert.areEqual(2, [SELECT COUNT() FROM DMT_Line_Product_Item__c WHERE Line__c = :line.Id AND Product_Code_Value__c IN ('DERI', 'CCSW')],
                        'The file product items are inserted');
        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line_Product_Item__c WHERE Line__c = :line.Id AND Product_Code_Value__c = 'OLD1'],
                        'The old product item is deleted');
        Assert.areEqual('Replace Products Line', [SELECT Name FROM DMT_Line__c WHERE Id = :line.Id].Name, 'The line is not updated');
    }

    // records removed one by one on the screen (UNIT_RLT_DELETE): only those are deleted, and only when
    // they belong to the unit's line
    @isTest
    static void testProcessDeletesSingleRecordsOfTheLine() {
        DMT_Line__c line  = DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'Single Delete Line', DMT_Line__c.Line_Id__c => 'TESTLIN022', DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        DMT_Line__c other = DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'Other Line', DMT_Line__c.Line_Id__c => 'TESTLIN023', DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        List<DMT_Risk_Line_Term__c> terms = new List<DMT_Risk_Line_Term__c>{
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{ DMT_Risk_Line_Term__c.DMT_Line__c => line.Id }),
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{ DMT_Risk_Line_Term__c.DMT_Line__c => line.Id }),
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{ DMT_Risk_Line_Term__c.DMT_Line__c => other.Id })
        };
        insert terms;
        Map<String, Object> unit = buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN022' }, false, null, null);
        unit.put(DMT_BulkImportBatch.UNIT_RLT_DELETE, new List<Object>{ String.valueOf(terms[0].Id), String.valueOf(terms[2].Id), 'notAnId' });

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-022', 'TreasurySettlement'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE Id = :terms[0].Id], 'The removed record is deleted');
        Assert.areEqual(1, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE Id = :terms[1].Id], 'The other record of the line is kept');
        Assert.areEqual(1, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE Id = :terms[2].Id], 'A record of another line is never deleted');
    }

    // a loaded table without rows for the line (empty list): all its records of that object are deleted;
    // the table not loaded (key absent) leaves that object untouched
    @isTest
    static void testProcessEmptyTableDeletesAllProducts() {
        DMT_Line__c line = DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'Empty Table Line', DMT_Line__c.Line_Id__c => 'TESTLIN021', DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        insert new List<SObject>{
            DMT_UTIL.buildRiskLineTerm(new Map<Schema.SObjectField, Object>{ DMT_Risk_Line_Term__c.DMT_Line__c => line.Id }),
            DMT_UTIL.buildLineProductItem(new Map<Schema.SObjectField, Object>{
                DMT_Line_Product_Item__c.Line__c => line.Id, DMT_Line_Product_Item__c.Product_Code_Value__c => 'OLD1'
            })
        };
        Map<String, Object> unit = buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN021' }, false, new List<Object>(), null);

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-021', 'TreasurySettlement'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id], 'Loaded table without rows: terms deleted');
        Assert.areEqual(1, [SELECT COUNT() FROM DMT_Line_Product_Item__c WHERE Line__c = :line.Id], 'Table not loaded: items untouched');
    }

    // new line created together with its products (children point to it by Line_Id__c in the same insert);
    // a unit without the Line Product Items key keeps that object untouched
    @isTest
    static void testProcessCreatesLineWithProducts() {
        Map<String, Object> unit = buildUnit(buildLineRow('TESTLIN012', 'New Line With Products', CUSTOMER_CODE, 'ES'), true,
            new List<Object>{ buildTermFileRow('Derivatives', '100000', '0', '2'), buildTermFileRow('Depos', '250000', '365', '1095') },
            null);

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-012', 'TreasurySettlement'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        DMT_Line__c line = [SELECT Id, Status__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN012'];
        Assert.areEqual('Draft', line.Status__c, 'New line in Draft');
        Assert.areEqual(2, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :line.Id], 'Both terms inserted under the new line');
    }

    // a line whose products fail keeps its old products; the other line of the chunk is saved
    // (chunk rolled back, then saved line by line)
    @isTest
    static void testProcessFailedLineKeepsOldProducts() {
        DMT_Line__c failing = DMT_UTIL.createLineRecord(null, new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'Failing Line', DMT_Line__c.Line_Id__c => 'TESTLIN013', DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });
        DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{
            DMT_Risk_Line_Term__c.DMT_Line__c => failing.Id, DMT_Risk_Line_Term__c.DMT_RiskLineTermId__c => 'TESTLIN013-OLD'
        });
        List<Map<String, Object>> units = new List<Map<String, Object>>{
            buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN013' }, false,
                      new List<Object>{ buildTermFileRow('NotARiskType', '1', '0', '2') }, null),
            buildUnit(buildLineRow('TESTLIN014', 'Line Saved Alone', CUSTOMER_CODE, 'ES'), true,
                      new List<Object>{ buildTermFileRow('Derivatives', '100000', '0', '2') }, null)
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units, 'job-test-013', 'TreasurySettlement'), DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> oldTerms = [SELECT DMT_RiskLineTermId__c FROM DMT_Risk_Line_Term__c WHERE DMT_Line__c = :failing.Id];
        Assert.areEqual(1, oldTerms.size(), 'The failing line keeps its products');
        Assert.areEqual('TESTLIN013-OLD', oldTerms[0].DMT_RiskLineTermId__c, 'The kept product is the old one');
        Assert.areEqual(1, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE DMT_Line__r.Line_Id__c = 'TESTLIN014'],
                        'The other line of the chunk is saved with its product');
    }

    // a full chunk (UNITS_PER_CHUNK new lines, each with 2 terms and 1 product item) in one execute
    @isTest
    static void testProcessFullChunk() {
        List<Map<String, Object>> units = new List<Map<String, Object>>();
        for (Integer i = 0; i < DMT_BulkImportBatch.UNITS_PER_CHUNK; i++) {
            String lineId = 'TESTCHUNK' + String.valueOf(i).leftPad(3, '0');
            units.add(buildUnit(buildLineRow(lineId, 'Chunk Line ' + i, CUSTOMER_CODE, 'ES'), true,
                new List<Object>{ buildTermFileRow('Derivatives', '100000', '0', '2'), buildTermFileRow('Depos', '250000', '365', '1095') },
                new List<Object>{ buildItemFileRow('DERI') }));
        }

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units, 'job-test-014', 'TreasurySettlement'), DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        Integer lines = DMT_BulkImportBatch.UNITS_PER_CHUNK;
        Assert.areEqual(lines, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c LIKE 'TESTCHUNK%'], 'Every line created');
        Assert.areEqual(lines * 2, [SELECT COUNT() FROM DMT_Risk_Line_Term__c WHERE DMT_Line__r.Line_Id__c LIKE 'TESTCHUNK%'], 'Every term created');
        Assert.areEqual(lines, [SELECT COUNT() FROM DMT_Line_Product_Item__c WHERE Line__r.Line_Id__c LIKE 'TESTCHUNK%'], 'Every product item created');
    }

    // ── PROCESS: status rules ──────────────────────────────

    // a Proposal line whose file changes a field blocked outside Draft is saved in Draft with the change
    // (DMT_BatchSanctionAMIWEB moves it back afterwards)
    @isTest
    static void testProcessSendsBlockedChangeToDraft() {
        createProposalLine('TESTLIN015');
        Map<String, Object> unit = buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN015', 'Name' => 'Renamed In Proposal' },
                                             true, null, null);

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-015', 'OtherProducts'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        DMT_Line__c line = [SELECT Name, Status__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN015'];
        Assert.areEqual('Draft', line.Status__c, 'A blocked field change sends the line to Draft');
        Assert.areEqual('Renamed In Proposal', line.Name, 'The blocked field is saved');
        Assert.areEqual('Proposal', DMT_BulkImportBatch.lastStatusTargets.get('TESTLIN015'),
                        'The line moves back to its previous status (no code) after the load');
        // the screen is told the status move started for one line
        DMT_BulkImportProgress__e statusEvent = DMT_BulkImportBatch.publishedEvents[DMT_BulkImportBatch.publishedEvents.size() - 1];
        Assert.areEqual(DMT_BulkImportBatch.PHASE_STATUS, statusEvent.Phase__c, 'Status phase after the load');
        Assert.areEqual(DMT_BulkImportBatch.EVENT_IN_PROGRESS, statusEvent.Status__c, 'The status move is running');
        Assert.areEqual(1, statusEvent.Total__c, 'One line to move');
    }

    // a Treasury line in Approval whose file changes a field of the rule ApprovalProcessDataEdit (the
    // comment) is saved in Draft with the change and moves back to Approval, like a blocked field
    @isTest
    static void testProcessSendsApprovalDataChangeToDraft() {
        DMT_UTIL.createLineRecord(customerId(), new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name               => 'Approval Line TESTLIN018',
            DMT_Line__c.Line_Id__c         => 'TESTLIN018',
            DMT_Line__c.DMT_Origin__c      => 'BulkImport',
            DMT_Line__c.Status__c          => 'Approval',
            DMT_Line__c.RecordTypeId       => Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId(),
            DMT_Line__c.Amount__c          => 100000,
            DMT_Line__c.DMT_LastLevelId__c => '20200'
        });
        Map<String, Object> unit = buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN018', 'DMT_Comments__c' => 'Changed in Approval' },
                                             true, null, null);

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-018', 'TreasurySettlement'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        DMT_Line__c line = [SELECT DMT_Comments__c, Status__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN018'];
        Assert.areEqual('Draft', line.Status__c, 'The comment change sends the line to Draft');
        Assert.areEqual('Changed in Approval', line.DMT_Comments__c, 'The comment is saved');
        Assert.areEqual('Approval', DMT_BulkImportBatch.lastStatusTargets.get('TESTLIN018'),
                        'The line moves back to Approval after the load');
    }

    // stayDraft (the LWC found the org rules would reject the move): saved in Draft, not moved
    @isTest
    static void testProcessStayDraftSkipsMove() {
        createProposalLine('TESTLIN017');
        Map<String, Object> unit = buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN017', 'Name' => 'Renamed Stays Draft' },
                                             true, null, null);
        unit.put(DMT_BulkImportBatch.UNIT_STAY_DRAFT, true);

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-017', 'OtherProducts'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        DMT_Line__c line = [SELECT Name, Status__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN017'];
        Assert.areEqual('Draft', line.Status__c, 'The blocked field change still sends the line to Draft');
        Assert.areEqual('Renamed Stays Draft', line.Name, 'The blocked field is saved');
        Assert.isFalse(DMT_BulkImportBatch.lastStatusTargets.containsKey('TESTLIN017'), 'The line is not moved after the load');
    }

    // client type of a line by its client (DMT_Line__c.Client_Type__c formula without golden / custom)
    @isTest
    static void testClientTypeOf() {
        Map<String, Account> accounts = DMT_BulkImportBatch.accountsByClientCode(new Set<String>{ CUSTOMER_CODE, GROUP_CODE });
        Assert.areEqual(2, accounts.size(), 'Both codes are found');
        // DES_Client_Type__c is a formula: in-memory accounts through JSON
        Account subsidiary = (Account) JSON.deserialize('{"DES_Client_Type__c":"Subsidiary"}', Account.class);
        Account country    = (Account) JSON.deserialize('{"RecordType":{"Name":"Country"}}', Account.class);
        Assert.areEqual('Customer', DMT_BulkImportBatch.clientTypeOf(subsidiary), 'Subsidiary');
        Assert.areEqual('Country Customer', DMT_BulkImportBatch.clientTypeOf(country), 'Country record type');
        Assert.areEqual('Group', DMT_BulkImportBatch.clientTypeOf((Account) JSON.deserialize('{}', Account.class)), 'No subsidiary');
        Assert.isTrue(DMT_BulkImportBatch.accountsByClientCode(new Set<String>()).isEmpty(), 'No codes, no query');
    }

    // a field allowed outside Draft keeps the status
    @isTest
    static void testProcessKeepsStatusForAllowedField() {
        createProposalLine('TESTLIN016');
        Map<String, Object> unit = buildUnit(new Map<String, Object>{ 'Line_Id__c' => 'TESTLIN016', 'DMT_Comments__c' => 'Allowed in Proposal' },
                                             true, null, null);

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ unit }, 'job-test-016', 'OtherProducts'),
                                  DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        DMT_Line__c line = [SELECT DMT_Comments__c, Status__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN016'];
        Assert.areEqual('Proposal', line.Status__c, 'An allowed field keeps the status');
        Assert.areEqual('Allowed in Proposal', line.DMT_Comments__c, 'The allowed field is saved');
        Assert.isTrue(DMT_BulkImportBatch.lastStatusTargets.isEmpty(), 'No status change');
        // no line to move: the status phase ends at once
        DMT_BulkImportProgress__e statusEvent = DMT_BulkImportBatch.publishedEvents[DMT_BulkImportBatch.publishedEvents.size() - 1];
        Assert.areEqual(DMT_BulkImportBatch.PHASE_STATUS, statusEvent.Phase__c, 'Status phase after the load');
        Assert.areEqual(DMT_BulkImportBatch.EVENT_COMPLETED, statusEvent.Status__c, 'Nothing to move');
        Assert.areEqual(0, statusEvent.Total__c, 'No line to move');
    }

    // the status code is saved in upper case (DMT_BatchSanctionAMIWEB sets Closed__c only for CW / CL)
    @isTest
    static void testLinesImportSavesCodeInUpperCase() {
        Map<String, Object> row = buildLineRow('TESTLIN020', 'Lower Case Code', CUSTOMER_CODE, 'ES');
        row.put('g_line_status_type__c', 'cw');

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units(new List<Map<String, Object>>{ row }), 'job-test-020', 'TreasurySettlement'), 50);
        Test.stopTest();

        Assert.areEqual('CW', [SELECT g_line_status_type__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN020'].g_line_status_type__c,
                        'Code saved in upper case');
    }

    // a term that is not a value of the picklist of days rejects the line; 365.0 is saved as 365
    @isTest
    static void testProcessChecksTermDays() {
        List<Map<String, Object>> units = new List<Map<String, Object>>{
            buildUnit(buildLineRow('TESTLIN018', 'Term As Date', CUSTOMER_CODE, 'ES'), true,
                      new List<Object>{ buildTermFileRow('Derivatives', '100000', '2026-01-01', '365') }, null),
            buildUnit(buildLineRow('TESTLIN019', 'Term With Decimals', CUSTOMER_CODE, 'ES'), true,
                      new List<Object>{ buildTermFileRow('Derivatives', '100000', '0', '365.0') }, null)
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(units, 'job-test-018', 'TreasurySettlement'), DMT_BulkImportBatch.UNITS_PER_CHUNK);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN018'], 'A date as term rejects the line');
        DMT_Risk_Line_Term__c term = [SELECT DMT_End_Term__c FROM DMT_Risk_Line_Term__c WHERE DMT_Line__r.Line_Id__c = 'TESTLIN019'];
        Assert.areEqual('365', term.DMT_End_Term__c, 'A whole number with decimals is saved as the picklist value');
        DMT_BulkImportProgress__e processEnd;
        for (DMT_BulkImportProgress__e evt : DMT_BulkImportBatch.publishedEvents) {
            if (evt.Phase__c == DMT_BulkImportBatch.IMPORT_TYPE_PROCESS && evt.Status__c == DMT_BulkImportBatch.EVENT_COMPLETED) {
                processEnd = evt;
            }
        }
        Assert.isTrue(processEnd.Errors_JSON__c.contains('DMT_Init_Term__c: invalid value 2026-01-01'), 'The reason is reported');
    }

    @isTest
    static void testEmptyRowsCompleteWithoutError() {
        Test.startTest();
            DMT_BulkImportBatch batch = new DMT_BulkImportBatch(
                new List<Map<String, Object>>(),
                'job-test-005',
                'TreasurySettlement'
            );
            Database.executeBatch(batch, 50);
        Test.stopTest();

        Assert.isTrue(true, 'Empty batch should complete without error');
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    // Row maps are the payload the LWC sends (one per file row), not records: built by hand on purpose.
    private static Map<String, Object> buildLineRow(String lineId, String name, String clientCode, String geo) {
        return new Map<String, Object>{
            'Line_Id__c'                        => lineId,
            'Name'                              => name,
            'Client_Code__c'                    => clientCode,
            'Booking_Geography__c'              => geo,
            'Start_Date__c'                     => '2026-01-01',
            'End_Date__c'                       => '2027-01-01',
            'CurrencyIsoCode'                   => 'EUR',
            'DMT_LastLevelId__c'                => '20200',
            'g_risk_level_clsfn_type__c'        => 'L',
            'g_line_status_type__c'             => 'CW',
            'owner User id_user__c'             => '',
            'DMT_Risk_Line_Term__c DMT_Amount__c' => '1000000.0',
            'g_global_product_family_id__c'     => '',
            'g_global_product_subfamily_id__c'  => '',
            'g_global_product_category_id__c'   => '',
            'g_gbl_product_subcategory_id__c'   => '',
            'g_global_product_id__c'            => ''
        };
    }

    // the client of the test lines (the subsidiary created in makeData)
    private static Id customerId() {
        return [SELECT Id FROM Account WHERE g_customer_id__c = :CUSTOMER_CODE LIMIT 1].Id;
    }

    // an Other Products line created in Proposal (moving it there before Test.stopTest fails: its
    // customer selection is set up asynchronously)
    private static DMT_Line__c createProposalLine(String lineId) {
        DMT_Line__c line = DMT_UTIL.createLineRecord(customerId(), new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name               => 'Proposal Line ' + lineId,
            DMT_Line__c.Line_Id__c         => lineId,
            DMT_Line__c.DMT_Origin__c      => 'BulkImport',
            DMT_Line__c.Status__c          => 'Proposal',
            DMT_Line__c.RecordTypeId       => Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId(),
            DMT_Line__c.Amount__c          => 100000,
            DMT_Line__c.DMT_LastLevelId__c => '20200'
        });
        DMT_UTIL.createRiskLineTermRecord(new Map<Schema.SObjectField, Object>{
            DMT_Risk_Line_Term__c.DMT_Line__c => line.Id, DMT_Risk_Line_Term__c.DMT_Amount__c => 100000
        });
        // the move through Draft needs a Customer client on an Other Products line (flow DMT_OTHER_Line_Validations)
        Assert.areEqual('Customer', [SELECT Client_Type__c FROM DMT_Line__c WHERE Id = :line.Id].Client_Type__c,
                        'Test setup: the line client must be a Customer');
        return line;
    }

    // Process units (DMT_BulkImportBatch.UNIT_*): the payload the LWC sends, one per line
    private static List<Map<String, Object>> units(List<Map<String, Object>> lineRows) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (Map<String, Object> row : lineRows) {
            result.add(buildUnit(row, true, null, null));
        }
        return result;
    }

    // terms / items null = that object is not in the load for the line
    private static Map<String, Object> buildUnit(Map<String, Object> lineRow, Boolean updateLine, List<Object> terms, List<Object> items) {
        Map<String, Object> unit = new Map<String, Object>{
            DMT_BulkImportBatch.UNIT_LINE        => lineRow,
            DMT_BulkImportBatch.UNIT_ROW_NUMBER  => 2,
            DMT_BulkImportBatch.UNIT_UPDATE_LINE => updateLine
        };
        if (terms != null) unit.put(DMT_BulkImportBatch.UNIT_RLT, terms);
        if (items != null) unit.put(DMT_BulkImportBatch.UNIT_LPI, items);
        return unit;
    }

    // Risk Line Terms / Line Product Items file rows as the LWC sends them (keyed by field name)
    private static Map<String, Object> buildTermFileRow(String riskType, String amount, String initTerm, String endTerm) {
        return new Map<String, Object>{
            'DMT_Risk_Type__c' => riskType, 'DMT_Amount__c' => amount, 'DMT_Init_Term__c' => initTerm, 'DMT_End_Term__c' => endTerm
        };
    }

    private static Map<String, Object> buildItemFileRow(String productCode) {
        return new Map<String, Object>{
            'Product_Code_Value__c' => productCode, 'DMT_DerivativeRestriction__c' => 'FALSE',
            'DMT_FDRestriction__c' => 'FALSE', 'DMT_DVPRestriction__c' => 'FALSE'
        };
    }
}
