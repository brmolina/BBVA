({
	jsLoaded : function(cmp, evt, helper) {
		console.log('>>>>> EMPIEZO v2 <<<<< ');
		var lstTopics = cmp.get('v.nameTopic').split(',');
		var strTopic = '/topic/'+cmp.get('v.nameTopic');
		
		var jsonResponse = null;
		var actionSessionId = cmp.get("c.getSessionId"); 		
		
		console.log('>>>>> lstTopics : ' + lstTopics);
		console.log('>>>>> strTopic : ' + strTopic);
		console.log('>>>>> actionSessionId : ' + actionSessionId);
		
		actionSessionId.setCallback(this, function(response) {
			if (response.getState() === "SUCCESS") {
				jsonResponse = JSON.parse(response.getReturnValue());                     
				console.log('>>>>> jsonResponse : ' + jsonResponse);
				(function($){
					//$(document).ready(function() {		
					
					$.cometd.init({
						url: window.location.protocol+'//'+window.location.hostname+'/cometd/29.0/',
						requestHeaders: { Authorization: 'OAuth '+jsonResponse.sessionId}
					});
					
					var objToMap = {};
					for(var i = 0; i<lstTopics.length; i++){
                        var currentTopic = lstTopics[i].toString();
						var strTopic = '/topic/'+lstTopics[i].toString();
						objToMap[strTopic] = i;
						$.cometd.subscribe(strTopic.toString(), function(message) {
							var lstStrApiName = cmp.get('v.relatedApiName').split(',');//MM_GBL_Cliente__c
							
							var objPos = cmp.get('v.objMap');
							var pos = objPos[message.channel];
							var strApiNameCompare = lstStrApiName[pos];
                            console.log('>>>>> objPos : ' + objPos);
                            console.log('>>>>> pos : ' + pos);
                            console.log('>>>>> strApiNameCompare : ' + strApiNameCompare);
							if ( (jsonResponse.userId ===  message.data.sobject.CreatedById || jsonResponse.userId ===  message.data.sobject.OwnerId) && cmp.get('v.recordId') === message.data.sobject[strApiNameCompare] ){
								console.log('>>>>> Dentro del IF ');								
                                console.log('>>>>> message.data.sobject.Id : ' + message.data.sobject.Id);
                                if (currentTopic == 'VisitaTemaTopic'){
                                  var gotoRecordId = message.data.sobject.dwp_kitv__visit_id__c;
                                }else{
                                  var gotoRecordId = message.data.sobject.Id;  
                                }
								var navEvt = $A.get("e.force:navigateToSObject");
								navEvt.setParams({
									"recordId": gotoRecordId,
									"slideDevName": "detail"
								});
								console.log('>>>>> navEvt : ' + navEvt);
								navEvt.fire();
							}
						});
						
						
					}
					cmp.set('v.objMap',objToMap);
					
					
					
					
					//});
				})(jQuery);
				
			}
			
		});
		$A.enqueueAction(actionSessionId);
	}
})