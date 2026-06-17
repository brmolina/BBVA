/**
* ____________________________________________________________________________
* Test Class for Template Builder Callable class
*
* ____________________________________________________________________________
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-08-16
* @modified
* @systemLayer Service
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
@isTest
public class TemplateBuilder_ProfSheets_Test {

    @TestSetup
    static void setup() {

        final DES_UtilTestClass utilClass = new DES_UtilTestClass();

        Account accountParent = UnitTestUtils.GetStandardAccount();
        accountParent.Name = 'Account Test 0';
        accountParent.OwnerId = UserInfo.getUserId();
        accountParent.g_customer_id__c = '000000010';
        accountParent.DES_BBVA_Segmentation__c = 'C';
        accountParent.DES_Structure_Type__c = 'Group';
        insert accountParent;

        Account accountChild = UnitTestUtils.GetStandardAccount();
        accountChild.ParentId = accountParent.Id;
        accountChild.Name = 'Account Test Child 0';
        accountChild.OwnerId = UserInfo.getUserId();
        accountChild.g_customer_id__c = '000000011';
        accountChild.DES_BBVA_Segmentation__c = 'C';
        accountChild.DES_Structure_Type__c = 'Subsidiary';
        accountChild.DES_Entity_Type__c = 'Subsidiary';
        accountChild.Merge_Insert__c = true;
        accountChild.DES_ID_Fiscal__c = 'x1234';
        insert accountChild;

        Contact con = UnitTestUtils.GetContact(accountParent.Id);
        insert con;

        final AMH_GBL_Account_Relationship__c relationship = utilClass.createAccRelationship(accountParent, accountChild);
        insert relationship;

        final List<cuco__profitability_sheet__c> profSheets = cuco.Test_Utils.createProfSheet(1, accountParent);
        profSheets[0].cuco__gf_profitability_sheet_id__c = 'ES0182000000010';
        profSheets[0].cuco__gf_prftbly_sheet_end_date__c = Date.newInstance(2199, 31, 12);
        profSheets[0].apply_cond_ind_type__c = 'N';
        insert profSheets;

        final List<cuco__profitability_sheet_participant__c> participants = cuco.Test_Utils.createProfSheetParticipant(1, profSheets[0].Id, new List<Id>{accountChild.Id});
        participants[0].Valid_Participant__c = true;
        insert participants;

        /* create catalog */
        final List<cuco__ps_catalog_family__c> families = cuco.Test_Utils.createPSCatalogFamilies(1);
        insert families;

        final List<cuco__ps_catalog_condition__c> conditions = cuco.Test_Utils.createPSCatalogConditons(2, families[0]);
        insert conditions;

        final List<cuco__ps_catalog_attribute__c> attributes = cuco.Test_Utils.createPSCatalogAttributes(2);
        attributes[0].cuco__gf_psc_bknd_svc_format_type__c = 'RATE';
        attributes[1].cuco__gf_psc_bknd_svc_format_type__c = 'RATE';
        insert attributes;

        final List<cuco__ps_catalog_condition_attribute__c> conditionAttributes = cuco.Test_Utils.createPSCatalogConditonAttributes(2, conditions[0], attributes);
        conditionAttributes[0].cuco__gf_psc_condition_attribute_id__c = 'np.nat.transfer.EEE.ob.branch.type';
        conditionAttributes[1].cuco__gf_psc_condition_attribute_id__c = 'np.SEPA.day.payroll.eur.branch.type';
        conditionAttributes[0].cuco__gf_psc_condition_id__c = conditions[0].Id;
        conditionAttributes[1].cuco__gf_psc_condition_id__c = conditions[1].Id;
        insert conditionAttributes;

        // Flat rates catalog
        final List<cuco__ps_catalog_flat_rates_account__c> lstPsCatFlatRatesAccPicasso = cuco.Test_Utils.createPSCatFlatRatesAcc();
        insert lstPsCatFlatRatesAccPicasso;

        // Create Profitability Sheet Conditions
        final List<cuco__profitability_sheet_condition__c> psCondition1 = cuco.Test_Utils.createProfSheetConditons(1, profSheets[0], conditions[0]);
        psCondition1[0].cuco__gf_ps_cond_atrb_srce_type_name__c = '';
        insert psCondition1;

        final List<cuco__profitability_sheet_condition__c> psCondition2 = cuco.Test_Utils.createProfSheetConditons(1, profSheets[0], conditions[1]);
        psCondition2[0].cuco__gf_ps_cond_atrb_srce_type_name__c = 'COMMISSIONS_FLAT';
        insert psCondition2;

        /*template builder config*/
        String objId = String.ValueOf(profSheets[0].Id).Substring(0,3);
        tmpb__TemplateBuilderSettings__c settings = new tmpb__TemplateBuilderSettings__c(Name = 'test', tmpb__Class_Name__c = 'TemplateBuilder_Profsheets', tmpb__Folder__c = 'test', tmpb__Object_Id__c = objId);
        insert settings;

        tmpb__TemplateBuilder__c tmpb = new tmpb__TemplateBuilder__c(Name='test', tmpb__Folder__c='test', tmpb__Subject__c='test', tmpb__Template__c='test');
        insert tmpb;
    }

    private static tmpb__TemplateBuilderSettings__c getSettings(String id) {
        String objId = id.substring(0,3);
        List<tmpb__TemplateBuilderSettings__c> cSettings = [SELECT Name, tmpb__Class_Name__c, tmpb__Object_Id__c, tmpb__Folder__c, tmpb__Title__c from tmpb__TemplateBuilderSettings__c WHERE tmpb__Object_Id__c =:objId];
        return cSettings[0];
    }

    private static String callExtension(String action, String id, Map<String, Object> args) {
        tmpb__TemplateBuilderSettings__c cSettings = getSettings(id);
        String extensionClass = cSettings.tmpb__Class_Name__c;
        Callable extension = (Callable) Type.forName(extensionClass).newInstance();
        Object res = extension.call(action, new Map<String, Object>{'recordId' => id, 'args' => args});
        return JSON.serialize(res);
    }

    @isTest
    static void testIsUserAllowed() {

        Id profSheetId = [SELECT Id, Name, cuco__gf_profitability_sheet_id__c FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1].Id;
        String action = 'isUserAllowed';
        Map<String, Object> args = new Map<String, Object>();

        Test.startTest();
            final String res = (String)callExtension(action, profSheetId, args);
            System.assertEquals(res, 'true', 'Error in TemplateBuilder_ProfSheets_Test - testIsUserAllowed');
        Test.stopTest();
    }

    @isTest
    static void testSendEmail() {

        Id profSheetId = [SELECT Id, Name, cuco__gf_profitability_sheet_id__c FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1].Id;
        String action = 'sendEmail';
        Map<String, Object> args = new Map<String, Object>();

        Test.startTest();
            final String res = (String)callExtension(action, profSheetId, args);
            System.assertEquals(res, 'true', 'Error in TemplateBuilder_ProfSheets_Test - testSendEmail');
        Test.stopTest();
    }

    @isTest
    static void testHandleResult() {

        Id profSheetId = [SELECT Id, Name, cuco__gf_profitability_sheet_id__c FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1].Id;
        String action = 'handleResult';
        Map<String, Object> args = new Map<String, Object>();

        Test.startTest();
            final String res = (String)callExtension(action, profSheetId, args);
            System.assertEquals(res, 'true', 'Error in TemplateBuilder_ProfSheets_Test - testHandleResult');
        Test.stopTest();
    }

    @isTest
    static void testGetContent() {

        Id profSheetId = [SELECT Id, Name, cuco__gf_profitability_sheet_id__c FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1].Id;
        String action = 'getContent';
        Map<String, Object> args = new Map<String, Object>();

        Test.startTest();
            tmpb__TemplateBuilderSettings__c cSettings = getSettings(profSheetId);
            String extensionClass = cSettings.tmpb__Class_Name__c;
            Callable extension = (Callable) Type.forName(extensionClass).newInstance();
            tmpb.TemplateBuilder.TemplateBuilderContent res = (tmpb.TemplateBuilder.TemplateBuilderContent)extension.call(action, new Map<String, Object>{'recordId' => profSheetId, 'args' => args});
            List<tmpb.TemplateBuilder.TemplateBuilderContentCategory> categories = res.categories;
            List<tmpb.TemplateBuilder.TemplateBuilderContentItem> items = categories[0].items;
            System.assertEquals('Condition 0', items[0].title, 'Error in TemplateBuilder_ProfSheets_Test - testGetContent');
        Test.stopTest();
    }

    @isTest
    static void getRecipients() {

        Id profSheetId = [SELECT Id, Name, cuco__gf_profitability_sheet_id__c FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1].Id;
        String action = 'getRecipients';
        Map<String, Object> args = new Map<String, Object>();

        Test.startTest();
            tmpb__TemplateBuilderSettings__c cSettings = getSettings(profSheetId);
            String extensionClass = cSettings.tmpb__Class_Name__c;
            Callable extension = (Callable) Type.forName(extensionClass).newInstance();
            tmpb.TemplateBuilder.TemplateBuilderContent res = (tmpb.TemplateBuilder.TemplateBuilderContent)extension.call(action, new Map<String, Object>{'recordId' => profSheetId, 'args' => args});
            List<tmpb.TemplateBuilder.TemplateBuilderContentCategory> categories = res.categories;
            List<tmpb.TemplateBuilder.TemplateBuilderContentItem> items = categories[1].items;
            String resEmail = items[0].value;
            System.assertEquals('@test.comm', resEmail.right(10), 'Error in TemplateBuilder_ProfSheets_Test - getRecipients');
        Test.stopTest();
    }

    @isTest
    static void renderContent() {

        Id profSheetId = [SELECT Id, Name, cuco__gf_profitability_sheet_id__c FROM cuco__profitability_sheet__c WHERE Name = 'Prof Sheet Test 0' LIMIT 1].Id;
        Id familyId = [SELECT Id FROM cuco__ps_catalog_family__c WHERE cuco__gf_psc_family_id__c = 'FAM0' LIMIT 1].Id;
        Id conditionId = [SELECT Id FROM cuco__ps_catalog_condition__c WHERE cuco__gf_psc_condition_id__c = 'CON0' LIMIT 1].Id;
        Id participantId = [SELECT cuco__participant_id__c FROM cuco__profitability_sheet_participant__c  WHERE cuco__gf_profitability_sheet_id__c =: profSheetId LIMIT 1].cuco__participant_id__c;

        String action = 'renderContent';
        Map<String, Object> selectedMap = new Map<String, Object>{'selectedIds' => new List<String>{familyId + '-' + conditionId, 'flatrates-yes', 'participants-' + participantId}};
        String args = System.JSON.serialize(selectedMap);

        Test.startTest();
            tmpb__TemplateBuilderSettings__c cSettings = getSettings(profSheetId);
            String extensionClass = cSettings.tmpb__Class_Name__c;
            Callable extension = (Callable) Type.forName(extensionClass).newInstance();
            tmpb.TemplateBuilder.TemplateBuilderContent res = (tmpb.TemplateBuilder.TemplateBuilderContent)extension.call(action, new Map<String, Object>{'recordId' => profSheetId, 'args' => args});
            List<tmpb.TemplateBuilder.TemplateBuilderRenderedElement> rendered = res.rendered;
            System.assertEquals(true, rendered[0].value.contains('Family 0'), 'Error in TemplateBuilder_ProfSheets_Test - renderContent');
        Test.stopTest();
    }
}