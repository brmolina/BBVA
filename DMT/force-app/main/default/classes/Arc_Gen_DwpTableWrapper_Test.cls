/**
* @description Tests for Arc_Gen_DwpTableWrapper wrappers.
*/
@isTest
private class Arc_Gen_DwpTableWrapper_Test {
    /** Constant for column key used in tests */
    static final String COLUMN = 'Column';

    /**
    * @description Validates the controller constructor instantiates successfully.
    */
    @isTest static void testConstructor() {
        Test.startTest();
        final Arc_Gen_DwpTableWrapper_Controller ctrl = new Arc_Gen_DwpTableWrapper_Controller();
        Test.stopTest();

        Assert.isNotNull(ctrl, 'Constructor should create an instance');
    }

    /**
    * @description Validates getHeadersTable returns one row with cells matching the input map.
    */
    @isTest static void testGetHeadersTableColumns() {
        final Map<String, Object> mapCells = new Map<String, Object>{
            'col1' => COLUMN + ' 1',
            'col2' => COLUMN + ' 2'
        };

        Test.startTest();
        final List<Arc_Gen_DwpTableWrapper.Row_Wrapper> headers =
            Arc_Gen_DwpTableWrapper_Controller.getHeadersTable(mapCells);
        Test.stopTest();

        Assert.isTrue(headers.size() == 1 && headers[0].lstCells.size() == 2,
            'getHeadersTable should return one header row with two cells');
    }

    /**
    * @description Validates fillRow creates one data cell when not editable.
    */
    @isTest static void testFillRowNotEditable() {
        final Id rowId = UserInfo.getUserId();
        final Map<String, Object> rowData = new Map<String, Object>{'name' => 'TestRow'};

        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Row_Wrapper row =
            Arc_Gen_DwpTableWrapper_Controller.fillRow(rowId, rowData, false);
        Test.stopTest();

        Assert.isTrue(row != null && row.lstCells.size() == 1,
            'fillRow should create exactly one data cell when not editable');
    }

    /**
    * @description Validates fillRow prepends an edit action cell when editable.
    */
    @isTest static void testFillRowEditable() {
        final Id rowId = UserInfo.getUserId();
        final Map<String, Object> rowData = new Map<String, Object>{'name' => 'TestRow'};

        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Row_Wrapper row =
            Arc_Gen_DwpTableWrapper_Controller.fillRow(rowId, rowData, true);
        Test.stopTest();

        Assert.isTrue(row != null && row.lstCells.size() == 2,
            'fillRow should create two cells (editAction + data) when editable');
    }

    /**
    * @description Validates buildDwpTable returns a wrapper with headers and one data row.
    */
    @isTest static void testBuildDwpTableWithRows() {
        final Id rowId = UserInfo.getUserId();
        final Arc_Gen_DwpTableWrapper_Controller.Configuration_Table config =
            new Arc_Gen_DwpTableWrapper_Controller.Configuration_Table();
        config.mapHeader    = new Map<String, Object>{'col1' => COLUMN + ' 1'};
        config.mapRows      = new Map<Id, Map<String, Object>>{rowId => new Map<String, Object>{'col1' => 'Value 1'}};
        config.editable     = false;
        config.lblEmptyTable = 'No data';

        Test.startTest();
        final Arc_Gen_DwpTableWrapper result =
            Arc_Gen_DwpTableWrapper_Controller.buildDwpTable(config);
        Test.stopTest();

        Assert.isTrue(result != null && result.table != null && result.table.lstRows.size() == 1,
            'buildDwpTable should return a wrapper with exactly one data row');
    }

    /**
    * @description Validates evtSelectRow returns a non-null wrapper updating the selected row.
    */
    @isTest static void testEvtSelectRowUpdatesSelection() {
        final Id rowId = UserInfo.getUserId();
        final Arc_Gen_DwpTableWrapper_Controller.Configuration_Table config =
            new Arc_Gen_DwpTableWrapper_Controller.Configuration_Table();
        config.mapHeader    = new Map<String, Object>{'col1' => COLUMN + ' 1'};
        config.mapRows      = new Map<Id, Map<String, Object>>{rowId => new Map<String, Object>{'col1' => 'Value 1'}};
        config.editable     = true;
        config.lblEmptyTable = 'No data';

        final Arc_Gen_DwpTableWrapper built = Arc_Gen_DwpTableWrapper_Controller.buildDwpTable(config);
        final String jsonSetup = JSON.serialize(built.table);

        Test.startTest();
        final Arc_Gen_DwpTableWrapper result =
            Arc_Gen_DwpTableWrapper_Controller.evtSelectRow(jsonSetup, String.valueOf(rowId));
        Test.stopTest();

        Assert.isTrue(result != null && result.table != null,
            'evtSelectRow should return a non-null wrapper with a table');
    }

    /**
    * @description Validates Dynamic_Table_Wrapper can be instantiated with headers and rows.
    */
    @isTest static void testDynamicTableWrapper() {
        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Dynamic_Table_Wrapper tableWrapper = new Arc_Gen_DwpTableWrapper.Dynamic_Table_Wrapper();
        tableWrapper.lstHeaders = new List<Arc_Gen_DwpTableWrapper.Row_Wrapper>();
        tableWrapper.lstRows = new List<Arc_Gen_DwpTableWrapper.Row_Wrapper>();
        Test.stopTest();

        Assert.isTrue(tableWrapper.lstHeaders != null && tableWrapper.lstRows != null,
            'Both headers and rows lists should be initialized');
    }

