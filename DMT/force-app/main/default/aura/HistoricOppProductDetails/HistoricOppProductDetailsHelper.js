({
  executeAction2: function(cmp, actToExecute, callback) {
    return new Promise(function(resolve, reject) {
      actToExecute.setCallback(this, function(response) {
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
      $A.enqueueAction(actToExecute);
    });
  },
  initComponent: function(cmp, event, helper) {

    var actionData = cmp.get("c.getProduct");
    actionData.setParams({
      optyId: cmp.get("v.oppId"),
      optLineId: cmp.get("v.oppLineId")
    });
    var promiseData = this.executeAction2(cmp, actionData);
    promiseData.then(
      $A.getCallback(function(result) {
        cmp.set("v.ObjectType", JSON.parse(result));
        let keyFields = ['pre_oppy_revenue_next_12m_amount__c', 'deal_total_amount__c','syndicated_loan_drawn_amount__c'];
        for(let i = 0; i < JSON.parse(result).Items[0].length; i++) {
          helper.setKeyFields(cmp, result, i, keyFields);
        }
      }),
      $A.getCallback(function(error) {})
    );
  },
    setKeyFields: function(cmp, result, i, keyFields) {
    if(JSON.parse(result).Items[0][i].name === 'solution_classification_desc__c') {
      cmp.set("v.ProductName", JSON.parse(result).Items[0][i].value);
    } else if(JSON.parse(result).Items[0][i].name === 'DES_Product_Family__c') {
      cmp.set("v.ProductFamily", JSON.parse(result).Items[0][i].value);
    } else if(JSON.parse(result).Items[0][i].name === 'opportunity_currency_id__c') {
      cmp.set("v.currencyCode", JSON.parse(result).Items[0][i].value);
    } else if(keyFields.includes(JSON.parse(result).Items[0][i].name)) {
      var keyFieldsObj = {"label":JSON.parse(result).Items[0][i].label, "value":JSON.parse(result).Items[0][i].value};
      var currentKeyFields = cmp.get("v.keyFields");
      currentKeyFields.push(keyFieldsObj);
      cmp.set("v.keyFields", currentKeyFields);
    }
  }
});