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
    clientId: [
        { label: 'Group<br/>Head', field: 'groupHeaderName', title: 't_hpgr_customers.gf_risk_group_header_type', type: 'text', sortable: false },
        { label: 'Golden<br/>Customer', field: 'goldenCustomerId', title: 't_hpgr_customers.g_golden_customer_id', type: 'text', sortable: false },
        { label: 'LEI', field: 'lei', title: 't_hpgr_customers.g_lei_id', type: 'text', sortable: false },
        { label: 'Specialized<br/>Lending', field: 'specializedLendingType', title: 't_hpgr_customers.gf_specialized_lending_type', type: 'text', sortable: false },
        { label: 'NACE<br/>Activity', field: 'naceActivityId', title: 't_hpgr_customers.g_nace_activity_id', type: 'text', sortable: false },
        { label: 'Sector<br/>AA', field: 'sectorAA', title: 't_hpgr_customers.gf_asset_allc_sector_desc', type: 'text', sortable: false },
        { label: 'Subsector<br/>AA', field: 'subSectorAA', title: 't_hpgr_customers.gf_aa_subsector_desc', type: 'text', sortable: false },
        { label: 'Activity<br/>AA', field: 'activityAA', title: 't_hpgr_customers.gf_aa_activity_desc', type: 'text', sortable: false },
        { label: 'Booking<br/>Country', field: 'countryId', title: 't_hpgr_customers.g_country_id', type: 'text', sortable: false },
        { label: 'Outlook', field: 'outlookRpvGeographyDesc', title: 't_hpgr_customers.gf_outlook_rpv_geography_desc', type: 'text', sortable: false },
        { label: 'RPV', field: 'riskPortfolioViewDesc', title: 't_hpgr_customers.gf_risk_portfolio_view_desc', type: 'text', sortable: false },
        { label: 'Front Analyst', field: 'frontAnalystId', title: 't_hpgr_customers.gf_front_analyst_id', type: 'text', sortable: false },
        { label: 'Rating Analyst', field: 'riskAnalystId', title: 't_hpgr_customers.gf_risk_analyst_id', type: 'text', sortable: false }
    ],
    clientRisk: [
        { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 't_hpgr_customers.g_upd_smscl_internal_ratg_type', type: 'text', sortable: false },
        { label: 'Internal<br/>Rating (long)', field: 'updLmsclInternalRatgType', title: 't_hpgr_customers.g_upd_lmscl_internal_ratg_type', type: 'text', sortable: false },
        { label: 'Current Rating<br/>Tool', field: 'currentRatingToolId', title: 't_hpgr_customers.gf_current_rating_tool_id', type: 'text', sortable: false },
        { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 't_hpgr_customers.gf_current_rating_tool_date', type: 'date', sortable: false },
        { label: 'FFSS Regulatory<br/>Rating Date', field: 'ffssRegulatoryRatingDate', title: 't_hpgr_customers.gf_ffss_regulatory_rating_date', type: 'date', sortable: false },
        { label: 'Override', field: 'regyRatgOverrideIndType', title: 't_hpgr_customers.g_regy_ratg_override_ind_type', type: 'text', sortable: false },
        { label: 'Adjusted<br/>Subsidiaries Rating', field: 'adjSbsidRatingIndType', title: 't_hpgr_customers.g_adj_sbsid_rating_ind_type', type: 'text', sortable: false },
        { label: 'Watchlist', field: 'wltClassificacionType', title: 't_hpgr_customers.g_wlt_classification_type', type: 'number', sortable: false },
        { label: 'External Rating<br/>(Local Curr)', field: 'unLtSmsclExtRatgLcType', title: 't_hpgr_customers.g_un_lt_smscl_ext_ratg_lc_type', type: 'text', sortable: false },
        { label: 'External Rating<br/>(Foreign Curr)', field: 'unifiedExtRatgLtFcType', title: 't_hpgr_customers.g_unified_ext_ratg_lt_fc_type', type: 'text', sortable: false },
        { label: 'Worst<br/>Stage', field: 'custTrdWorstStageType', title: 't_hpgr_customers.gf_cust_trd_worst_stage_type', type: 'text', sortable: false, align: 'right' },
        { label: 'ARCE Internal<br/>Rating (short)', field: 'arceSmsclIntRatgType', title: 't_hpgr_customers.gf_arce_smscl_int_ratg_type', type: 'text', sortable: false },
        { label: 'ARCE Internal<br/>Rating (long)', field: 'arceLmsclIntRatgType', title: 't_hpgr_customers.gf_arce_lmscl_int_ratg_type', type: 'text', sortable: false },
        { label: 'ARCE Current<br/>Rating Tool', field: 'regyCurrRatgToolId', title: 't_hpgr_customers.gf_regy_curr_ratg_tool_id', type: 'text', sortable: false },
        { label: 'ARCE Rating<br/>Generation Date', field: 'ratingGenerationDate', title: 't_hpgr_customers.gf_rating_generation_date', type: 'date', sortable: false },
        { label: 'ARCE Rating Validity<br/>Start Date', field: 'ratingValidityStartDate', title: 't_hpgr_customers.gf_rating_validity_start_date', type: 'date', sortable: false },
        { label: 'ARCE Rating<br/>Validity Months', field: 'rtFfssvldydtmtNumber', title: 't_hpgr_customers.gf_rt_ffss_vldy_dt_m_t_number', type: 'text', sortable: false },
        { label: 'ARCE Scale<br/>Last Update', field: 'scaleLastUpdDate', title: 't_hpgr_customers.gf_scale_last_upd_date', type: 'date', sortable: false },
        { label: 'ARCE Override<br/>Desc', field: 'custRtgOvrdRsnType', title: 't_hpgr_customers.gf_cust_rtg_ovrd_rsn_type', type: 'text', sortable: false },
        { label: 'ARCE Subsidiary/Matrix<br/>Relationship', field: 'rtSbsidMtrxReInshpType', title: 't_hpgr_customers.g_rt_sbsid_mtrx_relnshp_type', type: 'text', sortable: false }
    ],
    dataReport: [
        { label: 'Table name', field: 'tableDesc', title: 'Table name', type: 'text', sortable: false},
        { label: 'Entific', field: 'entificId', title: 'Entific', type: 'text', sortable: false },
        { label: 'Last Updated Date', field: 'tableUpdateDateDesc', title: 'Last Updated Date', type: 'text', sortable: false },
        { label: 'Data Description', field: 'originDataDesc', title: 'Data Description', type: 'text', sortable: false }
    ],
    overrideConsumption: [
        { label: '', field: 'action', title: '', type: 'text', sortable: false, align: 'center' },
        { label: 'Customer', field: 'customerId', title: 't_hpgr_consumption_override.g_customer_id', type: 'text', sortable: false },
        { label: 'Contract Id', field: 'contractId', title: 't_hpgr_consumption_override.g_contract_id', type: 'text', sortable: false },
        { label: 'Override Last Edited', field: 'overrideUploadDate', title: 't_hpgr_consumption_override.gf_override_upload_date', type: 'date', sortable: false },
        { label: 'Consumption Last Level', field: 'consumptionLastLevelName', title: 't_hpgr_consumption_override.gf_consumption_last_level_id', type: 'text', sortable: false },
        { label: 'Drawn Committed Contracts', field: 'committedContractsDisposedAmount', title: 't_hpgr_consumption_override.gf_cmt_cont_disposed_amount', type: 'euro', currencyDisplayAs: 'code', sortable: false, align: 'right' },
        { label: 'Drawn Uncommitted Contracts', field: 'uncommittedContractsDisposedAmount', title: 't_hpgr_consumption_override.gf_uncmt_cont_disposed_amount', type: 'euro', currencyDisplayAs: 'code', sortable: false, align: 'right' },
        { label: 'Undrawn Committed Contracts', field: 'committedContractsNonDisposedAmount', title: 't_hpgr_consumption_override.gf_cmt_cont_non_dsps_amount', type: 'euro', currencyDisplayAs: 'code', sortable: false, align: 'right' },
        { label: 'Undrawn Uncommitted Contracts', field: 'uncommittedContractsNonDisposedAmount', title: 't_hpgr_consumption_override.gf_uncmt_cont_non_dsps_amount', type: 'euro', currencyDisplayAs: 'code', sortable: false, align: 'right' },
        { label: 'Pending Authorized', field: 'authorizedRiskAmount', title: 't_hpgr_consumption_override.gf_authorized_risk_amount', type: 'euro', currencyDisplayAs: 'code', sortable: false, align: 'right' },
        { label: 'Total Exposure', field: 'unavailableRiskAmount', title: 't_hpgr_consumption_override.gf_unavailable_risk_amount', type: 'euro', currencyDisplayAs: 'code', sortable: false, align: 'right' },
        { label: 'Risk Analyst', field: 'riskAnalystId', title: 't_hpgr_consumption_override.gf_risk_analyst_id', type: 'text', sortable: false },
        { label: 'Override Start Date', field: 'overrideStartDate', title: 't_hpgr_consumption_override.gf_override_effective_str_date', type: 'date', sortable: false },
        { label: 'Override End Date', field: 'overrideEndDate', title: 't_hpgr_consumption_override.gf_override_effective_end_date', type: 'date', sortable: false },
        { label: 'Override Need', field: 'overrideComments', title: 't_hpgr_consumption_override.gf_override_need_desc', type: 'text', sortable: false }
    ],
    tcm: [
        { label: 'Risk Analyst', field: 'riskAnalystId', title: '', type: 'text', sortable: false },
        { label: 'Internal Rating (long)', field: 'updLmsclInternalRatgType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation ActvyType', field: 'assetAllocationActvyType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation SubScType', field: 'assetAllocationSubSecType', title: '', type: 'text', sortable: false }, 
        { label: 'Star Code', field: 'customerCounterpartiesCodesDesc', type: 'text', sortable: false },
        { label: 'Operation Mitigant', field: 'operationMitigantDesc', title: '', type: 'text', sortable: false },
        { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 't_hpgr_customers.g_upd_smscl_internal_ratg_type', type: 'text', sortable: false },
        { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 't_hpgr_customers.gf_current_rating_tool_date', type: 'date', sortable: false },
        { label: 'Expiration Rating Date', field: 'expirationRatingDate', title: 't_hpgr_customers.gf_current_rating_tool_date', type: 'date', sortable: false }
    ]
    ,
    tcmcustomer: [
        { label: 'Risk Analyst', field: 'riskAnalystId', title: '', type: 'text', sortable: false },
        { label: 'Internal Rating (long)', field: 'updLmsclInternalRatgType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation ActvyType', field: 'assetAllocationActvyType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation SubScType', field: 'assetAllocationSubSecType', title: '', type: 'text', sortable: false }, 
        { label: 'Star Code', field: 'customerCounterpartiesCodesDesc', type: 'text', sortable: false },
        { label: 'Operation Mitigant', field: 'operationMitigantDesc', title: '', type: 'text', sortable: false },
        { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 't_hpgr_customers.g_upd_smscl_internal_ratg_type', type: 'text', sortable: false },
        { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 't_hpgr_customers.gf_current_rating_tool_date', type: 'date', sortable: false }
    ]
    ,
    tcmotherlines: [
        { label: 'Risk Analyst', field: 'riskAnalystId', title: '', type: 'text', sortable: false },
        { label: 'Internal Rating (long)', field: 'updLmsclInternalRatgType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation ActvyType', field: 'assetAllocationActvyType', title: '', type: 'text', sortable: false },
        { label: 'Asset allocation SubScType', field: 'assetAllocationSubSecType', title: '', type: 'text', sortable: false }, 
        { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 't_hpgr_customers.g_upd_smscl_internal_ratg_type', type: 'text', sortable: false },
        { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 't_hpgr_customers.gf_current_rating_tool_date', type: 'date', sortable: false }, 
        { label: 'Star Code', field: 'customerCounterpartiesCodesDesc', type: 'text', sortable: false },
        { label: 'Operation Mitigant', field: 'operationMitigantDesc', title: '', type: 'text', sortable: false }
    ]
};

