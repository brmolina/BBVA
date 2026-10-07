@isTest
private class DMT_FormattingUtils_Test {

    @isTest
    static void testTableRow1Column_hasFieldTagging() {
        String html = DMT_FormattingUtils.tableRow1column('Label A', 'Value A');
        Assert.isTrue(html.contains('data-dmt-row="field"'), 'Row should be tagged as a field');
        Assert.isTrue(html.contains('data-dmt-label="Label A"'), 'Label should be tagged');
        Assert.isTrue(html.contains('data-dmt-value="true"'), 'Value should be tagged');
    }

    @isTest
    static void testTableRow1ColumnWithHelper_hasFieldTagging() {
        String html = DMT_FormattingUtils.tableRow1columnWithHelper('Label A', 'Helper text', 'Value A');
        Assert.isTrue(html.contains('data-dmt-row="field"'), 'Row should be tagged as a field');
        Assert.isTrue(html.contains('data-dmt-label="Label A"'), 'Label should be tagged');
        Assert.isTrue(html.contains('data-dmt-value="true"'), 'Value should be tagged');
    }

    @isTest
    static void testTableRow2Columns_hasBothPairsTagged() {
        String html = DMT_FormattingUtils.tableRow2columns('Label A', 'Value A', 'Label B', 'Value B');
        Assert.isTrue(html.contains('data-dmt-row="field"'), 'Row should be tagged as a field');
        Assert.isTrue(html.contains('data-dmt-pair="1"'), 'First pair should be tagged');
        Assert.isTrue(html.contains('data-dmt-pair="2"'), 'Second pair should be tagged');
        Assert.isTrue(html.contains('data-dmt-label="Label A"'), 'First label should be tagged');
        Assert.isTrue(html.contains('data-dmt-label="Label B"'), 'Second label should be tagged');
    }

    @isTest
    static void testTableRow2ColumnsNew_emptyRightCell_onlyTagsFirstPair() {
        String html = DMT_FormattingUtils.tableRow2columns_New('Label A', 'Value A', '', '');
        Assert.isTrue(html.contains('data-dmt-pair="1"'), 'First pair should be tagged');
        Assert.isFalse(html.contains('data-dmt-pair="2"'), 'Empty right cell should not be tagged as a pair');
    }

    @isTest
    static void testTableRow2ColumnsNew_populatedRightCell_tagsBothPairs() {
        String html = DMT_FormattingUtils.tableRow2columns_New('Label A', 'Value A', 'Label B', 'Value B');
        Assert.isTrue(html.contains('data-dmt-pair="1"'), 'First pair should be tagged');
        Assert.isTrue(html.contains('data-dmt-pair="2"'), 'Second pair should be tagged');
    }

    @isTest
    static void testTableRow1ColumnCheckbox_hasCheckedState() {
        String htmlChecked = DMT_FormattingUtils.tableRow1column_checkbox('Label A', true);
        Assert.isTrue(htmlChecked.contains('data-dmt-checked="true"'), 'Checked state should be tagged true');

        String htmlUnchecked = DMT_FormattingUtils.tableRow1column_checkbox('Label A', false);
        Assert.isTrue(htmlUnchecked.contains('data-dmt-checked="false"'), 'Checked state should be tagged false');
    }

    @isTest
    static void testTableRow2ColumnsCheckbox_hasBothPairsAndCheckedStates() {
        String html = DMT_FormattingUtils.tableRow2columns_checkbox('Label A', true, 'Label B', false);
        Assert.isTrue(html.contains('data-dmt-pair="1"'), 'First pair should be tagged');
        Assert.isTrue(html.contains('data-dmt-pair="2"'), 'Second pair should be tagged');
        Assert.isTrue(html.contains('data-dmt-checked="true"'), 'First checkbox checked state should be tagged');
        Assert.isTrue(html.contains('data-dmt-checked="false"'), 'Second checkbox checked state should be tagged');
    }

    @isTest
    static void testRenderTrafficLight_red_tagsActiveColorAndTripleMode() {
        String html = DMT_FormattingUtils.renderTrafficLight('RED');
        Assert.isTrue(html.contains('data-dmt-traffic="RED"'), 'Active color should be tagged RED');
        Assert.isTrue(html.contains('data-dmt-traffic-mode="triple"'), 'Mode should be tagged triple');
    }

    @isTest
    static void testRenderTrafficLight_blank_returnsEmptyUntagged() {
        String html = DMT_FormattingUtils.renderTrafficLight('');
        Assert.areEqual('', html, 'Blank color should still render nothing');
    }

