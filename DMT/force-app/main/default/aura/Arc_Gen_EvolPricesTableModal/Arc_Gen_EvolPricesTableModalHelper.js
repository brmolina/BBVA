({
  saveRecords: function(cmp, event, helper) {
    var records2Insert = [];
    var newBodyList = [];
    var allValid = true;
    var bodyList = cmp.get('v.body');
    if (!bodyList) {
      bodyList = [];
    }
    for (var z = 0; z < bodyList.length; z++) {
      if (bodyList[z].find('product') !== undefined) {
        newBodyList.push(bodyList[z]);
      }
    }
    for (var i = 0; i < newBodyList.length; i++) {
      for (var j = 0; j < 3; j++) {
        if (!newBodyList[i].find('product').get('v.validity').valid || !newBodyList[i].find('year' + j).get('v.validity').valid) {
          newBodyList[i].find('product').showHelpMessageIfInvalid();
          newBodyList[i].find('year' + j).showHelpMessageIfInvalid();
          allValid = false;
          break;
        }
        records2Insert.push({arce__gf_commodity_product_name__c: newBodyList[i].find('product').get('v.value'),
          arce__year_id__c: Math.abs(cmp.get('v.year') - j),
          arce__gf_comod_prd_avg_price_amount__c: Math.abs(newBodyList[i].find('year' + j).get('v.value')),
          arce__account_has_analysis_agro_id__c: cmp.get('v.accHasId'),
          Id: newBodyList[i].find('year' + j).get('v.name')
        });
      }
    }
    if (allValid) {
      helper.upsertRecords(cmp, event, helper, records2Insert, newBodyList);
    } else {
      cmp.set('v.disable', false);
    }
  },
  upsertRecords: function(cmp, event, helper, records2Insert, newBodyList) {
    var records = JSON.stringify(records2Insert);
    var insertRecords = cmp.get('c.insertRecords');
    insertRecords.setParams({
      records: records
    });
    return helper
      .callAction(insertRecords)
      .then(result => {
        var resp = JSON.parse(result);
        if (resp.saveStatus === 'true') {
          helper.asignId(cmp, event, helper, resp.createdRsr, newBodyList);
          helper.showToast(cmp, 'SUCCESS', $A.get('$Label.c.Arc_Gen_recordSaveSuccess'));
        } else {
          cmp.set('v.error', true);
        }
      })
      .catch(error => {
        cmp.set('v.error', error);
      });
  },
  asignId: function(cmp, event, helper, recordLts, bodyLts) {
    var k = 0;
    for (var i = 0; i < bodyLts.length; i++) {
      for (var j = 0; j < 3; j++) {
        bodyLts[i].find('year' + j).set('v.name', recordLts[k]);
        k++;
      }
    }
    cmp.set('v.disable', false);
  },
  handleDelete: function(cmp, event, helper) {
    var ids2Del = [];
    var index = event.getSource().get('v.value');
    var bodyLts = cmp.get('v.body');
    if (!bodyLts) {
      bodyLts = [];
    }
    for (var j = 0; j < 3; j++) {
      ids2Del.push(bodyLts[index - 1].find('year' + j).get('v.name'));
    }
    var deleteRecords = cmp.get('c.deleteRecords');
    deleteRecords.setParams({
      records: ids2Del
    });
    return helper
      .callAction(deleteRecords)
      .then(result => {
        var resp = JSON.parse(result);
        if (resp.saveStatus === 'true') {
          bodyLts[index - 1].find('divId').destroy();
        } else {
          cmp.set('v.error', true);
        }
      })
      .catch(error => {
        cmp.set('v.error', error);
      });
  },
  loadRecords: function(cmp, event, helper) {
    let loadRec = cmp.get('c.loadRecords');
    loadRec.setParams({
      accHasId: cmp.get('v.accHasId')
    });
    return helper
      .callAction(loadRec)
      .then(result => {
        return Promise.resolve(JSON.parse(result));
      })
      .catch(error => {
        cmp.set('v.error', error);
      });
  },
  showToast: function(cmp, type, message) {
    var messageToast = $A.get('e.force:showToast');
    messageToast.setParams({
      title: '',
      type: type,
      message: message,
      duration: '8000'
    });
    messageToast.fire();
  },
  callAction: function(action) {
    return new Promise($A.getCallback((resolve, reject) => {
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else {
          reject(response.getError());
        }
      });
      $A.enqueueAction(action);
    }));
  }
});