({
    doInit : function(cmp, event, helper){
        var detailView = cmp.get("v.header");
        if(detailView == true) {
            window.scrollTo(0,0);
        }

        helper.getTableData(cmp);

        if(detailView == true) {
            cmp.set('v.columns', [
                {label: 'Client Name', fieldName: 'clientRed', type: 'url', typeAttributes: { label: { fieldName: 'clientName' }} },
                {label: 'Frachise', fieldName: 'franchise', type: 'currency', cellAttributes: { alignment: 'left' }},
                {label: 'Date', fieldName: 'dateDeal', type: 'Date'},
                {label: 'Product', fieldName: 'relProduct', type: 'String'},
                {label: 'Id Operation', fieldName: 'idOperation', type: 'String'},
                {label: 'Area', fieldName: 'areaName', type: 'String'},
                {label: 'App Operation', fieldName: 'appOperation', type: 'String'}
                //{label: 'Room', fieldName: 'roomFranchise', type: 'String'},
                //{label: 'Desk', fieldName: 'deskFranchise', type: 'String'}
             ]);
        } else {
            cmp.set('v.columns', [
                {label: 'Client Name', fieldName: 'clientRed', type: 'url', typeAttributes: { label: { fieldName: 'clientName' }} },
                {label: 'Frachise', fieldName: 'franchise', type: 'currency', cellAttributes: { alignment: 'left' }},
                {label: 'Date', fieldName: 'dateDeal', type: 'Date'},
                {label: 'Product', fieldName: 'relProduct', type: 'String'},
                {label: 'Id Operation', fieldName: 'idOperation', type: 'String'}
            ]);
        }
    }
})