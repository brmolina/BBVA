({
    doInit: function(component, event, helper) {
        helper.getInitialData(component, event, helper);
    },
    handleOnCheckTerminal: function(cmp, event, helper) {
        helper.handleOnCheckTerminal(cmp, event, helper);
    },
    handleNodeClicked: function(component, event) {
        var filters = event.getParams('ap');
        console.log(JSON.stringify(filters.title));
    },
    handleMostrarInfo: function(cmp, event, helper) {
        helper.handleMostrarInfo(cmp, event, helper);
    },
    handleMostrarInfo1: function(cmp, event, helper) {
        let value = 1;
        helper.handleMostrarInfov(cmp, event, helper, value);
    },
    handleMostrarInfo2: function(cmp, event, helper) {
        let value = 2;
        helper.handleMostrarInfo(cmp, event, helper, value);
    },
    handleMostrarInfo3: function(cmp, event, helper) {
        let value = 3;
        helper.handleMostrarInfo(cmp, event, helper, value);
    },
    handleMostrarInfo4: function(cmp, event, helper) {
        let value = 4;
        helper.handleMostrarInfo(cmp, event, helper, value);
    },
    handleSort: function(cmp, event, helper) {
        helper.handleSort(cmp, event);
    },
    filter: function(component, event, helper) {
        let filterField = component.get('v.filterField');
        let data = component.get('v.data');
        let term = component.get('v.filter');

        var results = data;
        var regex;
        try {
            regex = new RegExp(term, 'i');
            switch (filterField) {
                case 'rating':
                    results = data.filter(row => regex.test(row.rating));
                    break;
                case 'name':
                    results = data.filter(row => regex.test(row.name));
                    break;
                case 'participantType':
                    results = data.filter(row => regex.test(row.participantType));
                    break;
                case 'country':
                    results = data.filter(row => regex.test(row.country));
                    break;
                case 'dateEEFF':
                    results = data.filter(row => regex.test(row.dateEEFF));
                    break;
                case 'state':
                    results = data.filter(row => regex.test(row.state));
                    break;
                default:
                    results = data.filter(row => (regex.test(row.rating) || regex.test(row.participantType) ||
                        regex.test(row.country) || regex.test(row.dateEEFF) || regex.test(row.state) || regex.test(row.name)));
            }
        } catch (e) {
            console.log(JSON.stringify(e));
        }
        component.set('v.acctList', results);
    },
    handleChange: function(cmp, event, helper) {
        helper.handleChange(cmp, event);
    },
    handlefilter: function(cmp, event, helper) {
        helper.getSearchData(cmp, event, helper);
    },
    nextPage: function(cmp, event, helper) {
        helper.nextPage(cmp, event, helper);
    },
    previusPage: function(cmp, event, helper) {
        helper.previusPage(cmp, event, helper);
    }
});