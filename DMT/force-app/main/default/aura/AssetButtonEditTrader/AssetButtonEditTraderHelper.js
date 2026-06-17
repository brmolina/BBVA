({

    canEdit: function (component, event, helper) {
        var idrecord = component.get('v.inputAttributes').recordId;
        console.log('Record id '+idrecord);
        component.set('v.recordId',idrecord);
        var appEvent = $A.get("e.c:AssetSalesTierEvent");
        appEvent.setParams({ "message": 'edit-asset-tier' });
        appEvent.fire();
        $A.get("e.force:closeQuickAction").fire();
    }

  })