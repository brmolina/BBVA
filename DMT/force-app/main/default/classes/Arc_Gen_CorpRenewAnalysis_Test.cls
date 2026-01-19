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

    /**
    * @description makeData
    * @author amunguia.contractor@bbva.com | 04-12-2022
    **/
    @TestSetup
    static void makeData() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        
        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
        newSector.arce__rar_rating_tool_id__c = RAIP;
        insert newSector;
        final Account acc = new Account();
        acc.Name = 'TestAcc';
        acc.AccountNumber = 'CAONlXcCA_uxyJ402AA_xw';
        insert acc;
        final arce__Analysis__c analisis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, acc.Id);
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
        tab.renewal_attributes__c = '{"sections5":{"CONCENTRATION":[]},"sections512":{"CONCENTRATION":[]}}';
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
        final arce__Analysis__c analisis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, null);
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
}