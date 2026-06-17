({
    doCallOuts: function ( component ) {
        let urlgetConfData = component.get('v.endPoint') + $A.get("$Label.c.DES_IP_URL_OPP") + component.get('v.idOppIP') + $A.get("$Label.c.DES_IP_URL_OPP_FORM")
            + component.get('v.recordId');       
        let urlgetListData =  component.get('v.endPoint') +$A.get("$Label.c.DES_IP_URL_BASE")+ $A.get("$Label.c.DES_IP_URL_OPP_FORM") 
            + component.get('v.recordId') + $A.get("$Label.c.DES_IP_COMPANY") + $A.get("$Label.c.DES_IP_LIST");

        let callOutHeaders = {
            "Content-Type": "application/json",
            "ip-user": component.get('v.codBbvaUser')
        };

        let callConfiguration = {
            method: 'GET',
            headers: callOutHeaders,
            credentials: "include"
        };

        this.callOut( component, urlgetConfData,callConfiguration, 'v.data_formExt' );
        this.callOut( component, urlgetListData, callConfiguration, 'v.data_CompaniesExt' );

    },

    callOut: function ( component, endpoint, callConfiguration, dataProvider ) {
        fetch( endpoint, callConfiguration )
            .then(response => {
                if ( response.ok ) {
                    return response.json();
                }else if ( response.status == 404 ) {
                    return {};
                }
                throw new Error('There\'re some problems getting the data, please try later.');
            })
            .then(data => {
                component.set( dataProvider, data );
            })
            .catch( error => {
                this.handleErrors(error);
            });
    },

    handleErrors: function ( error ) {
        let errorMsg = error instanceof TypeError ? $A.get("$Label.c.DES_ERROR_IP_SERVER") : error.message;
        console.error('fail to load data: ' + errorMsg);
        let lexOrigin = location.protocol  + "//" +  location.host;
        parent.postMessage({ "operation":"showToast", "toastMsg": errorMsg }, lexOrigin );
    }

})