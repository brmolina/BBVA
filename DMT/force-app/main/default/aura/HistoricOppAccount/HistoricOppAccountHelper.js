({
  promiseOpp: function(cmp, promiseOppAction, callback) {
    return new Promise(function(resolve, reject) {
      promiseOppAction.setCallback(this, function(response) {
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
      $A.enqueueAction(promiseOppAction);
    });
  },
  initCmp: function(cmp, helper) {
    var actionData = cmp.get("c.getDataOpp");
    actionData.setParams({
      optyId: cmp.get("v.oppId"),
      accId: cmp.get("v.accountId")
    });
    var promiseData = this.promiseOpp(cmp, actionData);
    promiseData.then(
      $A.getCallback(function(result) {
        cmp.set("v.ObjectType", JSON.parse(result));
        let keyFields = ['disclosure_info_type__c', 'pre_oppy_revenue_next_12m_amount__c','StageName__c', 'DES_Date_Won_Lost__c', 'DES_Booking_Geography__c','Owner__c'];
        for(let i = 0; i < JSON.parse(result).Items[0].length; i++) {
          helper.setMembersOpp(cmp, result, i);
          helper.setKeyFieldsOpp(cmp, result, i, keyFields);
        }
      }),
      $A.getCallback(function(error) {})
    );
  },
  setMembersOpp: function(cmp, result, i) {
    if(JSON.parse(result).Items[0][i].name === 'Opportunity_Members__c') {
      cmp.set("v.sizeMembers", JSON.parse(result).Items[0][i].value.split('//').length);
      var members = [];
      for(let j = 0; j < JSON.parse(result).Items[0][i].value.split('//').length; j++) {
        var nameaux = JSON.parse(result).Items[0][i].value.split('//')[j].split(';')[0];
        var memberaux = JSON.parse(result).Items[0][i].value.split('//')[j].split(';')[1];
        var member = {"Name":nameaux, "DES_Opportunity_member_role__c":memberaux};
        console.log(member);
        members.push(member);
      }
      cmp.set("v.members", members);
    }
  },
  setKeyFieldsOpp: function(cmp, result, i, keyFields) {
    if(JSON.parse(result).Items[0][i].name === 'Name__c') {
      cmp.set("v.oppName", JSON.parse(result).Items[0][i].value);
    } else if(JSON.parse(result).Items[0][i].name === 'CurrencyIsoCode__c') {
      cmp.set("v.currencyCode", JSON.parse(result).Items[0][i].value);
    } else if(keyFields.includes(JSON.parse(result).Items[0][i].name)) {
      var keyFieldsObj = {};
      if(JSON.parse(result).Items[0][i].value.includes('00:00:00')){
        keyFieldsObj = {"label":JSON.parse(result).Items[0][i].label, "value":JSON.parse(result).Items[0][i].value.split(' ')[0]};
      } else {
        keyFieldsObj = {"label":JSON.parse(result).Items[0][i].label, "value":JSON.parse(result).Items[0][i].value};
      }
      var currentKeyFields = cmp.get("v.keyFields");
      currentKeyFields.push(keyFieldsObj);
      cmp.set("v.keyFields", currentKeyFields);
    }
  }
});