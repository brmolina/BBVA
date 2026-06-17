({
	doInit: function (component, event, helper) {
		var actionCampos = component.get("c.getCampos");
            actionCampos.setCallback(this,function(response){
                if (response.getState() === "ERROR") {
                    console.log(response.getError());
                }
                else if (response.getState()==="SUCCESS"){
                    var arrayCampos = [];
                    var AccCampos = response.getReturnValue();
                    for (var campo in AccCampos){
                        arrayCampos.push({value:AccCampos[campo],key:campo});
                    }
                    component.set("v.camposDeAccount",arrayCampos);
                }
            });
            $A.enqueueAction(actionCampos);
	},
    insertreport : function(component, event, helper) {
    var url1 = component.find('url1').get('v.value');
    var url2 = component.find('url2').get('v.value');
    var cliente1 = component.find('cliente1').get('v.value');
    var cliente2 = component.find('cliente2').get('v.value');
    var rtCliente = component.find('rtCliente').get('v.value');
    var name = component.find('name').get('v.value');
    var action = component.get("c.createNewReport");
    var report = component.get("v.report");
    console.log(report);
     var parameters = {
    	"url1": url1,
        "url2": url2,
        "cliente1": cliente1,
        "cliente2": cliente2,
        "name": name,
        "rtCliente": rtCliente
};
    action.setParams({
        "parameters": JSON.stringify(parameters)
    });
    action.setCallback(this,function(response){
        var state = response.getState();
        console.log(state);
        var toastEvent = $A.get("e.force:showToast");
        if(component.isValid() && state === "SUCCESS"){
            toastEvent.setParams({
                "title": "Success!",
                "message": "The record has been created successfully."
            });
            toastEvent.fire();
        }
    });
    $A.enqueueAction(action);
  }
})