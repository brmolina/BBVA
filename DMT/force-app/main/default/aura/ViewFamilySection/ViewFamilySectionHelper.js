({
  retrieveParams : function(cmp, event, helper) {
      var myPageRef = cmp.get("v.pageReference");
      console.log('::::::mypageref::::::' + myPageRef);
      var familyChecked = myPageRef.state.c__familyChecked;
      console.log('::::::familyChecked::::::' + familyChecked);
      if(familyChecked != undefined){
        cmp.set("v.familyChecked", familyChecked);
      }
      var recordId = myPageRef.state.c__recordId;
      console.log('::::::recordId::::::' + recordId);

      if(familyChecked != undefined){
        cmp.set("v.recordId", recordId);
      }
  },
  navigateGoBackAccount : function(cmp, event, helper) {
      cmp.find("nav").navigate({
        type: "standard__recordPage",
        attributes: {
          recordId: cmp.get("v.recordId"),
            objectApiName: "PersonAccount",
            actionName: "view"
          }
      });
  },
  reloadRecord : function(cmp, event, helper){
    cmp.find("forceRecordCmp").reloadRecord();
  },
  firstPromise : function(cmp, event, helper) {
      var family = cmp.get("v.familyChecked");
      var action = cmp.get("c.legalLogicUser");
      action.setParams( {profile: family, recordId: cmp.get('v.recordId'),});
        return new Promise($A.getCallback(function (resolve, reject) {
          action.setCallback(this, function (response) {
              var state = response.getState();
              if (state === "SUCCESS") {
                cmp.set("v.legal", response.getReturnValue());
                cmp.set("v.onload", true);
              } else if (state === "ERROR") {
                  var errors = response.getError();
                  if (errors) {
                    if (errors[0] && errors[0].message) {
                      console.log("Error message: " +
                         errors[0].message);
                    }
                  } else {
                    console.log("Unknown error");
                  }
              }
          })
          $A.enqueueAction(action);
      }));
}
})