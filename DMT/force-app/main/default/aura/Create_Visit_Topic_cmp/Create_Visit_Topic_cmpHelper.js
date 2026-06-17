({
  helperComponentEvent: function(component, event) {
    var oppId = event.getParam('recordByEvent');
    if (oppId === undefined || oppId === null) {
      component.set('v.oppId', '');
    } else {
      component.set('v.oppId', oppId.Id);
    }
  },
  saveForm : function(component, event) {
      var doneVal = component.find("doneField").get("v.value");
      var descriptionVal = component.find("descriptionField").get("v.value");
      this.setVal(component, "v.doneVal", doneVal);
      this.setVal(component, "v.descriptionVal", descriptionVal);
      if (descriptionVal === undefined || descriptionVal === null || descriptionVal === '') {
          this.setVal(component, "v.showError", true);
          this.setVal(component, "v.errorMessage", 'These required fields must be completed: Description');
      } else {
          this.setVal(component, "v.showError", false);
            // Figure out which action was called
          var actionClicked = event.getSource().getLocalId();
          // Fire that action
          var navigate = component.get("v.navigateFlow");
          navigate(actionClicked);
      }
  },
  setVal: function(component, field, val) {
    if (val !== undefined && val !== null) {
      component.set(field, val);
    }
  },
  setInitialValues: function(component, event) {
    var descriptionVal = component.find("descriptionField").get("v.value");
    this.setVal(component, "v.descriptionVal", descriptionVal);
  }
})