export const columnsOpp = [
    {
        type: "button-icon",
        typeAttributes: {
            iconName: "utility:sync",
            name: "Renew",
            title: "Renew",
            variant: "brand-outlined", // opcional (brand, bare, border, etc.)
            alternativeText: "Renew",
            disabled: {
                fieldName: "disableRenew"
            }
        },
        label: "Renew",
        cellAttributes: {
            alignment: "center"
        },
        hideDefaultActions: "true"
    },
    {
        typeAttributes: {
            actionName: "goToRecord",
            target: "_blank",
            label: {
                fieldName: "Name"
            },
            disabled: {
                fieldName: "isDisabled"
            },
            tooltip: {
                fieldName: "Name"
            },
            variant: "base"
        },
        type: "url",
        sortable: "true",
        label: "Name",
        cellAttributes: {
            class: {
                fieldName: "buttonClass"
            }
        },
        hideDefaultActions: "true",
        fieldName: "NameURL"
    },
    {
        label: "Type",
        sortable: "true",
        hideDefaultActions: "true",
        fieldName: "RecordType.Name"
    },
    {
        typeAttributes: {
            value: {
                fieldName: "StageName"
            },
            textColor: {
                fieldName: "statusTextColor"
            },
            iconVariant: {
                fieldName: "statusIconVariant"
            },
            iconColor: {
                fieldName: "statusIconColor"
            },
            tooltip: {
                fieldName: "statusTooltip"
            },
            iconPosition: "left",
            iconName: {
                fieldName: "statusIcon"
            }
        },
        type: "customIconText",
        label: "Status",
        sortable: "true",
        hideDefaultActions: "true",
        fieldName: "StageName"
    },
    {
        sortable: "true",
        label: "Entific",
        hideDefaultActions: "true",
        fieldName: "Entific__c"
    },
    {
        label: "Start Date",
        sortable: "true",
        hideDefaultActions: "true",
        fieldName: "DMT_DATE_Initial_Date__c"
    },
    {
        sortable: "true",
        label: "End Date",
        hideDefaultActions: "true",
        fieldName: "DMT_DATE_Maturity_Date__c"
    },
    {
        sortable: "true",
        label: "Client Type",
        hideDefaultActions: "true",
        fieldName: "DMT_Client_Type__c"
    },
    {
        type: "text",
        label: "Opportunity Details",
        hideDefaultActions: "true",
        fieldName: "Opportunity_Details__c",
        wrapTextMaxLines: "7"
    }
];