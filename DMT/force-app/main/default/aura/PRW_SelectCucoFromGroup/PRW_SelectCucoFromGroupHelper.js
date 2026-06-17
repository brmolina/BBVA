({
  getDataFromGroup: function (component, helper) {
    var getCucos = component.get('c.getCucoFromGroup');
    getCucos.setParams({
      accId: component.get('v.recordId'),
      accName: null,
      table: null
    });
    var promise = this.promisifyTabGroup(getCucos);
    return promise.then(
      $A.getCallback(function (result) {
        component.set('v.tableData', JSON.parse(result));
        component.set('v.originalData', JSON.parse(result));
        helper.setData(component);
      }),
      $A.getCallback(function (error) {
        console.error('Error calling action "' + getCucos + '" with state: ' + error.message);
      })
    ).catch(function (e) {
    });
  },
  getFilterDataFromGroup: function (component, event, helper) {
    var getCucos = component.get('c.getCucoFromGroup');
    getCucos.setParams({
      accId: component.get('v.recordId'),
      accName: event.getSource().get('v.value'),
      table: JSON.stringify(component.get('v.tableData'))
    });
    var promise = this.promisifyTabGroup(getCucos);
    return promise.then(
      $A.getCallback(function (result) {
        component.set('v.tableData', JSON.parse(result));
        helper.setData(component);
      }),
      $A.getCallback(function (error) {
        console.error('Error calling action "' + getCucos + '" with state: ' + error.message);
      })
    ).catch(function (e) {
    });
  },
  setData: function (component, helper) {
    let wrapper = component.get('v.tableData');
    let getUrl = window.location;
    let baseUrl = getUrl.protocol + "//" + getUrl.host + "/";
    let tabUrl = 'lightning/n/PRW_LightningTab/?';
    let urlAcc = '&c__accountId=';
    let urlStart = '&c__startDate=';
    let urlEnd = '&c__endDate=';
    let urlSheetSFId = '&c__sheetSFId=';
    let urlSheetId = '&c__sheetId=';
    let urlListAcc = '&c__lAccountId=';
    let urlIsGroup = '&c__isGroup=true';
    let firstName = '';
    let rows = [];
    let rowsNoCuCo = [];
    for (let i = 0; i < wrapper.length; i++) {
      let clients = [];
      let clientsID=[];
      var aux = new Array();

      for (let id in wrapper[i].mFilialIDName) {
        if(!(aux.includes(wrapper[i].mFilialIDName[id]) && wrapper[i].cucoID == 'nocuco') || wrapper[i].mFilialIDName[id]!==null){
         clients.push({ 
            name: i + '-' + id, 
            idCucoClient: baseUrl + id,
            classNameURL:'client-row no-url',
            nameCucoClient: wrapper[i].mFilialIDName[id],
            numberClients: undefined, 
            statement: undefined,
            expiration: undefined, 
            className: 'client-row'
          });
          clientsID.push(id);
          aux.push(wrapper[i].mFilialIDName[id]);
        }
      }
      clients.reverse();
      let expDate;
      if (wrapper[i].expirationDate !== undefined && wrapper[i].expirationDate !== null && wrapper[i].expirationDate !== 'null') {
        expDate = wrapper[i].expirationDate.split('-')[2] + '/' + wrapper[i].expirationDate.split('-')[1] + '/' + wrapper[i].expirationDate.split('-')[0];
      }

      if (firstName === '') firstName = wrapper[i].cucoID;
      let urlWithParameters;
      
      if (wrapper[i].cucoID !== 'nocuco') {
        urlWithParameters = baseUrl + tabUrl;
        urlWithParameters +=  urlAcc + component.get('v.recordId');
        urlWithParameters +=  urlStart + wrapper[i].startDate;
        urlWithParameters +=  urlEnd + wrapper[i].expirationDate;
        urlWithParameters +=  urlSheetSFId + wrapper[i].cucoID;
        urlWithParameters +=  urlSheetId + wrapper[i].codeID;
        urlWithParameters +=  urlListAcc + clientsID.join('-');
        urlWithParameters +=  urlIsGroup;
        rows.push({
          name: wrapper[i].cucoID,
          idCucoClient: urlWithParameters, 
          nameCucoClient: wrapper[i].cucoName,
          numberClients: clients.length, 
          statement: wrapper[i].statement,
          expiration: expDate,
          _children: clients
        });
      } else { 
          rowsNoCuCo.push({ 
            name: wrapper[i].cucoID, 
            idCucoClient: '#', 
            className:'no-url', 
            nameCucoClient: wrapper[i].cucoName, 
            numberClients: clients.length, 
            _children: clients });        
      }
    }
    component.set('v.gridDataCuCo', rows);
    component.set('v.gridDataNoCuCo', rowsNoCuCo);

    if(rows.length == 0) {
      component.set('v.emptyDataCuCo', true);
    } else {
      component.set('v.emptyDataCuCo', false);
    }

    if(rowsNoCuCo.length == 0) {
      component.set('v.emptyDataNoCuCo', true);
    } else {
      component.set('v.emptyDataNoCuCo', false);
    }

    let expandedRows = [firstName];

    component.set('v.gridExpandedRows', expandedRows);
  },
  setTable: function (component) {
    var columns = [
      {
        type: 'url',
        fieldName: 'idCucoClient',
        label: $A.get("$Label.c.PRW_SelectCucoFromGroup_Header1"),
        initialWidth: 220,
        typeAttributes: {
          label: {
            fieldName: 'nameCucoClient'
          }
        },
        cellAttributes: {
          class: {
            fieldName: 'classNameURL'
          }
        }
      },
      {
        type: 'number',
        fieldName: 'numberClients',
        label: $A.get("$Label.c.PRW_SelectCucoFromGroup_Header2")
      },
      {
        type: 'text',
        fieldName: 'statement',
        label: $A.get("$Label.c.PRW_SelectCucoFromGroup_Header3"),
        cellAttributes: {
          iconName: 'utility:success',
          iconPosition: 'left',
          class: {
            fieldName: 'className'
          }
        }
      },
      {
        type: 'text',
        fieldName: 'expiration',
        label: $A.get("$Label.c.PRW_SelectCucoFromGroup_Header4")
      }
    ];

    var columnsNoCuCo = [
      {
        type: 'url',
        fieldName: 'idCucoClient',
        label: $A.get("$Label.c.PRW_SelectCucoFromGroup_Header5"),
        initialWidth: 300,
        typeAttributes: {
          label: {
            fieldName: 'nameCucoClient'
          }
        },
        cellAttributes: {
          class: {
            fieldName: 'className'
          }
        }
      },
      {
        type: 'number',
        fieldName: 'numberClients',
        label: $A.get("$Label.c.PRW_SelectCucoFromGroup_Header2")
      }
    ];

    component.set('v.gridColumns', columns);
    component.set('v.gridColumnsNoCuCo', columnsNoCuCo);
  },
  promisifyTabGroup: function (actionGroupInfo) {
    return new Promise((resolve, reject) => {
      actionGroupInfo.setCallback(this, function (response) {
        const statusGrInfo = response.getState();
        if (statusGrInfo === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else if (statusGrInfo === 'ERROR') {
          var errorsGRInfo = response.getError();
          if (errorsGRInfo) {
            if (errorsGRInfo[0] && errorsGRInfo[0].message) {
              reject(Error('Error message: ' + errorsGRInfo[0].message));
            }
          } else {
            reject(Error('Unknown error'));
          }
        }
      });

      $A.enqueueAction(actionGroupInfo);
    });
  }
})