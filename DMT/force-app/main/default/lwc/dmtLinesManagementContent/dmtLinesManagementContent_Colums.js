export const columsLine = [
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
            target: "_blank",
            actionName: "goToRecord",
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
        label: "Name",
        sortable: "true",
        cellAttributes: {
            class: {
                fieldName: "buttonClass"
            }
        },
        hideDefaultActions: "true",
        fieldName: "NameURLLine"
    },
    {
        label: "Product",
        sortable: "true",
        cellAttributes: {
            style: "max-width:50px"
        },
        hideDefaultActions: "true",
        fieldName: "Product__c"
    },
    {
        typeAttributes: {
            textColor: {
                fieldName: "statusTextColor"
            },
            value: {
                fieldName: "Status__c"
            },
            iconVariant: {
                fieldName: "statusIconVariant"
            },
            iconColor: {
                fieldName: "statusIconColor"
            },
            iconPosition: "left",
            tooltip: {
                fieldName: "statusTooltip"
            },
            iconName: {
                fieldName: "statusIcon"
            }
        },
        type: "customIconText",
        sortable: "true",
        label: "Status",
        hideDefaultActions: "true"
    },
    {
        // typeAttributes: {
        //     checkedItem: {
        //         fieldName: "auto"
        //     },
        //     context: {
        //         fieldName: "Line_Id__c"
        //     },
        //     fixedWidth: "50",
        //     aviableItem: {
        //         fieldName: "multiEditable"
        //     }
        // },
        type: "boolean",
        label: "Auto",
        cellAttributes: {
            style: "text-align: center;padding:0"
        },
        hideDefaultActions: "true",
        fieldName: "auto"
    },
    {
        sortable: "true",
        label: "Entific",
        hideDefaultActions: "true",
        fieldName: "Booking_Geography__c"
    },
    {
        label: "Start Date",
        sortable: "true",
        hideDefaultActions: "true",
        fieldName: "Start_Date__c"
    },
    {
        label: "End Date",
        sortable: "true",
        hideDefaultActions: "true",
        fieldName: "End_Date__c"
    },
    {
        label: "Client Type",
        sortable: "true",
        hideDefaultActions: "true",
        fieldName: "Client_Type__c"
    },
    {
        typeAttributes: {
            class: "notLinkAccess",
            label: {
                fieldName: "Line_Details__c"
            },
            tooltip: {
                fieldName: "Line_Details__c"
            },
            variant: "base"
        },
        type: "text",
        label: "Line Details",
        cellAttributes: {
            class: {
                fieldName: "buttonClass2"
            }
        },
        hideDefaultActions: "true",
        fieldName: "Line_Details__c"
    }
];