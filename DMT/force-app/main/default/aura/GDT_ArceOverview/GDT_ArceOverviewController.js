({
  doInit: function(component, event, helper) {
    helper.setColumns(component);
    helper.fetchAccHelper(component, event, helper);
  },
  handleNodeClicked: function(component, event) {
    var filters = event.getParams('ap');
    console.log(JSON.stringify(filters.title));
  },
  handleSort: function(cmp, event, helper) {
    helper.handleSort(cmp, event);
  },
  filter: function(component, event, helper) {
    let filterField = component.get('v.filterField');
    let data = component.get('v.data');
    let term = component.get('v.filter');

    var results = data;
    var regex;
    try {
      regex = new RegExp(term, 'i');
      switch (filterField) {
        case 'rating':
          results = data.filter(row => regex.test(row.rating));
          break;
        case 'name':
          results = data.filter(row => regex.test(row.name));
          break;
        case 'participantType':
          results = data.filter(row => regex.test(row.participantType));
          break;
        case 'country':
          results = data.filter(row => regex.test(row.country));
          break;
        case 'dateEEFF':
          results = data.filter(row => regex.test(row.dateEEFF));
          break;
        case 'state':
          results = data.filter(row => regex.test(row.state));
          break;
        default:
          results = data.filter(row => (regex.test(row.rating) || regex.test(row.participantType)
          || regex.test(row.country) || regex.test(row.dateEEFF) || regex.test(row.state) || regex.test(row.name)));
      }
    } catch (e) {
      console.log(JSON.stringify(e));
    }
    component.set('v.acctList', results);
  },
  handleChange: function(cmp, event) {
    var selectedOptionValue = event.getParam('value');
    cmp.set('v.filterField', selectedOptionValue);
    cmp.set('v.filter', '');
    var data = cmp.get('v.data');
    cmp.set('v.acctList', data);
  },
  handleToggle: function(cmp, event) {
    var selectedOptionValue = cmp.get('v.showHierarchy');
    var toogle = !selectedOptionValue ? 'height: 800px' : 'height: 150px';
    cmp.set('v.styleHier', toogle);
  }
});