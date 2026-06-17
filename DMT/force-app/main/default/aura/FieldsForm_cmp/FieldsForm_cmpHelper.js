({
	getInfo : function(cmp, evt, helper) {
		var action = cmp.get("c.getInfo");
		action.setParams({
			"recordId" : cmp.get("v.recordId"),
			"nameTable" : cmp.get("v.developerNameTable")
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var ret = response.getReturnValue();
				if(ret.isOk){
					var fieldObject = [];
					for(var i in ret.setFields){
						var field = {};
						field["ApiName"]=ret.setFields[i];
						field["label"]=ret.mapLabel[ret.setFields[i]];
						field["type"]=ret.mapType[ret.setFields[i]];
						if(ret.mapField[ret.setFields[i]].default_value__c != undefined && ret.record[ret.setFields[i]] == undefined){
							field["value"]=ret.mapField[ret.setFields[i]].default_value__c;
						}else{
							field["value"]=ret.record[ret.setFields[i]];
						}
						field["htmlInput"] = field["value"];
						if(!isNaN(field["value"])){
							var formatNumber = parseFloat(field["value"]);
							field["htmlInput"] = formatNumber.toFixed(2);
						}
						field["readOnly"]=ret.mapField[ret.setFields[i]].is_readonly__c;
						field["isMandatory"]=ret.mapField[ret.setFields[i]].is_required__c;
						field["CurrencyIsoCode"]=ret.CurrencyIsoCode;
						fieldObject.push(field);						
					}
					if(ret.needReload)
						document.location.reload(true);
					var valueDynamic = cmp.get("v.valueDynamic");
					if(valueDynamic!=undefined && valueDynamic != null){
						var lstDynamic = valueDynamic.split(",");
						for(var i in lstDynamic){
							if(lstDynamic[i]!="-"){
								fieldObject[i].value = lstDynamic[i];
								fieldObject[i].htmlInput = lstDynamic[i];
							}
						}
					}
					cmp.set("v.lstFields",fieldObject);
					cmp.set("v.objectApiName",ret.fieldForm.object_api_name__c);
					cmp.set("v.isOk",true);
				}else{
					cmp.set("v.isOk",false);
				}
			}
		});
		$A.enqueueAction(action);
	}  
})