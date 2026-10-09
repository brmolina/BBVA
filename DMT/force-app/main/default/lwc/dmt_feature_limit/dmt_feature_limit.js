import { LightningElement, api, wire, track } from 'lwc';
import passportModal from 'c/dmt_passport_modal';
import { getRecords,getFieldValue } from 'lightning/uiRecordApi';

import PRODUCT_NAME_FIELD from '@salesforce/schema/OpportunityLineItem.DES_Product_Name__c';
import MITIGANT_NAME_FIELD from '@salesforce/schema/DMT_Opportunity_Mitigant__c.Name';

import OPPORTUNITY_LINE_ITEM_OBJECT from '@salesforce/schema/OpportunityLineItem';
import OPPORTUNITY_MITIGANT_OBJECT from '@salesforce/schema/DMT_Opportunity_Mitigant__c';
import getMitigantsAndOppLineItemsByField from '@salesforce/apex/DMT_feature_limitController.getMitigantsAndOppLineItemsByField';

export default class Dmt_feature_limit extends LightningElement {

    _feature;
    _isbig;
    @api oppId;
    @track isExpanded = false;
    @track haveProducts = false;
    @track opportunityLineItemIds = [];
    @track opportunityMitigantItemIds = [];
    @track processedProducts = [];

    wiredResult;

    @api
    get feature() {
        return this._feature;
    }
    set feature(value) {
        if (!value) return;

        const tempValue = JSON.parse(JSON.stringify(value));

        const products = tempValue.products || [];
        this.haveProducts = products.length > 0;

        this.opportunityLineItemIds = products.map(product => product.productId).filter(id => id);
        this.opportunityMitigantItemIds = products.flatMap(product => product.mitigants || []).map(mitigant => mitigant.mitigantId).filter(id => id);
        this._feature = tempValue;
    }

    @api
    get isbig() {
        return this._isbig;
    }
    set isbig(value) {
        this._isbig = value;
    }

    get rowClass() {
        return 'slds-hint-parent' + (this._feature?.isFaded ? ' faded-row' : '');
    }

    get wireConfiguration() {
        return  [
            {
                recordIds: this.opportunityLineItemIds,
                fields: [PRODUCT_NAME_FIELD]
            },
            {
                recordIds: this.opportunityMitigantItemIds,
                fields: [MITIGANT_NAME_FIELD]
            }
        ];
    }

    /*@wire(getRecords, { records: '$wireConfiguration' })
    wiredRecords(result) {
        this.wiredResult = result;
        const { error, data } = result;

        if (data) {
            this.processData(data);
        } else if (error) {
            this.notifyParentError(error);
        }
    }*/
    @wire(getMitigantsAndOppLineItemsByField, {
        oppId: '$oppId',
        productsId: '$opportunityLineItemIds', 
        mitigantsId: '$opportunityMitigantItemIds'
    })
    wiredRecords(result) {

        console.log('wiredRecords oppId: ', this.oppId);
        this.wiredResult = result;
        const { error, data } = result;
        console.log('wiredRecords data: ', data);
        console.log('wiredRecords error: ', error);
        if (data) {
            this.processData(data);
        } else if (error) {
            this.notifyParentError(error);
        }
    }
    processData(data) {

        const productMap = {};
        const mitigantMap = {};

        data?.results?.forEach(item => {

            if (item?.statusCode === 200 && item?.result) {

                const record = item.result;
                const apiName = record.apiName;
                if (apiName === OPPORTUNITY_LINE_ITEM_OBJECT.objectApiName) {
                    productMap[record.gf_group_priority_opportunity_id__c] = getFieldValue(record, PRODUCT_NAME_FIELD);
                }
                else if (apiName === OPPORTUNITY_MITIGANT_OBJECT.objectApiName) {
                    mitigantMap[record.id] = getFieldValue(record, MITIGANT_NAME_FIELD);
                }
            }
        });

        if (this._feature && this._feature.products) {

            this.processedProducts = this._feature.products.map(product => {

                const mitigants = (product.mitigants || []).map(mitigant => {
                    return {
                        ...mitigant,
                        displayName: mitigant.customerId || `Mitigant (${mitigant.mitigantId})`
                    };
                });
                return {
                    ...product,
                    displayName: productMap[product.productId]?.value || `Product (${product.productId})`,
                    mitigants: mitigants,
                    hasMitigants: mitigants.length > 0
                };
            });
        }
    }

