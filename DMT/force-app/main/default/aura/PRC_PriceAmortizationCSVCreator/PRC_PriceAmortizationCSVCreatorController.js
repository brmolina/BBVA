({
    //
    // carga CSV
    //
    displayMsgInfo: function (component, event, helper) {
    },
    launchFileUpload: function (component, event, helper) {
        var msgDisplay = helper.showToast(component, event, helper, 'info', 'Remember that the Amortization start and end dates must be ' +
            'the same dates entered in the "Start Date" and "Maturity Date" fields of the price form.', 'sticky');
        console.log(msgDisplay);
        var fileInput = component.find("file").getElement();
        fileInput.click();
        /*	}));  */
    },
    handleUploadFinished: function (component, event, helper) {
        var fileInput = component.find("file").getElement();
        var file = fileInput.files[0];
        if (file) {
            console.log(">>>>>> UPLOADED")
            var reader = new FileReader();
            reader.readAsText(file, 'UTF-8');
            reader.onload = function (evt) {
                var csv = evt.target.result;
                component.set("v.csvString", csv);
            }
            var appEvent = $A.get("e.c:PRC_AmortizationCSVInterface_Refresh");
            appEvent.fire();
        }
    },

    handleGetCSV: function (component, event, helper) {
        var csv = component.get("v.csvString");
        if (csv != null) {
            helper.saveAmortizationCSV(component, helper, csv);
            var initTable = component.get('c.doInit');
            $A.enqueueAction(initTable);
        }
    },
    //
    // paginacion
    //
    doInit: function (component, event, helper) {
        console.log('Amortization Interface init : editable : ' + component.get('v.isEditableForm'));
        var opportunityId = component.get('v.recordId');
        var pageSize = component.get("v.pageSize");
        var action = component.get("c.getPriceAmortizationData");
        var params = { 'oppId': opportunityId };
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set('v.amortizationList', response.getReturnValue());
                component.set("v.totalSize", component.get("v.amortizationList").length);
                component.set("v.start", 0);
                component.set("v.end", pageSize - 1);
                var numPages = Math.floor(component.get("v.totalSize") / pageSize);
                if (component.get("v.totalSize") % pageSize > 0) { numPages++; }
                component.set("v.numPages", numPages);
                var paginationList = [];
                var firstPageSize = (component.get("v.totalSize") < pageSize ? component.get("v.totalSize") : pageSize);
                for (var i = 0; i < firstPageSize; i++) {
                    paginationList.push(response.getReturnValue()[i]);
                }
                component.set('v.paginationList', paginationList);
                var totalNonAccrualFees = 0;
                var amortizationList = component.get('v.amortizationList');
                for (var j = 0; j < component.get("v.totalSize"); j++) {
                    totalNonAccrualFees += amortizationList[j].gf_non_accrual_comission_per__c;
                }
                component.set('v.totalNonAccrualFees', totalNonAccrualFees);
                helper.updatePricingDetails(component, helper, totalNonAccrualFees);
                console.log('----------- doInit -----------');
                console.log('>>>>>>>>> paginationList.lengh: ' + paginationList.length);
                console.log('>>>>>>>>> pageSize: ' + component.get("v.pageSize"));
                console.log('>>>>>>>>> start: ' + component.get("v.start"));
                console.log('>>>>>>>>> end: ' + component.get("v.end"));
            }
        });
        action.setParams(params);
        $A.enqueueAction(action);
    },
    onSelectChange: function (component, event, helper) {
        var selectedLabel = component.find("records").get("v.value");
        var selected;
        var amortList = component.get("v.amortizationList");
        if (selectedLabel === 'All') {
            selected = parseInt(amortList.length);
        } else {
            selected = parseInt(selectedLabel);
        }
        var paginationList = [];
        component.set("v.pageSize", selected);
        component.set("v.start", 0);
        component.set("v.end", selected - 1);
        component.set("v.currentPage", 1);
        var numPages = Math.floor(amortList.length / selected);
        if (amortList.length % selected > 0) { numPages++; }
        component.set("v.numPages", numPages);
        for (var i = 0; i < selected; i++) {
            paginationList.push(amortList[i]);
        }
        component.set('v.paginationList', paginationList);
        console.log('----------- onSelectChange -----------');
        console.log('>>>>>>>>> paginationList.lengh: ' + paginationList.length);
        console.log('>>>>>>>>> pageSize: ' + component.get("v.pageSize"));
        console.log('>>>>>>>>> start: ' + component.get("v.start"));
        console.log('>>>>>>>>> end: ' + component.get("v.end"));
    },
    next: function (component, event, helper) {
        var amortList = component.get("v.amortizationList");
        var end = component.get("v.end");
        var pageSize = component.get("v.pageSize");
        var currentPage = component.get("v.currentPage");
        var paginationList = [];
        var counter = 0;
        for (var i = end + 1; i < end + pageSize + 1; i++) {
            if (amortList.length > i) {
                paginationList.push(amortList[i]);
                counter++;
            }
        }
        var start = end + 1;
        end = end + counter;
        component.set("v.start", start);
        component.set("v.end", end);
        component.set('v.paginationList', paginationList);
        component.set("v.currentPage", currentPage + 1);
        console.log('----------- next -----------');
        console.log('>>>>>>>>> paginationList.lengh: ' + paginationList.length);
        console.log('>>>>>>>>> pageSize: ' + component.get("v.pageSize"));
        console.log('>>>>>>>>> start: ' + component.get("v.start"));
        console.log('>>>>>>>>> end: ' + component.get("v.end"));
    },
    previous: function (component, event, helper) {
        var amortList = component.get("v.amortizationList");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var currentPage = component.get("v.currentPage");
        var paginationList = [];
        var counter = 0;
        for (var i = start - pageSize; i < start; i++) {
            if (i > -1) {
                paginationList.push(amortList[i]);
                counter++;
            }
        }
        var end = start - 1;
        start = start - pageSize;
        component.set("v.start", start);
        component.set("v.end", end);
        component.set('v.paginationList', paginationList);
        component.set("v.currentPage", currentPage - 1);
        console.log('----------- previous -----------');
        console.log('>>>>>>>>> paginationList.lengh: ' + paginationList.length);
        console.log('>>>>>>>>> pageSize: ' + component.get("v.pageSize"));
        console.log('>>>>>>>>> start: ' + component.get("v.start"));
        console.log('>>>>>>>>> end: ' + component.get("v.end"));
    },
    first: function (component, event, helper) {
        var amortList = component.get("v.amortizationList");
        var pageSize = component.get("v.pageSize");
        component.set("v.start", 0);
        component.set("v.end", pageSize - 1);
        var paginationList = [];
        for (var i = 0; i < pageSize; i++) {
            paginationList.push(amortList[i]);
        }
        component.set('v.paginationList', paginationList);
        console.log('----------- first -----------');
        console.log('>>>>>>>>> paginationList.lengh: ' + paginationList.length);
        console.log('>>>>>>>>> pageSize: ' + component.get("v.pageSize"));
        console.log('>>>>>>>>> start: ' + component.get("v.start"));
        console.log('>>>>>>>>> end: ' + component.get("v.end"));
    },
    last: function (component, event, helper) {
        var amortList = component.get("v.amortizationList");
        var pageSize = component.get("v.pageSize");
        var totalSize = component.get("v.totalSize");
        component.set("v.start", totalSize - pageSize + 1);
        component.set("v.end", totalSize - 1);
        var paginationList = [];
        for (var i = totalSize - pageSize + 1; i < totalSize; i++) {
            paginationList.push(amortList[i]);
        }
        component.set('v.paginationList', paginationList);
        console.log('----------- last -----------<');
        console.log('>>>>>>>>> paginationList.lengh: ' + paginationList.length);
        console.log('>>>>>>>>> pageSize: ' + component.get("v.pageSize"));
        console.log('>>>>>>>>> start: ' + component.get("v.start"));
        console.log('>>>>>>>>> end: ' + component.get("v.end"));
    },
    downloadTempalteCsv: function (component, event, helper) {
        helper.showToast(component, event, helper, 'info', 'Remember that the Amortization start and end dates must be ' +
            'the same dates entered in the "Start Date" and "Maturity Date" fields of the price form.', 'sticky');
        var amortizationData = [];

        // call the helper function which "return" the CSV data as a String
        var csv = helper.convertArrayOfObjectsToCSV(component, amortizationData);
        if (csv == null) { //if error
            return;
        }

        // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####
        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self';
        hiddenElement.download = 'TemplateAmortizationSchedule.csv';  // CSV file: only name can be changed, not .csv
        document.body.appendChild(hiddenElement); // Required for FireFox browser
        hiddenElement.click();
    },
    downloadCsv: function (component, event, helper) {
        var amortizationData = component.get("v.amortizationList");

        // call the helper function which "return" the CSV data as a String
        var csv = helper.convertArrayOfObjectsToCSV(component, amortizationData);
        if (csv == null) { //if error
            return;
        }

        // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####
        var hiddenElement = document.createElement('a');
        var currentDate = new Date();
        var mes = currentDate.getMonth() + 1;
        if (mes < 10) { mes = '0' + mes; }
        var strDate = currentDate.getFullYear() + '-' + mes + '-' + currentDate.getDate();
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self';
        hiddenElement.download = 'AmortizationScheduleExportData_' + strDate + '.csv';  // CSV file: only name can be changed, not .csv
        document.body.appendChild(hiddenElement); // Required for FireFox browser
        hiddenElement.click();
    },
    displayConfirmPopup: function (component, event, helper) {
        component.set('v.displaymodal', true);
    },
    deleteAmortization: function (component, event, helper) {
        component.set('v.displaySpinner', true);
        var amortData = component.get("v.amortizationList");
        if (amortData != null) {
            helper.deleteAmortizationData(component, helper);
        }

    },
    cancelDeleteAmortization: function (component, event, helper) {
        component.set('v.displaymodal', false);
    }
})