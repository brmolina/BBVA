App = {};
Session = {};
Llamada = {};

/* ******************** FUNCTIONS ADDED ******************** */
// Control de error en la conexión
var userDisconnected = false;

//función que se ejecuta onkeypress/onkeydown/onkeyup (cualquiera de las tres, según sea más cómodo) en el textbox de entrada de nº de teléfono
function validateEnter(e) {
	var key=e.keyCode || e.which;
	if (key==13){ 
		return true; 
	} else { 
		return false;
	}
}


// Icono de connected/Disconnected. Controla el icono de conectado/desconectado de click to dial.
function setTraderIcon(){
	if (Session.connection.connected && !userDisconnected){
       document.getElementById("divtraderIcon2").style.display = 'none';		
	   document.getElementById("divtraderIcon").style.display = 'block';
	}else {
       document.getElementById("divtraderIcon2").style.display = 'block';		
	   document.getElementById("divtraderIcon").style.display = 'none';	
	   saveLogUserCTI('User is disconnected (Strophe is disconnected).', 'Connection', false,'','','','');
	}
	userDisconnected = false;
  }

  
// Control de lista de llamadas
var listCallObjectIds = [];
//Añade la llamada recibida a la lista de llamadas.
function addListCallObjectIds(newCallid){
	listCallObjectIds.push(newCallid);
}	


var mapCallObjectIds = new Object();
//añade al objeto “mapCallObjectIds” el estado de la llamada, la hora de inicio, el tipo de llamada  y el número.
function addMapCallObjectIds(newCallid, callState, callType, callNumber){
	mapCallObjectIds[newCallid] = callState;	
	addStartTimeCallById(newCallid);
	addMapCallTypeById(newCallid,callType);
	addMapCallNumberById(newCallid,callNumber);
}

//elimina la llamada que se pasa como parámetro y Vuelve a añadir el estado de la llamada, la hora de inicio, el tipo de llamada y el número.
function delMapCallObjectIds(callId){
	delete mapCallObjectIds[callId];
	delMapCallTypeById(callId);
	delMapCallNumberById(callId);
	delMapCallIdRelatedTo(callId);
}

//actualiza el estado de la llamada que le es pasada como parámetro.
function updateStateMapCallById(callId, newCallState){
	if (callId in mapCallObjectIds){
		mapCallObjectIds[callId] = newCallState;
		console.log('--- ******************* updateStateMapCallById -> ' + callId + ': ' + mapCallObjectIds[callId]);		
	}
}

//obtiene el estado de la llamada que le es pasada como parametron.
function getStateCallById(callId) {
	var response = '';
	if (callId in mapCallObjectIds){
		response = mapCallObjectIds[callId];
	}
	
console.log('---- ******************* getStateCallById['+callId+']: ' + response);	
	return response;
}

//comprueba si el mapa “mapCallObjectIds” esta vacío o contiene elementos.
function isEmptyMapCallObjectIds() {
	var size = Object.keys(mapCallObjectIds).length;
	if (size < 1){
		return true;
	}else {
		return false;
	}
    
}


// Duration Call
var mapDurationCalls = new Object(); // or var map = {};
//Añade el comienzo de la llamada
function addStartTimeCallById(newCallid) {
    mapDurationCalls[newCallid] = Date.now();	
}

//elimina la duración de la llamada
function delMapDurationCalls(callId) {
    delete mapDurationCalls[callId];
}

//obtiene el inicio de la llamada, el final de esta y resta ambas variables para obtener la duración total de dicha llamada.
function getDurationCallById(k) { //map[myKey1] == get(myKey1); 
	var startCall = mapDurationCalls[k];
	var endCall = Date.now();   
	var elapsed  = Math.floor( (endCall - startCall) / 1000 );		
	console.log("---- getDurationCallById - Duration Call (callid: " + k + "): " + elapsed + ' sec');		
	delMapDurationCalls(k);	
	return elapsed;
}


// controla la navegación entre las diferentes tabs de click to dial.
//Dependiendo del evento que llegue (action) se desplazara automáticamente de una tab a otra.
function setActiveTab(action){
	var content;
	//sforce.opencti.setSoftphonePanelVisibility({visible: true});
			
	if (action == 'RetrieveCall' || action == 'AnswerCall' || action == 'MakeCall') {
    	content = j$('.slds-tabs__item').addClass('slds-active')[0];
	} else if (action == 'HoldCall') {
    	content = j$('.slds-tabs__item').addClass('slds-active')[2];
	}

    j$(content).find('a').attr('aria-selected', true);
    var j$contentToShow = j$('#'+j$(content).find('a').attr('aria-controls'));
    j$contentToShow.removeClass('slds-hide');
    j$contentToShow.addClass('slds-show');

    j$(content).siblings().removeClass('slds-active');
    j$(content).siblings().find('a').attr('aria-selected', false);
    j$contentToShow.siblings('.slds-tabs__content').removeClass('slds-show');
    j$contentToShow.siblings('.slds-tabs__content').addClass('slds-hide');
}
	
var tabName = '';

// var openConsoleUrl = function openConsoleUrl(result) {
//     console.log(' --- openConsoleUrl: ' + result.consoleUrl);
//     sforce.console.openConsoleUrl(null, result.consoleUrl, true, [tabName], [tabName], openSuccess);  
// }	

/*
	o	Da formato al número de teléfono entrante/saliente.
	o	Busca en Salesforce los registros que coincidan con el número.
	o	Si encuentra un registro, lo muestra.
	o	Si encuentra más de uno, muestra la visualforce CAServerSearchPhone con los diferentes registros para que se seleccione uno de ellos y lo muestre.

*/
function searchAndScreenPop(callNumber, callDirection, callId) {
		
		if (makeCallByClickToDial == null || makeCallByClickToDial == ''){		
			formatPhoneNumberDialed(callNumber);

			// if (callDirection == 'Incoming'){
			// 	callNumber = formatCallNumberIncoming(callNumber);
			// } else {
			// 	callNumber = formatPhoneNumberDialed(callNumber);
			// }
			
			CAServerCallContact.getRecordByPhoneNumber(callNumber, function(resultDoFind, event) {
	                console.log(' --- phone number search OK: ' + resultDoFind.numRecords);
					if (resultDoFind.numRecords != null) {
						var url = '';
						if (resultDoFind.numRecords == 1){						
							//saveLogUserCTI('Formatted phone number (' + callNumber + ') found: ' + resultDoFind.contactName, 'OpenTab', false, callId, callDirection,'','');
							console.log(' --- phone number search OK: ' + resultDoFind);
							tabName = resultDoFind.contactName;
							url = '/' + resultDoFind.id;
							openTabNumber(url);
						}else if (resultDoFind.numRecords == 0){	
							//saveLogUserCTI('Formatted phone number not found: ' + callNumber, 'OpenTab', false, callId, callDirection,'','');
							console.log(' --- Redirigiendo a búsqueda por defecto');
							tabName = callNumber;
							url = '/apex/CAServerSearchPhone?phone=' + callNumber;
							openTabNumber(url);
						} else {
							//saveLogUserCTI('Formatted phone number "' + callNumber +'" found ' + resultDoFind.numRecords + ' times.', 'OpenTab', false, callId, callDirection,'','');
							console.log(' --- Redirigiendo a búsqueda custom');
							tabName = callNumber;
							url = '/apex/CAServerSearchPhone?phone=' + callNumber;
							openTabNumber(url);
						}                   
					} else {
	                    console.log(' --- Error al buscar phone number');
	                    saveLogUserCTI('Error when searching formatted phone number:' + callNumber, 'OpenTab', false, callId, callDirection,'','');
	                }                       
			});

		} //fin IF
		else{
			console.log(' --- searchAndScreenPop.makeCallByClickToDial: ' + makeCallByClickToDial);
			tabName = makeCallByClickToDial.split('%%')[1];
			openTabNumber('/' + makeCallByClickToDial.split('%%')[0]);
		}
																
}

//abre el registro que se le pasa como parámetro.
function openTabNumber(url) {
    sforce.opencti.screenPop({type: sforce.opencti.SCREENPOP_TYPE.URL, params: {url: url}, callback: callbackabrir  });
}


var callbackabrir = function(response) {
if (response.success) {
	console.log('API method call executed successfully! returnValue:', response.returnValue);
	syncFocusedTabWithCallLog();
}else { 
	console.error('Something went wrong! Errors:', response.errors);
}
};


// Image Buttons
var imgClearCall = '<img width="22" height="22" alt="End Call" src="/resource/1462980098000/SoftphoneIcons/end-call-ligh.png">';
var imgAnswerCall = '<img width="22" height="22" alt="Answer Call" src="/resource/1462980098000/SoftphoneIcons/phone-ligh.png">';
var imgAnswerCallMini = '<img width="14" height="14" alt="Answer Call" src="/resource/1462980098000/SoftphoneIcons/phone-ligh.png">';
var imgHoldCall = '<img width="22" height="22" alt="Hold Call" src="/resource/1462980098000/SoftphoneIcons/pause-ligh.png">';
var imgPublicHoldCall = '<img width="22" height="22" alt="Public Hold Call" src="/resource/1462980098000/SoftphoneIcons/Hold-Public-48.png">';
var imgRetrieveCall = '<img width="22" height="22" alt="Retrieve Call" src="/resource/1462980098000/SoftphoneIcons/end-ligh.png">';
var imgConsultationCall = '<img width="22" height="22" alt="Transfer Call" src="/resource/1462980098000/SoftphoneIcons/transer-between-light.png">';
var imgTransferCall = '<img width="22" height="22" alt="Consultation Call" src="/resource/1462980098000/SoftphoneIcons/CallTransfer-48.png">';
var imgConferenceCall = '<img width="22" height="22" alt="Conference Call" src="/resource/1462980098000/SoftphoneIcons/conference-call-ligh.png">';

//obtiene la imagen para construir el botón en función de la acción que se le pase como parámetro.
function getImgButton(buttonId){ 
	var result = '';	
	switch(buttonId) {
        case 'ClearConnection':
			result = imgClearCall;
            break;
        case 'ClearConference':
			result = imgClearCall;
            break;
		case 'ClearCall':
			result = imgClearCall;
            break;			
        case 'AnswerCall':
			result = imgAnswerCall;
            break;
        case 'HoldCall':
			result = imgHoldCall;
            break;
        case 'PublicHoldCall':
			result = imgPublicHoldCall;
            break;            
        case 'RetrieveCall': 
			result = imgRetrieveCall;
            break;
        case 'ConsultationCall':
            result = imgConsultationCall;
            break;			
        case 'TransferCall':
			result = imgTransferCall;
            break;
        case 'ConferenceCall':
			result = imgConferenceCall;
            break;
		case 'AnswerCall-mini':
			result = imgAnswerCallMini;
            break;

       /* default:
            default code block
        */
	} 
    
    return result;  
}



// verifica la llegada de eventos que son descartados.
function isCallEventToDiscard(callId, newCallState, callDirection, callCalled){
console.log('---------*********** Entering function isEventEtraliToDiscard --- callId: ' + callId + ' --- newCallState: ' + newCallState + ' --- callDirection: ' + callDirection + ' --- callCalled: ' + callCalled.number);
		if (isCallTransferedToDiscard(callId, newCallState, callDirection) || isEventEtraliToDiscard(callId, newCallState, callDirection, callCalled) ){
			return true;		
		}else{
			return false;
		}
}

