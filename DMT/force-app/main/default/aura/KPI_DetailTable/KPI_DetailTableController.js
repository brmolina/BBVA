/* eslint-disable no-unused-expressions */
({
    doInit : function(component, event, helper) {
        helper.setColumns(component, event, helper);
        helper.setData(component, helper);
    },

    handleClose: function(component, event, helper) {
        helper.destroyCmp(component, event, helper);
    },

    waiting: function(component) {
        component.set('v.waiting', true);
    },

    doneWaiting: function(component) {
        component.set('v.waiting', false);
    },

    handleSave: function (component, event, helper) {
        var draftValues = event.getParam('draftValues');
        helper.save(component, helper, draftValues);
    },

    handleCancel: function(component, event, helper) {
        component.set('v.errors', false);
        component.set('v.draftValues', []);
        component.set('v.showSaveButton', false);
    },

    handleChange: function( component, event, helper) {
        component.set('v.showSaveButton', true);
    },

    handleRowActions: function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {
            case 'show_details':
            console.log('row: ', JSON.stringify(row));
                break;
            case 'delete':
                helper.removeKpi(component, row);
                break;
        }
    }
 })