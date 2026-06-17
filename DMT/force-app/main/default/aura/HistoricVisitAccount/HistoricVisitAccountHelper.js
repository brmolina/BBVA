({
  executePromise: function(cmp, promiseAction, callback) {
    return new Promise(function(resolve, reject) {
      promiseAction.setCallback(this, function(response) {
        var status = response.getState();
        if (status === "SUCCESS") {
          resolve(response.getReturnValue());
        } else if (status === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject(Error("Error messge: " + errors[0].message));
            }
          } else {
            reject(Error("Unknown error"));
          }
        }
      });
      $A.enqueueAction(promiseAction);
    });
  },
  initCmp: function(cmp, helper) {
    var actionData = cmp.get("c.getDataVisit");
    actionData.setParams({
      visitId: cmp.get("v.visitId"),
      accId: cmp.get("v.accountId")
    });
    var promiseData = this.executePromise(cmp, actionData);
    promiseData.then(
      $A.getCallback(function(result) {
        cmp.set("v.ObjectType", JSON.parse(result));
        let keyFields = ['disclosure_info_type__c', 'dwp_kitv_visit_start_date__c','dwp_kitv_visit_end_date__c','Owner__c'];
        for(let i = 0; i < JSON.parse(result).Items[0].length; i++) {
          helper.setMembers(cmp, result, i);
          helper.setKeyFields(cmp, result, i, keyFields);
        }
      }),
      $A.getCallback(function(error) {})
    );
  },
  setMembers: function(cmp, result, i) {
    if(JSON.parse(result).Items[0][i].name === 'Attendees__c') {
      cmp.set("v.sizeMembers", JSON.parse(result).Items[0][i].value.split('//').length);
      var members = [];
      for(let j = 0; j < JSON.parse(result).Items[0][i].value.split('//').length; j++) {
        var typeaux = JSON.parse(result).Items[0][i].value.split('//')[j].split(';')[0];
        var nameaux = JSON.parse(result).Items[0][i].value.split('//')[j].split(';')[1];
        var emailaux = JSON.parse(result).Items[0][i].value.split('//')[j].split(';')[2];
        var member = {"Type":typeaux,"Name":nameaux, "Email":emailaux};
        console.log(member);
        members.push(member);
      }
      cmp.set("v.members", members);
    }
  },
  setKeyFields: function(cmp, result, i, keyFields) {
    if(JSON.parse(result).Items[0][i].name === 'Name__c') {
      cmp.set("v.visitName", JSON.parse(result).Items[0][i].value);
    } else if(JSON.parse(result).Items[0][i].name === 'CurrencyIsoCode__c') {
      cmp.set("v.currencyCode", JSON.parse(result).Items[0][i].value);
    } else if(keyFields.includes(JSON.parse(result).Items[0][i].name)) {
      var keyFieldsObj = {};
      keyFieldsObj = {"label":JSON.parse(result).Items[0][i].label, "value":JSON.parse(result).Items[0][i].value};
      var currentKeyFields = cmp.get("v.keyFields");
      currentKeyFields.push(keyFieldsObj);
      cmp.set("v.keyFields", currentKeyFields);
    }
  }
});