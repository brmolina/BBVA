({
    init : function(component, event, helper) {
        var idrecord = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrecord);
        component.set('v.recordId',idrecord);
        
        var action = component.get("c.typeNBC");
        // set param to method  
        action.setParams({
            'recordId': idrecord
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('>>>>> response');
            console.log(response);
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                window.location.replace(response.getReturnValue());
            //SI LA RESPUESTA ES SUCCESS, MUESTRO MENSAJE / REDIRECCIONO
                //var storeResponse = response.getReturnValue();
                //console.log('>>>>> RESPUESTA : ');
                //console.log(storeResponse);
                //component.set('v.recordTypeId',storeResponse);
                //var createRecord = component.get('c.createRecord');
				//$A.enqueueAction(createRecord);   
            }else{
            	console.log('FALLO');
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    }/*,
    createRecord : function (component, event, helper) {
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName"	: "DES_Template__c",
            "recordTypeId"	: component.get('v.recordTypeId'),
            "defaultFieldValues": {
                'opportunity_id__c' : component.get('v.recordId')
            }
        });
        createRecordEvent.fire();
	}*/
})