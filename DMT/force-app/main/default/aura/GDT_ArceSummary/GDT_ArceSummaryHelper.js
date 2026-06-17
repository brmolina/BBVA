({
    getIfisPath: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getAccountIfisPath"); 
        action.setParams({"account":recordId});
        
        action.setCallback(this, function (response) { 
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                switch (result) {
                  case '01':
                    component.set('v.path01', true); 
                    break;
                  case '02':
                    component.set('v.path02', true);
                    break;
                  case '1':
                    component.set('v.path1', true);
                    break;
                  case '2':
                    component.set('v.path2', true);
                    break;
                  case '3':
                    component.set('v.path3', true);
                }
                component.set('v.isValidated', true); 
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                        console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action); 
    },

    getAccHasAnalysis: function(component, event, helper) {
          var recordId = component.get("v.recordId");
          var action = component.get("c.getAccAHA"); 
          action.setParams({"account":recordId});
          
          action.setCallback(this, function (response) { 
              var state = response.getState();
              if (state === 'SUCCESS') {
                  var result = response.getReturnValue();
                  component.set('v.idSelect', result); 
              } else if (state === 'ERROR') {
                  var errors = response.getError();
                  if (errors) {
                      if (errors[0] && errors[0].message) {
                          console.log("Error message: " + errors[0].message);
                      }
                  } else {
                          console.log("Unknown error");
                  }
              }
          });
          $A.enqueueAction(action); 
      }
})