    @isTest
    static void testRenderTrafficLight_unrecognizedColor_tagsGrey() {
        String html = DMT_FormattingUtils.renderTrafficLight('PURPLE');
        Assert.isTrue(html.contains('data-dmt-traffic="GREY"'), 'Unrecognized non-blank color should tag GREY (matches the all-grey render)');
    }

    @isTest
    static void testRenderTrafficLightSingle_green_tagsActiveColorAndSingleMode() {
        String html = DMT_FormattingUtils.renderTrafficLightSingle('GREEN');
        Assert.isTrue(html.contains('data-dmt-traffic="GREEN"'), 'Active color should be tagged GREEN');
        Assert.isTrue(html.contains('data-dmt-traffic-mode="single"'), 'Mode should be tagged single');
    }

    @isTest
    static void testGenerateHtmlTable_tagsFieldGridAndCells() {
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Label A', 'Value A'),
            new DMT_FormattingUtils.DisplayField('Label B', 'Value B')
        };
        String html = DMT_FormattingUtils.generateHtmlTable(fields);
        Assert.isTrue(html.contains('data-dmt-fieldgrid="true"'), 'Outer table should be tagged as a field grid');
        Assert.isTrue(html.contains('data-dmt-row="field"'), 'Each cell should be tagged as a field');
        Assert.isTrue(html.contains('data-dmt-label="Label A"'), 'First label should be tagged');
        Assert.isTrue(html.contains('data-dmt-label="Label B"'), 'Second label should be tagged');
    }

    @isTest
    static void testRenderHtmlDataTable_tagsRealTableStructure() {
        DMT_FormattingUtils.DataTableWrapper tableData = new DMT_FormattingUtils.DataTableWrapper('Title', new List<String>{'Col1', 'Col2'});
        tableData.rows.add(new List<String>{'A1', 'A2'});
        tableData.rows.add(new List<String>{'B1', 'B2'});

        String html = DMT_FormattingUtils.renderHtmlDataTable(tableData);
        Assert.isTrue(html.contains('data-dmt-table="true"'), 'Outer table should be tagged as a real table');
        Assert.isTrue(html.contains('data-dmt-table-title="true"'), 'Title row should be tagged');
        Assert.isTrue(html.contains('data-dmt-table-header="true"'), 'Header row should be tagged');
        Assert.isTrue(html.contains('data-dmt-header-cell="true"'), 'Header cells should be tagged');
        Assert.isTrue(html.contains('data-dmt-table-row="true"'), 'Data rows should be tagged');
        Assert.isTrue(html.contains('data-dmt-cell="true"'), 'Data cells should be tagged');
    }

    @isTest
    static void testRenderHtmlDataTable_emptyRows_rendersNothing() {
        DMT_FormattingUtils.DataTableWrapper tableData = new DMT_FormattingUtils.DataTableWrapper('Title', new List<String>{'Col1'});
        String html = DMT_FormattingUtils.renderHtmlDataTable(tableData);
        Assert.areEqual('', html, 'Empty rows should still render nothing, unaffected by tagging changes');
    }

    @isTest
    static void testCheckNull_nullReturnsEmpty() {
        Assert.areEqual('', DMT_FormattingUtils.checkNull(null), 'Null object should return empty string.');
    }

    @isTest
    static void testCheckNull_literalNullStringReturnsEmpty() {
        Assert.areEqual('', DMT_FormattingUtils.checkNull('null'), 'String "null" should return empty string.');
    }

    @isTest
    static void testCheckNull_dateFormatsLocally() {
        Date d = Date.newInstance(2026, 7, 30);
        String result = DMT_FormattingUtils.checkNull(d);
        Assert.isTrue(result.contains('2026') || result.contains('7') || result.contains('30'), 'Date should be formatted.');
        Assert.isTrue(String.isNotBlank(result), 'Date checkNull should return a non-blank string.');
    }

    @isTest
    static void testCheckNull_datetimeFormatsYmd() {
        Datetime dt = Datetime.newInstance(2026, 7, 30, 10, 0, 0);
        String result = DMT_FormattingUtils.checkNull(dt);
        Assert.isTrue(result.startsWith('2026-07-30'), 'Datetime checkNull should format as yyyy-MM-dd.');
    }

    @isTest
    static void testCheckNull_stringPassthrough() {
        Assert.areEqual('Hello', DMT_FormattingUtils.checkNull('Hello'), 'Non-null string should pass through unchanged.');
    }

    @isTest
    static void testTraductorDate_blank() {
        Assert.areEqual(' ', DMT_FormattingUtils.traductorDate(''), 'Blank input should return single space.');
    }

    @isTest
    static void testTraductorDate_days() {
        Assert.areEqual('10D', DMT_FormattingUtils.traductorDate('10'), 'Values under 30 should be formatted as days.');
    }

    @isTest
    static void testTraductorDate_months() {
        Assert.areEqual('2M', DMT_FormattingUtils.traductorDate('60'), '60 days should be formatted as 2M.');
    }

    @isTest
    static void testTraductorDate_years() {
        Assert.areEqual('2Y', DMT_FormattingUtils.traductorDate('730'), '730 days should be formatted as 2Y.');
    }

    @isTest
    static void testTraductorDate_18months() {
        Assert.areEqual('18M', DMT_FormattingUtils.traductorDate('548'), '548 days is the special 18M exception.');
    }

    @isTest
    static void testTraductorDate_nonNumericReturnsSpace() {
        Assert.areEqual(' ', DMT_FormattingUtils.traductorDate('abc'), 'Non-numeric input should return single space.');
    }

    @isTest
    static void testGetWarrantyNamesAsString_nullList() {
        Assert.areEqual('', DMT_FormattingUtils.getWarrantyNamesAsString(null), 'Null warranty list should return empty string.');
    }

    @isTest
    static void testGetWarrantyNamesAsString_emptyList() {
        Assert.areEqual('', DMT_FormattingUtils.getWarrantyNamesAsString(new List<DMT_Warranty__c>()), 'Empty list should return empty string.');
    }

    @isTest
    static void testGetWarrantyNamesAsString_multipleWarranties() {
        List<DMT_Warranty__c> warranties = new List<DMT_Warranty__c>{
            new DMT_Warranty__c(Name = 'WarrantyA'),
            new DMT_Warranty__c(Name = 'WarrantyB')
        };
        String result = DMT_FormattingUtils.getWarrantyNamesAsString(warranties);
        Assert.isTrue(result.contains('WarrantyA'), 'Result should include first warranty name.');
        Assert.isTrue(result.contains('WarrantyB'), 'Result should include second warranty name.');
    }

    @isTest
    static void testConvertValue_null() {
        Assert.areEqual(0, DMT_FormattingUtils.convertValue(null), 'Null should convert to 0.');
    }

    @isTest
    static void testConvertValue_decimal() {
        Assert.areEqual(1.5, DMT_FormattingUtils.convertValue(1.5), 'Decimal should pass through.');
    }

    @isTest
    static void testConvertValue_long() {
        Assert.areEqual(100, DMT_FormattingUtils.convertValue(100L), 'Long should convert to decimal.');
    }

    @isTest
    static void testToSafeMultilineHtml_preservesLineBreaks() {
        String html = DMT_FormattingUtils.toSafeMultilineHtml('Line 1\nLine 2\r\nLine 3');
        Assert.isTrue(html.contains('Line 1<br/>Line 2<br/>Line 3'), 'Manual line breaks should still be converted to <br/> tags.');
    }

    @isTest
    static void testToSafeMultilineHtml_insertsSoftBreaksForLongRuns() {
        String longWord = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
        String html = DMT_FormattingUtils.toSafeMultilineHtml(longWord);
        Assert.isTrue(html.contains('<wbr/>'), 'Long uninterrupted runs should include soft break opportunities for PDF rendering.');
        Assert.areEqual(longWord, html.replace('<wbr/>', ''), 'Soft break markup should not alter the visible text content.');
    }

    @isTest
    static void testToSafeMultilineHtml_preservesEscapedEntities() {
        String html = DMT_FormattingUtils.toSafeMultilineHtml('Tom & Jerry <Cartoon>');
        Assert.isTrue(html.contains('Tom &amp; Jerry &lt;Cartoon&gt;'), 'HTML-sensitive characters should remain escaped.');
    }

    @isTest
    static void testConvertValue_string() {
        Assert.areEqual(42, DMT_FormattingUtils.convertValue('42'), 'Numeric string should convert to decimal.');
    }

    @isTest
    static void testFormatDecimalAbbreviation_millions() {
        Assert.isTrue(DMT_FormattingUtils.formatDecimalAbbreviation(2500000).contains('M'), 'Millions should use M suffix.');
    }

    @isTest
    static void testFormatDecimalAbbreviation_thousands() {
        Assert.isTrue(DMT_FormattingUtils.formatDecimalAbbreviation(1500).contains('K'), 'Thousands should use K suffix.');
    }

    @isTest
    static void testFormatDecimalAbbreviation_below1000() {
        String result = DMT_FormattingUtils.formatDecimalAbbreviation(500);
        Assert.isFalse(result.contains('K') || result.contains('M'), 'Values below 1000 should have no suffix.');
    }

    @isTest
    static void testFormatDecimalAbbreviation_null() {
        Assert.areEqual('0', DMT_FormattingUtils.formatDecimalAbbreviation(null), 'Null should return "0".');
    }

    @isTest
    static void testFormatDecimalAbbreviation_negative() {
        Assert.isTrue(DMT_FormattingUtils.formatDecimalAbbreviation(-2000000).startsWith('-'), 'Negative millions should start with -.');
    }

    @isTest
    static void testFormatPercent_null() {
        Assert.areEqual('0.00 %', DMT_FormattingUtils.formatPercent(null), 'Null should return 0.00 %.');
    }

    @isTest
    static void testFormatPercent_decimal() {
        Assert.isTrue(DMT_FormattingUtils.formatPercent(0.5).contains('50.00'), 'Decimal 0.5 should format as 50.00 %.');
    }

    @isTest
    static void testFormatBps_null() {
        Assert.areEqual('0.000 bps', DMT_FormattingUtils.formatBps(null), 'Null should return 0.000 bps.');
    }

    @isTest
    static void testFormatBps_decimal() {
        String result = DMT_FormattingUtils.formatBps(1.5);
        Assert.isTrue(result.contains('bps'), 'Result should contain bps suffix.');
    }

    @isTest
    static void testBooleanToYesNo_true() {
        Assert.areEqual('Yes', DMT_FormattingUtils.booleanToYesNo(true), 'true should return Yes.');
    }

    @isTest
    static void testBooleanToYesNo_false() {
        Assert.areEqual('No', DMT_FormattingUtils.booleanToYesNo(false), 'false should return No.');
    }

    @isTest
    static void testBooleanToYesNo_null() {
        Assert.areEqual('No', DMT_FormattingUtils.booleanToYesNo(null), 'null should return No.');
    }

    @isTest
    static void testFormatDecimalEs_null() {
        Assert.areEqual('', DMT_FormattingUtils.formatDecimalEs(null, 2), 'Null should return empty string.');
    }

    @isTest
    static void testFormatDecimalEs_standard() {
        String result = DMT_FormattingUtils.formatDecimalEs(1234.56, 2);
        Assert.isTrue(result.contains('1.234'), 'Integer part should use period as thousands separator.');
        Assert.isTrue(result.contains(','), 'Decimal separator should be a comma.');
    }

    @isTest
    static void testFormatDecimalEs_small() {
        String result = DMT_FormattingUtils.formatDecimalEs(5.0, 2);
        Assert.isTrue(result.contains('5'), 'Small value should format correctly.');
    }

    @isTest
    static void testChangeDateFormat_blank() {
        Assert.areEqual('', DMT_FormattingUtils.changeDateFormat(null), 'Null date should return empty string.');
    }

    @isTest
    static void testChangeDateFormat_validDate() {
        String result = DMT_FormattingUtils.changeDateFormat(Date.newInstance(2026, 7, 30));
        Assert.isTrue(result.contains('2026'), 'Formatted date should contain the year.');
        Assert.isTrue(result.contains('Jul'), 'Formatted date should contain the month abbreviation.');
    }

    @isTest
    static void testGetListMap_nullList() {
        Map<String, Object> feature = new Map<String, Object>{'items' => null};
        List<Map<String, Object>> result = DMT_FormattingUtils.getListMap(feature, 'items');
        Assert.isTrue(result.isEmpty(), 'Null list should return an empty list.');
    }

    @isTest
    static void testGetListMap_withEntries() {
        Map<String, Object> feature = new Map<String, Object>{
            'items' => new List<Object>{ new Map<String, Object>{'key' => 'val'} }
        };
        List<Map<String, Object>> result = DMT_FormattingUtils.getListMap(feature, 'items');
        Assert.areEqual(1, result.size(), 'Should return one entry.');
        Assert.areEqual('val', result[0].get('key'), 'Entry content should be preserved.');
    }

    @isTest
    static void testCreateTrafficLightJson_oneCircleRed() {
        Map<String, Object> result = DMT_FormattingUtils.createTrafficLightJson('RED', 'ONE');
        Assert.isNotNull(result, 'ONE-circle RED should return a non-null map.');
        Assert.areEqual('custom', result.get('type'), 'Type should be custom.');
    }

    @isTest
    static void testCreateTrafficLightJson_threeCircleGreen() {
        Map<String, Object> result = DMT_FormattingUtils.createTrafficLightJson('GREEN', 'THREE');
        Assert.isNotNull(result, 'THREE-circle GREEN should return a non-null map.');
        Assert.areEqual('custom', result.get('type'), 'Type should be custom.');
    }

    @isTest
    static void testCreateTrafficLightJson_threeCircleUnrecognized() {
        Map<String, Object> result = DMT_FormattingUtils.createTrafficLightJson('PURPLE', 'THREE');
        Assert.isNotNull(result, 'THREE-circle with unrecognized color should return the white/blank map.');
    }

    @isTest
    static void testGenerateHtmlTable_fullSizeField() {
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Full Label', 'Full Value', 'FULL')
        };
        String html = DMT_FormattingUtils.generateHtmlTable(fields);
        Assert.isTrue(html.contains('Full Label'), 'FULL size field should be rendered.');
        Assert.isTrue(html.contains('colspan="4"'), 'FULL size should use colspan 4.');
    }

    @isTest
    static void testGenerateHtmlTable_booleanField() {
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Check Me', true)
        };
        String html = DMT_FormattingUtils.generateHtmlTable(fields);
        Assert.isTrue(html.contains('checkbox'), 'Boolean DisplayField should render as a checkbox.');
        Assert.isTrue(html.contains('checked'), 'True boolean should render checked checkbox.');
    }

    @isTest
    static void testGenerateHtmlTable_rowWrapping() {
        List<DMT_FormattingUtils.DisplayField> fields = new List<DMT_FormattingUtils.DisplayField>{
            new DMT_FormattingUtils.DisplayField('Field A', 'Val A'),
            new DMT_FormattingUtils.DisplayField('Field B', 'Val B'),
            new DMT_FormattingUtils.DisplayField('Field C', 'Val C')
        };
        String html = DMT_FormattingUtils.generateHtmlTable(fields);
        Assert.isTrue(html.contains('Field A'), 'Field A should be rendered.');
        Assert.isTrue(html.contains('Field C'), 'Field C should be rendered.');
    }

    @isTest
    static void testRenderHtmlDataTable_withCustomWidth() {
        DMT_FormattingUtils.DataTableWrapper tableData = new DMT_FormattingUtils.DataTableWrapper('Title', new List<String>{'Col1'}, '50%');
        tableData.rows.add(new List<String>{'Value1'});
        String html = DMT_FormattingUtils.renderHtmlDataTable(tableData);
        Assert.isTrue(html.contains('50%'), 'Custom width should appear in the table HTML.');
    }

    @isTest
    static void testCheckNull_DateObject() {
        Date d = Date.newInstance(2026, 3, 15);
        String result = DMT_FormattingUtils.checkNull(d);
        Assert.isNotNull(result, 'checkNull on a Date must return a non-null string.');
        Assert.isTrue(result.contains('2026'), 'checkNull on a Date must include the year.');
    }

    @isTest
    static void testChangeDateFormat_InvalidString() {
        String result = DMT_FormattingUtils.changeDateFormat('not-a-valid-date');
        Assert.isNotNull(result, 'changeDateFormat with invalid input must not return null.');
        Assert.isTrue(result.equals('not-a-valid-date') || result.equals(''),
            'Invalid date input should fall back to original string or empty.');
    }

    @isTest
    static void testCreateTrafficLightJson_YellowColor() {
        Map<String, Object> result = DMT_FormattingUtils.createTrafficLightJson('YELLOW', 'ONE');
        Assert.isNotNull(result, 'createTrafficLightJson YELLOW/ONE must return a non-null map.');
    }

    @isTest
    static void testCreateTrafficLightJson_GreenColor() {
        Map<String, Object> result = DMT_FormattingUtils.createTrafficLightJson('GREEN', 'ONE');
        Assert.isNotNull(result, 'createTrafficLightJson GREEN/ONE must return a non-null map.');
    }

    @isTest
    static void testCreateTrafficLightJson_OneCircleUnrecognizedColor() {
        Map<String, Object> result = DMT_FormattingUtils.createTrafficLightJson('GREY', 'ONE');
        Assert.isNotNull(result, 'ONE-circle with unrecognized color should return the grey/blank map.');
    }

    @isTest
    static void testGetWorkflowColor_noTasks_returnsNopintar() {
        Map<String, Object> feature = new Map<String, Object>{'id' => 'f1'};
        String color = DMT_FormattingUtils.getWorkflowColor(feature, new List<DMT_Case_Steps_Controller.WRAPPER_Step>());
        Assert.areEqual('NOPINTAR', color, 'Feature without tasks must return NOPINTAR.');
    }

    @isTest
    static void testGetWorkflowColor_emptyTaskList_returnsNopintar() {
        Map<String, Object> feature = new Map<String, Object>{'id' => 'f1', 'tasks' => new List<Object>()};
        String color = DMT_FormattingUtils.getWorkflowColor(feature, new List<DMT_Case_Steps_Controller.WRAPPER_Step>());
        Assert.areEqual('NOPINTAR', color, 'Feature with empty tasks list must return NOPINTAR.');
    }

    @isTest
    static void testGetWorkflowColor_withTasksNoMatchingStep_returnsYellow() {
        Map<String, Object> feature = new Map<String, Object>{
            'id' => 'f1',
            'tasks' => new List<Object>{ new Map<String, Object>{'id' => 'task1'} }
        };
        String color = DMT_FormattingUtils.getWorkflowColor(feature, new List<DMT_Case_Steps_Controller.WRAPPER_Step>());
        Assert.areEqual('YELLOW', color, 'Feature with tasks but no matching step must return YELLOW.');
    }

    @isTest
    static void testCreateTitleWithCircles_green() {
        List<Object> result = DMT_FormattingUtils.createTitleWithCircles('Test Title', 'GREEN');
        Assert.isNotNull(result, 'createTitleWithCircles must return a non-null list.');
        Assert.isTrue(!result.isEmpty(), 'createTitleWithCircles must return a non-empty list.');
    }

    @isTest
    static void testCreateTitleWithCircles_red() {
        List<Object> result = DMT_FormattingUtils.createTitleWithCircles('Title Red', 'RED');
        Assert.isNotNull(result, 'createTitleWithCircles RED must return a non-null list.');
    }

    @isTest
    static void testCreateTitleWithCircles_yellow() {
        List<Object> result = DMT_FormattingUtils.createTitleWithCircles('Title Yellow', 'YELLOW');
        Assert.isNotNull(result, 'createTitleWithCircles YELLOW must return a non-null list.');
    }

    @isTest
    static void testFormatObjectAbbreviation_millions() {
        String result = DMT_FormattingUtils.formatObjectAbbreviation(2500000);
        Assert.isTrue(result.contains('M'), 'Millions should use M suffix.');
    }

    @isTest
    static void testFormatObjectAbbreviation_thousands() {
        String result = DMT_FormattingUtils.formatObjectAbbreviation(1500);
        Assert.isTrue(result.contains('K'), 'Thousands should use K suffix.');
    }

    @isTest
    static void testFormatObjectAbbreviation_small() {
        String result = DMT_FormattingUtils.formatObjectAbbreviation(500);
        Assert.isFalse(result.contains('K') || result.contains('M'), 'Values below 1000 should have no suffix.');
    }

    @isTest
    static void testFormatObjectAbbreviation_null() {
        String result = DMT_FormattingUtils.formatObjectAbbreviation(null);
        Assert.areEqual('0', result, 'Null value should return 0.');
    }

    @isTest
    static void testFormatObjectAbbreviation_billions() {
        String result = DMT_FormattingUtils.formatObjectAbbreviation(1500000000);
        Assert.isTrue(result.contains('B'), 'Billions should use B suffix.');
    }

    @isTest
    static void testFormatObjectAbbreviation_negative() {
        String result = DMT_FormattingUtils.formatObjectAbbreviation(-2000000);
        Assert.isTrue(result.startsWith('-'), 'Negative millions should start with -.');
    }

    @isTest
    static void testPrintRectTableDetail_red() {
        Map<String, Object> result = DMT_FormattingUtils.printRectTableDetail('#D73F52');
        Assert.isNotNull(result, 'printRectTableDetail must return a non-null map.');
        Assert.areEqual('custom', result.get('type'), 'Type must be custom.');
    }
}