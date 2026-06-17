({
    QueryMethod : function(component, event,var1) {
        var opp = component.get("v.recordId");
        var action = component.get("c.getVflasClient");
        action.setParams({
            "Idopp" : opp,
            "tipex" : var1,
        });  
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.varSaList", response.getReturnValue());
                this.VarColor1(component, event, component.find("input1").get("v.value"),'input1');
                this.VarColor1(component, event, component.find("input2").get("v.value"),'input2');
                this.VarColor1(component, event, component.find("input3").get("v.value"),'input3');
                this.VarColor1(component, event, component.find("input4").get("v.value"),'input4');
                this.showSection(component, event,var1);
            }
        });
        $A.enqueueAction(action);
    },
    VarColor1 : function(component, event, var1,var2){
        $A.util.removeClass(component.find(""+var2+""), "inputRed");
        if(var1.includes("-")){
            $A.util.toggleClass(component.find(""+var2+""), "inputRed");
        }
    },
    showSection :function(component, event, var1){
        $A.util.removeClass(component.find("cont2"), "slds-hide");
        if(var1=="Recursos gestionados"){
            $A.util.toggleClass(component.find("cont2"), "slds-hide");
        }
    }
    
})