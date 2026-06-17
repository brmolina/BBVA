({ //eslint-disable-line
  fetchComponentData: function(component, event, helper) {
    var action = component.get('c.buildTable');
    var fieldsToSplit = component.get('v.fieldsToDisplay');

    //Split the fields that are entered to be used in the sub component
    var res = fieldsToSplit.split(',');
    var splittedFields = [];

    for (var i = 0; i < res.length; i++) {
      var fieldValue = res[i];
      splittedFields.push(fieldValue);
    }

    //Set the field name attribute to be used in the sub component
    // component.set("{!v.fieldNames}", splittedFields);

    //Set the parameters for the buildTable method in the Apex Class
    action.setParams({
      'recordId': component.get('v.recordId'),
      'fields': component.get('v.fieldsToDisplay'),
      'parentRecordTypesForDisplay': component.get('v.parentRecordTypesForDisplay'),
      'childDeveloperName': component.get('v.relatedObjectName'),
      'customLabelAPIname': component.get('v.customLabelAPIname'),
      'whereClause': component.get('v.WhereClause'),
      'totalRowFieldsToDisplay': component.get('v.totalRowFieldsToDisplay'),
      'customLabelAPInameReceived': component.get('v.customLabelAPIname'),
      'labelsToDisplayFromParent': component.get('v.labelsToDisplayFromParent')
    });

    action.setCallback(this, function(response) {
      var responseBool = false;

      if (response.getState() === 'SUCCESS') {
        helper.fetchSuccess(response, component, action, res);
      } else if (response.getState() === 'ERROR') {
        var errors = response.getError();
        var errorMessage = errors[0].message;
      }
    });

    $A.enqueueAction(action);

    component.set('v.showComponentForRecType', true);
  },

  fetchSuccess: function(response, component, action, res) {

    var flow = {
      setAttributes: function() {
        //The return object is a Json String. Parse the string for the list of Sobjects and Field Labels
        var objectReturn = JSON.parse(response.getReturnValue());

        //Mark an action as storable to have its response stored in the client-side cache by the framework. Caching can be useful if you want your
        //app to be functional for devices that temporarily don’t have a network connection.
        action.setStorable({ 'ignoreExisting': 'true' });

        //Set the Sobjects and field labels attributes from the Json String

        //TODO: froucher. Change Name of sObject, because it an inherite dattribute
        component.set('v.childObjects', objectReturn.ChildObjectList.ChildObjects);
        component.set('v.complexObject', objectReturn);
        component.set('v.fieldLabels', objectReturn.fLabelstList.fLabels);
        component.set('v.showComponentForRecType', objectReturn.showTheComponent.showComponent);
        component.set('v.parentSobject', objectReturn.ParentRecords.ParentRecord);
        component.set('v.fieldDescription', objectReturn.childFieldDescriptions.childFieldDescriptionList);
        component.set('v.fieldNames', objectReturn.listOfFields.StringList);

        return objectReturn;
      },

      setAttributesNoInRecordType: function() {
        //getReference now working in Winter17 Dynamically get the Custom label name from the Input and set to the
        // v.labelMessage attribute
        if (component.get('v.customLabelAPIname') !== null) {
          var customLabelInput = component.get('v.customLabelAPIname');
          if (customLabelInput && customLabelInput !== '') {
            var labelReference = $A.getReference('$Label.c.' + customLabelInput);
            component.set('v.labelMessage', labelReference);
            component.set('v.showNoComponentMessage', true);
          } else {
            component.set('v.showNoComponentMessage', false);
          }
        } else {
          component.set('v.showNoComponentMessage', false);
        }
      },

      setAttributesTotals: function(totalMap) {
        //If the Total Row is displayed get the value from the totalMap and display for each field
        //The first column will have the value 'Total'
        var showTotalsRow = Object.keys(totalMap).length > 0;
        component.set('v.showTotalsRow', showTotalsRow);

        if (showTotalsRow) {
          var micm = component.find('micm');

          if (micm.length > 0) {
            for (var x = 0; x < micm.length; x++) {
              var key = micm[x].get('v.fieldName');
              if (totalMap[key]) {
                micm[x].set('v.FieldValue', parseFloat(totalMap[key]));
                micm[x].set('v.theMapValue', parseFloat(totalMap[key]));
              } else {
                if (x === 0) {
                  micm[0].set('v.FieldValue', 'Total');
                } else {
                  micm[x].set('v.FieldValue', '');
                }
              }
            }
          }
        }
      },

      setAttributesNoRecords: function() {
        //If there are no records for the related object, display a custom label message or a default one
        if (component.get('v.childObjects').length < 1) {
          component.set('v.showComponentForRecType', false);
          component.set('v.noRecordsReturned', true);
          var noRecordsLabelName = component.get('v.noRecordscustomLabelAPIname');
          if (!noRecordsLabelName || noRecordsLabelName === undefined || noRecordsLabelName === '') {
            component.set('v.NoRecordsLabelMessage', 'There are no records for this object');
          } else {
            var noRecordsCustomLabelInput = component.get('v.noRecordscustomLabelAPIname');
            var noRecordsLabelReference = $A.getReference('$Label.c.' + noRecordsCustomLabelInput);
            component.set('v.NoRecordsLabelMessage', noRecordsLabelReference);
          }
        }
      }
    };

    var objectReturn = flow.setAttributes();
    flow.setAttributesNoInRecordType();
    flow.setAttributesTotals(objectReturn.FieldTotalMap.FieldTotalSum);
    flow.setAttributesNoRecords();
  }
});