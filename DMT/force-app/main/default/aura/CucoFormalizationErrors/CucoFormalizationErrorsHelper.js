({
    setupDataTable: function(component, event, helper) {
        component.set('v.columns', [
            {label: $A.get("$Label.c.Error_Table_Column_One"), fieldName: 'cuco__gf_error_desc__c', type: 'text', columnWidthsMode: 'fixed'},
            {label: $A.get("$Label.c.Error_Table_Column_Two"), fieldName: 'Family_Code__c', type: 'text', columnWidthsMode: 'fixed'},
            {type: 'button-icon', fixedWidth: 40, typeAttributes: {
                iconName: 'utility:delete',
                name: 'deleteError',
                title: 'Delete',
                variant: 'border-filled'
            }}
        ]);
    },

    getData: function(component, event, helper) {
        var action = component.get("c.getErrors");
        action.setParams({
            recordId : component.get('v.recordId')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                component.set('v.allData', resultData);
                component.set('v.filteredData', resultData);
                this.setPaging(component, resultData);
            }
        });
        $A.enqueueAction(action);
    },

    deleteError : function (component, row) {
        var serverAction = component.get("c.deleteErrors");
        serverAction.setParams({
            error : row,
            recordId : component.get('v.recordId')
        });
        serverAction.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var eventToast = $A.get("e.force:showToast");
                eventToast.setParams({
                    "title": $A.get("$Label.c.Success"),
                    "type":'success',
                    "message": $A.get("$Label.c.Record_deleted_successfully")
                });
                eventToast.fire();
                this.getData(component);
            }
        });
        $A.enqueueAction(serverAction);
    },

    setPaging: function (component, resultData) {
        var countTotalPage = Math.ceil(resultData.length/component.get("v.pageSize"));
        var totalPage = countTotalPage > 0 ? countTotalPage : 1;
        component.set("v.totalPages", totalPage);
        component.set("v.currentPageNumber", 1);
        this.setDataByPage(component);
    },

    setDataByPage: function(component) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var filteredData = component.get('v.filteredData');
        var x = (pageNumber - 1) * pageSize;
        for (; x < (pageNumber) * pageSize; x++){
            if (filteredData[x]) {
                data.push(filteredData[x]);
            }
        }
        component.set("v.tableData", data);
    }

})