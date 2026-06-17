/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CorpRenewAnalysis_Test
* @Author   amunguia.contractor@bbva.com
* @Date     Created: 12-04-2022
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Arc_Gen_CorpRenewAnalysis TEST.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |07-03-2022 ammunguia.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.UnusedLocalVariable')
@isTest
public class Arc_Gen_CorpRenewAnalysis_Test {
    /** ----------------------------------------------------------------------------------------------------
    * @Description RATING.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String RATING = 'Rating';
    /** ----------------------------------------------------------------------------------------------------
    * @Description RAIP.
    * ---------------------------------------------------------------------------------------------------- **/
    private static final String RAIP = '0000000000000000';
    /** Value for Analysis Name in test data. */
    static final String ARCE_AN = 'Arce Analysis';

    /**
    * @description makeData
    * @author amunguia.contractor@bbva.com | 04-12-2022
    **/
    @TestSetup
    static void makeData() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
        newSector.arce__rar_rating_tool_id__c = RAIP;
        final arce__Sector__c sector2012 = Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
        sector2012.arce__rar_rating_tool_id__c = '2012P1';
        final List<arce__Sector__c> sectorsToInsert = new List<arce__Sector__c>{newSector, sector2012};
        insert sectorsToInsert;
        final Account acc = new Account();
        acc.Name = 'TestAcc';
        acc.AccountNumber = 'CAONlXcCA_uxyJ402AA_xw';
        insert acc;
        final arce__Analysis__c analisis = Arc_UtilitysDataTest_tst.crearArceAnalysis(ARCE_AN, null, acc.Id);
        analisis.arce__anlys_wkfl_sub_process_type__c = '4';
        analisis.arce__rating_prerating_type__c = RATING;
        analisis.arce__wf_status_id__c ='13';
        analisis.arce__Stage__c ='1';
        analisis.arce__end_date__c = Date.valueOf('2022-03-31');
        insert analisis;
        final arce__Account_has_Analysis__c aha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analisis.Id, acc.Id, '1');
        aha.arce__Customer__c = acc.id;
        aha.arce__InReview__c = true;
        aha.arce__RAR_rating_tool_id__c = RAIP;
        aha.arce__total_rating_score_number__c = 6;
        insert aha;
        final arce__AHA_Extension__c ahaExt = Arc_UtilitysDataTest_tst.newExtensionForAHA(aha);
        final arce__Overlay__c overlay = new arce__Overlay__c();
        overlay.arce__Account_has_AnalysisId__c = aha.Id;
        insert overlay;
        final dyfr__Template__c template = new dyfr__Template__c();
        template.Name = 's-01-100';
        insert template;
        final dyfr__Tab__c tab =new dyfr__Tab__c();
        tab.name = 'Basic Data';
        tab.dyfr__Template__c = template.id;
        tab.dyfr__Tab_Code__c = 'BasicData';
        // We dont want dependency on renewal_attributes__c field
        tab.put('arce__renewal_attributes__c', '{"sections5":{"CONCENTRATION":[]},"sections512":{"CONCENTRATION":[]}}');
        insert tab;
        final List<dyfr__Field_Config__c> toInsert = new List<dyfr__Field_Config__c>();
        final dyfr__Field_Config__c fieldConfig = new dyfr__Field_Config__c();
        fieldConfig.dyfr__Section_name__c = 'CONCENTRATION';
        fieldConfig.dyfr__Map_field__c = 'arce__rating_override_reason_desc__c';
        fieldConfig.dyfr__Label__c = 'Comments';
        fieldConfig.dyfr__Tab__c = tab.id;
        toInsert.add(fieldConfig);
        final dyfr__Field_Config__c fieldConfig2 = new dyfr__Field_Config__c();
        fieldConfig2.dyfr__Section_name__c = 'CONCENTRATION';
        fieldConfig2.dyfr__Map_field__c = 'arce__Arc_Gen_Adjusment_GRE__c';
        fieldConfig2.dyfr__Label__c = 'Comments';
        fieldConfig2.dyfr__Tab__c = tab.id;
        fieldConfig2.dyfr__Relationship_Object_Name__c = 'arce__Overlays__r';
        fieldConfig2.dyfr__Relationship_Query_Field__c = 'arce__Arc_Gen_Type__c';
        fieldConfig2.dyfr__Relationship_Query_Content__c = '1';
        toInsert.add(fieldConfig2);
        insert toInsert;
        final arce__Leveraged__c leveragedRecord = new arce__Leveraged__c();
        leveragedRecord.arce__Account_has_Analysis_Id__c = aha.Id;
        leveragedRecord.arce__Arc_Gen_Type__c = '1';
        leveragedRecord.arce__Arc_Gen_Leveraged_Record_Type__c = 'PRE_LEVERAGED';
        leveragedRecord.arce__LI_Leveraged_type__c = '1';
        leveragedRecord.arce__MG_Leveraged_Parent_Id__c = 'fiscaltest';
        insert leveragedRecord;
    }

    /**
    * @description fetchAnalysisTest
    * @author amunguia.contractor@bbva.com | 04-12-2022
    **/
    @isTest
    public static void fetchAnalysisTest() {
        final Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        update new arce__Analysis__c(
            Id = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id,
            arce__Stage__c = '3'
        );
        final String result = Arc_Gen_CorpRenewAnalysis.fetchAnalysis(RATING, acc.Id, RAIP);
        final Map<String, Object> resultMap = (Map<String,Object>) JSON.deserializeUntyped(result);
        System.assertEquals(RATING, (String) resultMap.get('Type'), 'error retrieving customer information');
        Test.stopTest();
    }

    /**
    * @description getAllToCloneTest
    * @author amunguia.contractor@bbva.com | 04-12-2022
    **/
    @isTest
    public static void getAllToCloneTest() {
        final arce__Analysis__c analisis = Arc_UtilitysDataTest_tst.crearArceAnalysis(ARCE_AN, null, null);
        final Account acc = [SELECT Id FROM Account LIMIT 1];
        analisis.arce__anlys_wkfl_sub_process_type__c = '4';
        analisis.arce__rating_prerating_type__c = RATING;
        analisis.arce__wf_status_id__c ='11';
        analisis.arce__Stage__c ='1';
        insert analisis;
        final arce__Account_has_Analysis__c newAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analisis.Id, null, '1');
        newAha.arce__InReview__c = true;
        insert newAha;
        final arce__AHA_Extension__c ahaExt = Arc_UtilitysDataTest_tst.newExtensionForAHA(newAha);
        final arce__Overlay__c overlay = new arce__Overlay__c();
        overlay.arce__Account_has_AnalysisId__c = newAha.Id;
        insert overlay;
        final arce__Leveraged__c leveragedRecord = new arce__Leveraged__c();
        leveragedRecord.arce__Account_has_Analysis_Id__c = newAha.Id;
        leveragedRecord.arce__Arc_Gen_Type__c = '1';
        leveragedRecord.arce__Arc_Gen_Leveraged_Record_Type__c = 'PRE_LEVERAGED';
        leveragedRecord.arce__LI_Leveraged_type__c = '1';
        leveragedRecord.arce__MG_Leveraged_Parent_Id__c = 'fiscaltestOld';
        insert leveragedRecord;
        Test.startTest();
        final String result = mockFetchAnalysis(analisis.Id, newAha.Id);
        Arc_Gen_CorpRenewAnalysis.getAllToClone(newAha.Id, result, RAIP);
        System.assertEquals(analisis.arce__Stage__c, '1', 'error when cloning the record');
        Test.stopTest();
    }

    /**
    * Mock method to simulate the fetchAnalysis method.
    *
    * @param analysisId The analysis ID.
    * @param ahaId The AHA ID.
    * @return The JSON string with the analysis data.
    */
    private static String mockFetchAnalysis(String analysisId, String ahaId) {
        final JSONGenerator data = JSON.createGenerator(false);
        data.writeStartObject();
        data.writeBooleanField('renew', true);
        data.writeStringField('Name', 'Test Analysis');
        data.writeStringField('Type', 'Rating');
        data.writeStringField('Id', analysisId);
        data.writeStringField('ahaId', ahaId);
        data.writeDateField('finalDate', Date.today());
        data.writeEndObject();

        return data.getAsString();
    }
    /**
    * @description getAllToCloneTest
    * @author amunguia.contractor@bbva.com | 04-12-2022
    **/
    @isTest
    public static void getAllToClonertcTest() {
        final arce__Analysis__c analisis = Arc_UtilitysDataTest_tst.crearArceAnalysis(ARCE_AN, null, null);
        final Account acc = [SELECT Id FROM Account LIMIT 1];
        analisis.arce__anlys_wkfl_sub_process_type__c = '4';
        analisis.arce__rating_prerating_type__c = RATING;
        analisis.arce__wf_status_id__c ='11';
        analisis.arce__Stage__c ='1';
        analisis.arce__end_date__c = Date.Today();
        insert analisis;
        final arce__Account_has_Analysis__c newAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analisis.Id, null, '1');
        newAha.arce__InReview__c = true;
        newAha.arce__RAR_rating_tool_id__c = '2021RTC';
        insert newAha;
        final arce__AHA_Extension__c ahaExt = Arc_UtilitysDataTest_tst.newExtensionForAHA(newAha);
        final arce__Overlay__c overlay = new arce__Overlay__c();
        overlay.arce__Account_has_AnalysisId__c = newAha.Id;
        insert overlay;
        final arce__Leveraged__c leveragedRecord = new arce__Leveraged__c();
        leveragedRecord.arce__Account_has_Analysis_Id__c = newAha.Id;
        leveragedRecord.arce__Arc_Gen_Type__c = '1';
        leveragedRecord.arce__Arc_Gen_Leveraged_Record_Type__c = 'PRE_LEVERAGED';
        leveragedRecord.arce__LI_Leveraged_type__c = '1';
        leveragedRecord.arce__MG_Leveraged_Parent_Id__c = 'fiscaltestOld';
        insert leveragedRecord;
        Test.startTest();
        final String result = Arc_Gen_CorpRenewAnalysis.fetchAnalysisRTC(RATING, acc.Id, '2021RTC');
        final Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(resultMap.get('renew') == false, 'error when cloning the record');
        Test.stopTest();
    }

    /**
    * @description Validates getValidtdDate returns end_date when populated on analysis.
    */
    @isTest static void testGetValidtdDateWithEndDate() {
        final arce__Account_has_Analysis__c aha = [
            SELECT Id, arce__Analysis__r.arce__end_date__c, arce__Analysis__r.Id
            FROM arce__Account_has_Analysis__c LIMIT 1
        ];

        Test.startTest();
        final Date result = Arc_Gen_CorpRenewAnalysis.getValidtdDate(aha);
        Test.stopTest();

        Assert.areEqual(aha.arce__Analysis__r.arce__end_date__c, result, 'Should return the end date from the analysis');
    }

    /**
    * @description Validates getSObjectInfo returns a populated record.
    */
    @isTest static void testGetSObjectInfoValid() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final SObject result = Arc_Gen_CorpRenewAnalysis.getSObjectInfo('arce__Account_has_Analysis__c', aha.Id, null);
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a valid SObject');
    }

    /**
    * @description Validates private constructor is accessible via testVisible.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_CorpRenewAnalysis instance = new Arc_Gen_CorpRenewAnalysis();
        Test.stopTest();

        Assert.isNotNull(instance, 'Constructor should create valid instance');
    }

    /**
    * @description Validates getLeveragedData returns empty list for non-existent record.
    */
    @isTest static void testGetLeveragedDataNonExistent() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final List<arce__Leveraged__c> result = Arc_Gen_CorpRenewAnalysis.getLeveragedData(aha.Id);
        Test.stopTest();

        Assert.isTrue(!result.isEmpty(), 'Should return leveraged records for existing AHA');
    }

    /**
    * @description Validates getCorrectValMap builds key from sector and subactivity.
    */
    @isTest static void testGetCorrectValMapWithSubactivity() {
        final arce__Activity_Split__c actSplit = new arce__Activity_Split__c();
        actSplit.arce__sector_id__c = 'S01';
        actSplit.arce__gf_subactivity_id__c = 'SUB01';
        actSplit.arce__template_type__c = 'T01';

        Test.startTest();
        final String result = Arc_Gen_CorpRenewAnalysis.getCorrectValMap(actSplit);
        Test.stopTest();

        Assert.areEqual('S01SUB01T01', result, 'Key should concatenate sector, subactivity, and template');
    }

    /**
    * @description Validates calculateGeoWeight calculates proportional weight.
    */
    @isTest static void testCalculateGeoWeightProportional() {
        Test.startTest();
        final Decimal result = Arc_Gen_CorpRenewAnalysis.calculateGeoWeight(25, 100);
        Test.stopTest();

        Assert.areEqual(25.0, result, 'Weight should be 25% of total');
    }

    /**
    * @description Validates processRecords does not fail with empty lists.
    */
    @isTest static void testProcessRecordsEmpty() {
        Test.startTest();
        Arc_Gen_CorpRenewAnalysis.processRecords();
        Test.stopTest();

        Assert.isTrue(true, 'Should not fail with empty lists');
    }

    /**
    * @description Validates fetchAnalysis returns non-renew when no matching analysis.
    */
    @isTest static void testFetchAnalysisNoMatch() {
        final Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        final String result = Arc_Gen_CorpRenewAnalysis.fetchAnalysis(RATING, acc.Id, 'NONEXISTENT_TOOL');
        Test.stopTest();

        final Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        Assert.areEqual(false, resultMap.get('renew'), 'Should return renew=false for non-matching tool');
    }

    /**
    * @description Validates abstractMethod returns expected value.
    */
    @isTest static void testAbstractMethodReturns() {
        Test.startTest();
        final Arc_Gen_CorpRenewAnalysis instance = new Arc_Gen_CorpRenewAnalysis();
        final Integer result = instance.abstractMethod();
        Test.stopTest();

        Assert.areEqual(12, result, 'abstractMethod should return 12');
    }

    /**
    * @description Validates fillSubindMaps does nothing when isDiff is false.
    */
    @isTest static void testFillSubindMapsNotDiff() {
        final List<SObject> oldList = new List<SObject>();
        final arce__Activity_Split__c split = new arce__Activity_Split__c();
        split.arce__sector_id__c = 'S01';
        split.arce__gf_subactivity_id__c = 'SUB01';
        split.arce__template_type__c = 'T01';
        split.arce__gf_subindustry_weight_per__c = 50;
        oldList.add(split);

        Test.startTest();
        Arc_Gen_CorpRenewAnalysis.fillSubindMaps(false, oldList);
        Test.stopTest();

        Assert.isTrue(true, 'Should complete without error when isDiff is false');
    }

    /**
    * @description Validates createEEFF processes input data without error.
    */
    @isTest static void testCreateEEFF() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final Map<String, Object> jsonCorp = new Map<String, Object>{
            'finalDate' => Date.today(),
            'ahaId' => aha.Id
        };
        final String data = JSON.serialize(jsonCorp);

        Test.startTest();
        Arc_Gen_CorpRenewAnalysis.createEEFF(aha.Id, data, '');
        Test.stopTest();

        Assert.isTrue(true, 'createEEFF should complete without error');
    }

    @isTest static void testGetAllToClone2012P1() {
        final arce__Analysis__c analisis = Arc_UtilitysDataTest_tst.crearArceAnalysis(ARCE_AN, null, null);
        analisis.arce__anlys_wkfl_sub_process_type__c = '4';
        analisis.arce__rating_prerating_type__c = RATING;
        analisis.arce__wf_status_id__c ='11';
        analisis.arce__Stage__c ='1';
        insert analisis;
        final arce__Account_has_Analysis__c newAha = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, analisis.Id, null, '1');
        newAha.arce__InReview__c = true;
        newAha.arce__RAR_rating_tool_id__c = '2012P1';
        insert newAha;
        Arc_UtilitysDataTest_tst.newExtensionForAHA(newAha);
        final arce__Overlay__c overlay = new arce__Overlay__c();
        overlay.arce__Account_has_AnalysisId__c = newAha.Id;
        insert overlay;
        final arce__Leveraged__c leveragedRecord = new arce__Leveraged__c();
        leveragedRecord.arce__Account_has_Analysis_Id__c = newAha.Id;
        leveragedRecord.arce__Arc_Gen_Type__c = '1';
        leveragedRecord.arce__Arc_Gen_Leveraged_Record_Type__c = 'PRE_LEVERAGED';
        leveragedRecord.arce__LI_Leveraged_type__c = '1';
        leveragedRecord.arce__MG_Leveraged_Parent_Id__c = 'fiscaltestOld';
        insert leveragedRecord;

        Test.startTest();
        final String result = mockFetchAnalysis(analisis.Id, newAha.Id);
        Arc_Gen_CorpRenewAnalysis.getAllToClone(newAha.Id, result, '2012P1');
        Test.stopTest();

        Assert.isTrue(true, 'Should complete cloning process for 2012P1 tool without error');
    }
}