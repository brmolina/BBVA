({
    loaddata: function (component, event, helper) {
        console.log('loaddata');
        return new Promise(function (resolve, reject) {
            var action = component.get('c.xdata');
            var oppid = component.get('v.recordId');
            console.log('loaddate recordId: ' + oppid);
            var params = { 'oppid': oppid };
            var callback = function (response) {
                var state = response.getState();
                var value = response.getReturnValue();
                if (state === 'SUCCESS') {
                    console.log('value: ' + value);
                    component.set('v.data', value);
                    resolve();
                } else {
                    reject('load data failed!');
                }
            };
            action.setParams(params);
            action.setCallback(this, callback);
            $A.enqueueAction(action);
        });
    },
    loadcolumns: function (component) {
        return new Promise(function (resolve, reject) {
            var columns = [];
            columns.push({ label: 'YEAR', fieldName: 'year_id__c', type: 'number' });
            columns.push({ label: 'RAROEC', fieldName: 'PRC_RAR_with_Funding__c', type: 'percentage' });
            columns.push({ label: 'RORC', fieldName: 'PRC_RORC_with_Funding__c', type: 'percentage' });
            columns.push({ label: 'CAP.ECO.', fieldName: 'economic_capital_amount__c', type: 'number' });
            columns.push({ label: 'APR REG.', fieldName: 'gf_sum_rwa_regy_amount__c', type: 'number' });
            try {
                console.log('try del columns');
                component.set('v.columns', columns);
                resolve();
            } catch (error) {
                console.log('columns error : ' + error.message);
                reject('columns not set');
            }
        });
    },
    test: function (component) {
        var action = component.get('c.test');
        var oppid = component.get('v.recordId');
        console.log('test recordId: ' + oppid);
        var params = { 'oppid': oppid };
        var callback = function (response) {
            var state = response.getState();
            var value = response.getReturnValue();
            if (state === 'SUCCESS') {
                console.log('value: ' + value);
                component.set('v.data', value);
                resolve();
            } else {
                reject('load data failed!');
            }
        };
        action.setParams(params);
        action.setCallback(this, callback);
        $A.enqueueAction(action);
    }
})