({ // eslint-disable-line 
  callServerData: function(cmp, evt, helper) {
    var cssClassName = cmp.get('v.cssClassName');
    var cmpTarget = cmp.find('changeIt');
    var tdivTarget = cmp.find('tdiv');

    if (cssClassName === 'Vertical_Clear') {
      cmp.set('v.Vertical_Clear', true);
      cmpTarget = cmp.find('changeIt');

      $A.util.addClass(cmpTarget, 'Normal');
      $A.util.removeClass(cmpTarget, 'One');
    } else if (cssClassName === 'Horizontal_Grey_Space') {
      cmp.set('v.Horizontal_Grey_Space', true);
      cmpTarget = cmp.find('changeIt');

      $A.util.addClass(cmpTarget, 'One');
      $A.util.removeClass(cmpTarget, 'Normal');
    } else if (cssClassName === 'Horizontal_Grey_No_Space') {
      cmp.set('v.Horizontal_Grey_No_Space', true);
      cmpTarget = cmp.find('changeIt');

      $A.util.addClass(cmpTarget, 'Two');
      $A.util.removeClass(cmpTarget, 'Normal');
    } else if (cssClassName === 'Vertical_Grey') {
      cmp.set('v.Vertical_Grey', true);
      cmpTarget = cmp.find('changeIt');

      $A.util.addClass(cmpTarget, 'Normal');
      $A.util.removeClass(cmpTarget, 'One');
    }
      else if (cssClassName === 'Row') {
      cmp.set('v.Row', true);
      cmpTarget = cmp.find('changeIt');

      $A.util.addClass(cmpTarget, 'Normal');
      $A.util.removeClass(cmpTarget, 'One');
    } 

    var action = cmp.get('c.getTableJSON');
    action.setParams({
      recordId: cmp.get('v.recordId'),
      objectName: cmp.get('v.sObjectName'),
      fieldsToDisplay: cmp.get('v.fieldsToDisplay')
    });

    action.setCallback(this, function(response) {
      if (cmp.isValid() && response.getState() === 'SUCCESS') {
        var objectReturn = JSON.parse(response.getReturnValue());
        var fieldsToDisplay = cmp.get('v.fieldsToDisplay');
        var fieldsArray = fieldsToDisplay.split(',');

        cmp.set('v.fieldsArray', fieldsArray);
        cmp.set('v.complexObject', objectReturn);
        cmp.set('{!v.fieldLabels}', objectReturn.fLabelstList.fieldLabels);
        cmp.set('v.detailsComponent', true);

          if (helper.allFieldsAreEmpty(fieldsArray, objectReturn) && cssClassName === 'Row'){
             helper.fetchSuccess(response, cmp, action); 
          } else if (cssClassName !== 'Row'){
          	cmp.set('v.showComponent', !helper.allFieldsAreEmpty(fieldsArray, objectReturn));
          }
        
        var fieldSize = objectReturn.fLabelstList.fieldLabels.length - 1;
        cmp.set('v.fieldLabelSize', fieldSize);
      } else {
        var errors = response.getError();
        var errorMessage = errors[0].message;
        var toastError = $A.get('e.force:showToast');

        toastError.setParams({
          'title': 'Error!',
          'type': 'error',
          'message': errorMessage
        });
        toastError.fire();
      }
    });

    $A.enqueueAction(action);
  },
     fetchSuccess: function(response, component, action) {
     var flow = {     
      setAttributesNoRecords: function() {
        //If there are no records for the related object, display a custom label message or a default one    
          component.set('v.noRecordsReturned', true);
      }
    };
    flow.setAttributesNoRecords();    
  },

  allFieldsAreEmpty: function(fieldsArray, objectReturn) {
    var i = 0;

    for (var key in fieldsArray) {
      if (key) {
        var fieldName = fieldsArray[key];

        if (objectReturn.ParentRecords.ParentRecord[0][fieldName] === null ||
            objectReturn.ParentRecords.ParentRecord[0][fieldName] === undefined ||
            objectReturn.ParentRecords.ParentRecord[0][fieldName] === 0) {
          i++;
        }
      }
    }

    /* When all the lines has null, undefined or '0' values then the component must not be shown */
    return (i === fieldsArray.length);
  },
});