({
	// Sets an empApi error handler on component initialization
	onInit : function(component, event, helper) {
			// Get the empApi component
			const empApi = component.find('empApi');

			// Uncomment below line to enable debug logging (optional)
			// empApi.setDebugFlag(true);

			// Register error listener and pass in the error handler function
			empApi.onError($A.getCallback(error => {
					// Error can be any type of error (subscribe, unsubscribe...)
					console.error('EMP API error: ', error);
			}));

			/////

			// Get the channel from the input box
			const channel = '/topic/SoldOrderUpdated';
			// Replay option to get new events
			const replayId = -1;

			// Subscribe to an event
			empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
                // Process event (this is called each time we receive an event)
                console.log('Received event ', JSON.stringify(eventReceived));
                window.setTimeout(
                $A.getCallback(function() {
                	$A.get('e.force:refreshView').fire();
            	}), 2000//HAY 2 DE DELAY PORQUE EL PUSH TOPIC SE EJECUTA NADA MAS ENTRAR EN BASE DE DATOS, ANTES DE QUE TERMINE EL TRIGGER
            		// POR LO QUE AL RECARGAR EL FORMULARIO DE PRODUCTOS NO DABA TIEMPO A MOSTRAR LA FORMULA DE POTENTIAL REVENUES BIEN CALCULADA
            		// YA QUE NO DABA TIEMPO A QUE TERMINASE EL TRIGGER, POR LO QUE SIN EL DELAY SE MOSTRABA EL VALOR ANTIGUO, LO CUAL OBLIGABA AL USUARIO A HACER F5
					// HACIENDO ESTE DELAY ES MÁS LENTA LA HERRAMIENTA, PERO HASTA ENCONTRAR OTRA SOLUCION QUE PERMITA EJECUTAR EL REFRESHVIEW AL TERMINAR
					// LA EJECUCION DEL TRIGGER ES NECESARIO EL DELAY
                );

			}))
			.then(subscription => {
					// Confirm that we have subscribed to the event channel.
					// We haven't received an event yet.
					console.log('Subscribed to channel ', subscription.channel);
					// Save subscription to unsubscribe later
					component.set('v.subscription', subscription);
			});
	}
})