export function getColumns(tabName) {
    if (columns[tabName]) {
        return columns['common'].concat(columns[tabName]);
    } else {
        return columns['common'];
    }
}

export function getVisibleColumns(tabName) {
    if (tabName === 'tcm') {
        return [{ label: 'Client Name', field: 'name', type: 'text',title: 'displaytext', sortable: false }, 
            { label: 'Star Code', field: 'customerCounterpartiesCodesDesc', type: 'text',title: 'displaytext', sortable: false }, 
            { label: 'Mitigant Contracts', field: 'operationMitigantDesc', type: 'text',title: 'displaytext', sortable: false }, 
            { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 'displaytext', type: 'text', sortable: false },
            { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 'displaytext', type: 'date', sortable: false },
            { label: 'Expiration Rating Date', field: 'expirationRatingDate', title: 'displaytext', type: 'date', sortable: false },
                { label: "Derivatives Amount", field: 'amount', type: 'textinput', sortable: false, inselectcolumn: true}, 
                { label: "FD Amount", field: 'amountFD', type: 'textinput', sortable: false, inselectcolumn: true},
                { label: "DvP Amount", field: 'amountDVP', type: 'textinput', sortable: false, inselectcolumn: true},
                { label: "Currency", field: 'currency', type: 'isCurrencylabel', sortable: false, inselectcolumn: true},
                { label: "Term", field: 'term', type: 'combobox', sortable: false, 
                    options:[{label: "", value :""},{label: "0Y", value: "0Y"},{label: "1Y", value: "1Y"},{label: "2Y", value: "2Y"},
                        {label: "3Y", value: "3Y"},{label: "4Y", value: "4Y"},{label: "5Y", value: "5Y"},{label: "6Y", value: "6Y"}
                        ,{label: "7Y", value: "7Y"},{label: "8Y", value: "8Y"},{label: "9Y", value: "9Y"},{label: "10Y", value: "10Y"}
                        ,{label: "11Y", value: "11Y"},{label: "12Y", value: "12Y"}], inselectcolumn: true}
        ];
    } else if (tabName === 'tcmcustomer') {
        return [{ label: 'Client Name', field: 'name', type: 'text',title: 'displaytext', sortable: false }, 
            { label: 'Star Code', field: 'customerCounterpartiesCodesDesc', type: 'text',title: 'displaytext', sortable: false }, 
            { label: 'Mitigant Contracts', field: 'operationMitigantDesc', type: 'text',title: 'displaytext', sortable: false }, 
            { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 'displaytext', type: 'text', sortable: false },
            { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 'displaytext', type: 'date', sortable: false }]
    } else if (tabName === 'tcmotherlines') {
        return [{ label: 'Client Name', field: 'name', type: 'text',title: 'displaytext', sortable: false }, 
            { label: 'Internal<br/>Rating (short)', field: 'updSmsclInternalRatgType', title: 'displaytext', type: 'text', sortable: false },
            { label: 'Current Rating<br/>Tool Date', field: 'currentRatingToolDate', title: 'displaytext', type: 'date', sortable: false }]
    }else {
        return [{ label: 'Client Name', field: 'name', type: 'text', sortable: false }];
    }
}

export function  getGrillFields(field) {
    var grillFields = {
        'ucc': {'label': 'Undrawn Committed Contracts', 'field': 'committedContractsNonDisposedAmount'},
        'uuc': {'label': 'Undrawn Uncommitted Contracts', 'field': 'uncommittedContractsNonDisposedAmount'},
        'dcc': {'label': 'Drawn Committed Contracts', 'field': 'committedContractsDisposedAmount'},
        'duc': {'label': 'Drawn Uncommitted Contracts', 'field': 'uncommittedContractsDisposedAmount'},
        'aut': {'label': 'Pending Authorized', 'field': 'authorizedRiskAmount'},
        'una': {'label': 'Total Exposure', 'field': 'unavailableRiskAmount'},
        'dra': {'label': 'Draft', 'field': 'cNotSignedTrConsumptionAmount'}
    }
    return grillFields[field];
}