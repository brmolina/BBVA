/* eslint-disable no-unused-expressions */
({
  doInit: function(cmp, event, helper) {
    var location = cmp.get('v.appPageLocation');
    if (location === 'Toolkit') {
      cmp.set('v.toolkitId', cmp.get('v.recordId'));
    }
    helper.init(cmp, helper);
  },
  handleSelectChange: function(cmp, event, helper) {
    var filterSelectedOptions = [];
    var eventComponentOrigin = event.getParam('origin');

    // No hay por qué volver a la 1ª pág. al seleccionar un KPI Catalogue, ya se hace en 'handleSearch'
    if (eventComponentOrigin !== 'KPICatalog') {
      cmp.set('v.page', 1);
    }

    if (event.getParam('selectedValues').length === 0) {
      cmp.set('v.' + event.getParam('origin') + 'Selected', []);
      if (eventComponentOrigin === 'KPICatalog') {
        cmp.set('v.disableSearch', true);
      }
    } else {
      if (eventComponentOrigin !== 'businessArea') {
        if (eventComponentOrigin === 'KPICatalog') {
          cmp.set('v.disableSearch', false);
        }
        event.getParam('selectedValues').forEach(filterOption => {
          filterSelectedOptions.push(filterOption.value);
        });
      } else {
        event.getParam('selectedValues').forEach(filterOption => {
          filterSelectedOptions.push(filterOption.label);
        });
      }
      cmp.set('v.' + event.getParam('origin') + 'Selected', filterSelectedOptions);
    }
    if (eventComponentOrigin !== 'KPICatalog') {
      helper.searchOperations(cmp, helper, false);
    }
    if (eventComponentOrigin === 'group') {
      helper.setClientsByGroup(cmp, helper);
    }
  },
  handleMainTable: function(cmp, event, helper) {
    cmp.set('v.isLoading', false);
  },
  handleSearch: function(cmp, event, helper) {
    cmp.set('v.page', 1);
    helper.buttonSearch(cmp, helper);
    cmp.set('v.disableSearch', true);
  },
  handleReset: function(cmp, event, helper) {
    helper.resetAllFilters(cmp, helper);
    helper.setClientsByGroup(cmp, helper);
  },
  handlePrevious: function(cmp, event, helper) {
    cmp.set('v.page', cmp.get('v.page') - 1);
    helper.searchOperations(cmp, helper, false);
  },
  handleNext: function(cmp, event, helper) {
    cmp.set('v.page', cmp.get('v.page') + 1);
    helper.searchOperations(cmp, helper, false);
  },
  handleDomo: function(cmp, event, helper) {
    var urlVar = 'https://secureapp-aws.live.es.platform.bbva.com/api/stack/datiobieu-live-xg?sessionContext=true&object=https%3A%2F%2Fbbva-datio-live01.domo.com%2Fpage%2F797936791';
    let eUrl = $A.get('e.force:navigateToURL');
    eUrl.setParams({
      url: urlVar
    });
    eUrl.fire();
  }
});