// método para verificar llegada de event de una llamada transferida por mí (yo inicio una ConsultationCall y culmino la Transfer)
function isCallTransferedToDiscard(callId, newCallState, callDirection){
for (var key in mapCallObjectIds)  {
	var obj = mapCallObjectIds[key];
	console.log('--- *******************  ' + key + ': ' + obj);
}

	var isTransfer = false;
	if ( App.connection.system.indexOf('cisco') != -1 && getStateCallById(callId) == 'CallEstablished' &&  newCallState == 'CallEstablished'){ // && callDirection == 'Outgoing') 
		isTransfer = true;
	}	
	return isTransfer;
}


// método para verificar llegada de event de una llamada ETRALI de tipo Cabeza-Cola
function isEventEtraliToDiscard(callId, newCallState, callDirection, callCalled){
	var isHeadTail = false;
	if ( App.connection.system.indexOf('etrali') != -1 && callDirection == 'Outgoing' && callCalled && !callCalled.number) { /* && (newCallState == 'CallOriginated' || newCallState == 'ConnectionCleared') */
		isHeadTail = true;
	}	
	return isHeadTail;
}

// método para guardar en el objeto custom de Salesforce los logs con datos de conexión y eventos CTI que llegan
var auxCountLog = 0;
function saveLogUserCTI(message, typeMsg, isDiscarded, callId, callDirection,activitySubject,activityRelatedTo){
    if ( userLogCTI != null && userLogCTI != '' && 
    	 (userLogCTI.includes(currentUser) || userLogCTI == 'ALL') &&
    	 (levelLogCTI.includes(typeMsg) || levelLogCTI == 'ALL')
      ){
        var logCTI = new sforce.SObject("CIB_Log_Click_to_Dial__c");
        logCTI.Log_Message__c = message;
        logCTI.Log_User__c = currentUser;
        logCTI.Type__c = typeMsg;        
        logCTI.Discarded_Call_Event__c= isDiscarded;
        logCTI.Telephony_System__c = App.options.app.system;
        logCTI.CallId__c = callId;
        logCTI.Call_Direction__c = callDirection;
        logCTI.User_Location__c = userPrefix;
        logCTI.ActivitySubject__c = activitySubject;
        logCTI.Activity_Related_To__c = activityRelatedTo;
        
        auxCountLog = auxCountLog + 1;
        console.log('>>>>>>>>>>>>>> New log CTI inserted: ' + auxCountLog);        
        
        var result = sforce.connection.create([logCTI]);

        if (result[0].getBoolean('success')) {
            console.log('>>>>>>>>>>>>>> New log CTI inserted with id ' + result[0].id);
        } else {
            console.log('>>>>>>>>>>>>>> Failed to insert log CTI ' + result[0]);
        }

    }
}

		/*************************** INICIO FUNCIONES INTERACTION LOG **************************/
		
		
var currentCallId = '';
		
// Type Call
var mapCallType = new Object(); 
//añade el tipo de llamada al “mapCallType”, cuya llamada sea pasada por parámetro.
function addMapCallTypeById(newCallid,callType) {
    mapCallType[newCallid] = callType;	
}

//elimina la llamada que sea pasada como parámetro.
function delMapCallTypeById(callId) {
    delete mapCallType[callId];
}

//Obtiene el type de la id correspondiente a la llamada que se pasa como parametro.
function getCallTypeById(callId) {
	return mapCallType[callId];
}

// Call Number
var mapCallNumber = new Object();
//añade al objeto mapCallNumber los datos de la llamada.
function addMapCallNumberById(newCallid,callNumber) {
    mapCallNumber[newCallid] = callNumber;	
}

//elimina la llamada que sea pasada como parámetro.
function delMapCallNumberById(callId) {
    delete mapCallNumber[callId];
}

//obtiene el numero de la llamada cuya Id se pasa como parámetro
function getCallNumberById(callId) {
	return mapCallNumber[callId];
}

//obtiene el Id de la llamada a través del número de teléfono pasado como parámetro
function getCallIdByCallNumber(callNumber) {
	var result = '';
	for(var callid in mapCallNumber) { 
		if( mapCallNumber[callid] == callNumber){
			result = callid;
			break;
		}
	}
	return result;
}


// Related To - CallId
var mapCallIdRelatedTo = new Object(); //mapa necesario para relacionar callId - relatedTo, de manera que si se tienen varias llamadas, cuando se haga Hold y después Retrieve se carguen los datos de la llamada recuperada

/*rellena el mapa “mapCallIdRelatedTo”, necesario para relacionar callId - relatedTo, de manera que si se tienen varias llamadas,
 cuando se haga Hold y después Retrieve se carguen los datos de la llamada recuperada.*/
function addMapCallIdRelatedTo(callId, relatedToId){
	mapCallIdRelatedTo[callId] = relatedToId;
}

//Elimina el related to de la llamada que se ha pasado como parámetro mediante su Id.
function delMapCallIdRelatedTo(callId){
	delete mapCallIdRelatedTo[callId];
}

//Obtiene el related to de la llamada mediante la Id que se pasa como parametro.
function getCallIdRelatedTo(callId) {
	var response = '';
	if (callId in mapCallIdRelatedTo){
		response = mapCallIdRelatedTo[callId];
	}	
	console.log('---- ******************* getCallIdRelatedTo['+callId+']: ' + response);	
	return response;
}		
		
// Related To - Comments		
var mapInteractionLog = new Object(); //mapa necesario por si hay varias llamadas a la vez, relaciona el contacto/cuenta/prospect seleccionado con los comentarios escritos: relationTo_id  ->   Comments. 
/*rellena el mapa “necesario por si hay varias llamadas a la vez, relaciona el contacto/cuenta/prospect 
	seleccionado con los comentarios escritos: relationTo_id  ->   Comments.”*/
function addMapInteractionLog(relatedToId, comments){
	mapInteractionLog[relatedToId] = comments;
}

//Elimina la iteración Log de la llamada mediante la Id del related to que se pasa como parámetro.
function delMapInteractionLog(relatedToId){
	delete mapInteractionLog[relatedToId];
}

//añade al mapa “mapInteractionLog” los comentarios  mediante la Id del related to que se le pasa como parametron.
function updateCommentsMapInteractionLog(relatedToId, comments){
	mapInteractionLog[relatedToId] = comments;
	console.log('--- ******************* updateCommentsMapInteractionLog -> ' + relatedToId + ': ' + mapCallObjectIds[relatedToId]);
}

//obtiene los comentarios mediante la Id del related to que se le pasa como parámetro.
function getCommentsFromRelatedTo(relatedToId) {
	var response = '';
	if (relatedToId in mapInteractionLog){
		response = mapInteractionLog[relatedToId];
	}
	
	console.log('---- ******************* getCommentsFromRelatedTo['+relatedToId+']: ' + response);	
	return response;
}



//METODO LLAMADO AL PULSAR EL BOTON "Add/Change"
//método llamado al pulsar el botón “Add/Change”.
function syncFocusedTabWithCallLog() {
	// first check if the focused tab is a subtab, then check if focused tab is a primary tab.
	for(i = 0;i<=10;i++){
		setTimeout(function() {
			getFocusedSubTabId();
		}, 2000);
		
	}
}

//Devuelve información sobre la vista de la aplicación actual.
function getFocusedSubTabId() {
	console.log('getFocusedSubtabId');
	sforce.opencti.getAppViewInfo({callback:showSubTabId});

	//sforce.console.getFocusedSubtabId(showSubTabId);
}

 var showSubTabId = function showSubTabId(result) {
      // Display the tab ID
     console.log('>>>>>>>>>>>>>> Subtab ID: ' + result.id);   
     if (result.success == false ){
     	console.log('getFocusedPrimaryTabId');
     		getFocusedPrimaryTabId();     
     }else{ 
     	console.log('getPageInfo');
     	sforce.opencti.getAppViewInfo({callback: showPrimaryTabId});
   	 }       
 }; 
 
 //Devuelve el ID de la pestaña principal en la que se enfoca el navegador.
function getFocusedPrimaryTabId() {
	console.log('getFocusedPrimaryTabId');
	//Devuelve el ID de la pestaña principal en la que se enfoca el navegador. 
    sforce.console.getFocusedPrimaryTabId(showPrimaryTabId);
}
var showPrimaryTabId = function showPrimaryTabId(result) {
    //Display the tab ID
    sforce.opencti.getAppViewInfo({callback: showPageInfo});  
};
 

var urlSalesforce = '';
var relatedTo = '';

//carga el resultado obtenido en el combobox “related to”.
var showPageInfo = function showPageInfo(result) {
			if (result.success) {
				var objId = result.returnValue.recordId;
				var objName = (result.returnValue.recordName  ? result.returnValue.recordName :  tabName );
				if (objId != null && objId != '' && (objId.startsWith('001') || objId.startsWith('003') || objId.startsWith('00Q') ) ) {				
					addItemToSelectBox(objName, objId);
					j$('#callLogRelatedTo').val(objId);
					loadComments();
					addMapCallIdRelatedTo(currentCallId, objId); // se añade al mapa que relaciona CallId con "Related to". Este mapa se utilza para cuando tienes varias llamadas a la vez, si pones una en Hold y luego la recuperas que se cargue la opcion y comentarios automáticamente
					
					if (objName == ''){ // si no se ha cargado el nombre en el combo "related to" se vuelve a lanzar para que recargue
							setTimeout(function() {
									syncFocusedTabWithCallLog();
								}, 2000);
					}
				}else {
					console.log('>>>>>>>>> The focused tab must be a Contact/Client/Prospect to add data to call log.');            
				}
			}
			else {
				console.log('>>>>>>>>> The focused tab must be a Contact/Client/Prospect to add data to call log.');            
			}
			makeCallByClickToDial = '';
			tabName = '';


};
 

		/*************************** FIN FUNCIONES INTERACTION LOG **************************/
//Si el número contiene “+”, lo quita.
function formatPhoneCreateContact(phoneNum){
	if(phoneNum.startsWith('+')){
		phoneNum = phoneNum.substring(1);
	}

	return phoneNum;
}	


var formatNumberDialed = '';

/*
	Método que recibe como parámetro un número de teléfono y quita el “+” y los ceros iniciales.
	Posteriormente, si son necesarios añadir ceros, se hará en función del país.
*/
function quitarCeros(phoneNum){
	var newPhone = phoneNum;
	for(i = 0; i<=phoneNum.length;i++){
		if(phoneNum[i] == '0' || phoneNum[i] == ' ' || phoneNum[i] == '+'){
			newPhone =  phoneNum.substring(i+1, phoneNum.length);
		}else{
			break;
		}
	}

	return newPhone;
	
}

/*
	Si el número que se le pasa como parámetro es igual o mayor de nueve caracteres, llama al método quitarCeros.
	Una vez quitados los ceros, se comprueba el prefix (Pais) del usuario y, en función de este, se llama a un método
	u otro para su correcta codificación. Finalmente, este método devuelve el método correctamente formateado.
*/
function formatPhoneNumberDialed(phoneNum){

	console.log('UserPrefix: '+userPrefix+ ' System: '+App.options.app.system);

	if (phoneNum.length >= 9) {
		phoneNum = quitarCeros(phoneNum);
		console.log('Numero sin ceros: '+phoneNum);

		if(userPrefix == 'ES'){
			formatNumberDialed = isSpain(phoneNum);
			console.log('>>>>>>>>> formatted Number: ' + formatNumberDialed);
			return formatNumberDialed
		}else if(userPrefix == 'PT'){
			formatNumberDialed = isPortugal(phoneNum);
			console.log('>>>>>>>>> formatted Number: ' + formatNumberDialed);
			return formatNumberDialed;
		}else if(userPrefix == 'IT'){
			formatNumberDialed = isItaly(phoneNum);
			console.log('>>>>>>>>> formatted Number: ' + formatNumberDialed);
			return formatNumberDialed;
		}else if(userPrefix == 'FR'){
			formatNumberDialed = isFrance(phoneNum);
			console.log('>>>>>>>>> formatted Number: ' + formatNumberDialed);
			return formatNumberDialed;
		}else if(userPrefix == 'DE'){
			formatNumberDialed = isGermany(phoneNum);
			console.log('>>>>>>>>> formatted Number: ' + formatNumberDialed);
			return formatNumberDialed;
		}else if(userPrefix == 'GB'){
			formatNumberDialed = isUnitedKingDom(phoneNum);
			console.log('>>>>>>>>> formatted Number: ' + formatNumberDialed);
			return formatNumberDialed;
		}else{
			console.log('>>>>>>>>> formatted Number: ' + phoneNum);
			return phoneNum;
		}
	}

	  console.log('>>>>>>>>> formatted Number: ' + phoneNum);


	  return phoneNum;

}

