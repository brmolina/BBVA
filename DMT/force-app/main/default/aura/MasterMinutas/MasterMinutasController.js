({
	doInit: function (cmp, event, helper) {

		  helper.getTableData(cmp);

		  cmp.set('v.myColumns', [
				{label: 'Fecha', fieldName: 'nbcDate', type: 'Text', sortable: true},
				{label: 'NBC', fieldName: 'nbcUrl', type: 'url', typeAttributes: { label: { fieldName: 'nbcRegion' } }, sortable: true},
				{label: 'Booking Office', fieldName: 'bookOff', type: 'Text', sortable: true},
				{label: 'Industry', fieldName: 'industry', type: 'Text', sortable: true},
				{label: 'Banker', fieldName: 'banker', type: 'Text', sortable: true},
				{label: 'Borrower', fieldName: 'borrower', type: 'Text', sortable: true},
				{label: 'Nº Operacion', fieldName: 'nOperation', type: 'Text', sortable: true},
				{label: 'Guarantor', fieldName: 'guarantor', type: 'Text', sortable: true},
				{label: 'Group', fieldName: 'groupCliURL', type: 'url', typeAttributes: { label: { fieldName: 'groupClient' } }, sortable: true},
				{label: 'Group Code', fieldName: 'groupCode', type: 'Text', sortable: true},
				{label: 'Country of Management', fieldName: 'countryManage', type: 'Text', sortable: true},
				{label: 'Internal Rating', fieldName: 'intRating', type: 'Text', sortable: true},
				{label: 'Deal Type', fieldName: 'dealType', type: 'Text', sortable: true},
				{label: 'Bilateral/Syndicated', fieldName: 'bilateral', type: 'Text', sortable: true},
				{label: 'Product Area', fieldName: 'productArea', type: 'Text', sortable: true},
				{label: 'Product', fieldName: 'product', type: 'Text', sortable: true},
				{label: 'Currency', fieldName: 'currencyTranch', type: 'Text', sortable: true},
				{label: 'Underwritting', fieldName: 'underwritting', type: 'Text', sortable: true},
				{label: 'Final Take (Mn)', fieldName: 'finalTake', type: 'Text', sortable: true},
				{label: 'Final Take (EUR Mn)', fieldName: 'finalTakeEUR', type: 'Text', sortable: true},
				{label: 'EAD', fieldName: 'EADs', type: 'Text', sortable: true},
				{label: 'New Money EUR', fieldName: 'newMoneyEUR', type: 'Text', sortable: true},
				{label: 'RORC', fieldName: 'rorc', type: 'Text', sortable: true},
				{label: 'RAROEC', fieldName: 'rar', type: 'Text', sortable: true},
				{label: 'Expected RaR', fieldName: 'expectedRar', type: 'Text', sortable: true},
				{label: 'Client\'s Global RAR FY-1', fieldName: 'cibDeskPast', type: 'Text', sortable: true},
				{label: 'Client\'s Global RAR YTD', fieldName: 'cibDeskNow', type: 'Text', sortable: true},
				{label: 'Expected Global RORC CIB w/o X-sell', fieldName: 'rorcCIBSell', type: 'Text', sortable: true},
				{label: 'Expected Global RORC CIB', fieldName: 'rorcCIB', type: 'Text', sortable: true},
				{label: 'Client\'s Global RORC CIB', fieldName: 'clientRorc', type: 'Text', sortable: true},
				{label: 'All-In (drawn)', fieldName: 'allInDrawn', type: 'Text', sortable: true},
				{label: 'All-In (undrawn)', fieldName: 'allInUnDrawn', type: 'Text', sortable: true},
				{label: 'Tenor', fieldName: 'tenor', type: 'Text', sortable: true},
				{label: 'Vida Media', fieldName: 'avgLife', type: 'Text', sortable: true},
				{label: 'Clausula Suelo', fieldName: 'floorClause', type: 'Text', sortable: true},
				{label: 'Syndication Opinion', fieldName: 'syndicationOp', type: 'Text', sortable: true},
				{label: 'Sustainable Deal', fieldName: 'sustainableDeal', type: 'Text', sortable: true},
				{label: 'X-Sell Committee Monitoring', fieldName: 'xSell', type: 'Text', sortable: true},
				{ label: 'X-Sell Committee Review Date', fieldName: 'xSellDate', type: 'Text', sortable: true },
				{label: 'SPPI Test', fieldName: 'sppiTest', type: 'Text', sortable: true},
				{label: 'Sectorial Norm', fieldName: 'sectorialNorm', type: 'Text', sortable: true},
				{label: 'Comments', fieldName: 'comments', type: 'Text', sortable: true},
				{label: 'Decision', fieldName: 'decision', type: 'Text', sortable: true},
				{label: 'GC Participant', fieldName: 'gcParticipant', type: 'Text', sortable: true},
				{label: 'GTB Participant', fieldName: 'gtbParticipant', type: 'Text', sortable: true},
				{label: 'GF Participant', fieldName: 'gfParticipant', type: 'Text', sortable: true},
				{label: 'Risk Participant', fieldName: 'riskParticipant', type: 'Text', sortable: true},
				{label: 'CIB Geography', fieldName: 'cibParticipant', type: 'Text', sortable: true}
				]);
	},
	updateColumnSorting: function (cmp, event, helper) {
		  var fieldNam = event.getParam('fieldName');
		  var sortDirection = event.getParam('sortDirection');
		  // Assign the latest attribute with the sorted column fieldNam and sorted direction
		  cmp.set("v.sortedBy", fieldNam);
		  cmp.set("v.sortedDirection", sortDirection);
		  helper.sortData(cmp, fieldNam, sortDirection);
	},
	// ## function call on Click on the "Download As CSV" Button.
	downloadCsv : function(component,event,helper){

		  // get the Records [contact] list from 'ListOfContact' attribute
		  var stockData = component.get("v.myData");

		  // call the helper function which "return" the CSV data as a String
		  var csv = helper.convertArrayOfObjectsToCSV(component,stockData);
		  if (csv == null){return;}

		  // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####
		  var hiddenElement = document.createElement('a');
		  hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
		  hiddenElement.target = '_self'; //
		  hiddenElement.download = 'ExportData.csv';  // CSV file Name* you can change it.[only name not .csv]
		  document.body.appendChild(hiddenElement); // Required for FireFox browser
		  hiddenElement.click(); // using click() js function to download csv file
				},

				search_year : function(component,event,helper){
					  // call the helper function which "return" year data as a Integer
					  helper.getTableData(component);

	}
})