/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionBankTable_Service
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service class for Arc_Gen_PotitionBankTable_Ctlr.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-11-27 mariohumberto.ramirez.contractor@bbva.com
*             Change the object limits exposure to risk position summary
* |2020-07-27 joseluis.garcia4.contractor@bbva.com
*             Adds method buildNestedData() to build position table row structure.
* -----------------------------------------------------------------------------------------------
*/
global class Arc_Gen_PotitionBankTable_Service implements Arc_Gen_PotitionTable_Interface {
    /**
    * --------------------------------------------------------------------------------------
    * @Description insert TOTAL if is missing
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId - id of the acc has analysis object
    * @return void
    * @example verifyDataInserted(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public Arc_Gen_DataTable getData(Id recordId) {
        final Arc_Gen_DataTable dataJson = new Arc_Gen_DataTable();
        dataJson.columns = Arc_Gen_PotitionBankTable_Service_Helper.getColumns(recordId);
        dataJson.data = Arc_Gen_PotitionBankTable_Service_Helper.getRowsHelper(recordId);
        return dataJson;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description insert TOTAL if is missing
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordId - id of the acc has analysis object
    * @return void
    * @example verifyDataInserted(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static void verifyDataInserted(Id recordId) {
        if (Arc_Gen_Risk_Position_summary_Data.getPositionSummaryData(new List<Id>{recordId}).isEmpty()) {
            Arc_Gen_PotitionBankTable_Service_Helper.insertTotal(recordId);
        }
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Return an Id of an recordType
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param recordTypeDevName - developer name of the record type
    * @return Id of a recordType
    * @example getRecordTypeId(recordTypeDevName)
    * --------------------------------------------------------------------------------------
    **/
    public static String getRecordTypeId(String recordTypeDevName) {
        return (String)Arc_Gen_Risk_Position_summary_Data.getRecordTypeRiskPositionSum(recordTypeDevName);
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Delete a record
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-11-27
    * @param recordId - id of the record to delete
    * @return void
    * @example deleteRecord(recordId)
    * --------------------------------------------------------------------------------------
    **/
    public static void deleteRecord(String recordId) {
        Arc_Gen_Risk_Position_summary_Data.deleteRecord(new List<String>{recordId});
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Builds tree information to be displayed in the position table.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-27
    * @param table - Table information wrapper with the list of rows (no typologies)
    * @return the table information to be displayed (with typologies)
    * --------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_DataTable buildNestedData(Arc_Gen_DataTable table) {
        final List<Arc_Gen_TableRow> rows = table.data;

        // Fetch typologies
        final List<arce__limits_typology__c> typologies = Arc_Gen_LimitsTypologies_Data.getTypologiesData();

        // Arrange rows into parent topologies & orphans.
        final Map<String, List<Arc_Gen_TableRow>> rowsByParTop = new Map<String, List<Arc_Gen_TableRow>>();
        final List<Arc_Gen_TableRow> orphanRows = new List<Arc_Gen_TableRow>();
        for (Arc_Gen_TableRow row : rows) {
            final String typology = row.info.get('typology');
            if (typology == null || typology == '') {
                orphanRows.add(row);
            } else if (rowsByParTop.containsKey(typology)) {
                rowsByParTop.get(typology).add(row);
            } else {
                final List<Arc_Gen_TableRow> rowList = new List<Arc_Gen_TableRow>();
                rowList.add(row);
                rowsByParTop.put(typology, rowList);
            }
        }

        // Create rows for typologies.
        final Map<String, Arc_Gen_TableRow> typoLv1ByCode = new Map<String, Arc_Gen_TableRow>();
        final Map<String, Arc_Gen_TableRow> typoLv2ByCode = new Map<String, Arc_Gen_TableRow>();
        final Map<String, Arc_Gen_TableRow> typologiesByCode = new Map<String, Arc_Gen_TableRow>();
        for (arce__limits_typology__c typology : typologies) {
            final String code = typology.arce__risk_typology_level_id__c;
            final Arc_Gen_TableRow typoRow = new Arc_Gen_TableRow();
            typoRow.name = typology.Name;
            typoRow.product = typology.Name.toUpperCase();
            typoRow.tipology = code;
            typoRow.order = new Map<String, Double>();
            typoRow.order.put('order', typology.arce__Typology_Order__c);
            typoRow.info = new Map<String, String>();
            typoRow.info.put('isTypology', 'true');
            typoRow.info.put('automatic', 'true');
            if (typology.arce__risk_typology_parent_id__c == null) {
                typoLv1ByCode.put(code, typoRow);
            } else {
                typoRow.info.put('typology', typology.arce__risk_typology_parent_id__r.arce__risk_typology_level_id__c);
                typoLv2ByCode.put(code, typoRow);
            }
            typologiesByCode.put(code, typoRow);
        }

        // Build nested tree data.
        final List<Arc_Gen_TableRow> nestedRows = buildTreeRowStructure(typologiesByCode, typoLv1ByCode, typoLv2ByCode, rowsByParTop);
        nestedRows.addAll(orphanRows);

        // Purge empty categories.
        table.data = purgeEmptyCategories(nestedRows);
        return table;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Builds tree structure given the row data from typologies and products.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-27
    * @param typologiesByCode - Map of typology rows indexed by name.
    * @param typoLv1ByCode - Map of level 1 typology rows indexed by name.
    * @param typoLv2ByCode - Map of level 2 typology rows indexed by name.
    * @param rowsByParTop - Map of row lists indexed by parent typology.
    * @return the final list of rows.
    * --------------------------------------------------------------------------------------
    **/
    private static List<Arc_Gen_TableRow> buildTreeRowStructure(Map<String, Arc_Gen_TableRow> typologiesByCode,
            Map<String, Arc_Gen_TableRow> typoLv1ByCode, Map<String, Arc_Gen_TableRow> typoLv2ByCode,
            Map<String, List<Arc_Gen_TableRow>> rowsByParTop) {
        // Build nested tree data.
        final List<Arc_Gen_TableRow> nestedRows = new List<Arc_Gen_TableRow>();

        // Start with level 1 typologies and orphans.
        nestedRows.addAll(typoLv1ByCode.values());

        // Level 2 typologies.
        for (Arc_Gen_TableRow row : typoLv2ByCode.values()) {
            final String parentTypology = row.info.get('typology');
            final Arc_Gen_TableRow parent = typoLv1ByCode.get(parentTypology);
            if (parent.children == null) {
                final List<Arc_Gen_TableRow> children = new List<Arc_Gen_TableRow>();
                children.add(row);
                parent.children = children;
            } else {
                parent.children.add(row);
            }
        }

        // Add general data rows.
        for (String typology : rowsByParTop.keySet()) {
            final List<Arc_Gen_TableRow> children = rowsByParTop.get(typology);
            final Arc_Gen_TableRow typologyRow = typologiesByCode.get(typology);

            if (typologyRow.children == null) {
                typologyRow.children = new List<Arc_Gen_TableRow>();
            }
            typologyRow.children.addAll(children);
        }

        return nestedRows;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Removes empty typology rows from the tree structure.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-27
    * @param rowList - List of rows (each with its own tree structure), potentially with empty
    * typologies.
    * @return the final list of rows.
    * --------------------------------------------------------------------------------------
    **/
    private static List<Arc_Gen_TableRow> purgeEmptyCategories(List<Arc_Gen_TableRow> rowList) {
        final List<Arc_Gen_TableRow> finalList = new List<Arc_Gen_TableRow>();

        for (Arc_Gen_TableRow row : rowList) {
            final Arc_Gen_TableRow purgeResult = purgeCategory(row);
            if (purgeResult != null) {
                finalList.add(purgeResult);
            }
        }

        return finalList;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Removes empty typology rows from the tree structure.
    * --------------------------------------------------------------------------------------
    * @Author   José Luis García   joseluis.garcia4.contractor@bbva.com
    * @Date     Created: 2020-07-27
    * @param row - Row with its own tree structure.
    * @return The same row if it contains useful data, null if the provided row does not contain
    * products.
    * --------------------------------------------------------------------------------------
    **/
    private static Arc_Gen_TableRow purgeCategory(Arc_Gen_TableRow row) {
        Arc_Gen_TableRow returnVal = null;
        if (row.info.get('isTypology') == 'true') {
            if (row.children != null) {
                row.children = purgeEmptyCategories(row.children);
                returnVal = row.children.isEmpty() ? null : row;    //NOSONAR
            }
        } else {
            returnVal = row;
        }
        return returnVal;
    }
}