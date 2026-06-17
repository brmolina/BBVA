({
    doInit: function (component, event, helper) {


         // Carga lista de insiders
         let action = component.get("c.getIpSalesforceData");
         action.setParams({
             "formId": component.get("v.recordId")
         });
         action.setCallback(this, function (response) {

             let state = response.getState();
             if (state === "SUCCESS") {

                component.set('v.data_bbvaInsiders', response.getReturnValue().bbvaInsiders);
                component.set('v.data_extInsiders', response.getReturnValue().extInsidersPages);
                component.set('v.questions', response.getReturnValue().questions);
				component.set('v.formCountry', response.getReturnValue().formCountrys);
                component.set('v.codBbvaUser', response.getReturnValue().codBbvaUser);
                component.set('v.endPoint', response.getReturnValue().endPoint);
                component.set('v.idOppIP', component.get('v.data_form.opportunity_id__c'));

                helper.doCallOuts(component);

             } else {
             }
         });
         $A.enqueueAction(action);
    },

    onDoneRendering: function (component, event, helper) {


        if ( component.get('v.data_form') && component.get('v.data_bbvaInsiders') && component.get('v.data_extInsiders') &&
            component.get('v.questions') && component.get('v.data_formExt') && component.get('v.data_CompaniesExt') ) {

            

                // Imprimir:
                window.print();

                // Cerrar ventana:
                let lexOrigin = location.protocol  + "//" +  location.host;
                parent.postMessage({'operation': 'closeAction'}, lexOrigin );

            
        }

    }

})