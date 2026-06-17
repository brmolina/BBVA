({
    handleClose: function(cmp, evt, helper) {
        cmp.destroy();
        let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
        appEvent.setParams({
            'recordId': cmp.get('v.recordId')
        });
        appEvent.fire();
    }
})