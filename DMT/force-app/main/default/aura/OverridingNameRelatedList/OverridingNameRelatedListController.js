({
  doInit : function(cmp, event, helper) {
        helper.checkNBC(cmp);
},
  onClickRedirect : function(cmp, event, helper) {
    window.location.href = "/lightning/r/"+ cmp.get("v.recordId") + "/related/dwp_kitv__Visit_Contacts__r/view";
  }
})