({
  doInit: function(component, event, helper) {
    component.set('v.spinnerCmp', true);
    component.set('v.connClientsCols', [
      {label: 'Participant name', fieldName: 'firstName', type: 'text'},
      {label: 'Global Customer code', fieldName: 'customerId', type: 'text'},
      {label: 'Country Branch', fieldName: 'countryId', type: 'text'},
      {label: 'Class of economic relationship', fieldName: 'groupRelationClassType', type: 'text'},
      {label: 'Entity', fieldName: 'entityId', type: 'text'}
    ]);
    component.set('v.recordsPerPageOpts', [
      {'label': '10', 'value': '10'},
      {'label': '15', 'value': '15'},
      {'label': '20', 'value': '20'}
    ]);
    component.set('v.connClientsCheckOpts', [
      {'label': 'No', 'value': '0'},
      {'label': 'Yes. There is the complete list', 'value': '1'},
      {'label': 'Yes. The main ones are found', 'value': '2'},
      {'label': 'Reviewed. There are no connected clients', 'value': '3'},
      {'label': 'Unknown', 'value': '4'}
    ]);
    helper.getConnClients(component, event, helper);
  },
  refreshTable: function(component, event, helper) {
    helper.getConnClients(component, event, helper);
  },
  saveAnswer: function(component, event, helper) {
    component.set('v.spinnerCmp', true);
    if (component.get('v.connClientsCheck') === '0') {
      let link = 'https://bbva-hoggtool.appspot.com/#/universe/hogg/process/create/ugcyg/CRM_119_V17/0';
      helper.showToast('Info', 'Please, modify them on ', link, 'HOGG');
    }
    helper.persistAnswer(component, event, helper);
  },
  recPerPageChanged: function(component, event, helper) {
    var newRecPerPage = event.getParam('value');
    helper.initPagination(component, event, helper, newRecPerPage);
  },
  clickNavigation: function(component, event, helper) {
    var buttonElement = event.getSource().get('v.name');
    var currPage = component.get('v.currentPage');
    var totalPages = component.get('v.totalPages');

    switch (buttonElement) {
      case 'first':
        currPage = 1;
        break;
      case 'previous':
        currPage -= currPage > 0 ? 1 : 0;
        break;
      case 'next':
        currPage += currPage <= totalPages - 1 ? 1 : 0;
        break;
      case 'last':
        currPage = totalPages;
        break;
    }
    helper.moveToPage(component, event, helper, currPage);
    component.set('v.currentPage', currPage);
  }
});