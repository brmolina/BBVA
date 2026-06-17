/* eslint-disable no-unused-expressions */
({
    setColumns : function(component, event, helper) {
        let columnsArray = $A.get('$Label.c.KPI_DetailTable_Columns');
        let columnsList = columnsArray.split('||');

        var columns = [];
        columns = [
          {label: "KPI Catalogue", fieldName: 'catalogue', type: 'text', wrapText: true},
          {label: "KPI number", fieldName: 'kpiNumber', type: 'text', cellAttributes: {alignment: 'right'}},
          {label: "KPI descirption", fieldName: 'kpiDescription', type: 'text', cellAttributes: {alignment: 'right'}},
          {label: "Price impact", fieldName: 'priceImpact', type: 'text', editable: true, cellAttributes: {alignment: 'right'}},
          {label: "Baseline target" , fieldName: 'target', type: 'text', editable: true, cellAttributes: {alignment: 'right'}},
          {label: "Effective Start Date", fieldName: 'effStartDate', type: 'date', editable: true, 
          typeAttributes: {year: 'numeric', month: 'short', day: 'numeric'}, cellAttributes: {alignment: 'right'}},
          {label: "Efective End Date", fieldName: 'effEndDate', type: 'date', editable: true,
           typeAttributes: {year: 'numeric', month: 'short', day: 'numeric'}, cellAttributes: {alignment: 'right'}},
          {label: "Minimum Criteria", fieldName: 'minCriteria', type: 'text', editable: true, cellAttributes: {alignment: 'right'}},
          {label: "Minimum value", fieldName: 'minValue', type: 'percent', editable: true, cellAttributes: {alignment: 'right'}},
          {type: 'action', typeAttributes: {rowActions: [{label: 'Show details', name: 'show_details'}, {label: 'Delete', name: 'delete'}]}}
        ]
        component.set('v.columns', columns);
    },

    setData : function(component, helper) {
      helper.getObligation(component).then(result => {
        if (result.success) {
          var tableData = [];
          result.data.forEach( data =>  {
            data.actions.forEach( action =>  {
              action.triggers.forEach( (trigger, index) =>  {
                var rowData = {
                  catalogue: trigger.name,
                  kpiNumber: trigger.sortOrder,
                  kpiDescription: trigger.obligationReviewWorkflowId,
                  target: trigger.scale.obligationReviewWorkflowId,
                  priceImpact: trigger.scale.rate,
                  effStartDate: trigger.scale.effectiveStartDate,
                  effEndDate: trigger.scale.effectiveEndDate,
                  minCriteria: trigger.scale.criteriaIdMinimum,
                  minValue: trigger.scale.criteriaValueMinimum,
                  kpiId: trigger.scale.id
                };
                tableData.push(rowData);
              });
            });
          });

          tableData.push({});

          component.set('v.detailData', tableData);

        } else {
            helper.showToast('error', 'Error', result.message);
            console.error(result.message);
        }
      }).catch(function(error) {
          $A.reportError('Search Failed', error);
      });
    },

    removeKpi: function (cmp, row) {
      var rows = cmp.get('v.data');
      var rowIndex = rows.indexOf(row);
      rows.splice(rowIndex, 1);
      cmp.set('v.detailData', rows);
    },

    save: function (cmp, helper, draftValues) {
      // call save service
      helper.updateKPIs(draftValues).then($A.getCallback( result => {
          if (result.success) {

              if (Object.keys(result.errors).length > 0) {
                  cmp.set('v.errors', result.errors);

              } else {
                  cmp.set('v.errors', []);
                  cmp.set('v.draftValues', []);
                  cmp.set('v.showSaveButton', false);
                  helper.setData(cmp);
              }
          } else {
              var errors = result.errors;
              console.error(errors);
          }
        }));
    },

    updateKPIs: function(values) {
      return new Promise($A.getCallback(function(resolve, reject) {


        var action = component.get('c.updateKPIs');
        action.setParams(params);

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
              if (errors) {
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
      }));
    },

    getObligation: function(component) {
      return new Promise($A.getCallback(function(resolve, reject) {

        var contract = component.get('v.contract');
        var action = component.get('c.getObligation');

        action.setParams({
          contract: contract.operationId,
          category: contract.sustainableSubCategory
        });

        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            var result = response.getReturnValue();
            console.log('result', result);
            resolve(result);
          } else {
            if (state === 'INCOMPLETE') {
              console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
              var errors = response.getError();
              if (errors) {
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
      }));
    }

})