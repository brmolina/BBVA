({
  getConnClients: function(component, event, helper) {
    var action = component.get('c.getConnClients');
    let srcEvtIdValue = event.getSource().getLocalId() === undefined ? 'noEvent' : event.getSource().getLocalId();
    action.setParams({
      recordId: component.get('v.recordId'),
      srcEvtId: srcEvtIdValue
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        var res = response.getReturnValue();
        component.set('v.allData', res.retObj);
        this.initPagination(component);
        helper.retrieveAnswer(component, event, helper);
      }
    });
    $A.enqueueAction(action);
  },

  persistAnswer: function(component, event, helper) {
    var action = component.get('c.persistAnswer');
    action.setParams({
      recordId: component.get('v.recordId'),
      option: component.get('v.connClientsCheck')
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        component.set('v.spinnerCmp', false);
      }
    });
    $A.enqueueAction(action);
  },

  retrieveAnswer: function(component, event, helper) {
    var action = component.get('c.getAnswer');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        var res = response.getReturnValue();
        component.set('v.connClientsCheck', res);
        component.set('v.spinnerCmp', false);
      }
    });
    $A.enqueueAction(action);
  },

  initPagination: function(component, event, helper, recPerPage) {
    recPerPage = parseInt(recPerPage || component.get('v.recordsPerPage'));
    let allData = component.get('v.allData');
    var totalPages = Math.ceil(allData.length / recPerPage) || 1;
    var currPage = 0;
    var dataToDisplay = allData.slice(currPage, recPerPage);
    component.set('v.totalPages', totalPages);
    component.set('v.displayedData', dataToDisplay);
  },

  moveToPage: function(component, event, helper, newPage) {
    var allData = component.get('v.allData');
    let previousPage = newPage - 1;
    var recPerPage = parseInt(component.get('v.recordsPerPage'));
    var dataToDisplay = allData.slice(previousPage * recPerPage, newPage * recPerPage);
    component.set('v.displayedData', dataToDisplay);
  },

  showToast: function(type, message, link, linkLabel) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'mode': 'sticky',
      'type': type.toLowerCase(),
      'message': 'Required message',
      'messageTemplate': '{0} {1}!',
      'messageTemplateData': [message, {
        url: link,
        label: linkLabel
      }
      ]
    });
    toastEvent.fire();
  }
});({
  getConnClients: function(component, event, helper) {
    var action = component.get('c.getConnClients');
    let srcEvtIdValue = event.getSource().getLocalId() === undefined ? 'noEvent' : event.getSource().getLocalId();
    action.setParams({
      recordId: component.get('v.recordId'),
      srcEvtId: srcEvtIdValue
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        var res = response.getReturnValue();
        component.set('v.allData', res.retObj);
        this.initPagination(component);
        helper.retrieveAnswer(component, event, helper);
      }
    });
    $A.enqueueAction(action);
  },

  persistAnswer: function(component, event, helper) {
    var action = component.get('c.persistAnswer');
    action.setParams({
      recordId: component.get('v.recordId'),
      option: component.get('v.connClientsCheck')
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        component.set('v.spinnerCmp', false);
      }
    });
    $A.enqueueAction(action);
  },

  retrieveAnswer: function(component, event, helper) {
    var action = component.get('c.getAnswer');
    action.setParams({
      recordId: component.get('v.recordId')
    });
    action.setCallback(this, function(response) {
      if (component.isValid() && response.getState() === 'SUCCESS') {
        var res = response.getReturnValue();
        component.set('v.connClientsCheck', res);
        component.set('v.spinnerCmp', false);
      }
    });
    $A.enqueueAction(action);
  },

  initPagination: function(component, event, helper, recPerPage) {
    recPerPage = parseInt(recPerPage || component.get('v.recordsPerPage'));
    let allData = component.get('v.allData');
    var totalPages = Math.ceil(allData.length / recPerPage) || 1;
    var currPage = 0;
    var dataToDisplay = allData.slice(currPage, recPerPage);
    component.set('v.totalPages', totalPages);
    component.set('v.displayedData', dataToDisplay);
  },

  moveToPage: function(component, event, helper, newPage) {
    var allData = component.get('v.allData');
    let previousPage = newPage - 1;
    var recPerPage = parseInt(component.get('v.recordsPerPage'));
    var dataToDisplay = allData.slice(previousPage * recPerPage, newPage * recPerPage);
    component.set('v.displayedData', dataToDisplay);
  },

  showToast: function(type, message, link, linkLabel) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'mode': 'sticky',
      'type': type.toLowerCase(),
      'message': 'Required message',
      'messageTemplate': '{0} {1}!',
      'messageTemplateData': [message, {
        url: link,
        label: linkLabel
      }
      ]
    });
    toastEvent.fire();
  }
});