({
    init : function(component, event, helper) {
        helper.ConsultaDate_helper(component, event,helper);
        helper.ConsultaProducto_helper(component, event);
        component.set("v.showSpinner",false);
        component.find("BtnTotal").set("v.variant", "brand");
		component.find("BtnPEN").set("v.disabled", "true");
		component.find("BtnUSD").set("v.disabled", "true");
        helper.doInitRefreshView(component, event, helper);
    },
    BtnChangTotal: function(component, event, helper){
        helper.BtnNeutral(component, event, helper,'TOTAL','BtnTotal','PEN');
        component.set('v.isLoad', false);
        component.set("v.bGrafica",false);
        helper.doInitRefreshView(component, event, helper);
    },
    BtnChangPEN: function(component, event, helper){
        helper.BtnNeutral(component, event, helper,'MN','BtnPEN','PEN');
        component.set('v.isLoad', false);
        component.set("v.bGrafica",false);
        helper.doInitRefreshView(component, event, helper);
    },
    BtnChangUSD: function(component, event, helper){
        helper.BtnNeutral(component, event, helper,'ME','BtnUSD','OTRO');
        component.set('v.isLoad', false);
        component.set("v.bGrafica",false);
        helper.doInitRefreshView(component, event, helper);
    },
    chgProduct: function(component, event, helper){
        component.set("v.ProductIS", event.getParam("value"));
            helper.toTalClient(component, event, helper);
        if(event.getParam("value")!=='CLIENTE'){
        	helper.BtnNeutral(component, event, helper,'TOTAL','BtnTotal','PEN');
            component.find("BtnPEN").set("v.disabled", "false");
            component.find("BtnUSD").set("v.disabled", "false");
        }else{
            component.find("BtnPEN").set("v.disabled", "true");
            component.find("BtnUSD").set("v.disabled", "true");
        }
        component.set('v.isLoad', false);
        component.set("v.bGrafica",false);
        helper.doInitRefreshView(component, event, helper);
    }    
})