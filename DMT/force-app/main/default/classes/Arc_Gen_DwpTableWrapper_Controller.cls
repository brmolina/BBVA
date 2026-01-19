/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_DwpTableWrapper_Controller
* @Author   Juan Ignacio Hita Manso
* @Date     Created: 27/07/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class for create Dynamic Table using DwpTableWrapper
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-07-27 Juan Ignacio Hita Manso
*             Class creation.
* |2020-11-18 Juan Ignacio Hita Manso
*             Adds generic funcionality for building of DWP table wrapper
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_DwpTableWrapper_Controller {
    /*
    * @description Builder configuration table wrapper
    * */
    public class Configuration_Table {
        /*
        * @description Header map with the first row data
        * */
        public Map<String, Object> mapHeader {get;set;}
        /*
        * @description Map with the record if as key and each data map of record
        * */
        public Map<Id, Map<String, Object>> mapRows {get;set;}
        /*
        * @description Editable configuration table
        * */
        public Boolean editable {get;set;}
        /**
        * @Description: Label setting for empty table
        */
        public String lblEmptyTable {get;set;}
    }
    /*------------------------------------------------------------------------------------------------------
    * @description Builder Arc_Gen_DwpTableWrapper_Controller
    * -----------------------------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    27/07/2020
    * @return  Arc_Gen_DwpTableWrapper_Controller
    * @example new Arc_Gen_DwpTableWrapper_Controller()
    * */
    @TestVisible
    private Arc_Gen_DwpTableWrapper_Controller() {}
    /**
    *-------------------------------------------------------------------------------
    * @description Builds DWP table wrapper for instanciate Table Dynamic Table component
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    18/11/2020
    * @param   Configuration_Table configTable - Configuration table wrapper
    * @param   Map<String, Object> mapHeader - Map with the name identifier column as key and Label of each column
    * @param   Map<Id, Map<String, Object>> mapRows - Map with the record id as key and map with the record data
    * @return  Returns a Arc_Gen_DwpTableWrapper
    * @example Arc_Gen_DwpTableWrapper wrap = buildDwpTable(configTable, mapHeader, mapRows);
    **/
    public static Arc_Gen_DwpTableWrapper buildDwpTable(Configuration_Table configTable) {
        final Arc_Gen_DwpTableWrapper tableWrapper = new Arc_Gen_DwpTableWrapper();
        tableWrapper.table = new Arc_Gen_DwpTableWrapper.Dynamic_Table_Wrapper();
        tableWrapper.table.lstHeaders = Arc_Gen_DwpTableWrapper_Controller.getHeadersTable(configTable.mapHeader);
        tableWrapper.table.lstRows = createRowTable(configTable.mapRows, configTable);
        tableWrapper.lblEmptyTable = configTable.lblEmptyTable;
        return tableWrapper;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Create list of row wrapper data from map and config table
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    18/11/2020
    * @param   Map<String, Object> mapHeader - Map with the name identifier column as key and Label of each column
    * @param   Map<Id, Map<String, Object>> mapRows - Map with the record id as key and map with the record data
    * @return  Returns a List<Arc_Gen_DwpTableWrapper.Row_Wrapper>
    * @example List<Arc_Gen_DwpTableWrapper.Row_Wrapper> lst = createRowTable(mapRows, configTable);
    **/
    private static List<Arc_Gen_DwpTableWrapper.Row_Wrapper> createRowTable(Map<Id, Map<String, Object>> mapRows, Configuration_Table configTable) {
        final List<Arc_Gen_DwpTableWrapper.Row_Wrapper> rowsList = new List<Arc_Gen_DwpTableWrapper.Row_Wrapper>();
        for (Id keyId : mapRows.keySet()) {
            rowsList.add(Arc_Gen_DwpTableWrapper_Controller.fillRow(keyId, mapRows.get(keyId), configTable.editable));
        }
        return rowsList;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that creates the header of the table
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    27/07/2020
    * @param   Map<String, Object> mapCells : Map with the data of each cell
    * @return  Returns a list of row wrapper with the headers table
    * @example List<Arc_Gen_DwpTableWrapper.Row_Wrapper> headerRow = getHeadersTable();
    **/
    public static List<Arc_Gen_DwpTableWrapper.Row_Wrapper> getHeadersTable(Map<String, Object> mapCells) { //NOSONAR
        //Generate table header for JSON.
        final List<Arc_Gen_DwpTableWrapper.Row_Wrapper> headerList = new List<Arc_Gen_DwpTableWrapper.Row_Wrapper>();
        final Arc_Gen_DwpTableWrapper.Row_Wrapper rowHeader = new Arc_Gen_DwpTableWrapper.Row_Wrapper();
        final List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> lstCells = new List<Arc_Gen_DwpTableWrapper.Cell_Wrapper>();
        final Arc_Gen_DwpTableWrapper.TypeCell_Wrapper textType = new Arc_Gen_DwpTableWrapper.TypeCell_Wrapper();
        textType.type = 'text';//NOSONAR

        for (String key : mapCells.keySet()) {
            final Arc_Gen_DwpTableWrapper.Cell_Wrapper cell = new Arc_Gen_DwpTableWrapper.Cell_Wrapper(key, mapCells.get(key), textType);
            lstCells.add(cell);
        }
        rowHeader.lstCells = lstCells;
        headerList.add(rowHeader);
        return headerList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that creates a row with the financial statement data
    --------- -----------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    27/07/2020
    * @param   Id recordId : record id object
    * @param   Map<String, Object> mapRatingModel - map with the value and label of model rating
    * @param   Boolean selectRow : activate or desactivate select row funcionality
    * @return  Return a row wrapper
    * @example Arc_Gen_DwpTableWrapper.Row_Wrapper row = fillRow(recordId, mapRows, false);
    **/
    public static Arc_Gen_DwpTableWrapper.Row_Wrapper fillRow(Id recordId, Map<String, Object> mapRows, Boolean selectRow) {
        //Generate table Rows for JSON.
        final Arc_Gen_DwpTableWrapper.Row_Wrapper row = new Arc_Gen_DwpTableWrapper.Row_Wrapper();
        final List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> lstCells = new List<Arc_Gen_DwpTableWrapper.Cell_Wrapper>();
        final Arc_Gen_DwpTableWrapper.TypeCell_Wrapper textTypeCell = new Arc_Gen_DwpTableWrapper.TypeCell_Wrapper();
        textTypeCell.align = 'center';//NOSONAR
        textTypeCell.colspan = 1;
        textTypeCell.type = 'Text';//NOSONAR

        // Add edit action button
        if (selectRow) {
            lstCells.add(editActionCell());
        }
        for (String key : mapRows.keySet()) {
            final Arc_Gen_DwpTableWrapper.Cell_Wrapper cell = new Arc_Gen_DwpTableWrapper.Cell_Wrapper(key, mapRows.get(key), textTypeCell);
            lstCells.add(cell);
        }
        row.setRowWrapper(recordId, lstCells);
        return row;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that update select status of the financial statement on table.
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    05/08/2020
    * @param   String jsonSetup : json setup dwp table manager
    * @param   String ffssSelected : financial statement id selected
    * @return  Returns dwp table wrapper with status select updated
    * @example Arc_Gen_DwpTableWrapper wrapper = getJsonTable(jsonSetup, ffssSelected);
    **/
    public static Arc_Gen_DwpTableWrapper evtSelectRow(String jsonSetup, String ffssSelected) {
        final Map<String, Object> tableWrapper = (Map<String, Object>) JSON.deserializeUntyped(jsonSetup);
        final Arc_Gen_DwpTableWrapper dwpTable = new Arc_Gen_DwpTableWrapper();
        dwpTable.table = new Arc_Gen_DwpTableWrapper.Dynamic_Table_Wrapper();
        dwpTable.table.lstHeaders = createRowsWrapper((List<Object>) tableWrapper.get('lstHeaders'), null);
        dwpTable.table.lstRows = createRowsWrapper((List<Object>) tableWrapper.get('lstRows'), ffssSelected);
        return dwpTable;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that creates edit action row
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    27/07/2020
    * @return  Returns edit action cell wrapper
    * @example Arc_Gen_DwpTableWrapper.Cell_Wrapper cellEdit = editActionCell();
    **/
    private static Arc_Gen_DwpTableWrapper.Cell_Wrapper editActionCell() {
        final Arc_Gen_DwpTableWrapper.TypeCell_Wrapper editActionType = new Arc_Gen_DwpTableWrapper.TypeCell_Wrapper();
        editActionType.type = 'select';
        editActionType.colspan = 1;
        editActionType.align = 'center';
        final Arc_Gen_DwpTableWrapper.Cell_Wrapper editActionCell = new Arc_Gen_DwpTableWrapper.Cell_Wrapper('editAction', false, editActionType);
        return editActionCell;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that mapping json setup to list row wrapper
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    05/08/2020
    * @return  List<Object> lstRowWrapper : list of row wrapper object for mapping
    * @param   String valSelected : financial statement id selected
    * @return  Returns a list of row wrapper with the data mapped
    * @example List<Arc_Gen_DwpTableWrapper.Row_Wrapper> lstRowWrapper = createRowsWrapper(lstRowWrapper, valSelected);
    **/
    private static List<Arc_Gen_DwpTableWrapper.Row_Wrapper> createRowsWrapper(List<Object> lstRowWrapper, String valSelected) {
        final List<Arc_Gen_DwpTableWrapper.Row_Wrapper> rowsList = new List<Arc_Gen_DwpTableWrapper.Row_Wrapper>();
        for (Integer i = 0; i < lstRowWrapper.size(); i++) {
            final Map<String, Object> mapRows = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(lstRowWrapper[i]));
            final Arc_Gen_DwpTableWrapper.Row_Wrapper row = new Arc_Gen_DwpTableWrapper.Row_Wrapper();
            Boolean selected = false;
            final String idRow = (String) mapRows.get('idRow');
            if (idRow == valSelected && valSelected != null) {
                selected = true;
            }
            row.setRowWrapper(idRow, createCells((List<Object>) mapRows.get('lstCells'), selected));
            rowsList.add(row);
        }
        return rowsList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that mapping json setup to list cell wrapper
    --------------------------------------------------------------------------------
    * @author  juanignacio.hita.contractor@bbva.com
    * @date    05/08/2020
    * @return  List<Object> lstCells : list of cell object for mapping
    * @param   Boolean valSelected   : boolean value select action
    * @return  Returns a list of row wrapper with the data mapped
    * @example List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> lstCells = createCells(lstCells, ffssSelected);
    **/
    private static List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> createCells(List<Object> lstCells, Boolean valSelected) {
        final List<Arc_Gen_DwpTableWrapper.Cell_Wrapper> lstCellsWrapper = new List<Arc_Gen_DwpTableWrapper.Cell_Wrapper>();
        for (Integer i = 0; i < lstCells.size(); i++) {
            final Map<String, Object> mapCell = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(lstCells[i]));
            final Map<String, Object> mapTypeCell = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(mapCell.get('typeCell')));
            final Arc_Gen_DwpTableWrapper.TypeCell_Wrapper typeCell = new Arc_Gen_DwpTableWrapper.TypeCell_Wrapper();
            typeCell.type = (String) mapTypeCell.get('type');
            typeCell.align = (String) mapTypeCell.get('align');
            typeCell.colspan = (Decimal) mapTypeCell.get('colspan');
            typeCell.maximumFractionDigits = (Decimal) mapTypeCell.get('maximumFractionDigits');
            typeCell.currencyDisplayAs = (String) mapTypeCell.get('currencyDisplayAs');
            typeCell.currencyCode = (String) mapTypeCell.get('currencyCode');
            typeCell.href = (String) mapTypeCell.get('href');
            final String idCell = (String) mapCell.get('idCell');
            final Arc_Gen_DwpTableWrapper.Cell_Wrapper cellWrapper = new Arc_Gen_DwpTableWrapper.Cell_Wrapper(idCell, mapCell.get('valCell'), typeCell);
            if (i == 0 && idCell == 'editAction') {
                cellWrapper.valCell = valSelected;
            }
            lstCellsWrapper.add(cellWrapper);
        }
        return lstCellsWrapper;
    }

}