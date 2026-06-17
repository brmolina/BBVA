({
    doInit: function(cmp, event, helper) {

        helper.gtGAAccountId(cmp);
        if (cmp.get('v.obj') === 'bupl__BP_Need__c') {
            cmp.set('v.columns', [
                {
                    label: 'Need Name',
                    fieldName: 'needUrl',
                    type: 'url',
                    typeAttributes: { label: { fieldName: 'needDesc' } }
                },
                { label: 'Pain Points', fieldName: 'needPain', type: 'String' },
                { label: 'Need', fieldName: 'needNeed', type: 'String' },
                { label: 'Country', fieldName: 'needCountry', type: 'String' },
                {
                    label: 'Created By',
                    fieldName: 'needCrea',
                    type: 'url',
                    typeAttributes: { label: { fieldName: 'needCrName' } }
                },
                { label: 'Created Date', fieldName: 'needDate', type: 'Date' }
            ])}
        if (cmp.get('v.obj') === 'bupl__BP_GrowthDriver__c') {
            cmp.set('v.columns', [
                {
                    label: 'Driver Name',
                    fieldName: 'driverUrl',
                    type: 'url',
                    typeAttributes: { label: { fieldName: 'driverShort' } }
                },
                { label: 'Product Family', fieldName: 'driverFam', type: 'String' },
                { label: 'Product', fieldName: 'driverProd', type: 'String' },
                { label: 'Country', fieldName: 'driverCountry', type: 'String' },
                { label: 'Description', fieldName: 'driverDesc', type: 'String' },
                { label: 'Created Date', fieldName: 'driverDate', type: 'Date' }
            ])}
    },

  navigateToMyComponent: function(component, event, helper) {
    var evt = $A.get('e.force:navigateToComponent');
    evt.setParams({
      componentDef: 'c:DES_GA_NyGD_RelatedList',
      componentAttributes: {
        apId: component.get('v.apId'),
        tableSize: null,
        recordId: component.get('v.recordId')
      }
    });
    evt.fire();
  }
});