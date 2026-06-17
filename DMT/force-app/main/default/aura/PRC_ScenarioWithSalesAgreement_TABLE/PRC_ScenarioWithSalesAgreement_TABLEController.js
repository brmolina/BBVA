({
    doinit: function (component, event, helper) {
        console.log('doinit');
        var columnsloaded = helper.loadcolumns(component);
        columnsloaded.then(function (resolve) {
            console.log('columns loaded');
            return helper.loaddata(component, event, helper);
        }).then($A.getCallback(function (resolve) {
            console.log('then del loaddata');
            console.log('dataloaded');
        })).catch(function (error) {
            console.log('catch');
            console.log('el puto error:' + JSON.stringify(error));
        });
    }
})