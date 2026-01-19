/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailBehaviorTable_Helper
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-01-26
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Controller class for Auto retail behavior table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-01-26 eduardoefrain.hernandez.contractor@bbva.com
*             Class Creation
* |2021-02-15 eduardoefrain.hernandez.contractor@bbva.com
*             Added setClassMap method to manage the custom classes and styles of the table
* |2021-03-04 eduardoefrain.hernandez.contractor@bbva.com
*             Added format to decimal and integer values
* |2021-04-15 eduardoefrain.hernandez.contractor@bbva.com
*             Update methods with a lot of parameters to only one data map parameter
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_AutoRetailBehaviorTable_Helper {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param void
    * @return void
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper controller = new Arc_Gen_AutoRetailBehaviorTable_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_AutoRetailBehaviorTable_Helper() {

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the column information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return List of columns information of the autoretail table
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper.getColumns(year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    private static Map<String,String> setClassMap(String key, Object classAttribute) {
        return new Map<String,String> {
            key => (String)classAttribute
        };
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return the column information of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return List of columns information of the autoretail table
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper.getColumns(year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_TableColumns> getColumns(String year1, String year2) {
        final List<Arc_Gen_TableColumns> columns = new List<Arc_Gen_TableColumns>();
        final Map<String, String> boldRow = new Map<String, String> {'fieldName' => 'customCSSClass'};
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'text',
            'fieldName' => 'agencyName',
            'label' => System.Label.Lc_arce_autoRetailTable_Agency,
            'cellAttributes' => setClassMap('class', JSON.serialize(boldRow))

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'text',
            'fieldName' => 'brand',
            'label' => System.Label.Lc_arce_autoRetailTable_Brand,
            'cellAttributes' => setClassMap('alignment', 'left')

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'number',
            'fieldName' => 'agenciesNumber',
            'label' => System.Label.Lc_arce_autoRetailTable_AgenciesNumber,
            'cellAttributes' => setClassMap('class', 'rowAlignmentRight')

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'number',
            'fieldName' => 'totalUnitsYear1',
            'label' => year1,
            'cellAttributes' => setClassMap('class', 'rowAlignmentRight')

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'number',
            'fieldName' => 'totalUnitsYear2',
            'label' => year2,
            'cellAttributes' => setClassMap('class', 'rowAlignmentRight')

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'text',
            'fieldName' => 'stockRotationYear1',
            'label' => year1,
            'cellAttributes' => setClassMap('alignment', 'left')

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'text',
            'fieldName' => 'stockRotationYear2',
            'label' => year2,
            'cellAttributes' => setClassMap('alignment', 'left')

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'currency',
            'fieldName' => 'bankRisk',
            'label' => System.Label.Lc_arce_autoRetailTable_BankRisk,
            'cellAttributes' => setClassMap('class', 'rowAlignmentRight'),
            'typeAttributes' => new Map<String, String> {'maximumFractionDigits' => '2'}

        }));
        columns.add(setColumn(new Map<String, Object> {
            'type' => 'number',
            'fieldName' => 'stockDays',
            'label' => System.Label.Lc_arce_autoRetailTable_StockDays,
            'cellAttributes' => setClassMap('class', 'rowAlignmentRight'),
            'typeAttributes' => new Map<String, String> {'maximumFractionDigits' => '0'}

        }));
        return columns;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a column of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param columnAttributes - Map with the attributes of a column
    * @return column information of the column
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper.setColumn(columnAttributes)
    * --------------------------------------------------------------------------------------
    **/
    private static Arc_Gen_TableColumns setColumn(Map<String, Object> columnAttributes) {

        final Arc_Gen_TableColumns column = new Arc_Gen_TableColumns();
        column.type = (String)columnAttributes.get('type');
        column.fieldName = (String)columnAttributes.get('fieldName');
        column.label = (String)columnAttributes.get('label');
        column.cellAttributes = (Map<String,String>)columnAttributes.get('cellAttributes');
        column.initialWidth = (Integer)columnAttributes.get('initialWidth');
        column.typeAttributes = (Map<String,String>)columnAttributes.get('typeAttributes');
        return column;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a column of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param dataList - List of records to show in the table
    * @param year1 - Selected year 1
    * @param year2 - Selected year 2
    * @return List<Arc_Gen_AutoRetailTableRow> - List of rows to show
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper.getData(dataList, year1, year2)
    * --------------------------------------------------------------------------------------
    **/
    public static List<Arc_Gen_AutoRetailTableRow> getData(Map<String,Object> data) {
        final List<arce__autoretail_behavior_table__c> dataList = (List<arce__autoretail_behavior_table__c>)data.get('dataList');
        final String year1 = (String)data.get('year1');
        final String year2 = (String)data.get('year2');
        final Boolean isExecSummary = (Boolean)data.get('isExecSummary');

        final List<Arc_Gen_AutoRetailTableRow> tableRows = new List<Arc_Gen_AutoRetailTableRow>();
        final Map<String, arce__autoretail_behavior_by_year__c> yearMap = new Map<String, arce__autoretail_behavior_by_year__c>();

        Integer noAganciesTotal = 0; Decimal unitsSoldTotal1 = 0.0; Decimal unitsSoldTotal2 = 0.0; Decimal bankRiskTotal = 0.0;
        for (arce__autoretail_behavior_table__c objRow : dataList) {
            final Arc_Gen_AutoRetailTableRow singleRow = new Arc_Gen_AutoRetailTableRow();
            final Decimal bankRisk = objRow.arce__gf_entity_risk_bal_cur_amount__c;
            final Integer agenciesNumber = Integer.valueOf(objRow.arce__gf_agencies_number__c);
            final Decimal stockDays = objRow.arce__gf_stock_days_number__c;
            singleRow.standardRowId = objRow.Id;
            singleRow.agencyName = objRow.arce__gf_company_name__c;
            singleRow.brand = objRow.arce__gf_vehicle_brand_name__c;
            singleRow.agenciesNumber = agenciesNumber;
            singleRow.sAgenciesNumber = agenciesNumber.format();
            singleRow.bankRisk = bankRisk;
            singleRow.sBankRisk = bankRisk.format();
            singleRow.stockDays = stockDays;
            singleRow.sStockDays = stockDays.format();
            noAganciesTotal += Integer.valueOf(objRow.arce__gf_agencies_number__c);
            bankRiskTotal += objRow.arce__gf_entity_risk_bal_cur_amount__c;
            for (arce__autoretail_behavior_by_year__c objByYear : objRow.arce__Auto_Retail_Behavior_by_Year__r) {
                yearMap.put(objByYear.arce__year_id__c, objByYear);
            }
            final Map<String, Object> dataValid1 = new Map<String, Object>{'record' => yearMap.get(year1), 'year' => year1, 'objRow' => objRow, 'isExecSummary' => isExecSummary};
            final Map<String, Object> dataValid2 = new Map<String, Object>{'record' => yearMap.get(year2), 'year' => year2, 'objRow' => objRow, 'isExecSummary' => isExecSummary};
            final Map<String,Object> valuesByYear = getValuesByYear(validateChildRecord(dataValid1), validateChildRecord(dataValid2));

            final Decimal totalUnitsYear1 = (Decimal)valuesByYear.get('totalUnitsYear1');
            final Decimal totalUnitsYear2 = (Decimal)valuesByYear.get('totalUnitsYear2');

            singleRow.standardYear1Id = (String)valuesByYear.get('standardYear1Id');
            singleRow.standardYear2Id = (String)valuesByYear.get('standardYear2Id');
            singleRow.totalUnitsYear1 = totalUnitsYear1;
            singleRow.sTotalUnitsYear1 = totalUnitsYear1.format();
            singleRow.totalUnitsYear2 = (Decimal)valuesByYear.get('totalUnitsYear2');
            singleRow.sTotalUnitsYear2 = totalUnitsYear2.format();
            singleRow.stockRotationYear1 = (String)valuesByYear.get('stockRotationYear1');
            singleRow.stockRotationYear2 = (String)valuesByYear.get('stockRotationYear2');
            unitsSoldTotal1 += (Decimal)valuesByYear.get('totalUnitsYear1');
            unitsSoldTotal2 += (Decimal)valuesByYear.get('totalUnitsYear2');
            tableRows.add(singleRow);
        }
        tableRows.add(setTotalRow(noAganciesTotal, unitsSoldTotal1, unitsSoldTotal2, bankRiskTotal));
        return tableRows;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a column of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param objByYear1 - Row with the values of the year 1
    * @param objByYear2 - Row with the values of the year 2
    * @return Arc_Gen_AutoRetailTableRow - List of rows to show
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper.getValuesByYear(objByYear1, objByYear2)
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String,Object> getValuesByYear(arce__autoretail_behavior_by_year__c objByYear1, arce__autoretail_behavior_by_year__c objByYear2) {
        Map<String,Object> valuesMap = new Map<String,Object>();
        valuesMap.put('standardYear1Id', objByYear1?.Id);
        valuesMap.put('totalUnitsYear1', objByYear1.arce__gf_prd_typ_sold_units_number__c == null ? 0 : objByYear1.arce__gf_prd_typ_sold_units_number__c);
        valuesMap.put('totalUnitsYear2', objByYear2.arce__gf_prd_typ_sold_units_number__c == null ? 0 : objByYear2.arce__gf_prd_typ_sold_units_number__c);
        valuesMap.put('standardYear2Id', objByYear2?.Id);
        valuesMap.put('stockRotationYear1', objByYear1.arce__gf_stock_rotation_desc__c == null ? '' : objByYear1.arce__gf_stock_rotation_desc__c);
        valuesMap.put('stockRotationYear2', objByYear2.arce__gf_stock_rotation_desc__c == null ? '' : objByYear2.arce__gf_stock_rotation_desc__c);
        return valuesMap;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a column of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param noAganciesTotal - total of agencies
    * @param unitsSoldTotal1 - total of units sold in year 1
    * @param unitsSoldTotal2 - total of units sold in year 1
    * @param bankRiskTotal - total of bank risks
    * @return Arc_Gen_AutoRetailTableRow - List of rows to show
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper.setTotalRow(noAganciesTotal, unitsSoldTotal1, unitsSoldTotal2, bankRiskTotal)
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_AutoRetailTableRow setTotalRow(Integer noAganciesTotal, Decimal unitsSoldTotal1, Decimal unitsSoldTotal2, Decimal bankRiskTotal) {
        final Arc_Gen_AutoRetailTableRow totalRow = new Arc_Gen_AutoRetailTableRow();
        totalRow.agencyName = System.Label.Arc_Gen_Total;
        totalRow.agenciesNumber = noAganciesTotal;
        totalRow.sAgenciesNumber = noAganciesTotal.format();
        totalRow.totalUnitsYear1 = unitsSoldTotal1;
        totalRow.totalUnitsYear2 = unitsSoldTotal2;
        totalRow.sTotalUnitsYear1 = unitsSoldTotal1.format();
        totalRow.sTotalUnitsYear2 = unitsSoldTotal2.format();
        totalRow.bankRisk = bankRiskTotal;
        totalRow.sBankRisk = bankRiskTotal.format();
        totalRow.customCSSClass = 'boldText';
        return totalRow;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description return a column of the table
    * --------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2021-01-26
    * @param data - map with needed data
    * @return arce__autoretail_behavior_by_year__c - List of rows to show
    * @example Arc_Gen_AutoRetailBehaviorTable_Helper.validateChildRecord(record, year, objRow)
    * --------------------------------------------------------------------------------------
    **/
    public static arce__autoretail_behavior_by_year__c validateChildRecord(Map<String, Object> data) {
        final arce__autoretail_behavior_by_year__c record = (arce__autoretail_behavior_by_year__c)data.get('record');
        final String year = (String)data.get('year');
        final arce__autoretail_behavior_table__c objRow = (arce__autoretail_behavior_table__c)data.get('objRow');
        final Boolean isExecSummary = (Boolean)data.get('isExecSummary');

        arce__autoretail_behavior_by_year__c childRecord = new arce__autoretail_behavior_by_year__c();
        if (record == null) {
            childRecord.arce__autoretail_behavior_table_id__c = objRow.Id;
            childRecord.arce__year_id__c = year;
            if(!isExecSummary) {
                arce.Arc_Gen_GenericUtilities.insertRecords(new List<SObject>{childRecord});
            }
        } else {
            childRecord = record;
        }
        return childRecord;
    }
}