/**
* Global Desktop APC
* Description: methods used by Ficha de Grupo module
*/
window.baseFichaGrupo = (function () {
    return {
        setColumns: function (component) {
            component.set('v.columns', [
                { label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' } } },
                { label: 'Client Name', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } } },
                { label: 'Status', fieldName: 'status', type: 'String' },
                { label: 'Country', fieldName: 'oppCountry', type: 'String' },
                { label: 'Est. Closing Date', fieldName: 'closingDate', type: 'Date' },
                { label: 'Exp. Revenues', fieldName: 'expectedRevenue', type: 'currency', typeAttributes: { currencyCode: component.get('v.userISOCode') } }
            ]);
            return component;
        },
        setColumnsFilial: function (component) {
            component.set('v.columns', [
                {label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' }} },
                {label: 'Exp. Revenues', fieldName: 'expectedRevenue', type: 'currency', typeAttributes: { currencyCode: component.get('v.userISOCode') } },
                {label: 'Pot. Revenues', fieldName: 'potentialRevenue', type: 'currency', typeAttributes: { currencyCode: component.get('v.userISOCode') } },
                {label: 'Exp. Probability', fieldName: 'expProb', type: 'String'},
                {label: 'Status', fieldName: 'status', type: 'String'},
                {label: 'Country', fieldName: 'oppCountry', type: 'String'},
                {label: 'Est. Closing Date', fieldName: 'closingDate', type: 'Date'}
            ]);
            return component;
        },
        navigateGoBackAccount: function (component) {
            component.find('nav').navigate({
                type: 'standard__recordPage',
                attributes: {
                    recordId: component.get('v.idAcc'),
                    objectApiName: 'PersonAccount',
                    actionName: 'view'
                }
            });
            // return value;
        },
        setTimeRefresh: function(component) {
            let dat = new Date();
            if (dat.getHours() >= 0 && dat.getHours() < 10) {
                if (dat.getMinutes() >= 0 && dat.getMinutes() < 10) {
                    component.set("v.timeRefresh", "0" + dat.getHours() + ":0" + dat.getMinutes());
                } else {
                    component.set("v.timeRefresh", "0" + dat.getHours() + ":" + dat.getMinutes());
                }
            } else {
                if (dat.getMinutes() >= 0 && dat.getMinutes() < 10) {
                    component.set("v.timeRefresh", dat.getHours() + ":0" + dat.getMinutes());
                } else {
                    component.set("v.timeRefresh", dat.getHours() + ":" + dat.getMinutes());
                }
            }

        },
        convertHex: function (hexInput, opacity) {
            let hex = hexInput.replace('#', '');
            let r = parseInt(hex.substring(0, 2), 16);
            let g = parseInt(hex.substring(2, 4), 16);
            let b = parseInt(hex.substring(4, 6), 16);

            let result = 'rgba(' + r + ',' + g + ',' + b + ',' + opacity / 100 + ')';
            return result;
        },
        isEmpty: function isEmpty(obj) {
            for (let prop in obj) {
                if (obj.hasOwnProperty(prop))
                    return false;
            }
            return true;
        },
        parseToCurrency: function (value) {
            value = parseFloat(value);
            value += '';
            let x = value.split('.');
            let x1 = x[0];
            let x2 = x.length > 1 ? ',' + x[1] : '';
            let rgx = /(\d+)(\d{3})/;
            while (rgx.test(x1)) {
                x1 = x1.replace(rgx, '$1' + '.' + '$2');
            }
            value = x1 + x2;
            return value;
        },
        tooltipFunction: function(tooltipItem, data, horizontal, currencyCode, numDec = 2) {
            var label = data.datasets[tooltipItem.datasetIndex].label || '';
            var number;
            if (label) {
                label += ': ';
            }
            if(horizontal) {
                number = parseFloat(tooltipItem.xLabel).toFixed(numDec);
            } else {
                number = parseFloat(tooltipItem.yLabel).toFixed(numDec);
            }
            if(number === undefined || number === 'NaN') {
                number = parseFloat(0).toFixed(numDec);
            }
            number += '';
            var aux = number.split('.');
            var aux1 = aux[0];
            var aux2 = aux.length > 1 ? ',' + aux[1] : '';
            var rgxpression = /(\d+)(\d{3})/;
            while (rgxpression.test(aux1)) {
                aux1 = aux1.replace(rgxpression, '$1' + '.' + '$2');
            }
            number = aux1 + aux2;


            label += number;
            label += ' ' + currencyCode;
            return label;
        }
    };
}());