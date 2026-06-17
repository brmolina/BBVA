({
    doInit: function(cmp, event, helper) {

        // Crear el grupo

        let prepareOpp = cmp.get("c.preparePrivateOpportunity");
        let addMember = cmp.get("c.addMemberNF");
        let params = {
            userId: cmp.get("v.userId"),
            recordId: cmp.get("v.opportunityId"),
            formId: cmp.get("v.formId")
        };

        prepareOpp.setParams( params );
        addMember.setParams( params );

        prepareOpp.setCallback( this, function( response ) {

            let state = response.getState();
            if ( state === "SUCCESS" ) {

                // Añadir el miembro al grupo recien creado

                addMember.setCallback( this, function( response ) {

                    let state = response.getState();
                    if ( state === "SUCCESS" ) {

                        // Redirigir...
                        let navigate = cmp.get( "v.navigateFlow" );
                        navigate("NEXT");

                    } else {

                        helper.handleErrors(response.getError());

                    }

                } );

                $A.enqueueAction( addMember );

            } else {

                helper.handleErrors(response.getError());

            }

        } );

        $A.enqueueAction( prepareOpp );

    }
})