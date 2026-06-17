({
    init: function (component, event, helper) {
        	var recordid = component.get("v.recordId");//NOSONAR
            var actionInformesgrp = component.get("c.reportSelector");
        	actionInformesgrp.setParams({
            "recordId": component.get("v.recordId")//NOSONAR
        });
            actionInformesgrp.setCallback( this, function(response){
   					 if (response.getState()==="SUCCESS"){
                    var arrayCampos = [];
                    var RepCampos = response.getReturnValue();
                    for (var campo in RepCampos){
                        arrayCampos.push({value:RepCampos[campo],key:campo});
                    }
                    component.set("v.informesGRP",arrayCampos);
                }
              });
                $A.enqueueAction(actionInformesgrp);
            },
   navigate : function(component, event, helper) {
		helper.url(component, event);
   }
})