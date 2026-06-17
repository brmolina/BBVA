({
  doInit: function(component, event, helper) {
    helper.getData(component, event, helper);
  },
  doSave: function(component, event, helper) {
    helper.checkRequiredFields(component, event, helper);
  },
  getSeekerUser: function(component, event, helper) {
    let data = event.getParam('data');
    let userIds = [];
    if (data.length !== 0) {
      for (var i = 0; i < data.length; i++) {
        userIds.push(data[i].salesforceId);
      }
      component.set('v.ownerIds', userIds);
    } else {
      component.set('v.ownerIds', null);
    }
  },
  getSeekerArce: function(component, event, helper) {
    let data = event.getParam('data');
    if (data.length !== 0) {
      component.set('v.createTask.WhatId', data[0].salesforceId);
    } else {
      component.set('v.createTask.WhatId', null);
    }
  },
  handleShowModal: function(component, event, helper) {
    helper.createForm(component, event, helper);
  }
});