//Metodo encargado de formatear números que han sido marcados por un usuario de España.
function isSpain(phoneNum){
	formatNumberDialed = phoneNum;

	if(App.options.app.system.includes('cisco')){
		if (phoneNum.startsWith('34')){  
			formatNumberDialed =  phoneNum.substring(2);						
		}else if(phoneNum.startsWith('376') && phoneNum.length == 9){
			formatNumberDialed = '00' +  phoneNum;
		}else if(phoneNum.length == 9){
			formatNumberDialed = phoneNum;
		}else{
			formatNumberDialed = '00' +  phoneNum;
		}
	}else if(App.options.app.system.includes('etrali')){
		if (phoneNum.startsWith('34')){  
			formatNumberDialed =  phoneNum.substring(2);						
		}else if(phoneNum.startsWith('376') && phoneNum.length == 9){
			formatNumberDialed = '00' +  phoneNum;
		}else if(phoneNum.length == 9){
			formatNumberDialed = phoneNum;
		}else{
			formatNumberDialed = '00' +  phoneNum;
		}
	}

	return formatNumberDialed;		
}

//método encargado de formatear números que han sido marcados por un usuario de Portugal.
function isPortugal(phoneNum){
	formatNumberDialed = phoneNum;

	console.log('>>>>>>>>> isPortugal Number: ' + phoneNum);

	if(App.options.app.system.includes('etrali')){
		if (phoneNum.startsWith('35')){  
			formatNumberDialed =  phoneNum.substring(2);						
		}else if(phoneNum.length >= 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}
	console.log('>>>>>>>>> isPortugal ETRALI: ' + formatNumberDialed);

	}else if(App.options.app.system.includes('cisco')){
		if (phoneNum.startsWith('35')){  
			formatNumberDialed =  phoneNum.substring(2);						
		}else if(phoneNum.length >= 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}
		console.log('>>>>>>>>> isPortugal CISCO: ' + formatNumberDialed);

	}else if(App.options.app.system.includes('ipc')){
			
		if (phoneNum.startsWith('35')){  
			formatNumberDialed = '0' + phoneNum.substring(2);						
		}else if(phoneNum.length == 8 || phoneNum.length == 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else if(phoneNum.length == 10 && !phoneNum.startsWith('0')){
			formatNumberDialed = '0' + phoneNum;
		}else if(phoneNum.length > 9){
			formatNumberDialed = '000' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}
		console.log('>>>>>>>>> isPortugal IPC: ' + formatNumberDialed);
	}

	return formatNumberDialed;	
}

//método encargado de formatear números que han sido marcados por un usuario de Italia.
function isItaly(phoneNum){
	formatNumberDialed = phoneNum;

	if(App.options.app.system.includes('ipc')){
		if (phoneNum.startsWith('39')){  
			formatNumberDialed = '0' + phoneNum.substring(2);						
		}else if(phoneNum.length == 8 || phoneNum.length == 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else if(phoneNum.length == 10 && !phoneNum.startsWith('0')){
			formatNumberDialed = '0' + phoneNum;
		}else if(phoneNum.length > 9){
			formatNumberDialed = '000' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}
	}else if(App.options.app.system.includes('cisco')){
		if (phoneNum.startsWith('39')){  
			formatNumberDialed = '0' + phoneNum.substring(2);						
		}else if(phoneNum.length == 8 || phoneNum.length == 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else if(phoneNum.length == 10 && !phoneNum.startsWith('0')){
			formatNumberDialed = '0' + phoneNum;
		}else if(phoneNum.length > 9){
			formatNumberDialed = '000' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}	
	}else if(App.options.app.system.includes('etrali')){
		if (phoneNum.startsWith('39')){  
			formatNumberDialed = '0' + phoneNum.substring(2);						
		}else if(phoneNum.length == 8 || phoneNum.length == 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else if(phoneNum.length == 10 && !phoneNum.startsWith('0')){
			formatNumberDialed = '0' + phoneNum;
		}else if(phoneNum.length > 9){
			formatNumberDialed = '000' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}		
	}

	return formatNumberDialed;	
}

//método encargado de formatear números que han sido marcados por un usuario de Francia.
function isFrance(phoneNum){
	formatNumberDialed = phoneNum;

		// if (phoneNum.startsWith('33')){  
		// 	formatNumberDialed = '00' + phoneNum;						
		// }else if(phoneNum.length > 9){ 
		// 	formatNumberDialed = '00' + phoneNum;
		// }else{
		// 	formatNumberDialed = phoneNum;
		// }


	if(App.options.app.system.includes('ipc')){
		if(phoneNum.startsWith('376') && phoneNum.length == 9){
			formatNumberDialed = '00' +  phoneNum;
		}else if(phoneNum.length == 9){
			formatNumberDialed = '0033' + phoneNum;
		}else{
			formatNumberDialed = '00' + phoneNum;
		}	
	}else if(App.options.app.system.includes('cisco')){
		if(phoneNum.startsWith('376') && phoneNum.length == 9){
			formatNumberDialed = '00' +  phoneNum;
		}else if(phoneNum.length == 9){
			formatNumberDialed = '0033' + phoneNum;
		}else{
			formatNumberDialed = '00' + phoneNum;
		}	
	}

	return formatNumberDialed;	
}

//método encargado de formatear números que han sido marcados por un usuario de Alemania.
function isGermany(phoneNum){
	formatNumberDialed = phoneNum;

	console.log('>>>>>>>>> AR  isGermany Number: ' + phoneNum);

	if(App.options.app.system.includes('ipc')){
		if (phoneNum.startsWith('49')){  
			formatNumberDialed = '0' + phoneNum.substring(2);						
		}else if(phoneNum.length >= 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}
		console.log('>>>>>>>>> AR  isGermany IPC: ' + formatNumberDialed);
		
	}else if(App.options.app.system.includes('etrali')){
		if (phoneNum.startsWith('49')){  
			formatNumberDialed =  phoneNum.substring(2);						
		}else if(phoneNum.length >= 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}
		console.log('>>>>>>>>> isGermany ETRALI: ' + formatNumberDialed);

	}else if(App.options.app.system.includes('cisco')){
		if (phoneNum.startsWith('49')){  
			formatNumberDialed =  phoneNum.substring(2);						
		}else if(phoneNum.length >= 9){ 
			formatNumberDialed = '00' + phoneNum;
		}else{
			formatNumberDialed = phoneNum;
		}
		console.log('>>>>>>>>>  AR  isGermany CISCO: ' + formatNumberDialed);
	}

	return formatNumberDialed;	
}


var formatLondonNumber = '';
var oneThing = false;

//método encargado de formatear números que han sido marcados por un usuario de Reino Unido.
function isUnitedKingDom(phoneNum){
	formatNumberDialed = phoneNum;

	if(!oneThing){
		if(App.options.app.system.includes('cisco')){
			 if(phoneNum.length == 10){
			 	formatNumberDialed = '90'+phoneNum;
			 	formatLondonNumber = formatNumberDialed;
			 }else if(phoneNum.startsWith('44')){
			 	formatNumberDialed = '90' + phoneNum.substring(2);
			 	formatLondonNumber = formatNumberDialed;
			 }else if(!phoneNum.startsWith('44') && phoneNum.length >= 11){
			 	formatNumberDialed = '900' + phoneNum;
			 	formatLondonNumber = formatNumberDialed;
			 }else{
			 	formatNumberDialed = phoneNum;
			 	formatLondonNumber = formatNumberDialed;
			 }
		}else if(App.options.app.system.includes('etrali')){
			 if(phoneNum.length == 10){
			 	formatNumberDialed = '90'+phoneNum;
			 	formatLondonNumber = formatNumberDialed;
			 }else if(phoneNum.startsWith('44')){
			 	formatNumberDialed = '90' + phoneNum.substring(2);
			 	formatLondonNumber = formatNumberDialed;
			 }else if(!phoneNum.startsWith('44') && phoneNum.length >= 11){
			 	formatNumberDialed = '900' + phoneNum;
			 	formatLondonNumber = formatNumberDialed;
			 }else{
			 	formatNumberDialed = phoneNum;
			 	formatLondonNumber = formatNumberDialed;
			 }
		}

		oneThing = true;		
	}



	return formatNumberDialed;	
}

 

// function formatPhoneNumberDialedANTIGUO(phoneNum){
// 	 var formatNumberDialed = '';
// 	 // el prefixCTI (el '0' añadido para Etradeal) solo se le añade para llamadas que no son teléfonos BBVA internos
//      if (phoneNum.length > 6 && userLocation != '' && listEtradeal_PrefixCountries.indexOf(userLocation) != -1 ) {
// 			console.log('>>>>>>>>>>>>>>>> The user\'s country is in listEtradeal_PrefixCountries: ' + listEtradeal_PrefixCountries);	                                				
// 			// PORTUGAL
// 			if (userLocation == 'PT' ){
// 				formatNumberDialed = '0' + phoneNum;		
					
// 			// ALEMANIA
// 			}else if(userLocation == 'DE' ){
// 				if (phoneNum.startsWith('0049')){  // llamada nacional
// 					formatNumberDialed = '00' + phoneNum.substring(4);									
// 				}else { // llamada internacional
// 					formatNumberDialed = '0' + phoneNum;
// 				}			
			
// 			// ITALIA
// 			}else if (userLocation == 'IT') { // llamada nacional
// 				if (phoneNum.startsWith('0039')){
// 					formatNumberDialed = '0' + phoneNum.substring(4);
// 				}else { // llamada internacional
// 					formatNumberDialed = '0' + phoneNum;
// 				}
				
// 			// FRANCIA
// 			}else if (userLocation == 'FR'){				
// 				if (phoneNum.startsWith('0033')){  // llamada nacional
// 					formatNumberDialed = phoneNum.substring(4);
// 					if (formatNumberDialed.startsWith('0')){
// 						formatNumberDialed = '0' + formatNumberDialed;
// 					} else {
// 						formatNumberDialed = '00' + formatNumberDialed;
// 					}				
// 				}else { // llamada internacional
// 					formatNumberDialed = '0' + phoneNum;
// 				}

// 			// UNITED KINGDOM
// 			}else if (userLocation == 'UK' || userLocation == 'GB'){
// 				formatNumberDialed = '9' + phoneNum;
// 			}

//       } else {
// 		formatNumberDialed = phoneNum;
// 	  }
// 	  console.log('>>>>>>>>> formatted Number: ' + formatNumberDialed);
// 	  return formatNumberDialed;          
// }
		


// function formatCallNumberOutgoing(phoneNum){
// 	 var result = phoneNum;
//      if (phoneNum.length > 6 && userPrefix != '' && listEtradeal_PrefixCountries.indexOf(userPrefix) != -1 ) {
// 		 if (userPrefix == 'GB'){
// 		 	if (phoneNum.startsWith('9')){
// 				result = phoneNum.substring(1);	
// 			}
// 		 }else if (userPrefix == 'FR' || userPrefix == 'DE') {				
// 			if (phoneNum.startsWith('000')){
// 				result = phoneNum.substring(3);
// 			}else if (phoneNum.startsWith('00')){
// 				result = phoneNum.substring(2);
// 			}else if (phoneNum.startsWith('0')){
// 				result = phoneNum.substring(1);			
// 			}
			
// 		 } else if (phoneNum.startsWith('0')){
// 			result = phoneNum.substring(1);
// 		 }
// 	 } 
// 	 return result;          
// }


// function formatCallNumberIncoming(phoneNum){
// 	 var result = phoneNum;
//    	if (phoneNum.length > 6 ) {
//    		if ( userPrefix != '' && (userPrefix == 'GB') && phoneNum.startsWith('9')) {
//    			result = phoneNum.substring(1);
//    		}//else if (phoneNum.startsWith('00')){
//    		// 	result = phoneNum.substring(2);
//    		// }else if (phoneNum.startsWith('0')){
//    		// 	result = phoneNum.substring(1); 	
//    		// }
		
// 	 } 
// 	 return result;          
// }

/* ******************************************************************* */		
/***********************************************************************************************/

//método que se ejecuta cuando se inicia la app de click to dial.
App.start = function(options) {
    App.options = options;
    App.disco = [];
    console.log('Application Started');    
    BIND_PATH = '/http-bind/';
    BOSH_URL = 'https://' + App.options.app.bosh_domain + BIND_PATH;   
    if(App.options.app.controller) {
        App.controller = App.options.app.controller;
    }
    else
    {
        App.controller = false;
    }
    
    if (App.options.app.autologon) {
        App.signIn();	
    }
}

/*devuelve true/false, dependiendo del valor de:
 App.options.app.debug. si está definida al inicio a true, pues deja logs tanto en de 
 console.log como insertando en el objeto nuestro de Salesforce.
 Si está a false, no deja log*/
App.debug = function() {
    if (App.options.app.debug) {
        return true;
    }
    return false;
}


//Limpia la conexon
App.clear = function() {
    if (Session.connection) {
        Session.connection.disconnect();
        console.log("XMPP Disconnect");
        saveLogUserCTI('App.clear: XMPP Disconnect', 'Connection', false,'','','','');

    }
}


//realiza la conexión entre el teléfono y Salesforce para posteriormente poder realizar/recibir llamadas.
App.connected = function(connection) {
    Session.connection = connection;
    Session.connection.openlink.sendPresence();

    App.discoItems();

    if (App.options && App.options.app.system) {
        App.connection = {
            system: App.options.app.system,
            type: App.options.app.type || (App.options.app.system.match(/[0-9]/)? "openlink" : "gtx")
        }
        App.setHandler();
    }
    
    if (App.connection.type === "openlink") {
        App.getProfiles();
    }

    console.log("CONNECTION SYSTEM:", App.connection);
    saveLogUserCTI('User is connected (Strophe is connected). CONNECTION SYSTEM:' + JSON.stringify(App.connection), 'Connection', false,'','','','');

	App.reconnect = false;
	
}

//obtiene el número de teléfono e invoca al método makeCall(). El proceso comienza cuando se pulsa el botón “Dial”.
App.dialDestination = function() {
		var extension = document.getElementById('input-destination').value;
		var interest = document.getElementById('select-01').value;
		console.log('>>>>>>>>>>>>>> makeCall to number: ' + extension);
	      if(extension > 7){
	         extension = formatPhoneCreateContact(extension);   
	      }

		//extension = formatPhoneNumberDialed(extension);
		if (makeCallByClickToDial == '' || makeCallByClickToDial == null){
			saveLogUserCTI('Call made to number: ' + extension, 'CallMade', false,'','','','');
		}else {
			saveLogUserCTI('Call made by ClickToDial to formatted number: ' + extension  + '  --  ' + 'original number: ' + makeCallByClickToDial.split('%%')[3] + '  --  ' + 'SalesforceId: ' + makeCallByClickToDial.split('%%')[0] + '  --  ' + 'Object type: ' + makeCallByClickToDial.split('%%')[2] + '  --  ' + 'Name: ' + makeCallByClickToDial.split('%%')[1], 'CallMade', false,'','','','');
		}
		App.makeCall(extension, interest);  
}

//reinicia click to dial y obtiene los datos del profile invocanco a getProfiles().
App.loadSystem = function(system) {
    if (system === "blank") {
        return;
    }

    App.connection = {
        system: system,
        type: App.disco.systems[system].type
    };

    if (Session.callHandlerId) {
        Session.connection.openlink.removeHandler(Session.callHandlerId);
        delete Session.callHandlerId;
    }

    j$("#call-history").html('');
    j$("#call-list").html('');
    j$("#call-held").html('');
    j$("#call-incoming").html('');

    App.setHandler();

    if (App.connection.type === "openlink") {
        App.getProfiles();
    }
}

//en función del tipo de conexión, se conecta a “gtr” u “openlink”.
App.setHandler = function() {
    if (App.connection.type === "gtx") {
        Session.connection.gtx.profiles = {};
        Session.connection.gtx.addHandler(App.connection.system);
        Session.callHandlerId = Session.connection.gtx.addCallHandler(App.gtxCallHandler)
    } else if (App.connection.type === "openlink") {
        Session.connection.openlink.profiles = {};
        Session.callHandlerId = Session.connection.openlink.addCallHandler(App.callHandler)
    }
}

App.calls = [];
App.lastCallStates = [];

//Contador hecho para que no se llame repetidas veces a saveInteractionLog
var contador = 0;


var stateBG = false;
var durationCall = 0;
var typeCall = '';
var numberCall = '';

/*
	Este método es bastante extensor y realiza varias funciones:
	o	Obtiene todos los datos de la llamada.
	o	actualiza el nuevo estado de la llamada en el mapa mapCallObjectIds mediante la invocación de updateStateMapCallById(), al que se le pasa el Id de la llamada y el estado.
	o	Si el estado de la llamada es “CallFailed”. No devuelve nada.
	o	Si el estado de la llamada es “ConnectionCleared” o “CallMissed”, limpia los campos de click to dial.
	o	A partir de aquí, empezara a construir el layout en función de los datos que figuren en la llamada: 

*/
App.callHandler = function(callEv, changed) {
    if (App.connection.type === "openlink") {
			// do something
			console.log("CALL HANDLER: " + changed + " callEv: " + JSON.stringify(callEv));			
			var call = callEv;

			if(call.state == 'CallOriginated'){
				stateBG = true;
			}

			// Keep track of the last call state
			if (App.lastCallStates[call.id]) {
				var lastCallState = App.lastCallStates[call.id];
			};
			
			App.lastCallStates[call.id] = call.state;

			var interestLabel = App.user.interests[call.interest].label;

			if(call.called.number == null){
				call.called.number = 'unknown';
			}

			if(call.called.name == null){
				call.called.name = 'unknown';
			}

			//if (call.state === "CallBusy") {
			//	console.log("CallBusy is not supported");
			//	return;
			//}

			currentCallId = call.id;
			console.log('llamada: '+JSON.stringify(callEv));

			console.log('call satte: '+call.state);

			/* ****************** Is a Call Transferred by Me *********************** */						
			if ( isCallEventToDiscard(call.id, call.state, call.direction, call.called) ) { // Discarded event				
				console.log('---- ************************* Discarded event *************************');	
				saveLogUserCTI('CALL HANDLER: ' + call.state + ' - callEvent: ' + JSON.stringify(callEv), 'Event', true,call.id, call.direction,'','');	
			} else {	
			/* ***************************************** */
				saveLogUserCTI('CALL HANDLER: ' + call.state + ' - callEvent: ' + JSON.stringify(callEv), 'Event', false,call.id, call.direction,'','');

				// empty call list 
				var sipSplit = call.id.split("-sip");
				if (sipSplit.length > 1) {
					call.callid = sipSplit[0];
				} else {
					var hashSplit = call.id.split("#");
					if (hashSplit.length > 1) {
						call.callid = hashSplit[1];
					} else {
						call.callid = hashSplit[0];
					}
				}

				// If the last call state was Delivered, Established or Held, and you receive a CallBusy, remove the call object from the UI
				if (lastCallState === "CallDelivered" && call.states === "CallBusy") {
					console.log("CallBusy is not supported");
					j$("#active-call-" + call.callid).remove();
					if (call.direction === "Incoming") {
						j$("#incoming-history-" + call.callid).remove();
					};
					return;
				} else if ((lastCallState === "CallEstablished" || lastCallState === "CallHeld") && call.state === "CallBusy") {
					console.log("CallBusy is not supported");
					j$("#active-call-" + call.callid).remove();
					return;
				}

				// Se actualiza el nuevo estado de la llamada en el mapa mapCallObjectIds
				updateStateMapCallById(call.id, call.state);
				
				if (call.state === "CallFailed") {
					console.log('Call failed. Please check the dialed number.');
					saveLogUserCTI('CallFailed event received','Event',false,call.id,call.direction,'','');
					return;
				}

				if (call.state === "ConnectionCleared" || call.state === "CallMissed") {
					closeAlerta();
					document.getElementById('input-destination').value = '';				
					j$(".incoming-history-" + call.callid).remove();				
					j$("#active-call-" + call.callid).remove();
					App.getCallHistory('50');
					
					/* ***************** Interaction Log ************************** */
					
					if (call.state === "ConnectionCleared"){
						contador++;


						if (call.id in mapCallObjectIds) {
							durationCall = getDurationCallById(call.id);
							typeCall = getCallTypeById(call.id);
							numberCall = getCallNumberById(call.id);						
						}else {
							saveLogUserCTI('Call Cleared, the "CallEstablished" event was not received on softphone (Salesforce)','Event',false,call.id,call.direction,'','');							
							if (call.direction === "Incoming") {
									typeCall = "inbound";
									numberCall = call.caller.number;
							} else{
									typeCall = "outbound";
									//numberCall = Math.floor(call.called.number / 1000);
									numberCall = call.called.number;
							}
							if (call.duration){
									durationCall = call.duration;
							}								
			
						}


						if(contador == 1){
							saveInteractionLog(call.id, typeCall, durationCall, numberCall);	
						}else if(contador == 6){
							contador = 0;
						}
									
						
						console.log('--- *******************  Interaction Log Before - Active call object ids: ' + mapCallObjectIds[call.id]);
						 if (call.id in mapCallObjectIds) {
							listCallObjectIds.splice(listCallObjectIds.indexOf(call.id), 1);
							delMapCallObjectIds(call.id);
							console.log('--- ******************* Interaction Log After - Active call object ids: ' + (call.id in mapCallObjectIds) );
											
							if ( isEmptyMapCallObjectIds() ){
								document.getElementById('clearButton').disabled = true;  
								document.getElementById('syncButton').disabled = true;															
								// se oculta el softphone con un retardo de 1seg para que se vea el icono de "saving..." si se guarda la actividad
								setTimeout(function() {
									sforce.opencti.setSoftphonePanelVisibility({visible: false});
								}, 1000);
							}
							
						}
					}
					/* ******************************************* */				
				}
				if (call.state === "CallEstablished" || call.state === "CallHeld") {
					if(call.state === "CallEstablished")
						closeAlerta();
						document.getElementById('input-destination').value = '';
						j$(".incoming-history-" + call.callid).remove();
						j$("#active-call-undefined").remove();

					
					/* ***************** Interaction Log ************************** */
					if (call.state === "CallEstablished") {

						var callIdCisco;
						if (call.id.indexOf('-') != -1 ){
							callIdCisco = call.id.split('-')[0];
						}

						console.log('----- ********** CallEstablished -- App.connection.system: ' + App.connection.system + '  --- callIdCisco: '  + callIdCisco + ' --- call.called.number: ' + call.called.number);											
					
						var callType = '';
						var callLabel = '';
						var callNumber = '';
						if ( (call.direction != "Incoming") || 
							(call.direction === "Incoming" && callIdCisco != null && call.called.number && callIdCisco.indexOf(call.called.number) == -1 && (call.called.number.length > 7 || call.called.number.length <= 7 && call.caller.number.length <= 7))  ){
								if (call.direction === "Incoming"){
									callType = "inbound";
								}else {
									callType = "outbound";
								}
								callLabel = call.called.name;
								callNumber = call.called.number;							
						}else {
								if (call.direction === "Incoming" && call.caller.number) {
										callType = "inbound";
										callLabel = call.caller.name;
										callNumber = call.caller.number;
								} else{
										callType = "outbound";
										callLabel = call.called.name;
										callNumber = call.called.number;								
								}
		
						}
						
						console.log('--- Interaction Log call info: ' + call.id + ' - callType: ' + callType + ' - callLabel: '  + callLabel + ' - callNumber: '  + callNumber);					
						console.log('--- Interaction Log Active call object ids: ' + listCallObjectIds);	
						if (call.id in mapCallObjectIds) {
							console.log('---- Interaction Log - Hold');													
						}else {
							addListCallObjectIds(call.id);							
							addMapCallObjectIds(call.id, call.state, callType, callNumber);
							document.getElementById('clearButton').disabled = false;  
							document.getElementById('syncButton').disabled = false;													
							
							console.log('---- Interaction Log Add call info: ' + call.id + ' - ' + callType + ' - '  + callLabel);						
							//busqueda telefono y abrir tab Cuenta/contacto/Lead. Solo la primera vez call.state === "CallEstablished", si vienen de hold-retrieve que no vuelva a cargarse
							//searchAndScreenPop(callNumber,call.direction, call.id); // -> de momento no se formatea el numero que se busca
							
							callNumber = formatPhoneNumberDialed(callNumber);

							createContact(callNumber,call.direction, call.id, stateBG);

						}

					}
					/* ******************************************* */
					
				}

				if (call.state === "CallDelivered" && call.direction === "Incoming") {
					sforce.opencti.setSoftphonePanelVisibility({visible: true});
					var caller;
					var defaultCaller = '';
					var callIdCisco;
					if (call.id.indexOf('-') != -1 ){
						callIdCisco = call.id.split('-')[0];
					}


				   	if ( (App.connection.system.indexOf('etrali') != -1 && call.caller.number) || (callIdCisco != null && call.called.number && callIdCisco.indexOf(call.called.number) != -1) ) { // En Etrali o Cisco en una call normal									
								defaultCaller = call.caller.number;						
					} else{	 // Cisco cuando recibe una transferCall (nos quedamos con el teléfono original transferido no con el que realiza la ConsultationCall)			
						defaultCaller = call.called.number;									
					}
					console.log('---- callIdCisco: ' + callIdCisco);
					console.log('---- call.called.number:' + call.called.number + '   ----    call.id.indexOf(call.called.number): ' + call.id.indexOf(call.called.number));
					console.log('---- defaultCaller: ' + defaultCaller);

					// Etrali doesn't support line label, so don't show it for Etrali calls
					if (App.connection.system.indexOf('etrali') != -1) {
						var callText = '<div id="incoming-history-' + call.callid + '" class="incoming-history incoming-history-' + call.callid + ' flash"> ' +
							'<b>&nbsp;Incoming call:&nbsp;</b>' + defaultCaller + '<br><br><button style="width: 25%;" class="btn btn-sx btn-primary action-mini" onClick="App.answerCall(\'' + call.id + '\');setActiveTab(\'AnswerCall\');">' + getImgButton('AnswerCall-mini') + ' Answer Call</button> </div>';
					} else {
						var callText = '<div id="incoming-history-' + call.callid + '" class="incoming-history incoming-history-' + call.callid + ' flash"> ' +
							'<b>&nbsp;Incoming call:&nbsp;</b><b>Line</b>&nbsp;' + interestLabel + '&nbsp;-&nbsp;<b>Caller</b>&nbsp;' + defaultCaller + '<br><br><button style="width: 25%;" class="btn btn-sx btn-primary action-mini" onClick="App.answerCall(\'' + call.id + '\');setActiveTab(\'AnswerCall\');">' + getImgButton('AnswerCall-mini') + ' Answer Call</button> </div>';
					}

					if (document.getElementById("incoming-history-" + call.callid)) {
						j$("#incoming-history-" + call.callid).html(callText);
					} else {			
						j$(".incoming-other").append(callText);    
					}

					CAServerCallContact.getContactName(formatPhoneNumberDialed(defaultCaller), function(result, event) {
						console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
						var fullCaller;
						if (result.contactName === "No") {
							caller = defaultCaller;
						} else {
							caller = result.contactName;
						}
						console.log('---- caller: ' + caller);
						
						if (result.contactName == '' || result.contactName == "No"){
							fullCaller = defaultCaller;
							Llamada.clientName = 'Unknown';
							Llamada.contactName = defaultCaller;
						}else{
							fullCaller = result.contactName + ' - ' + result.clientName;
							Llamada.clientName = ((result.clientCode != 'No')?(result.clientCode + ' - ' + result.clientName):(result.clientName));
							Llamada.contactName = result.contactName;
						}
						if (fullCaller.length > 60){
							fullCaller = fullCaller.substring(0,57) + '...';
						}

						// Etrali doesn't support line label, so don't show it for Etrali calls
						if (App.connection.system.indexOf('etrali') != -1) {
							var callText = '<div id="incoming-history-' + call.callid + '" class="incoming-history incoming-history-' + call.callid + ' flash"> ' +
								'<b>&nbsp;Incoming call:&nbsp;</b>' + fullCaller + '<br><br><button style="width: 25%;" class="btn btn-sx btn-primary action-mini" onClick="App.answerCall(\'' + call.id + '\');setActiveTab(\'AnswerCall\');">' + getImgButton('AnswerCall-mini') + ' Answer Call</button> </div>';
						} else {
							var callText = '<div id="incoming-history-' + call.callid + '" class="incoming-history incoming-history-' + call.callid + ' flash"> ' +
								'<b>&nbsp;Incoming call:&nbsp;</b><b>Line</b>&nbsp;' + interestLabel + '&nbsp;-&nbsp;<b>Caller</b>&nbsp;' + fullCaller + '<br><br><button style="width: 25%;" class="btn btn-sx btn-primary action-mini" onClick="App.answerCall(\'' + call.id + '\');setActiveTab(\'AnswerCall\');">' + getImgButton('AnswerCall-mini') + ' Answer Call</button> </div>';
						}
						if (document.getElementById("incoming-history-" + call.callid)) {
							j$("#incoming-history-" + call.callid).html(callText);
						}
						if(Notification.permission != "granted")
							Notification.requestPermission();
						else
							alerta();
					});

				} else if (call.state === "CallOriginated" && call.direction === "Outgoing") {
					setActiveTab('MakeCall');					
				}

				if (document.getElementById("active-call-" + call.callid)) {
					var callText = "";
				} else {
					var callText = "<div id='active-call-" + call.callid + "' class='call-list-entry'>";
				}
				var callTextNumber, callTextState, callDateTime, newCallerText, callTextActions = '';
				
				if (call.direction === "Incoming") {
					callTextNumber = '<a onClick="App.makeCall(\'' + call.caller.number + '\')">'
										+ call.caller.number
										+ '</a>';
				} else {
					callTextNumber = '<a onClick="App.makeCall(\'' + call.called.number + '\')">'
										+ call.called.number
										+ '</a>';
				}
				var callState = call.state;
				var callDirection = " - " + call.direction;

				callTextState = callState + callDirection;

				callDateTime = "";

				callTextActions = '<div id="actions-call-' + call.id + '" style="padding-left: 5px;"><br/>';
				
				/* ******** conditional ADDED ******** */
				if (call.state === "CallHeld") { // Si esta en HELD, solo se permite la accion "retrieve". Esto es para evitar el error en Etrali que en HELD devuelve la accion de colgar y si pulsas se peta
					validActions = ['RetrieveCall'];
				}else if(call.actions.indexOf('TransferCall') !== -1 || call.actions.indexOf('ConferenceCall') !== -1 ){ // si ya se trata de una ConsultationCall, no se permite que de nuevo se pueda hacer otra ConsultationCall
					validActions = ['ClearConnection', 'ClearCall', 'AnswerCall', 'HoldCall', 'RetrieveCall', 'TransferCall', 'ConferenceCall', 'ClearConference' /* , 'SingleStepTransfer', 'SendDigits', 'SendDigit' */];		
				}else{
					validActions = ['ClearConnection', 'ClearCall', 'ConsultationCall', 'AnswerCall', 'HoldCall', 'RetrieveCall', 'TransferCall', 'ConferenceCall', 'ClearConference' /* , 'SingleStepTransfer', 'SendDigits', 'SendDigit' */];		
				}
				/* ******* ***************** ******** */

			
				j$.each(call.actions, function(key, action) {
					var actionSplit = action.replace(/([A-Z])/g, ' $1');
					if (validActions.indexOf(action) !== -1) {
						/* ************ imagen del boton ************ */
						var imgAction = getImgButton(action);
						if (action == 'ConsultationCall'){
							actionSplit = '';
						}else if (action == 'HoldCall' && App.connection.system.indexOf('etrali') != -1 ){ // si es etrali por defecto HOLD hace el HOLD PUBLICO
							actionSplit = 'Public Hold Call';
							imgAction = getImgButton('PublicHoldCall');
						}
						
						callTextActions += '<button style="padding-left: 5px;width: 15%;" class="btn btn-sx btn-primary action-mini" onClick="App.requestAction(\'\', \'' + call.id + '\', \'' + action + '\');setActiveTab(\''+ action +'\');">' + imgAction + '</button> ' + actionSplit;
						
						if (action == 'ConsultationCall'){
							callTextActions += '<input type="text" id="input-consultation-' + call.id + '" style="width: 150px; height: 24px;font-size: 12px;" placeholder=" Consultation Call..." onkeyup="if(validateEnter(event) == true) { App.requestAction(\'\', \'' + call.id + '\', \'' + action + '\');setActiveTab(\''+ action +'\'); }"></input>';
						}else if (action == 'HoldCall' && App.connection.system.indexOf('etrali') != -1 ){ // Hold Private ETRALI	
							callTextActions += '<br/><button style="padding-left: 5px;width: 15%;" class="btn btn-sx btn-primary action-mini" onClick="App.requestAction(\'\', \'' + call.id + '\', \'HoldCall\',\'private\');setActiveTab(\'HoldCall\');">' + getImgButton('HoldCall') + '</button> Private Hold Call';
						}						
										
						callTextActions += '<br/>';											
						/* ************  ************ */
					}
				});
				callTextActions += '</div><div class="divseparator"/>';
							  
				if (App.controller && call.state !== "ConnectionCleared" && call.state !== "CallMissed") {
					if (call.direction === "Incoming") {
						var defaultCaller = '';	
						var callIdCisco;
						if (call.id.indexOf('-') != -1 ){
							callIdCisco = call.id.split('-')[0];
						}

						console.log('----- ********** defaultCaller -- App.connection.system: ' + App.connection.system + '  --- callIdCisco: '  + callIdCisco + ' --- call.called.number: ' + call.called.number);					
						
						if ( (App.connection.system.indexOf('etrali') != -1 && call.caller.number) || (callIdCisco != null && call.called.number && callIdCisco.indexOf(call.called.number) != -1) ) {	// Etrali call normal y en un hold publico incoming. Cisco en una call normal
							defaultCaller = call.caller.number;						
						} else if (callIdCisco != null && call.called.number && callIdCisco.indexOf(call.called.number) == -1 && call.called.number.length <= 7 && call.caller.number.length > 7){	 //  Cisco cuando recibe una transferCall (nos quedamos con el teléfono original transferido no con el que realiza la ConsultationCall).
							defaultCaller = call.caller.number;
						}else {// Etrali en un hold publico outgoing. Cisco cuando recibe una transferCall (nos quedamos con el teléfono original transferido no con el que realiza la ConsultationCall).
							defaultCaller = call.called.number;									
						}	
						
						CAServerCallContact.getContactName(formatPhoneNumberDialed(defaultCaller), function(result, event) {
							console.log('----- ********** App.controller && call.state !== "ConnectionCleared" && call.state !== "CallMissed"');						
							console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);							
							if (call.state !== "CallDelivered" && document.getElementById("incoming-history-" + call.callid)){
								j$(".incoming-history-" + call.callid).remove();
							}							
							var caller;						
							if (result.contactName === "No") {
								//
							} else {
								caller = result.contactName;
								callTextNumber = '<a onClick="App.makeCall(\'' + call.caller.number + '\')">'
										+ result.contactName
										+ '</a>';																									
							}

							// Etrali doesn't support line label, so don't show it for Etrali calls
							if (App.connection.system.indexOf('etrali') != -1) {
								newCallerText = '<div id="info-call-' + call.callid + '" style="margin: 0;"> '
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Phone Number</div><div id="number-' + call.callid + '" style="margin: 0;float:right;width:70%;">' + defaultCaller + '<br/>' + callTextState +'</div><br/><br/>' 
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Contact</div><div id="contact-' + call.callid + '" style="float:right;width:70%;">' + result.contactName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Client</div><div id="client-' + call.callid + '" style="float:right;width:70%;">' + result.clientName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '</div>';	
							} else {
								newCallerText = '<div id="info-call-' + call.callid + '" style="margin: 0;"> '
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Line</div><div id="interest-' + call.callid + '" style="margin: 0;float:right;width:70%;">' + interestLabel + '</div><br/>' 
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Phone Number</div><div id="number-' + call.callid + '" style="margin: 0;float:right;width:70%;">' + defaultCaller + '<br/>' + callTextState +'</div><br/><br/>' 
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Contact</div><div id="contact-' + call.callid + '" style="float:right;width:70%;">' + result.contactName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Client</div><div id="client-' + call.callid + '" style="float:right;width:70%;">' + result.clientName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '</div>';
							}
							
							if (document.getElementById("active-call-" + call.callid)) {
								callText = "";
							}
							
							callText = callText + newCallerText + callTextActions;
							
							if (document.getElementById("active-call-" + call.callid) && (call.caller.number || App.connection.system.indexOf('etrali') != -1 && call.called.number) ) {			
								j$("#active-call-" + call.callid).html(callText);
								if (call.state === "CallDelivered") {
									j$("#active-call-" + call.callid).appendTo("#incoming-call-list");
									j$("#active-call-" + call.callid).addClass("flash");
								} else if (call.state === "CallHeld") {
									j$("#active-call-" + call.callid).appendTo("#held-call-list");
									j$("#active-call-" + call.callid).removeClass("flash");
								} else {
									j$("#active-call-" + call.callid).appendTo("#call-list");
									j$("#active-call-" + call.callid).removeClass("flash");
								}
							} else if (call.caller.number || App.connection.system.indexOf('etrali') != -1 && call.called.number ) {
								if (callText != null && callText != "" && callText.startsWith("<div")){
									callText += "</div>";
								}							
								
								if (call.state === "CallDelivered") {
									j$("#incoming-call-list").prepend(callText);
									j$("#active-call-" + call.callid).addClass("flash");
								} else if (call.state === "CallHeld") {
									j$("#held-call-list").prepend(callText);
									j$("#active-call-" + call.callid).removeClass("flash");
								} else {													
									j$("#call-list").prepend(callText);
									j$("#active-call-" + call.callid).removeClass("flash");
								}
							}
						});
						
					} else {
						var numCalled = '';
					    if (call.called.number && call.called.number != '') {
							numCalled = call.called.number;
						}
						CAServerCallContact.getContactName(formatPhoneNumberDialed(numCalled), function(result, event) {	
							console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
							var caller;
							if (result.contactName === "No") {
								//
							} else if (call.called.number) {
								caller = result.contactName;
								callTextNumber = '<a onClick="App.makeCall(\'' + call.called.number + '\')">'
										+ result.contactName
										+ '</a>';										
							}

							// Etrali doesn't support line label, so don't show it for Etrali calls
							if (App.connection.system.indexOf('etrali') != -1) {
								newCallerText = '<div id="info-call-' + call.callid + '" style="margin: 0;"> '
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Phone Number</div><div id="number-' + call.callid + '" style="margin: 0;float:right;width:70%;">' + call.called.number + '<br/>' + callTextState +'</div><br/><br/>' 
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Contact</div><div id="contact-' + call.callid + '" style="float:right;width:70%;">' + result.contactName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Client</div><div id="client-' + call.callid + '" style="float:right;width:70%;">' + result.clientName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '</div>';	
							} else {
								newCallerText = '<div id="info-call-' + call.callid + '" style="margin: 0;"> '
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Line</div><div id="interest-' + call.callid + '" style="margin: 0;float:right;width:70%;">' + interestLabel + '</div><br/>' 
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Phone Number</div><div id="number-' + call.callid + '" style="margin: 0;float:right;width:70%;">' + call.called.number + '<br/>' + callTextState +'</div><br/><br/>' 
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Contact</div><div id="contact-' + call.callid + '" style="float:right;width:70%;">' + result.contactName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '<div align="right" style="padding-left: 10px;font-weight: bold;float:left;width:20%;">Client</div><div id="client-' + call.callid + '" style="float:right;width:70%;">' + result.clientName + '</div><br/>'
												+ '<div style="padding-left: 6px;padding-right: 6px;"><hr noshade="noshade" style="margin: 0;color: #0056b2;" size="1"/></div>'
												+ '</div>';
							}
											
							if (document.getElementById("active-call-" + call.callid)) {
								callText = "";
							}											
							
							callText = callText + newCallerText + callTextActions;
							
							if (document.getElementById("active-call-" + call.callid) && call.called.number) {
								j$("#active-call-" + call.callid).html(callText);
								if (call.state === "CallDelivered") {
									j$("#active-call-" + call.callid).appendTo("#call-list");
									j$("#active-call-" + call.callid).addClass("flash");
								} else if (call.state === "CallHeld") {
									j$("#active-call-" + call.callid).appendTo("#held-call-list");
									j$("#active-call-" + call.callid).removeClass("flash");
								} else {
									j$("#active-call-" + call.callid).appendTo("#call-list");
									j$("#active-call-" + call.callid).removeClass("flash");
								}
							} else if (call.called.number) {
								if (callText != null && callText != "" && callText.startsWith("<div")){
									callText += "</div>";
								}                         
								if (call.state === "CallDelivered") {
									j$("#call-list").prepend(callText);
									j$("#active-call-" + call.callid).addClass("flash");
								} else if (call.state === "CallHeld") {
									j$("#held-call-list").prepend(callText);
									j$("#active-call-" + call.callid).removeClass("flash");
								} else { 							
									j$("#call-list").prepend(callText);
									j$("#active-call-" + call.callid).removeClass("flash");
								}
							}
						})
					}
				} /* ******* Este caso nunca se va a dar porque se utiliza siempre controller  ******** */
				else if (call.state !== "ConnectionCleared" && call.state !== "CallMissed") {
					callText = callText + callTextNumber + callTextState + callDateTime + callTextActions;
					console.log('-------  Controller FALSE. Var callText: ' + callText); 
					console.log('-------  call.state: ' + call.state);				
					if(document.getElementById("active-call-" + call.callid)) {
						console.log('------- Existe elemento "active-call-' + call.callid + '".');
						j$("#active-call-" + call.callid).html(callText);
						if (call.state === "CallDelivered") {
							j$("#active-call-" + call.callid).appendTo("#call-list");
							j$("#active-call-" + call.callid).addClass("flash");
						} else if (call.state === "CallHeld") {
							j$("#active-call-" + call.callid).appendTo("#held-call-list");
							j$("#active-call-" + call.callid).removeClass("flash");
						} else {
							j$("#active-call-" + call.callid).appendTo("#call-list");
							j$("#active-call-" + call.callid).removeClass("flash");
						}
					} else {
						if (callText != null && callText != "" && callText.startsWith("<div")){
							callText += "</div>";
						}
						console.log('------- NO Existe elemento "active-call-' + call.callid + '".');
						if ((call.state === "CallDelivered") || (call.state === "CallOriginated")) {
							j$("#call-list").prepend(callText);
							j$("#active-call-" + call.callid).addClass("flash");
						} else if (call.state === "CallHeld") {
							j$("#held-call-list").prepend(callText);
							j$("#active-call-" + call.callid).removeClass("flash");
						} else {
							j$("#call-list").prepend(callText);
							j$("#active-call-" + call.callid).removeClass("flash");
						}
					}
				} /* *************** */
				
			}	
			
        }

       oneThing = false;
}	

//Se desconecta de click to dial y se limpian todos los campos.
App.disconnected = function() {
    delete Session.callHandlerId;
    j$("#call-history").html('');
    j$("#call-list").html('');
    j$("#call-held").html('');
    j$("#call-incoming").html('');
    j$("#system-list").html('<option value="blank">Select System</option>');

    saveLogUserCTI('User is disconnected (Strophe is disconnected).', 'Connection', false,'','','','');
    
	/* Aqui hay que añadir que la tab del navegador sea activa, y que lo haga cada minuto como mucho */
	if (App.reconnect) {
		console.log("Reconnecting...");		
        Session.connection.flush();
        Session.connection.reset();
        console.log(Session.connection);
        setTimeout(function() {
            saveLogUserCTI('User is disconnected. - Reconnecting: ' + JSON.stringify(Session.connection), 'Connection', false,'','','','');
        }, 1000);      		
        setTimeout(function() {
            App.signIn();
        }, 30000);
    }
    
	// Icono connected/disconnected
	userDisconnected = true;
	setTraderIcon();
}

$(function() {
});

$(window).unload(function() {
   if (App) {
       App.clear();
   }
});

//Lleva a cabo el registro en click to dial.
App.signIn = function() {
    App.clear();

    var username = App.options.app.username;
    var password = App.options.app.password;
    var withCredentials = App.options.app.cookies;

    if (username && password) {
        Session.connection = new Strophe.Connection(BOSH_URL
            ,{
                "withCredentials": withCredentials
            }
        );
        connect({
            username: username,
            password: password,
            resource: App.options.app.xmpp_resource,
            domain: App.options.app.xmpp_domain
        });
    }

    App.user = {
        'username' : username,
        'domain' : App.options.app.xmpp_domain
    }

       setTimeout(function() {
            saveLogUserCTI('signIn: ' + JSON.stringify(App.user) + ' --- {"password":"'+ password +'", "withCredentials":"'+ withCredentials +'"}', 'Connection', false,'','','','');
        }, 1000);

}

//Lleva a cabo el cierre de sesión.
App.signOut = function() {
    Session.connection.disconnect();
}

//Para determinar qué servicios existen en el servidor, el cliente debe enviar un paquete de disco.
App.discoItems = function() {
    Session.connection.openlink.discoItems(App.options.app.xmpp_domain, function(iq) {
        var items = iq.getElementsByTagName('query')[0].childNodes;

        App.disco.items = [];
        App.disco.systems = [];

        for (var i = 0; i < items.length; i++) {
            var data = {};
            for (var j = 0; j < items[i].attributes.length; j++){
                data[ items[i].attributes[j].nodeName ] =  items[i].attributes[j].nodeValue;
            };
            App.disco.items.push(data);
            App.discoInfo(data.jid);
        }       
        });
}

//encuentra que servicios existen en el servidor.
App.discoInfo = function(jid) {
    Session.connection.openlink.discoInfo(jid, function(iq) {
        var info = iq.getElementsByTagName('query')[0].childNodes;

        for (var i = 0; i < info.length; i++) {
            var data = {};

            for (var j = 0; j < info[i].attributes.length; j++){
                data[ info[i].attributes[j].nodeName ] =  info[i].attributes[j].nodeValue;
            };

            data.node_name = info[i].nodeName;
            data.from = iq.getAttribute('from');
            data.xml = info[i];

            if (data.var) {
                if (data.var.indexOf("gtx/telephony") > -1) {
                    data.type = "gtx";
                } else if (data.var.indexOf("openlink:01:00:00#tsc") > -1) {
                    data.type = "openlink";
                }
                if (data.type) {
                    data.system = data.from.replace("." + Session.connection.domain, '');
                    j$("#system-list").append("<option value='" + data.system + "' >"
                        + data.system + "</option>");
                    App.disco.systems[data.system] = data;
                }
            }
        }
    });
}

//obtiene los datos de profile que se va a conectar a click to dial.
App.getProfiles = function() {
    // remove profiles and show new ones
    Session.connection.openlink.getProfiles(getDefaultSystem(), function(profiles) {
        // empty profile div
        console.log(profiles);
        saveLogUserCTI('Profiles: ' + JSON.stringify(profiles), 'Connection', false,'','','','');        
        for (var profileId in profiles) {
            var profile = profiles[profileId];

            if (profile.default && profile.default === "true") {
                App.user['profile'] = profile;
            }
        }

        if (App.options.app.autologon) {
            App.getInterests();
        }
    }, function(message) {
		userDisconnected = true;
		saveLogUserCTI('getProfiles: The user is not connected to Click To Dial server: ' + message, 'Connection', false,'','','','');
        alert('The user is not connected to Click To Dial server: ' + message);
    });
}


//Obtiene todas las líneas disponibles para poder recibir llamadas e invoca a subscribe().
App.getInterests = function(profileId) {
	// empty interest list and show new ones
	if (!profileId && App.user.profile) {
		profileId = App.user.profile.id;
	}
	
	
	Session.connection.openlink.getInterests(getDefaultSystem(), profileId, function (interests) {
		// success callback
		
		App.user.interests = [];
		App.user.interest = [];
		
		var listSubscribesForLog = [];

		if (j$("#line-placeholder")) {
			j$("#line-placeholder").remove();
		}

		for (var interestId in interests) {
			var interest = interests[interestId];
			App.user.interests[interestId] = interest;
			//if (interest.default && interest.default === "true") {  --> Si se comenta este IF, se registran todas la líneas de la torreta (se subscribe a todas)
			//														--> Si se deja sin comentar, se registran sólo las líneas "por defecto == true" 
			
			//App.user['interest'] = interest; // -> este es la variable donde se guarda el Interest con el que se va a realizar las llamadas, como esta en un FOR se va a quedar el último
			//App.user['interest'] = interest;							// y quizás habría que hacer que en lugar de ser un único valor sea una lista de valores de Interets,
										// y cuando se realice una llamada seleccionar con el Interest que se quiere llamar (habría que definir en base a qué elegimos un Interest u otro)
			
			//App.subscribe(interest.id); // --> añadimos la subscripción
			listSubscribesForLog.push('interest id: ' + interest.id);
			if ((interest.default && interest.default === "true") || (interest.label.includes("_GRP_"))) {
				App.user.interest.push(interest.id);
				App.subscribe(interest.id);
				if (interest.id.indexOf('-1') > -1) {
					j$("#select-01").prepend("<option value='" + interest.id + "' selected='true'>" + interest.label + "</option>");
				} else {
					j$("#select-01").append("<option value='" + interest.id + "' >" + interest.label + "</option>");
				}
			}
			// } else if (interest.label.indexOf('GRP')) {_GR_
			// 	App.user.interest.push(interest.id);
			// 	App.subscribe(interest.id);
			// };
			//}  --> FIN IF
		}


		
		console.log('>>>>>>>> interests: '+JSON.stringify(interests));
		console.log('>>>>>>>> App.user.interests: ' + JSON.stringify(App.user.interests));
		console.log('>>>>>>>> App.user.interests subscriptions(' + listSubscribesForLog.length + '): ' + JSON.stringify(listSubscribesForLog));
		console.log('>>>>>>>> App.user.interest: ' + JSON.stringify(App.user.interest));		
		saveLogUserCTI('getInterests: ' + '\r\n' + 'User interests: ' + JSON.stringify(App.user.interests) + '\r\n\r\n' + 'User interests subscriptions(' + listSubscribesForLog.length + '): ' + JSON.stringify(listSubscribesForLog) + '\r\n\r\n' + 'User interest selected to make calls: ' + JSON.stringify(App.user.interest), 'Connection', false,'','','','');
			
		/* código de prueba para comprobar un funcionamiento simple de recepción de evento y envío de peticiones, pero no hacer una monitorización completa de la torreta (registrar las líneas que estaban marcada en la torreta como "Líneas Por defecto")
		if (App.options.app.autologon) {
		    App.subscribe();
		}*/
		
	}, function (message) {
		userDisconnected = true;
		saveLogUserCTI('getInterests: The user is not connected to Click To Dial server: ' + message, 'Connection', false,'','','','');
        alert('The user is not connected to Click To Dial server: ' + message);
	});
}

//Si el servidor admite la función y el cliente está autorizado para usar el servicio telefónico, el resultado disco #info contendrá la función
App.getFeatures = function(profileId) {
    // empty feature lists 
    Session.connection.openlink.getFeatures(getDefaultSystem(), profileId, function(features) {
        // success callback
        console.log(features);
    }, function(message) {
    	userDisconnected = true;
    	saveLogUserCTI('getFeatures: The user is not connected to Click To Dial server: ' + message, 'Connection', false,'','','','');
        alert('The user is not connected to Click To Dial server: ' + message);
    });
}

//se conectan las líneas encontradas.
App.subscribe = function(interest) {
    if (interest) {
        var interest = interest;
    } else if (App.user.interest) {
        var interest = App.user.interest.id;
    }
    Session.connection.openlink.subscribe(Session.connection.openlink.getPubsubAddress(), interest, function(message) {
        if (App.options.app.autologon) {
            App.getCallHistory('50');
        }
    }, function(message) {
        if (App.options.app.autologon) {
            App.getCallHistory('50');
        }
    });
}

//se desconectan las líneas conectadas.
App.unsubscribe = function(interest) {
    Session.connection.openlink.unsubscribe(Session.connection.openlink.getPubsubAddress(), interest, function(message) {
        console.log(message);
    }, function(message) {
    	userDisconnected = true;
    	saveLogUserCTI('unsubscribe: The user is not connected to Click To Dial server: ' + message, 'Connection', false,'','','','');
        alert('The user is not connected to Click To Dial server: ' + message);
    });
}

//Se obtiene el historial de la llamada.
App.getCallHistory = function(count) {
    if (App.user) {
        var jid = App.user.username + '@' + App.user.domain;
        var profile = App.user.profile.id;
    }
    // Session.connection.openlink.getCallHistory(getDefaultSystem(), jid, profile,  
    //     "", "", "", "", "", "0", count, function(history) {
    //     var filteredCalls = [];
    //     j$.each(history, function(key, call) {
    //         if (App.user.interests[call.interest]) {
    //             filteredCalls.push(call);
    //         }
    //     });

    //     if (filteredCalls) {
    //         j$("#call-history").html('');
    //     }

    //     j$.each(filteredCalls, function(key, call) {
    //         if (key < 50) {
    //             var name;
    //             var callText;

    //             if (App.controller) {
    //                 if (call.state === "CallOriginated") {
    //                     console.log('Originated call found - being ignored');
    //                 } else if (call.direction === "Outgoing") {
				// 		var numCalled = '';
				// 	    if (call.called && call.called != '') {numCalled = call.called;}					
    //                     CAServerCallContact.getContactName(formatCallNumberOutgoing(numCalled), function(result, event) {
				// 			console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
    //                         var callHistoryLength = 0;
    //                         j$('.call-history-entry').each(function(){
    //                             callHistoryLength++;
    //                         })
    //                         if (callHistoryLength > 4) {
    //                             return;
    //                         }
    //                         if (result.contactName === "No") {
    //                             name = call.calledname;
    //                         } else {
    //                             name = result.contactName;
    //                         }
    //                         callText = ''
    //                             + '<a onClick="App.makeCall(\'' + call.called + '\')">'
    //                             + name
    //                             + '</a>';
    //                         callText += ' - out';

    //                         callText += '<li style="margin-left: 20px;">' + call.timestamp + '</li>';
    //                         callText += '';
    //                         j$("#call-history").append('<div class="call-history-entry">' + callText + '</div><br/>');
    //                     });
    //                 } else if (call.direction === "Incoming" || call.state === "CallMissed") {
				// 		var numCaller = '';
				// 	    if (call.caller && call.caller != '') {numCaller = call.caller;}					
    //                     CAServerCallContact.getContactName(formatPhoneNumberDialed(numCaller), function(result, event) {
				// 			console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
    //                         var callHistoryLength = 0;
    //                         j$('.call-history-entry').each(function(){
    //                             callHistoryLength++;
    //                         })
    //                         if (callHistoryLength > 5) {
    //                             return;
    //                         }
    //                         if (result.contactName === "No") {
    //                             name = call.callername;
    //                         } else {
    //                             name = result.contactName;
    //                         }
    //                         callText = ''
    //                             + '<a onClick="App.makeCall(\'' + call.caller + '\')">'
    //                             + name
    //                             + '</a>';
    //                         if (call.state === "CallMissed") {
    //                             callText += ' - missed';
    //                         } else if (call.direction === "Incoming") {
    //                             callText += ' - in';
    //                         }

    //                         callText += '<li style="margin-left: 20px;">' + call.timestamp + '</li>';
    //                         callText += '';
    //                         j$("#call-history").append('<div class="call-history-entry">' + 
    //                             callText + '</div><br/>');
    //                     });         
    //                 }
    //             } else {
    //                 if (call.direction === "Outgoing") {
    //                     callText = ''
    //                         + '<a onClick="App.makeCall(\'' + call.called + '\')">'
    //                         + call.calledname
    //                         + '</a>';
    //                     callText += ' - out';
    //                 } else if (call.direction === "Incoming") {
    //                     callText = ''
    //                         + '<a onClick="App.makeCall(\'' + call.caller + '\')">'
    //                         + call.callername
    //                         + '</a>';
    //                     callText += ' - in';
    //                 } else if (call.state === "CallMissed") {
    //                     callText = ''
    //                         + '<a onClick="App.makeCall(\'' + call.caller + '\')">'
    //                         + call.callername
    //                         + '</a>';
    //                     callText += ' - missed';
    //                 }
    //                 callText += '<li style="margin-left: 20px;">' + call.timestamp + '</li>';
    //                 callText += '';
    //                 j$("#call-history").append('<div class="call-history-entry">' + 
    //                     callText + '</div><br/>');
    //             }
    //         }
    //     })
    // },function(message) {
    //     alert(message);
    // });
}

var lastMakeCallClick, lastAnswerCallClick, lastClearCallClick, lastRequestActionClick;

//Se encarga de realizar el proceso mediante el cual se realiza la llamada.
App.makeCall = function(extension, interest) {
/* la funcion stripWhitespace se puede completar: a parte de quitar espacios tambien puede quitar "+" o el "+34".... 
	Tambien se puede invocar antes del MakeCall para que aparezca el n�mero formateado en la caja de texto */
	var now = new Date().getTime();
	if (lastMakeCallClick + 5000 > now) {
		return;
	}
	lastMakeCallClick = now;

	
    extension = stripWhitespace(extension);
    if (!Session.connection.connected) {
    	saveLogUserCTI('Please log in to use this functionality.', 'CallMade', false,'','','','');
        alert('Please log in to use this functionality');
        return;
    } else if (App.user.interest) {
        var interest = interest? interest:App.user.interest[0];  
    } else if (App.connection.type !== "gtx") {    	
    	saveLogUserCTI('Please log in to use this functionality.', 'CallMade', false,'','','','');        
    	alert('Please log in before using this functionality');
        return;
    }

    var type = App.connection.type;

    if (type === "gtx") {
        Session.connection.gtx.makeCallGtx(getDefaultSystem(), App.connection.system, extension,
            '', function(call) {
                alert('Call made with id: ' + call.id);
                console.log(call);
            },function(message) {
                alert(message);
            }
        );
    } else if (type === "openlink") {
        Session.connection.openlink.makeCall(getDefaultSystem(), interest, extension,
		'', function(call) {
                console.log('Call: '+JSON.stringify(call));
                Session.connection.openlink._updateCalls(call);
            },function(message) {
            	saveLogUserCTI('MakeCall Error: ' + message, 'CallMade', false,'','','','');
                alert(message);
            }
        );
    } else {
    	saveLogUserCTI('Phone system not supported.', 'CallMade', false,'','','','');
        alert("Phone system not supported");
    }
}

//obtiene los datos del contacto cuando entra una llamada.
App.answerCall = function(callid) {
	var now = new Date().getTime();
	if (lastAnswerCallClick + 5000 > now) {
		return;
	}
	lastAnswerCallClick = now;

    var type = App.connection.type;
    if (type === "gtx") {
        Session.connection.gtx.answerCallGtx(getDefaultSystem(), App.connection.system, callid,
            function(call) {
				var numCaller = '';
				if (call.callerId && call.callerId != '') {numCaller = call.callerId;}			
                CAServerCallContact.getContactName(formatPhoneNumberDialed(numCaller), function(result, event) {
					console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
                    if (result.contactName === "No") {
                        caller = call.callerId;
                    } else {
                        caller = result.contactName;
                    }
                    alert('Call answered from: ' + caller);
                })
                console.log(call);
            },function(message) {
                alert(message);
            }
        );
    } else if (type === "openlink") {
        App.requestAction("", callid, "AnswerCall");
    } else {
    	saveLogUserCTI('Phone system not supported.', 'CallMade', false,'','','','');
        alert("Phone system not supported");
    }
}

//gestiona el poner la llamada en espera.
App.holdCall = function(callid) {
    var type = App.connection.type;
    if (type === "gtx") {
        Session.connection.gtx.holdCallGtx(getDefaultSystem(), App.connection.system, callid,
            function(call) {
				var numCaller = '';
				if (call.callerId && call.callerId != '') {numCaller = call.callerId;}				
                CAServerCallContact.getContactName(formatPhoneNumberDialed(numCaller), function(result, event) {
					console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
                    if (result.contactName === "No") {
                        caller = call.callerId;
                    } else {
                        caller = result.contactName;
                    }
                    alert('Call held to: ' + caller);
                })
                console.log(call);
            },function(message) {
                alert(message);
            }
        );
    } else {
        alert("Phone system not supported");
    }
}


//gestiona el retomar la llamada cuando dicha llamada se encuentra en espera.
App.unholdCall = function(callid) {
    var type = App.connection.type;
    if (type === "gtx") {
        Session.connection.gtx.unholdCallGtx(getDefaultSystem(), App.connection.system, callid,
            function(call) {
				var numCaller = '';
				if (call.callerId && call.callerId != '') {numCaller = call.callerId;}				
                CAServerCallContact.getContactName(formatPhoneNumberDialed(numCaller), function(result, event) {
					console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
                    if (result.contactName === "No") {
                        caller = call.callerId;
                    } else {
                        caller = result.contactName;
                    }
                    alert('Call unheld to: ' + caller);
                })
                console.log(call);
            },function(message) {
                alert(message);
            }
        );
    } else {
        alert("Phone system not supported");
    }
}


//Limpia la llamada cuando esta finaliza.
App.clearCall = function(callid) {
	var now = new Date().getTime();
	if (lastClearCallClick + 5000 > now) {
		return;
	}
	lastClearCallClick = now;

    var type = App.connection.type;
    if (type === "gtx") {
        Session.connection.gtx.clearCallGtx(getDefaultSystem(), App.connection.system, callid, extension,
            function(call) {
                if (call.callOrigin === "INBOUND") {
					var numCaller = '';
					if (call.callerId && call.callerId != '') {numCaller = call.callerId;}					
                    CAServerCallContact.getContactName(formatPhoneNumberDialed(numCaller), function(result, event) {
						console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
                        var caller;
                        if (result.contactName === "No") {
                            caller = call.callerId;
                        } else {
                            caller = result.contactName;
                        }
                        alert('Call cleared from: ' + caller);
                    })
                } else {
					var numCalled = '';
					if (call.calledId && call.calledId != '') {numCalled = call.calledId;}				
                    CAServerCallContact.getContactName(formatPhoneNumberDialed(numCalled), function(result, event) {
						console.log('----- Response invoke CAServerCallContact.getContactName: ' + result.numRecords + ' record(s) found -- ' + result.contactName + ' -- ' + result.clientName);
                        var called;
                        if (result.contactName === "No") {
                            called = call.calledId;
                        } else {
                            called = result.contactName;
                        }
                        alert('Call cleared to: ' + called);
                    })
                }
                console.log(call);
            },function(message) {
                alert(message);
            }
        );
    } else if (type === "openlink") {
        var call = Session.connection.openlink.calls[callid];
        var supported;
        j$.each(call.actions, function(actionKey, action) {
            if (action === "ClearConnection") {
                supported = true;
            }
        })
        if (supported) {
            App.requestAction("", callid, "ClearConnection");
        } else {
            console.log("Action not supported");
        }
    } else {
        alert("Phone system not supported");
    }
}

//Una vez que tiene una llamada activa, puede realizar una Acción de solicitud en la llamada al pasar una acción válida.
App.requestAction = function(interest, callId, actionId, value1, value2) {
    var now = new Date().getTime();
    if (lastRequestActionClick + 5000 > now) {
        return;
    }
    lastRequestActionClick = now;

    var call = Session.connection.openlink.calls[callId];
    if (call && call.interest) {
        var interest = call.interest;
    }

    if (actionId == 'ConsultationCall')
    {
		value1 = document.getElementById('input-consultation-' + callId).value;
    }
    Session.connection.openlink.requestAction(getDefaultSystem(), interest, callId, new Action({
        'id': actionId,
        'value1': value1,
        'value2': value2
    }), function(call) {
        if (call) {
        }
        console.log(call);
		},function(message) {
		saveLogUserCTI('requestAction (' + actionId + '): ' + message, 'Event', false,callId,'','','');																						
        alert(message);
    });
	
/* ********************* ************ INTERACTION LOG ********* ********************* */	
	if (actionId == 'RetrieveCall'){
		console.log('>>>>>>>>>> Retrieve a call - reloading interaction log data...');
		var relatedToFromCallId = getCallIdRelatedTo(callId);
		if (relatedToFromCallId != '') {
			j$('#callLogRelatedTo option').each(function(){
				if (this.value == relatedToFromCallId) {
					j$('#callLogRelatedTo').val(relatedToFromCallId);
					loadComments();	
					
				}
			});
		}

	}
/* ********************* ********************* ********************* ********************* */
}

//Obtiene la configuración predeterminada del Sistema.
function getDefaultSystem() {
    return App.connection.system + '.' + Session.connection.domain;
}

//quita los espacios en blanco.
function stripWhitespace(str) {	
    var rStr = new String(str);
    rStr = rStr.split(" ");
    var ret = "";
    var i;
    for (i = 0; i < rStr.length; i++) {
        ret += rStr[i];
    }
    return ret;
}

//Realiza la conexión de Salesforce con click to dial.
function connect(data) {
    console.log("Connect to: " + BOSH_URL);
    setTimeout(function() {
            saveLogUserCTI('Connect data: ' + JSON.stringify(data), 'Connection', false,'','','','');
        }, 1000);        

    Session.connection.rawInput = function(body) {
        if (App.debug()) {
            console.log('RECV: ' + body);
            saveLogUserCTI('RECV: ' + body, 'RawInput', false,'','','','');
        }
    };

    Session.connection.rawOutput = function(body) {
        if (App.debug()) {
            console.log('SENT: ' + body);
            saveLogUserCTI('SENT: ' + body, 'RawOutput', false,'','','','');
        }
    };

    var connectionCallback = function(status) {
        if (status == Strophe.Status.ERROR) {
            console.log('Strophe connection error.');
            saveLogUserCTI('Strophe connection error.', 'Connection', false,'','','','');
			userDisconnected = true;
        } else if (status == Strophe.Status.CONNECTING) {
            console.log('Strophe is connecting.');
            saveLogUserCTI('Strophe is connecting.', 'Connection', false,'','','','');
        } else if (status == Strophe.Status.CONNFAIL) {
            console.log('Strophe failed to connect.');
            saveLogUserCTI('Strophe failed to connect.', 'Connection', false,'','','','');
			userDisconnected = true;
        } else if (status == Strophe.Status.AUTHENTICATING) {
            console.log('Strophe is authenticating.');
            saveLogUserCTI('Strophe is authenticating.', 'Connection', false,'','','','');
        } else if (status == Strophe.Status.AUTHFAIL) {
            console.log('Strophe failed to authenticate.');
            saveLogUserCTI('Strophe failed to authenticate.', 'Connection', false,'','','','');
			userDisconnected = true;
        } else if (status == Strophe.Status.CONNECTED) {
            console.log('Strophe is connected.');
            App.connected(this);
        } else if (status == Strophe.Status.DISCONNECTED) {
            console.log('Strophe is disconnected.');            
            App.disconnected();
        } else if (status == Strophe.Status.DISCONNECTING) {        	            
            saveLogUserCTI('User is disconnected (Strophe is disconnecting).', 'Connection', false,'','','','');
            console.log('Strophe is disconnecting.');            
        } else if (status == Strophe.Status.ATTACHED) {
            console.log('Strophe is attached.');
            saveLogUserCTI('Strophe is attached.', 'Connection', false,'','','','');
        } else {
            console.log('Strophe unknown: ' + status);
            saveLogUserCTI('Strophe unknown: ' + status, 'Connection', false,'','','','');
        }
    };

    var jid = data.username + "@" + data.domain + "/" + data.resource;
    console.log("Connect: jid: " + jid);        
    Session.connection.connect(jid, data.password, connectionCallback);
	
	// Icono de connected/Disconnected
    setTimeout(function() {
            setTraderIcon();
        }, 5000);
}

if(Notification.permission != "granted") {
	setTimeout(function() {
		Notification.requestPermission();
	},1500);
}