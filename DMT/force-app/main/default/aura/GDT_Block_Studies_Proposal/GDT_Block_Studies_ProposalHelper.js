({
    loadData: function(component) {
        var action = component.get("c.getTableData");
        var recordId = component.get("v.recordId");

        action.setParams({ parentId: recordId });

        action.setCallback(this, function(response) {
            if (response.getState() !== "SUCCESS") {
                console.error("Error obtaining data:", response.getError());
                component.set("v.columns", []);
                component.set("v.allData", []);
                component.set("v.pagedData", []);
                component.set("v.totalPages", 0);
                return;
            }

            var result = response.getReturnValue() || [];

            var mappedData = [];
            for (var i = 0; i < result.length; i++) {
                var row = result[i] || {};
                var newRow = Object.assign({}, row);
                if (row.Id) {
                    newRow.recordUrl = '/' + row.Id; 
                }
                if (row.analysisId) {
                    newRow.analysisUrl = '/' + row.analysisId; 
                }
                mappedData.push(newRow);
            }

            var hasAnyProposalLink = false;
            var hasAnyAnalysisLink = false;
            var hasStatusType = false;
            var hasPolicyExp = false;

            for (var j = 0; j < mappedData.length; j++) {
                var r = mappedData[j];
                if (r.recordUrl) hasAnyProposalLink = true;
                if (r.analysisUrl) hasAnyAnalysisLink = true;
                if (r.statusType) hasStatusType = true;
                if (r.policyExpirationDate) hasPolicyExp = true;
            }

            var columns = [];

            if (hasAnyProposalLink) {
                columns.push({
                    label: 'Proposal ID',
                    fieldName: 'recordUrl',
                    type: 'url',
                    typeAttributes: {
                        label: { fieldName: 'name' },
                        target: '_blank'
                    }
                });
            } else {
                columns.push({
                    label: 'Proposal ID',
                    fieldName: 'name',
                    type: 'text'
                });
            }

            columns.push({
                label: 'Group/ Client',
                fieldName: 'groupClient',
                type: 'text'
            });

            if (hasStatusType) {
                columns.push({
                    label: 'Status Type',
                    fieldName: 'statusType',
                    type: 'text'
                });
            }

            columns.push({
                label: 'Creation Date',
                fieldName: 'createdDate',
                type: 'text'
            });

            columns.push({
                label: 'Sanction Date',
                fieldName: 'validityDate',
                type: 'text'
            });

            if (hasPolicyExp) {
                columns.push({
                    label: 'Policy Expiration Date',
                    fieldName: 'policyExpirationDate',
                    type: 'text'
                });
            }

            columns.push({
                label: 'Risk Analyst',
                fieldName: 'contrastedUser',
                type: 'text'
            });

            columns.push({
                label: 'Total Direct Risk Ceiling',
                fieldName: 'finalCeiling',
                type: 'text'
            });

            columns.push({
                label: 'Currency',
                fieldName: 'ceilingCurrency',
                type: 'text'
            });

            columns.push({
                label: 'Unit',
                fieldName: 'unit',
                type: 'text'
            });

            if (hasAnyAnalysisLink) {
                columns.push({
                    label: 'Rating',
                    fieldName: 'analysisUrl',
                    type: 'url',
                    typeAttributes: {
                        label: { fieldName: 'analysisName' },
                        target: '_blank'
                    }
                });
            } else {
                columns.push({
                    label: 'Rating',
                    fieldName: 'analysisName',
                    type: 'text'
                });
            }

            component.set("v.columns", columns);
            component.set("v.allData", mappedData);

            var pageSize = component.get("v.pageSize") || 10;
            var totalPages = Math.ceil(mappedData.length / pageSize) || 0;
            component.set("v.totalPages", totalPages);

            var currentPage = component.get("v.currentPage") || 1;
            if (totalPages > 0 && currentPage > totalPages) {
                component.set("v.currentPage", totalPages);
            } else if (totalPages === 0) {
                component.set("v.currentPage", 1);
            }

            this.updatePagedData(component);
        });

        $A.enqueueAction(action);
    },

    updatePagedData: function(component) {
        var pageSize = component.get("v.pageSize") || 10;
        var currentPage = component.get("v.currentPage") || 1;
        var allData = component.get("v.allData") || [];

        var totalPages = Math.ceil(allData.length / pageSize) || 0;
        component.set("v.totalPages", totalPages);

        if (totalPages === 0) {
            component.set("v.pagedData", []);
            return;
        }

        if (currentPage < 1) currentPage = 1;
        if (currentPage > totalPages) currentPage = totalPages;
        component.set("v.currentPage", currentPage);

        var start = (currentPage - 1) * pageSize;
        var end = start + pageSize;
        var pageData = allData.slice(start, end);

        component.set("v.pagedData", pageData);
    }
});