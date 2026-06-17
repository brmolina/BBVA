({
    ConsultaProducto_helper : function(component, event) {
        var items = [];
        var opp = component.get("v.recordId");
        var action = component.get("c.recuperaServicio");
        action.setParams({
            "idAccount" : opp
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var arr = response.getReturnValue();
                items.push({ value: '--NINGUNA--', label: '--NINGUNA--' });
                arr.forEach(function(element) {
                    if(element==='CLIENTE'){
                        items.push({ value: 'CLIENTE', label: 'TOTAL CLIENTE' });
                    }else{
                        items.push({ value: element, label: element });
                    }
                });
                component.set("v.options", items);
            }
        });
        $A.enqueueAction(action);
    },
    BtnNeutral: function(component, event, helper,Type,btn,coin){
        if(component.get("v.ProductIS")!=='CLIENTE'){
            component.find("BtnTotal").set("v.variant", "Neutral");
            component.find("BtnPEN").set("v.variant", "Neutral");
            component.find("BtnUSD").set("v.variant", "Neutral");
            component.find(btn).set("v.variant", "brand");
            component.set('v.coint1', coin);
            component.set('v.profiType', Type);
            helper.toTalClient(component, event, helper);
        }
    },
    toTalClient: function(component, event, helper){
        var Types= [''];
        var producto = component.get('v.ProductIS');        
        if(component.get("v.ProductIS")==='CLIENTE'){
            Types= ['TOTAL DI','TOTAL SPREAD','TOTAL TASA'];
            component.set('v.profiType', 'TOTAL CLIENTE');
        }else{
            var tProduc = component.get('v.profiType');
            if(tProduc==='TOTAL')
                Types= ['','','']; 
            else
                Types= ['DI','Spread','Tasa']; 
        }
        component.set('v.profiType1', Types[0]);
        component.set('v.profiType2', Types[1]);
        component.set('v.profiType3', Types[2]);
    },
    doInitRefreshView : function(component, event, helper) {
		component.set('v.isLoad', true);
		component.set("v.bGrafica",true);
    },
    ConsultaDate_helper : function(component, event,helper){
        var items = [];
        var opp = component.get("v.recordId");
        var action = component.get("c.recuperaDate");
        action.setParams({
            "idAccount" : opp
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var arr = response.getReturnValue();
                arr.forEach(function(element) {
                    items.push({ value: element, label: element });
                });
            }
            component.set("v.fInicial", items[0]);
			component.set("v.fFInal", items[1]);
        });
        $A.enqueueAction(action);
    }
})