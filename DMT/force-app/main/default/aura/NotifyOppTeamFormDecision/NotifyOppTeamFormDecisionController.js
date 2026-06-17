({
    doInit: function(cmp, event, helper) {

        let notifyOppTeam = cmp.get("c.NotifyOppTeamFormDecision");
        let params = {
            targets: cmp.get("v.targets"),
            decision: cmp.get("v.decision"),
            form: cmp.get("v.form"),
            relatedCase: cmp.get("v.relatedCase")
        };

        notifyOppTeam.setParams( params );

        notifyOppTeam.setCallback( this, function( response ) {

            let state = response.getState();
            if ( state === "SUCCESS" ) {

                // Redirigir...
                let navigate = cmp.get( "v.navigateFlow" );
                navigate("NEXT");

            } else {

                helper.handleErrors(response.getError());

            }

        } );

        $A.enqueueAction( notifyOppTeam );
    }
})