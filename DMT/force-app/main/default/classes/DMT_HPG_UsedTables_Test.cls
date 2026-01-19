/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class forDMT_HPG_UsedTables apex class
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
public with sharing class DMT_HPG_UsedTables_Test {
@isTest
	static void wrapperTest() {
		Test.startTest();
            DMT_HPG_UsedTables.Wrapper usedTables = new DMT_HPG_UsedTables.Wrapper();
            usedTables.data = new List<DMT_HPG_UsedTables.Datac>();
            usedTables.pagination = new DMT_HPG_UsedTables.Pagination();
            usedTables.success = true;
            usedTables.errorMessage = 'Error Message';
            DMT_HPG_UsedTables.Datac datac = new DMT_HPG_UsedTables.Datac();
            datac.data = new List<DMT_HPG_UsedTables.Data>();
            DMT_HPG_UsedTables.Data data = new DMT_HPG_UsedTables.Data();
            data.cutoffDate = '';
            data.entificId = '';
            data.originDataDesc = '';
            data.tblMeEngineNameConcatenationDesc = '';
            data.tableDesc = '';
            data.tableUpdateDateDesc = '';
            datac.data.add(data);
            datac.dateRangeTables = new List<DMT_HPG_UsedTables.DateRangeTable>();
            DMT_HPG_UsedTables.DateRangeTable dateRangeTable = new DMT_HPG_UsedTables.DateRangeTable();
            dateRangeTable.tableDate = '';
            datac.dateRangeTables.add(dateRangeTable);
            DMT_HPG_UsedTables.Pagination pagination = new DMT_HPG_UsedTables.Pagination();
            pagination.links = new DMT_HPG_UsedTables.Links();
            pagination.links.first = '';
            pagination.links.last = '';
            pagination.links.next = '';
            pagination.links.previous = '';
            pagination.page = 1;
            pagination.pageSize = 100;
            pagination.totalElements = 1;
            pagination.totalPages = 1;
            System.assertEquals(true, usedTables.success, 'wrapperTest - Not passed - success');
		Test.stopTest();
	}
}