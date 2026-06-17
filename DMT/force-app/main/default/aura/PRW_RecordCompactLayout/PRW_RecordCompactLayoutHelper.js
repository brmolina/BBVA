({
  tableClients: function(component, event, helper) {

    let columnsArray = $A.get('$Label.c.PRW_ColumnsTablePricingClients');
    let columnsList = columnsArray.split('||');
    let numColumns = columnsList.length;

    var dataClients = component.get('v.lAccountNames');
    var data = [];
    for(var ind = 0; ind < dataClients.length; ind++) {
      var dataSplit = dataClients[ind].split('-');
      data.push({nameClient: dataSplit[0], cifClient: dataSplit[1]});
    }
    var columns = [];
    columns = [
      {label: columnsList[0], fieldName: 'nameClient', type: 'text', sortable: false, wrapText: true},
      {label: columnsList[numColumns - (numColumns - 1)], fieldName: 'cifClient', type: 'text', sortable: false, fixedWidth: 100}
    ];
    component.set('v.dataTable', data);
    component.set('v.columnsTable', columns);
  }
})