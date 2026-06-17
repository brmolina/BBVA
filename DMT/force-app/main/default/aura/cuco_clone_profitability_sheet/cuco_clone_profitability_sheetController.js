/* eslint-disable no-unused-expressions */
({
  doInit: function(cmp, event, helper) {
    helper.doInit(cmp, event, helper);
  },
  handleCheckBox: function(cmp, event) {
    if (event.getSource().get('v.name') === 'clonefr' && event.getSource().get('v.checked') === false)  {
      cmp.find("clonesc").set("v.checked", true);
    }
    if (event.getSource().get('v.name') === 'clonesc' && event.getSource().get('v.checked') === false)  {
      cmp.find("clonefr").set("v.checked", true);
    }
  },
  handleOnSubmit: function(cmp, event, helper) {
    event.preventDefault();

    let validate = true;
    ["name", "group"].forEach((a) => {
      validate = validate && cmp.find(a).reportValidity();
      console.log(a, cmp.find(a).reportValidity());
    });

    var cloneName = cmp.find("name").get("v.value");

    if (validate) {

      helper.waiting(cmp);
      var action = cmp.get('c.clone');

      action.setParams({
        name: cloneName,
        profSheetId: cmp.get('v.recordId'),
        groupId: cmp.find("group").get("v.value"),
        clonefr: cmp.find("clonefr").get("v.checked"),
        clonesc: cmp.find("clonesc").get("v.checked")
      });

      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var result = response.getReturnValue();
          if (result.success) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
              title: "Success",
              type: "success",
              mode: "dismissible",
              duration: "30000",
              message: 'This is a required message',
              messageTemplate: $A.get("$Label.c.cuco_clone_success") + ' {0}.',
              messageTemplateData: [
                {
                  url: '/' + result.profAId,
                  label: cloneName
                }
              ]
            });
            toastEvent.fire();
          } else {
            helper.showToast('Error', 'error', $A.get("$Label.c.cuco_clone_error"));
          }
          helper.closePanel();
        } else if (state === 'INCOMPLETE') {
          console.log('INCOMPLETE', response);
        } else if (state === 'ERROR') {
          var errors = response.getError();
          console.error('Error message: ' + errors[0].message);
        }
        helper.doneWaiting(cmp);
      });
      $A.enqueueAction(action);
    }
  },
  handleCancel: function(cmp, event, helper) {
    helper.closePanel();
  },
  dismissWarning: function(cmp) {
    cmp.set('v.showWarning', false);
  }
});