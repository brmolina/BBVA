/* eslint-disable no-unused-expressions */
({
  setColumns: function(component) {
    let columnsMainArray = $A.get('$Label.c.KPI_MainTable_Columns');
    let columnsList = columnsMainArray.split('||');
    let numColumns = columnsList.length;

    var columnsMain = [];
    columnsMain = [
      {
        label: columnsList[numColumns - (numColumns - 8)],
        fieldName: 'bookingCountry',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: columnsList[0],
        fieldName: 'businessArea',
        type: 'text',
        cellAttributes: { alignment: 'left' },
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 10)],
        fieldName: 'product',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 3)],
        fieldName: 'client',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 1)],
        fieldName: 'sector',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: 'Transactional Banker',
        fieldName: 'transactional',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 2)],
        fieldName: 'operationId',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 4)],
        fieldName: 'initialDate',
        cellAttributes: { alignment: 'left' },
        type: 'date-local',
        typeAttributes: {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit'
        },
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 5)],
        fieldName: 'finalDate',
        cellAttributes: { alignment: 'left' },
        type: 'date-local',
        typeAttributes: {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit'
        },
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 6)],
        fieldName: 'initialAmount',
        cellAttributes: { alignment: 'left' },
        type: 'number',
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 7)],
        fieldName: 'currency',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 9)],
        fieldName: 'sustainableSubCategory',
        cellAttributes: { alignment: 'left' },
        type: 'text',
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 14)],
        fieldName: 'initialFee',
        cellAttributes: { alignment: 'left' },
        type: 'number',
        editable: { fieldName: 'editable' },
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 15)],
        fieldName: 'initialMargin',
        cellAttributes: { alignment: 'left' },
        type: 'number',
        editable: { fieldName: 'editable' },
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 18)],
        fieldName: 'currentMargin',
        cellAttributes: { alignment: 'left' },
        type: 'number',
        editable: { fieldName: 'editable' },
        wrapText: true
      },
      {
        label: columnsList[numColumns - (numColumns - 19)],
        fieldName: 'currentFee',
        cellAttributes: { alignment: 'left' },
        type: 'number',
        editable: { fieldName: 'editable' },
        wrapText: true
      },
      {
        type: 'button',
        initialWidth: 100,
        typeAttributes: {
          label: 'View KPI',
          name: 'view_details',
          title: 'Click to View KPI',
          class: 'classButton'
        }
      }
    ];
    component.set('v.columnsMain', columnsMain);
  },

  doSearch: function(component, params, operation) {
    if (operation !== 'update') {
      return;
    }

    return new Promise(
      $A.getCallback(function(resolve, reject) {
        var action = component.get('c.putFinantialCustomer');
        action.setParams(params.action);
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            var result = response.getReturnValue();
            resolve(result);
          } else {
            if (state === 'INCOMPLETE') {
              console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
              var errors = response.getError();
              if (Array.isArray(errors)) {
                if (errors[0] && errors[0].message) {
                  console.error('Error message: ' + errors[0].message);
                }
              } else {
                console.error('Unknown error');
              }
            }
            reject(state);
          }
        });
        $A.enqueueAction(action);
      })
    );
  },

  buildTable: function(component, results) {
    var tableData = [];
    results.data.forEach((client) => {
      client.contracts.forEach((row, index) => {
        var rowData = {
          businessArea: this.checkUndefined(row, [ 'businessArea' ]),
          operationId: this.checkUndefined(row, [ 'codeLocal' ]),
          sustainableSubCategoryId: this.checkUndefined(row, [
            'sustainabilityFamily',
            'sustainabilityCategory',
            'id'
          ]),
          client: this.checkUndefined(client, [ 'name' ]),
          clientId: this.checkUndefined(client, [ 'code' ]),
          initialDate: this.checkUndefined(row, [ 'initialDate' ]),
          finalDate: this.checkUndefined(row, [ 'sustainabilityDate' ]),
          initialAmount: this.checkUndefined(row, [ 'initialMainAmount' ]),
          currency: this.checkUndefined(row, [ 'productCurrency' ]),
          bookingCountry: this.checkUndefined(client, [
            'country',
            'description'
          ]),
          sustainableSubCategory: this.checkUndefined(row, [
            'sustainabilityFamily',
            'sustainabilityCategory',
            'description'
          ]),
          kpiDetailsId: index,
          contractId: this.checkUndefined(row, [ 'id' ]),
          editable:
            this.checkUndefined(row, [ 'nameOriginSystem' ]) === 'CLAN' ||
            this.checkUndefined(row, [ 'nameOriginSystem' ]) === 'Clan (delta)'
              ? false
              : true,
          sector: this.checkUndefined(client, [
            'clientGroup',
            'sector',
            'description'
          ]),
          product: this.checkUndefined(row, ['product', 'description']),
          sustAgentId: this.checkUndefined(row, [
            'sustainabilityFamily',
            'sustainabilyAgentId'
          ]),
          sustCoordinator: this.checkUndefined(row, [
            'sustainabilityFamily',
            'sustainableCoordinator'
          ]),
          sustCoordinatorFee: this.checkUndefined(row, [
            'sustainabilityFamily',
            'feeSustainableCoordinator'
          ]),
          initialFee: this.checkUndefined(row, [ 'initialObligationFee' ]),
          initialMargin: this.checkUndefined(row, [ 'initialMarginFee' ]),
          currentMargin: this.checkUndefined(row, [ 'currentMargin' ]),
          currentFee: this.checkUndefined(row, [ 'currentFee' ]),
          activity: this.checkUndefined(client, [
            'group',
            'activity',
            'description'
          ])
        };
        tableData.push(rowData);
      });
    });
    component.set('v.mainData', tableData);
  },
  checkUndefined: function(data, params) {
    try {
      var dynamicData = data;
      params.forEach((param) => {
        dynamicData = dynamicData[param];
      });
      return dynamicData;
    } catch (exception) {
      return undefined;
    }
  },

  buildPagination: function(component, results) {
    var page = results.pagination.page;
    var pageSize = results.pagination.pageSize;
    var total = results.pagination.totalElements;
    var elements = 0;
    results.data.forEach((group) => {
      elements += group.contracts.length;
    });
    let displayFrom;
    if (total === 0) {
      displayFrom = 0;
    } else if (page === 1) {
      displayFrom = 1;
    } else {
      displayFrom = (page - 1) * pageSize + 1;
    }
    let displayTo;
    if (total === 0) {
      displayTo = 0;
    } else if (total <= pageSize || pageSize * page > total) {
      displayTo = total;
    } else {
      displayTo = pageSize * page;
    }
    let pageNumbers =
      Math.ceil(total / pageSize) === 0 ? 1 : Math.ceil(total / pageSize);
    var displaying =
      'Displaying ' +
      displayFrom +
      ' to ' +
      displayTo +
      ' of ' +
      total +
      '. Page ' +
      page +
      ' of ' +
      pageNumbers;

    component.set('v.currentPage', page);
    component.set('v.pageSize', pageSize);
    component.set('v.disabledPrevious', page <= 1);
    component.set('v.disabledNext', displayTo >= total);
    component.set('v.displaying', displaying);
  },

  showRowDetails: function(component, helper, row, sameRowDetail) {
    let attribs = {
      'aura:id': 'KPI_DetailsComponent',
      contract: row,
      onclosemodal: component.getReference('c.closeModal'),
      sameRowDetail: sameRowDetail
    };

    helper.loadComponent(helper, 'kpi_detail_table', attribs).then(
      $A.getCallback((newCmp) => {
        let body = [];
        body.push(newCmp);
        component.set('v.body', body);
      })
    );
  },

  loadComponent: function(helper, name, attribs) {
    return new Promise(
      $A.getCallback(function(resolve, reject) {
        $A.createComponent(
          'c:' + name,
          attribs,
          function(comp, status, errorMessage) {
            if (status === 'SUCCESS') {
              resolve(comp);
            } else if (status === 'INCOMPLETE' || status === 'ERROR') {
              console.error(errorMessage);
            }
          }
        );
      })
    );
  },

  waiting: function(component) {
    component.set('v.waiting', true);
  },

  doneWaiting: function(component) {
    component.set('v.waiting', false);
  },

  showToast: function(type, title, message) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      title: title,
      message: message,
      duration: 5000,
      key: 'info_alt',
      type: type,
      mode: 'dismissible'
    });
    toastEvent.fire();
  },
  saveEdition: function(component, draftValues, helper) {
    try {
      var dataList = [];
      var dataToSend = [];
      var tableData = component.get('v.mainData');
      var draftValueID;
      draftValues.forEach((draftValue) => {
        draftValueID = draftValue.id.substring(4);
        for (let propertie in draftValue) {
          if (propertie === 'id') {
            continue;
          }
          tableData[draftValueID][propertie] = draftValue[propertie];
        }
        if (!dataList[tableData[draftValueID].clientId]) {
          dataList[tableData[draftValueID].clientId] = [];
        }
        dataList[tableData[draftValueID].clientId].push({
          id: tableData[draftValueID].contractId,
          initialObligationFee: tableData[draftValueID].initialFee,
          initialMarginFee: tableData[draftValueID].initialMargin,
          currentMargin: tableData[draftValueID].currentMargin,
          currentFee: tableData[draftValueID].currentFee,
          sustainabilityFamily: {
            sustainabilyAgentId: tableData[draftValueID].sustAgentId,
            sustainableCoordinator: tableData[draftValueID].sustCoordinator,
            feeSustainableCoordinator:
              tableData[draftValueID].sustCoordinatorFee
          }
        });
      });

      Object.keys(dataList).forEach((key) => {
        dataToSend.push({
          code: key,
          contracts: dataList[key]
        });
      });
      helper
        .doSearch(
          component,
          {
            action: {
              updateRequest: JSON.stringify({ data: dataToSend })
            }
          },
          'update'
        )
        .then((result) => {
          if (!result.success) {
            throw new Error(result.message);
          }
        });

      component.set('v.mainData', tableData);
      component.set('v.draftValues', []);
    } catch (e) {
      console.error(e);
      helper.showToast('error', 'Error en la actualizacion de operaciones', e);
    }
  }
});