({
  helperMethod: function(cmp) {
    var action = cmp.get('c.getIdCont');
    action.setParams({
      idAcc: cmp.get('v.recordId'),
      section: cmp.get('v.section')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp !== '') {
          cmp.set('v.viewFile', false);
          this.printView(cmp, resp);
        }
      } else if (state === 'ERROR') {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
          }
        } else {
          console.log('Unknown error');
        }
      }
    });
    $A.enqueueAction(action);
  },
  updateName: function(cmp, idFil) {
    var action = cmp.get('c.updateFile');
    action.setParams({
      idFile: idFil,
      section: cmp.get('v.section')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        if (resp) {
          this.printView(cmp, idFil);
        }
      } else if (state === 'ERROR') {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
          }
        } else {
          console.log('Unknown error');
        }
      }
    });
    $A.enqueueAction(action);
  },
  printView: function(cmp, IdR) {
    $A.createComponent('lightning:fileCard', { 'fileId': IdR }, function(view, status, errorMessage) {
      if (status === 'SUCCESS') {
        const body = view;
        cmp.set('v.body', body);
      } else if (status === 'INCOMPLETE') {
        console.log('No response from server or client is offline.');
      } else if (status === 'ERROR') {
        console.log('Error: ' + errorMessage);
      }
    });
  }
});