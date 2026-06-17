({

  newBBVAParticipant: function(component, evt) {
      var userField = component.find("userField").get("v.value");
      var message = '';

      this.setVal(component, "v.UserVal", userField);

      message = this.logicRequired(component, message, userField);
      message = message.slice(0, -1);
      this.setErrorValues(component, message);
  },
  setVal: function(component, field, val) {
      if (val !== undefined) {
          component.set(field, val);
      }
  },
  logicRequired: function(component, message, userField) {
      message = this.checkRequiredFields(component, message, userField);
      return message;
  },
  logicNotNullStyles: function(component, idDiv, classDiv, idError, classToAdd, classToRemove) {
      $A.util.removeClass(component.find(idDiv), classDiv);
      $A.util.removeClass(component.find(idError), classToRemove);
      $A.util.addClass(component.find(idError), classToAdd);
  },
    logicNullStyles: function(component, idDiv, classDiv, idError, classToAdd, classToRemove) {
      $A.util.addClass(component.find(idDiv), classDiv);
      $A.util.addClass(component.find(idError), classToAdd);
      $A.util.removeClass(component.find(idError), classToRemove);
  },
  checkRequiredFields: function(component, message, userField) {
    if (userField === undefined || userField === null || userField === '') {
          message += 'User, ';
          this.logicNullStyles(component, 'divuser','slds-has-error', 'error-DES_User__c', 'slds-visible', 'slds-hidden');
        }
        return message;
  },
  setErrorValues: function(component, mesage) {
    if (mesage === '' || mesage === undefined) {
          component.set('v.showError', false);
      } else {
          var messageAux = 'These required fields must be completed: ' + mesage;
          component.set('v.errorMessage', messageAux);
          component.set('v.showError', true);
      }
  }
});