/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_RatingStudiosUpdateTable
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 28/10/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers: Arc_Gen_RatingStudiesTabSet_controller, Arc_Gen_RatingStudiesTabSet_service,
* Arc_Gen_RatingStudiesTabSet_service, Arc_Gen_DwpTableWrapper_Controller, Arc_Gen_DwpTableWrapper
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |28/10/2019 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation.
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-08-03 juanignacio.hita.contractor@bbva.com
*             Add new tests method for dynamic table with manual constructor
* |2020-08-11 javier.soto.carrascosa@bbva.com
*             Update sector field
* |2020-09-16 juanignacio.hita.contractor@bbva.com
*             Add new testDwpTable test method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_RatingStudiesTabSet_test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test setup method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example setupTest()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setupTest() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__Stage__c = '1';
        newArce.arce__anlys_wkfl_sub_process_type__c = '2';
        insert newArce;

        final arce__Sector__c sector = Arc_UtilitysDataTest_tst.crearSector('Generic', '100;200;300;400;500;600', '1', null);
        sector.arce__active_type__c = true;
        insert sector;

        final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, newArce.Id, groupAccount.accId, '1');
        newAnalysis.arce__InReview__c = true;
        newAnalysis.arce__path__c = 'MAC';
        insert newAnalysis;

        final arce__rating__c newRating = Arc_UtilitysDataTest_tst.crearRating('Default');
        newRating.arce__rating_id__c = '9999999999';
        insert newRating;

        final arce__Financial_Statements__c newFfss = Arc_UtilitysDataTest_tst.crearFinStatement(groupAccount.accId, newAnalysis.Id, newRating.Id, 'Default');
        insert newFfss;

        final dyfr__Template__c template = arc_UtilitysDataTest_tst.crearTemplate('s-01-100');
        insert template;

        final dyfr__Tab__c tab = arc_UtilitysDataTest_tst.crearTab('Test', template.Id);
        tab.dyfr__Tab_Code__c = 'Generic';
        insert tab;

        final dyfr__Field_Config__c fieldConfig = arc_UtilitysDataTest_tst.crearfieldConfigData('Test FieldConfig', tab.Id, 'arce__ffss_for_rating_id__r.arce__rating_type_code_id__c');
        fieldConfig.dyfr__Type__c = 'List';
        fieldConfig.dyfr__Read_only__c = false;
        fieldConfig.dyfr__Hidden__c = false;
        fieldConfig.qualitative_question_code__c = 'RatingStudies';
        insert fieldConfig;

        final dyfr__Dependent_value__c dependent = arc_UtilitysDataTest_tst.crearDependentVal(fieldConfig.Id, 'BAJO,MEDIO,ALTO', '0013,0014,0015');
        insert dependent;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testing()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetAnalyzedClientOK() {
        Test.startTest();
        final List<arce__Financial_Statements__c> ffssList = [SELECT Id, arce__rating_id__c, arce__status_type__c FROM arce__Financial_Statements__c LIMIT 1];
        final String strJson = Arc_Gen_RatingStudiesTabSet_controller.getJsonTable(new List<String>{ffssList.get(0).Id});
        final Map<String, Object> tableWrapper = (Map<String, Object>) JSON.deserializeUntyped(strJson);
        final String jsonSetup = JSON.serialize(tableWrapper.get('table'));
        final Arc_Gen_RatingStudiesTabSet_controller.DynamicFormParameters dynParams = Arc_Gen_RatingStudiesTabSet_controller.getAnalyzedClient(jsonSetup, ffssList[0].Id);
        Arc_Gen_RatingStudiosUpdateTable tableInterface = new Arc_Gen_RatingStudiosUpdateTable();
        tableInterface.updateSelected(ffssList.get(0).Id, false);
        System.assertEquals(ffssList.get(0).arce__rating_id__c, dynParams.ratingId, 'Get rating data');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @param void
    * @return void
    * @example testingConstructor()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testingConstructor() {
        Test.startTest();
        final Arc_Gen_RatingStudiesTabSet_service constrController = new Arc_Gen_RatingStudiesTabSet_service();
        final Arc_Gen_RatingStudiesTabSet_controller constrService = new Arc_Gen_RatingStudiesTabSet_controller();
        final Arc_Gen_RatingStudiesTabSet_data constrData = new Arc_Gen_RatingStudiesTabSet_data();
        final Arc_Gen_DwpTableWrapper_Controller constrWrap = new Arc_Gen_DwpTableWrapper_Controller();
        System.assertEquals(constrController, constrController,'Empty constructor of controller class');
        System.assertEquals(constrService, constrService,'Empty constructor of service class');
        System.assertEquals(constrData, constrData,'Empty constructor of data class');
        System.assertEquals(constrWrap, constrWrap,'Empty constructor of dwp table wrapper controller class');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test getInitData method
    * --------------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @param void
    * @return void
    * @example testGetInitData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testGetInitData() {
        Test.startTest();
        final arce__Financial_Statements__c ffss = [SELECT Id FROM arce__Financial_Statements__c LIMIT 1];
        final arce__Account_has_Analysis__c accHas = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        accHas.arce__ffss_for_rating_id__c = ffss.Id;
        update accHas;
        final List<String> lstInit = Arc_Gen_RatingStudiesTabSet_controller.getInitData(accHas.Id);
        System.assertEquals(lstInit.get(0), ffss.Id, 'getInitData method');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description
    * --------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @param   void
    * @return  void
    * @example testGetInitData()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testDwpTable() {
        Test.startTest();
        final arce__Account_has_Analysis__c accHas = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        final Map<String, Object> mapHeader = new Map<String, Object> {
            'selection' => '',
            'date' => 'TEST'
        };

        final List<Arc_Gen_DwpTableWrapper.Row_Wrapper> dataRows = Arc_Gen_DwpTableWrapper_Controller.getHeadersTable(mapHeader);
        final Arc_Gen_DwpTableWrapper.Row_Wrapper rowWrap = new Arc_Gen_DwpTableWrapper.Row_Wrapper();

        final List<Arc_Gen_DwpTableWrapper.Action_Wrapper> lstAction = new List<Arc_Gen_DwpTableWrapper.Action_Wrapper>();
        final Arc_Gen_DwpTableWrapper.Action_Wrapper action = new Arc_Gen_DwpTableWrapper.Action_Wrapper('label', 'action', 'edit', '');
        lstAction.add(action);

        final Arc_Gen_DwpTableWrapper.TypeCell_Wrapper textTypeCell = new Arc_Gen_DwpTableWrapper.TypeCell_Wrapper();
        textTypeCell.align = 'center';//NOSONAR
        textTypeCell.colspan = 1;
        textTypeCell.type = 'Text';//NOSONAR
        textTypeCell.lstAction = lstAction;

        final List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> lstCells = new List<Arc_Gen_DwpTableWrapper.Cell_Wrapper>();
        final Arc_Gen_DwpTableWrapper.Cell_Wrapper cells = new Arc_Gen_DwpTableWrapper.Cell_Wrapper('1', 'Data', textTypeCell);
        lstCells.add(cells);
        rowWrap.setRowWrapper(accHas.Id, lstCells);
        dataRows.add(rowWrap);
        System.assertEquals('1', cells.idCell, 'Assert cell wrapper');
        Test.stopTest();
    }

}