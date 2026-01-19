/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for HPG_UsedTables apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-11-07
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class HPG_UsedTables_Test {
    @isTest
    static void wrapperTest() {
        Test.startTest();
            HPG_UsedTables.Wrapper usedTables = new HPG_UsedTables.Wrapper();
            usedTables.data = new List<HPG_UsedTables.Datac>();
            usedTables.pagination = new HPG_UsedTables.Pagination();
            usedTables.success = true;
            usedTables.errorMessage = 'Error Message';
            HPG_UsedTables.Datac datac = new HPG_UsedTables.Datac();
            datac.data = new List<HPG_UsedTables.Data>();
            HPG_UsedTables.Data data = new HPG_UsedTables.Data();
            data.cutoffDate = '';
            data.entificId = '';
            data.originDataDesc = '';
            data.tblMeEngineNameConcatenationDesc = '';
            data.tableDesc = '';
            data.tableUpdateDateDesc = '';
            datac.data.add(data);
            datac.dateRangeTables = new List<HPG_UsedTables.DateRangeTable>();
            HPG_UsedTables.DateRangeTable dateRangeTable = new HPG_UsedTables.DateRangeTable();
            dateRangeTable.tableDate = '';
            datac.dateRangeTables.add(dateRangeTable);
            HPG_UsedTables.Pagination pagination = new HPG_UsedTables.Pagination();
            pagination.links = new HPG_UsedTables.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 300;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, usedTables.success, 'wrapperTest - Not passed - success');
        Test.stopTest();
    }
}