    /**
    * @description Validates Row_Wrapper setRowWrapper populates fields.
    */
    @isTest static void testRowWrapperSetRowWrapper() {
        final Arc_Gen_DwpTableWrapper.Cell_Wrapper cell = new Arc_Gen_DwpTableWrapper.Cell_Wrapper();
        cell.idCell = 'cell1';
        cell.valCell = 100;
        cell.lblCell = 'Amount';

        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Row_Wrapper row = new Arc_Gen_DwpTableWrapper.Row_Wrapper();
        row.setRowWrapper('FFSS001', new List<Arc_Gen_DwpTableWrapper.Cell_Wrapper>{cell});
        Test.stopTest();

        Assert.isTrue(row.idRow.equals('FFSS001') && row.lstCells.size() == 1,
            'Row idRow should match the ffssId and contain exactly one cell');
    }

    /**
    * @description Validates Row_Wrapper properties.
    */
    @isTest static void testRowWrapperProperties() {
        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Row_Wrapper row = new Arc_Gen_DwpTableWrapper.Row_Wrapper();
        row.idRow = 'row1';
        row.isHidden = true;
        row.isCollapsed = false;
        row.openCollapsible = true;
        row.lvlGroup = 2;
        row.isTotalRow = true;
        row.lstCells = new List<Arc_Gen_DwpTableWrapper.Cell_Wrapper>();
        Test.stopTest();

        Assert.isTrue(row.isHidden && row.isTotalRow && row.lvlGroup == 2,
            'Row should be hidden, a total row, and have level group 2');
    }

    /**
    * @description Validates Cell_Wrapper empty constructor.
    */
    @isTest static void testCellWrapperEmptyConstructor() {
        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Cell_Wrapper cell = new Arc_Gen_DwpTableWrapper.Cell_Wrapper();
        cell.idCell = 'testCell';
        cell.valCell = 'testValue';
        cell.lblCell = 'Test Label';
        Test.stopTest();

        Assert.areEqual('testCell', cell.idCell, 'Cell id should match');
    }

    /**
    * @description Validates Cell_Wrapper parameterized constructor.
    */
    @isTest static void testCellWrapperParameterizedConstructor() {
        final Arc_Gen_DwpTableWrapper.TypeCell_Wrapper typeCell = new Arc_Gen_DwpTableWrapper.TypeCell_Wrapper();
        typeCell.type = 'number';
        typeCell.align = 'right';

        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Cell_Wrapper cell = new Arc_Gen_DwpTableWrapper.Cell_Wrapper('cellId', 42, typeCell);
        Test.stopTest();

        Assert.isTrue(cell.idCell.equals('cellId') && cell.valCell.equals(42),
            'Cell idCell should be cellId and valCell should be 42');
    }

    /**
    * @description Validates TypeCell_Wrapper properties.
    */
    @isTest static void testTypeCellWrapper() {
        Test.startTest();
        final Arc_Gen_DwpTableWrapper.TypeCell_Wrapper typeCell = new Arc_Gen_DwpTableWrapper.TypeCell_Wrapper();
        typeCell.type = 'currency';
        typeCell.align = 'right';
        typeCell.colspan = 2;
        typeCell.maximumFractionDigits = 4;
        typeCell.currencyDisplayAs = 'symbol';
        typeCell.currencyCode = 'USD';
        typeCell.href = '/test';
        typeCell.lstAction = new List<Arc_Gen_DwpTableWrapper.Action_Wrapper>();
        Test.stopTest();

        Assert.isTrue(typeCell.type.equals('currency') && typeCell.colspan == 2 && typeCell.currencyCode.equals('USD'),
            'Type should be currency, colspan should be 2, and currency code should be USD');
    }

    /**
    * @description Validates Action_Wrapper empty constructor.
    */
    @isTest static void testActionWrapperEmptyConstructor() {
        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Action_Wrapper action = new Arc_Gen_DwpTableWrapper.Action_Wrapper();
        action.lblAction = 'Edit';
        action.txtAction = 'edit-action';
        action.actionType = 'button';
        action.componentName = 'c:EditComponent';
        Test.stopTest();

        Assert.areEqual('Edit', action.lblAction, 'Label should match');
    }

    /**
    * @description Validates Action_Wrapper parameterized constructor.
    */
    @isTest static void testActionWrapperParameterizedConstructor() {
        Test.startTest();
        final Arc_Gen_DwpTableWrapper.Action_Wrapper action = new Arc_Gen_DwpTableWrapper.Action_Wrapper(
            'View', 'view-action', 'link', 'c:ViewComponent'
        );
        Test.stopTest();

        Assert.isTrue(
            action.lblAction.equals('View') &&
            action.txtAction.equals('view-action') &&
            action.actionType.equals('link') &&
            action.componentName.equals('c:ViewComponent'),
            'All Action_Wrapper properties should match the expected values'
        );
    }
}