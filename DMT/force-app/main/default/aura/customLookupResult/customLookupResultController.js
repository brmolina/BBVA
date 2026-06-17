({
  selectRecord: function(component, event, helper) {
    var getSelectRecord = component.get('v.oRecord');
    var fieldName = component.get('v.fieldName');
    component.set("v.outputValue", getSelectRecord[fieldName]);
    var compEvent = component.getEvent('oSelectedRecordEvent');
    if(component.get('v.objectAPINameResult') === 'User') {
    	compEvent.setParams({'recordByEvent' : getSelectRecord });
    } else if(component.get('v.objectAPINameResult') === 'Account') {
    	compEvent.setParams({'recordAccByEvent' : getSelectRecord });
    } else if(component.get('v.objectAPINameResult') === 'Product2') {
    	compEvent.setParams({'recordByEvent' : getSelectRecord });
    } else if(component.get('v.objectAPINameResult') === 'Opportunity') {
    	compEvent.setParams({'recordByEvent' : getSelectRecord });
    } else {
        compEvent.setParams({'recordByEvent' : getSelectRecord });
    }
    compEvent.fire();
  },
    doInit: function(component,event,helper){
     var getSelectRecord = component.get('v.oRecord');
        var fieldName = component.get('v.fieldName');
        component.set("v.outputValue", getSelectRecord[fieldName]);
	}
})