/*
* COLUMNS
*/

const columns = {
    common: [
        { label: 'Group Name', field: 'groupName', title: 'Group Name', type: 'text', sortable: false },
        { label: 'Group Id', field: 'groupId', title: 'Group Id', type: 'text', sortable: false },
        { label: 'Subgroup Name', field: 'subGroupName', title: 'Subgroup Name', type: 'text', sortable: false },
        { label: 'Subgroup Id', field: 'subGroupId', title: 'Subgroup Id', type: 'text', sortable: false },
        { label: 'Level3 Name', field: 'level3groupName', title: 'Subgroup Name', type: 'text', sortable: false },
        { label: 'Level3 Id', field: 'level3groupId', title: 'Subgroup Id', type: 'text', sortable: false },
        { label: 'Client Id', field: 'customerId', title: 'Client Id', type: 'text', sortable: false },
        { label: 'Country Id', field: 'countryIfoId', title: 'Country Id', type: 'text', sortable: false },
        { label: 'Taxpayer Id', field: 'taxpayerId', title: 'Taxpayer Id', type: 'text', sortable: false },
        { label: 'Client Name', field: 'customerName', title: 'Client Name', type: 'text', sortable: false }
    ],
    tcm: [
        { label: 'Risk Analyst', field: 'riskAnalystId', title: '', type: 'text', sortable: false },
        { label: 'Internal Rating (long)', field: 'updLmsclInternalRatgType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation ActvyType', field: 'assetAllocationActvyType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation SubScType', field: 'assetAllocationSubSecType', title: '', type: 'text', sortable: false }, 
        { label: 'Star Code', field: 'customerCounterpartiesCodesDesc', type: 'text', sortable: false },
        { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 't_hpgr_customers.g_upd_smscl_internal_ratg_type', type: 'text', sortable: false },
        { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 't_hpgr_customers.gf_current_rating_tool_date', type: 'date', sortable: false }
    ]
};

export function getColumns(tabName) {
    if (columns[tabName]) {
        return columns['common'].concat(columns[tabName]);
    } else {
        return columns['common'];
    }
}

export function getVisibleColumns(groupName) {
        return [{ label: groupName, field: 'name', type: 'text', sortable: false }];
}