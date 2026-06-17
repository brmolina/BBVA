({
  getRTName: function(cmp, event, helper) {
    var action1 = cmp.get("c.getRecordTypeId");
    action1.setParams({
      'sObjecType': 'DES_Opportunity_Management_member__c',
      'rtName': $A.get("$Label.c.RT_OPP_TEAM_MEMBER_INSIDE_INFO")
  })
    action1.setCallback(this, function(response) {
      if (response.getState() === "SUCCESS" && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
            cmp.set("v.rtId", response.getReturnValue());
        }
    })
    $A.enqueueAction(action1);
  },
  checkTeamRole: function(component, teamRole) {
    if (teamRole ===  $A.get("$Label.c.DES_Role_Transactional_Banker")) {
      this.changeFieldsVisibility(component, false, true);
    } else if (teamRole ===  $A.get("$Label.c.DES_Role_Product_Specialist")) {
      this.changeFieldsVisibility(component, true, false);
    } else {
      this.changeFieldsVisibility(component, true, true);
    }
  },
  changeFieldsVisibility: function(component, transact, prodSpec) {
    component.set("v.disableTB", transact);
    component.set("v.disablePS", prodSpec);
  },
  newOppTeamMember: function(component, evt) {
      var userField = component.find("userField").get("v.value");
      var coveragetypeField = component.find("coveragetypeField").get("v.value");
      var teamroleField = component.find("teamroleField").get("v.value");
      var psprodfamilyField = component.find("psprodfamilyField").get("v.value");
      var countriesField = component.find("countriesField").get("v.value");
      var productField = component.get("v.PSProduct");
      var message = '';
      this.setVal(component, "v.UserVal", userField);
      this.setVal(component, "v.CoverageVal", coveragetypeField);
      this.setVal(component, "v.TeamRoleVal", teamroleField);
      this.setVal(component, "v.Scope", countriesField);
      this.setVal(component, "v.PSProductFamily", psprodfamilyField);
      this.setVal(component, "v.PSProduct", productField);
      message = this.logicRequired(component, message, userField, teamroleField, countriesField);
      message = this.logicIfTBorPS(component, message, coveragetypeField, teamroleField, psprodfamilyField, productField);
      message = message.slice(0, -1);
      this.setErrorValues(component, message);
  },
  setVal: function(component, field, val) {
      if (val !== undefined) {
          component.set(field, val);
      }
  },
  logicRequired: function(component, message, userField, teamroleField, countriesField) {
      message = this.checkRequiredFields(component, message, userField, teamroleField, countriesField);
      return message;
  },
  logicIfTBorPS: function(component, message, coveragetypeField, teamroleField, psprodfamilyField, productField) {
    message = this.checkTB(component, message, teamroleField, coveragetypeField);
    message = this.checkPS(component, message, teamroleField, psprodfamilyField, productField);
    return message;
  },
  logicNullStyles: function(component, idDiv, classDiv, idError, classToAdd, classToRemove) {
      $A.util.addClass(component.find(idDiv), classDiv);
      $A.util.addClass(component.find(idError), classToAdd);
      $A.util.removeClass(component.find(idError), classToRemove);
  },
  checkRequiredFields: function(component, message, userField, teamroleField, countriesField) {
    if (userField === undefined || userField === null || userField === '') {
        message += 'User, ';
        this.logicNullStyles(component, 'divuser','slds-has-error', 'error-DES_User__c', 'slds-visible', 'slds-hidden');
      } else {
        this.logicNotNullStyles(component, 'divuser','slds-has-error', 'error-DES_User__c', 'slds-hidden', 'slds-visible');
      }
      if (teamroleField === undefined || teamroleField === null || teamroleField === '') {
        message += 'Team Role, ';
        this.logicNullStyles(component, 'divteamrole','slds-has-error', 'error-teamrole', 'slds-visible', 'slds-hidden');
      } else {
        this.logicNotNullStyles(component, 'divteamrole','slds-has-error', 'error-teamrole', 'slds-hidden', 'slds-visible');
      }
      if (countriesField === undefined || countriesField === null || countriesField === '') {
        message += 'Scope, ';
        this.logicNullStyles(component, 'divcountries','slds-has-error', 'error-countries', 'slds-visible', 'slds-hidden');
      } else {
        this.logicNotNullStyles(component, 'divcountries','slds-has-error', 'error-countries', 'slds-hidden', 'slds-visible');
      }
      return message;
  },
  checkTB: function(component, message, teamroleField, coveragetypeField) {
    if (teamroleField === $A.get("$Label.c.DES_Role_Transactional_Banker") && (coveragetypeField === undefined || coveragetypeField === null || coveragetypeField === '')) {
      message += 'Coverage type,';
      this.logicNullStyles(component, 'divcoveragetype','slds-has-error', 'error-coveragetype', 'slds-visible', 'slds-hidden');
    } else {
      this.logicNotNullStyles(component, 'divcoveragetype','slds-has-error', 'error-coveragetype', 'slds-hidden', 'slds-visible');
    }
    return message;
  },
  checkPS: function(component, message, teamroleField, psprodfamilyField, productField) {
    if (teamroleField === $A.get("$Label.c.DES_Role_Product_Specialist")) {
      if (psprodfamilyField === undefined || psprodfamilyField === null || psprodfamilyField === '') {
        message += 'PS Product Family,';
        this.logicNullStyles(component, 'divpsprodfamily','slds-has-error', 'error-psprodfamily', 'slds-visible', 'slds-hidden');
      } else {
        this.logicNotNullStyles(component, 'divpsprodfamily','slds-has-error', 'error-psprodfamily', 'slds-hidden', 'slds-visible');
      }
      if (productField === undefined || productField === null || productField === '') {
        message += 'PS Product,';
        this.logicNullStyles(component, 'divproduct','slds-has-error', 'error-product', 'slds-visible', 'slds-hidden');
      } else {
        this.logicNotNullStyles(component, 'divproduct','slds-has-error', 'error-product', 'slds-hidden', 'slds-visible');
      }
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
  },
  helperComponentEvent: function(component, event) {
    var productId = event.getParam('recordByEvent');
    if (productId.Id === undefined || productId.Id === null) {
        component.set('v.PSProduct', '');
    } else {
        component.set('v.PSProduct', productId.Id);
    }
  },
  logicNotNullStyles: function(component, idDiv, classDiv, idError, classToAdd, classToRemove) {
      $A.util.removeClass(component.find(idDiv), classDiv);
      $A.util.removeClass(component.find(idError), classToRemove);
      $A.util.addClass(component.find(idError), classToAdd);
  },
  setScope: function(component, selectedRole) {
    if (selectedRole === $A.get("$Label.c.DES_ROLE_CIB_BANKER") || selectedRole === $A.get("$Label.c.DES_ROLE_GCC_POOL")
        || selectedRole === $A.get("$Label.c.DES_ROLE_GLOBAL_BANKER")
        || selectedRole === $A.get("$Label.c.DES_ROLE_INDUSTRY_HEAD") || selectedRole === $A.get("$Label.c.DES_ROLE_SECONDARY_GB")) {
      component.set("v.Scope", $A.get("$Label.c.DES_SCOPE_GLOBAL"));
      component.find("countriesField").set("v.value", $A.get("$Label.c.DES_SCOPE_GLOBAL"));
    }else{
      component.set("v.Scope", "");
      component.find("countriesField").set("v.value", "");
    }
  }
})