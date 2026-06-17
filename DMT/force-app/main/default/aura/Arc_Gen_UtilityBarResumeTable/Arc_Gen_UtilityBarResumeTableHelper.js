({
  methodsManager: function(component, event, helper) {
    let promise1 = helper.getColumns(component, event, helper);
    promise1.then(function(result1) {
      let promise2 = helper.getdata(component, event, helper);
      promise2.then(function(result2) {
        helper.getdataTotals(component, event, helper, result2);
      });
    });
  },
  getColumns: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      let arrayHelper = [
        'TP_ProposedAmmount',
        'TP_0007',
        'TP_0011',
        'TP_0014',
        'TP_0005',
        'TP_0010',
        'TP_0012',
        'TP_0008',
        'TP_0002',
        'TP_0003',
        'TP_0013',
        'TP_0006',
        'TP_Percentage',
      ];
      var action = component.get('c.getDataTypologies');
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var data = response.getReturnValue();
          var labelPercentage = {
            Name: $A.get('$Label.c.Arc_Gen_UtilityBarPercentage'),
            arce__risk_typology_level_id__c: 'TP_Percentage'
          };
          var proposedAmmount = {
            Name: $A.get('$Label.c.Arc_Gen_UtilityBarProposedAmmount'),
            arce__risk_typology_level_id__c: 'TP_ProposedAmmount'
          };
          data.push(labelPercentage);
          data.push(proposedAmmount);
          for (var i = 0; i < data.length; i++) {
            for (var j = 0; j < arrayHelper.length; j++) {
              if (arrayHelper[j] === data[i].arce__risk_typology_level_id__c) {
                var typologie = {
                  label: data[i].Name,
                  fieldName: data[i].arce__risk_typology_level_id__c,
                  type: 'text'
                };
                arrayHelper[j] = typologie;
              }
            }
          }
          component.set('v.columns', arrayHelper);
          resolve();
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  getdata: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.getTableData');
      action.setParams({
        recordId: component.get('v.pageReference').state.c__entryId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var retParse = JSON.parse(response.getReturnValue());
          var limits = retParse.limits;
          var rows = [];
          var rowstosend = [];
          for (var i = 0; i < limits.length; i++) {
            var currency = retParse.currencyType[i];
            var unitType = retParse.unitType[i];
            var parsedObject = limits[i];
            var row = {
              TP_ProposedAmmount: JSON.parse(parsedObject[0]).customerinfo.customerName + ' (' + currency + '/' + unitType + ')',
              TP_0007: JSON.parse(parsedObject[4]).typonames.typologyammount + ' ',
              TP_0011: JSON.parse(parsedObject[8]).typonames.typologyammount + ' ',
              TP_0014: JSON.parse(parsedObject[10]).typonames.typologyammount + ' ',
              TP_0005: JSON.parse(parsedObject[2]).typonames.typologyammount + ' ',
              TP_0010: JSON.parse(parsedObject[7]).typonames.typologyammount + ' ',
              TP_0012: JSON.parse(parsedObject[9]).typonames.typologyammount + ' ',
              TP_0008: JSON.parse(parsedObject[5]).typonames.typologyammount + ' ',
              TP_0002: JSON.parse(parsedObject[0]).typonames.typologyammount + ' ',
              TP_0003: JSON.parse(parsedObject[1]).typonames.typologyammount + ' ',
              TP_0013: JSON.parse(parsedObject[6]).typonames.typologyammount + ' ',
              TP_0006: JSON.parse(parsedObject[3]).typonames.typologyammount + ' ',
              TP_Percentage: '0'
            };
            var rowForTotal = {
              TP_ProposedAmmount: JSON.parse(parsedObject[0]).customerinfo.customerName,
              TP_0007: JSON.parse(parsedObject[4]).typonames.typologyammount,
              TP_0011: JSON.parse(parsedObject[8]).typonames.typologyammount,
              TP_0014: JSON.parse(parsedObject[10]).typonames.typologyammount,
              TP_0005: JSON.parse(parsedObject[2]).typonames.typologyammount,
              TP_0010: JSON.parse(parsedObject[7]).typonames.typologyammount,
              TP_0012: JSON.parse(parsedObject[9]).typonames.typologyammount,
              TP_0008: JSON.parse(parsedObject[5]).typonames.typologyammount,
              TP_0002: JSON.parse(parsedObject[0]).typonames.typologyammount,
              TP_0003: JSON.parse(parsedObject[1]).typonames.typologyammount,
              TP_0013: JSON.parse(parsedObject[6]).typonames.typologyammount,
              TP_0006: JSON.parse(parsedObject[3]).typonames.typologyammount,
              TP_Percentage: '0'
            };
            rowstosend.push(rowForTotal);
            rows.push(row);
          }
          component.set('v.data', rows);
          if (retParse.multiCurrency) {
            reject();
          } else {
            var rowsSendResolve = {
              rowstosend: rowstosend,
              currencyTotal: retParse.currencyType[0],
              unitTotal: retParse.unitType[0]
            };
            resolve(rowsSendResolve);
          }
        } else {
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  getdataTotals: function(component, event, helper, result2) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var tP0007 = 0;
      var tP0011 = 0;
      var tP0014 = 0;
      var tP0005 = 0;
      var tP0010 = 0;
      var tP0012 = 0;
      var tP0008 = 0;
      var tP0003 = 0;
      var tP0013 = 0;
      var tP0006 = 0;
      var tP0002 = 0;
      var returnValue = result2.rowstosend;
      var currency = result2.currencyTotal;
      var unitType = result2.unitTotal;
      for (var i = 0; i < returnValue.length; i++) {
        tP0007 = parseInt(tP0007) + parseInt(returnValue[i].TP_0007);
        tP0011 = parseInt(tP0011) + parseInt(returnValue[i].TP_0011);
        tP0014 = parseInt(tP0014) + parseInt(returnValue[i].TP_0014);
        tP0005 = parseInt(tP0005) + parseInt(returnValue[i].TP_0005);
        tP0010 = parseInt(tP0010) + parseInt(returnValue[i].TP_0010);
        tP0012 = parseInt(tP0012) + parseInt(returnValue[i].TP_0012);
        tP0008 = parseInt(tP0008) + parseInt(returnValue[i].TP_0008);
        tP0003 = parseInt(tP0003) + parseInt(returnValue[i].TP_0003);
        tP0013 = parseInt(tP0013) + parseInt(returnValue[i].TP_0013);
        tP0006 = parseInt(tP0006) + parseInt(returnValue[i].TP_0006);
        tP0002 = parseInt(tP0002) + parseInt(returnValue[i].TP_0002);
      }
      var totalCreditRisk = tP0006;
      var totalsRow = {
        TP_ProposedAmmount: $A.get('$Label.c.Arc_Gen_UtilityBarTotals') + ' (' + currency + '/' + unitType + ')',
        TP_0007: '' + tP0007,
        TP_0011: '' + tP0011,
        TP_0014: '' + tP0014,
        TP_0005: '' + tP0005,
        TP_0010: '' + tP0010,
        TP_0012: '' + tP0012,
        TP_0008: '' + tP0008,
        TP_0002: '' + tP0002,
        TP_0003: '' + tP0003,
        TP_0013: '' + tP0013,
        TP_0006: '' + tP0006,
        TP_Percentage: '100' + ' %'
      };
      var totalArray = component.get('v.data');
      totalArray.push(totalsRow);
      for (var j = 0; j < totalArray.length; j++) {
        totalArray[j].TP_Percentage = ((parseInt(totalArray[j].TP_0006) * 100 / parseInt(totalCreditRisk)).toFixed(2)).toString() + ' %';
        totalArray[j].TP_0006 = '' + totalArray[j].TP_0006;
      }
      component.set('v.data', totalArray);
      resolve();
    }));
  }
});