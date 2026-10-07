@IsTest
public class DMT_DefaultClientRendererTest {

    private static DMT_Line__c buildLineWithClientRelationship(String clientName) {
        // Use JSON deserialization to set the Client__r relationship in-memory
        // without performing DML on DMT_Line__c (which requires many required fields).
        String fakeAccountId = '001000000000001AAA';
        String lineJson = '{"Name":"Test Line","Client__c":"' + fakeAccountId + '",'
            + '"Client_Type__c":"Corporate",'
            + '"Client__r":{"Name":"' + clientName + '"}}';
        return (DMT_Line__c) JSON.deserialize(lineJson, DMT_Line__c.class);
    }

    @IsTest
    static void testEmptyLineReturnsGuardMessage() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        // An SObject with no fields set → getPopulatedFieldsAsMap().isEmpty() == true → guard message.
        data.line = new DMT_Line__c();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Client data not provided'), 'Empty line must return guard message.');
    }

    @IsTest
    static void testNullClientIdReturnsGuardMessage() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = new DMT_Line__c(Name = 'Test Line');
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Client data not provided'), 'Null Client__c must return guard message.');
    }

    @IsTest
    static void testNonSubsidiaryEmptyAssociationListRendersClientTable() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = buildLineWithClientRelationship('ACME Corp');
        data.isSubsidiary = false;
        data.customAssociationClientList = new List<Custom_Association_Client__c>();

        String result = renderer.renderHtml(data);

        Assert.isNotNull(result, 'Non-subsidiary happy path must return a non-null result.');
        Assert.isTrue(result.contains('CLIENT'), 'Result should contain the CLIENT section header.');
        Assert.isTrue(result.contains('ACME Corp'), 'Client name should be rendered.');
        Assert.isTrue(!result.contains('SELECTED CLIENT'), 'No customAssociationClientList means no SELECTED CLIENT table.');
        Assert.isTrue(!result.contains('INTERNAL RATING (SHORT)'), 'Non-subsidiary must not render INTERNAL RATING SHORT.');
    }

    @IsTest
    static void testNonSubsidiaryWithCustomAssociationRendersSelectedClientTable() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = buildLineWithClientRelationship('ACME Corp');
        data.isSubsidiary = false;
        data.mainHolderCustomerId = 'ES0182000170441';

        Custom_Association_Client__c cac = new Custom_Association_Client__c(
            Name = 'GRIFOLS S.A.',
            Alpha_Code_Client__c = 'ES0182000170441'
        );
        data.customAssociationClientList = new List<Custom_Association_Client__c>{ cac };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('SELECTED CLIENT'), 'customAssociationClientList present must render SELECTED CLIENT table.');
        Assert.isTrue(result.contains('GRIFOLS S.A.'), 'Client name in association list should be rendered.');
        Assert.isTrue(result.contains('Yes'), 'Matching mainHolderCustomerId should render Yes in MAIN HOLDER column.');
    }

    @IsTest
    static void testNonMainHolderRendersNo() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = buildLineWithClientRelationship('ACME Corp');
        data.isSubsidiary = false;
        data.mainHolderCustomerId = 'DIFFERENT_HOLDER';

        Custom_Association_Client__c cac = new Custom_Association_Client__c(
            Name = 'Some Other Company',
            Alpha_Code_Client__c = 'ES0182000170441'
        );
        data.customAssociationClientList = new List<Custom_Association_Client__c>{ cac };

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('No'), 'Non-matching holder should render No in MAIN HOLDER column.');
    }

    @IsTest
    static void testSubsidiaryPathRendersInternalRatingColumn() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.line = buildLineWithClientRelationship('Subsidiary Corp');
        data.isSubsidiary = true;
        data.ratingMonoHolder = 'AA';
        data.customAssociationClientList = new List<Custom_Association_Client__c>();

        String result = renderer.renderHtml(data);

        Assert.isTrue(result.contains('INTERNAL RATING (SHORT)'), 'Subsidiary path should render INTERNAL RATING (SHORT) column.');
        Assert.isTrue(result.contains('AA'), 'Rating value should be rendered.');
    }

    @IsTest
    static void testGetTrackedFieldsReturnsLineFields() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        List<String> trackedFields = renderer.getTrackedFields(null);
        // CIBGLOBALD-4117 - the two displayed header fields plus the three hand-added fields that
        // decide which CLIENT layout branch renders/what the computed columns show (not displayed
        // directly, see the comment in getTrackedFields itself).
        Assert.areEqual(5, trackedFields.size(), 'The two displayed header fields plus the three layout/computed-value dependencies should be tracked.');
        Set<String> trackedFieldSet = new Set<String>(trackedFields);
        Assert.isTrue(trackedFieldSet.contains('Client__r.Name'), 'Client__r.Name must be tracked.');
        Assert.isTrue(trackedFieldSet.contains('Client_Type__c'), 'Client_Type__c must be tracked.');
        Assert.isTrue(trackedFieldSet.contains('Custom_Association__c'), 'Custom_Association__c decides the subsidiary/non-subsidiary layout branch.');
        Assert.isTrue(trackedFieldSet.contains('Custom_Association__r.g_customer_id__c'), 'Custom_Association__r.g_customer_id__c feeds the MAIN HOLDER column.');
        Assert.isTrue(trackedFieldSet.contains('Client__r.g_customer_id__c'), 'Client__r.g_customer_id__c feeds the isSubsidiary/ratingMonoHolder branch.');
    }

    @IsTest
    static void testGetTrackedFieldsByObjectReturnsBothObjects() {
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();
        Map<String, List<String>> fieldsByObject = renderer.getTrackedFieldsByObject(null);

        Assert.isTrue(fieldsByObject.containsKey('DMT_Line__c'), 'DMT_Line__c section must be present.');
        Assert.isTrue(fieldsByObject.containsKey('Custom_Association_Client__c'), 'Custom_Association_Client__c section must be present.');

        Set<String> customAssociationFields = new Set<String>(fieldsByObject.get('Custom_Association_Client__c'));
        Set<String> expectedFields = new Set<String>{
            'Name', 'DMT_ClientStarCode__c', 'Alpha_Code_Client__c', 'DMT_Amount__c', 'DMT_Term__c',
            'DMT_FDAmount__c', 'DMT_DVPAmount__c', 'DMT_ClientContracts__c', 'DMT_ClientRating__c'
        };
        Assert.areEqual(expectedFields, customAssociationFields, 'Custom_Association_Client__c tracked fields must match exactly what is rendered, including DMT_ClientRating__c.');
    }

    // CIBGLOBALD-4117 - requires a real inserted Line since these methods re-query by Id.
    @IsTest
    static void testGetCalloutCacheKeyNullWhenNoCustomerId() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();

        String cacheKey = renderer.getCalloutCacheKey(new DMT_Line__c(Id = line.Id));

        Assert.isNull(cacheKey, 'No g_customer_id__c on the test fixture Account - cache key must be null, not throw.');
    }

    @IsTest
    static void testFetchLiveTrackedValuesEmptyWhenNoCustomerId() {
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_DefaultClientRenderer renderer = new DMT_DefaultClientRenderer();

        Map<String, Object> values = renderer.fetchLiveTrackedValues(new DMT_Line__c(Id = line.Id));

        Assert.isTrue(values.isEmpty(), 'No g_customer_id__c on the test fixture Account - must return an empty map, not throw or callout.');
    }
}