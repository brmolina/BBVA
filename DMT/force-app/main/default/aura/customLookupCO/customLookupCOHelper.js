({
	searchHelper : function(component,event,getInputkeyWord) {
    var wherer = component.get("v.fromObject");
    var apiName = component.get("v.objectAPIName");
    var accSelecHel = component.get("v.accSelected");

      var actt = component.get("c.lookupResultValues");
      // set param to method
        actt.setParams({
            'searchKeyWord': getInputkeyWord,
            'lookupObjct' : apiName,
            'fromObject' : wherer,
            'accountSelec' : accSelecHel
          });
          actt.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
              var state2 = response.getState();
              if (state2 === "SUCCESS") {
                  var strResp = response.getReturnValue();
                  if (strResp.length === 0) {
                      component.set("v.Message", 'No Result Found...');
                  } else {
                      component.set("v.Message", '');
                  }
                  component.set("v.listOfSearchRecords", strResp);
              }
          });
          $A.enqueueAction(actt);

  },
  searchHelpOvrr : function(component,event,getInputkeyWord) {

    var recordIdhelper = component.get("v.recordIdUp");
    var acti = component.get("c.fetchLookUpValues");
    // set param to method
    acti.setParams({
      'searchKeyWord': getInputkeyWord,
      'oppId' : recordIdhelper,
    });
    acti.setCallback(this, function(response) {
      $A.util.removeClass(component.find("mySpinner"), "slds-show");
      var stt = response.getState();
      if (stt === "SUCCESS") {
        var streResp = response.getReturnValue();
        if (streResp.length === 0) {
          component.set("v.Message", 'No Result Found...');
        } else {
          component.set("v.Message", '');
        }
        component.set("v.listOfSearchRecords", streResp);
      }
    });
    $A.enqueueAction(acti);

  }
})