    async openModal(event) {
        const idEvent = event.target.dataset.id;

        if (!this.shouldOpenModal(idEvent)) {
            return;
        }

        let conditions = [];
        let currencies = [];
        let labels = [];
        let limitLights = [];
        let sections = ["Drawn", "Undrawn committed", "Undrawn uncommitted", "Pending authorized", "New Opportunity"];
        let targets = [];

        let dataDraw = [];
        let dataUndrawnCommitted = [];
        let dataUndrawnUncommitted = [];
        let dataPendingAuthorized = [];
        let dataNewOpportunity = [];

        let noShowInfo = false;
        const { consumptionLimits, mitigantCurrency } = this.searchCorrectConsuptionLimit(idEvent);

        consumptionLimits?.forEach(limits => {
            if (limits?.stateName !== undefined) {
                conditions.push(limits.conditionDesc);
                currencies.push(limits.currencyId);
                labels.push(limits.limitDesc);
                limitLights.push(limits.stateName?.toUpperCase());
                targets.push(parseFloat(limits.amount?.currentApprovedAmount || 0));

                dataDraw.push(parseFloat(limits.amount?.cmtContDisposedAmount || 0) + parseFloat(limits.amount?.uncmtContDisposedAmount || 0));
                dataUndrawnCommitted.push(parseFloat(limits.amount?.cmtContNonDspsAmount || 0));
                dataUndrawnUncommitted.push(parseFloat(limits.amount?.uncmtContNonDspsAmount || 0));
                dataPendingAuthorized.push(parseFloat(limits.amount?.authorizedRiskAmount || 0));
                dataNewOpportunity.push(parseFloat(limits.amount?.notSignedTrConsumptionAmount || 0));
            }
        });

        let datasets = [
            {"backgroundColor": "rgba(4, 50, 99, 1)", "data": dataDraw, "hoverBackgroundColor": "rgba(4, 50, 99, 1)","label": "Drawn"},
            {"backgroundColor": "rgba(20, 100, 165, 1)", "data": dataUndrawnCommitted, "hoverBackgroundColor": "rgba(20, 100, 165, 1)","label": "Undrawn committed"},
            {"backgroundColor": "rgba(36, 150, 234, 1)", "data": dataUndrawnUncommitted, "hoverBackgroundColor": "rgba(36, 150, 234, 1)","label": "Undrawn uncommitted"},
            {"backgroundColor": "rgba(45, 204, 205, 1)", "data": dataPendingAuthorized, "hoverBackgroundColor": "rgba(45, 204, 205, 1)","label": "Pending authorized"},
            {"backgroundColor": "rgba(189, 189, 189, 1)", "data": dataNewOpportunity, "hoverBackgroundColor": "rgba(189, 189, 189, 1)","label": "New Opportunity"}
        ];

        let limits = {
            conditions: conditions,
            currencies: currencies,
            datasets: datasets,
            labels: labels,
            limitLights: limitLights,
            originCurrency: mitigantCurrency || currencies[0],
            sections: sections,
            targetColor: 'red',
            targets: targets
        };

        if (!consumptionLimits || dataDraw.length === 0) {
            noShowInfo = true;
        }
        

        try {
            console.log('Opening modal with limits:', this.oppId);
            await passportModal.open({
                noShowInfo: noShowInfo,
                graphicModal: true,
                limits: limits,
                featureName: this.feature?.name,
                featureLight: this.feature?.stateName?.toLowerCase(),
                validations: this.feature?.validations,
                errorModal: false,
                profitability: null,
                showProfitabilityChart: false,
                opportunityId: this.oppId,
                currencyId: mitigantCurrency || null
            });

            this.isExpanded = false;
        } catch (error) {
            this.notifyParentError(error);
        }
    }

    shouldOpenModal(idEvent) {
        const selectedProduct = this.feature?.products?.find(product => product.productId == idEvent);

        return selectedProduct ? selectedProduct.stateName?.toLowerCase() !== 'gray' : true;
    }

    searchCorrectConsuptionLimit(idEvent) {
        let consumptionLimits = [];
        let mitigantCurrency = null;

        if (this.feature.idProccess == idEvent) {
            consumptionLimits = this.feature?.consumptionLimits;
        }

        this.feature.products?.forEach(product => {
            if (product.productId == idEvent) {
                consumptionLimits = product.consumptionLimits;
            }

            product.mitigants?.forEach(mitigant => {
                if (mitigant.mitigantId == idEvent) {
                    consumptionLimits = mitigant.consumptionLimits;
                    mitigantCurrency = mitigant.mitigantCurrency || null;
                }
            });
        });

        return { consumptionLimits, mitigantCurrency };
    }

    expandedControlEvent(event) {
        this.isExpanded = !this.isExpanded;
    }

    notifyParentError(errorMessage) {

        const errorEvent = new CustomEvent('notifyparenterror', {
            detail: { message: errorMessage }
        });

        this.dispatchEvent(errorEvent);
    }

}