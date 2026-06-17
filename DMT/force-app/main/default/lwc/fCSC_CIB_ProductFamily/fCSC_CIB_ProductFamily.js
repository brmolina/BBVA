import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as CONSTANTS from './constants';
import getCIBTaxonomyValues from '@salesforce/apex/FCSC_Request_CIB_ProductFamily_Ctrl.getCIBTaxonomyValues';
import getNextLevelValues from '@salesforce/apex/FCSC_Request_CIB_ProductFamily_Ctrl.getNextLevelValues';
import updateProductCommitment from '@salesforce/apex/FCSC_Request_CIB_ProductFamily_Ctrl.updateProductCommitment';

export default class FCSC_CIB_ProductFamily extends LightningElement {
    @api recordId;

    familyValue = null;
    productValue = null;
    subProductN1Value = null;
    subProductN2Value = null;

    cibfamily = [];
    cibProducts = [];
    cibSubproductsN1 = [];
    cibSubproductsN2 = [];

    currentCatalog = null;
    catalogLevel2 = null;   
    catalogLevel3 = null;

    isEditMode = false;
    rawRecords = [];
    latestRequestToken = 0;

    navigationRequestToken = 0;

    @wire(getCIBTaxonomyValues)
    wiredCatalogValues({ error, data }) {
        if (data) {
            this.rawRecords = Array.isArray(data) ? data : [];
            return;
        }
        if (error) {
            console.error(CONSTANTS.MESSAGES.FETCH_ERROR);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: CONSTANTS.COMMITMENT_FIELDS })
    wiredCommitment({ error, data }) {
        if (error) {
            console.error(CONSTANTS.MESSAGES.LOG_FETCH_COMMITMENT_ERROR, error);
            return;
        }
        if (!data) return;
        this.preview(data);
    }

    preview(recordData) {
        const getValue = (apiName) => recordData.fields?.[apiName]?.value ?? null;
        const asOption = (v) => (v ? [{ label: String(v), value: String(v) }] : []);

        const familyField  = getValue(CONSTANTS.COMMITMENT_FIELDS_DEF.API.FAMILY);
        const productField = getValue(CONSTANTS.COMMITMENT_FIELDS_DEF.API.PRODUCT);
        const n1Field      = getValue(CONSTANTS.COMMITMENT_FIELDS_DEF.API.SUBPRODUCT_N1);
        const n2Field      = getValue(CONSTANTS.COMMITMENT_FIELDS_DEF.API.SUBPRODUCT_N2);
        
        this.cibfamily = asOption(familyField);
        this.cibProducts = asOption(productField);
        this.cibSubproductsN1 = asOption(n1Field);
        this.cibSubproductsN2 = asOption(n2Field);

        this.productValue = productField ? String(productField) : null;
        this.subProductN1Value = n1Field ? String(n1Field) : null;
        this.subProductN2Value = n2Field ? String(n2Field) : null;
        this.familyValue = familyField ? String(familyField) : null;

    }

    buildFamilyFromRaw() {
        const level1Records = this.rawRecords.filter((r) => String(r.DMT_Catalog__c) === CONSTANTS.CATALOG.FAMILY);
        this.cibfamily = this.mapToOptions(level1Records);
        this.currentCatalog = level1Records.length ? level1Records[0].DMT_Catalog__c : null;
    }

    mapToOptions(records) {
        return (Array.isArray(records) ? records : [])
            .map((r) => ({
                label: r?.DMT_Name__c ?? r?.label ?? '',
                value: r?.DMT_Value__c ?? r?.value ?? ''
            }))
            .filter((o) => o.value)
            .sort((a, b) => (a.label || '').localeCompare(b.label || ''));
    }

    familyHandler(event) {
        this.handleSelectionChange({
            selectedValue: event.detail.value,
            valueProp: CONSTANTS.LEVEL_PROPERTIES.familyValue,
            resetLevel: CONSTANTS.RELATIONSHIP.L1,
            catalog: this.currentCatalog,
            toLevel: CONSTANTS.RELATIONSHIP.L1
        });
    }

    productHandler(event) {
        this.handleSelectionChange({
            selectedValue: event.detail.value,
            valueProp: CONSTANTS.LEVEL_PROPERTIES.productValue,
            resetLevel: CONSTANTS.RELATIONSHIP.L2,
            catalog: this.catalogLevel2,
            toLevel: CONSTANTS.RELATIONSHIP.L2
        });
    }

    subProductN1Handler(event) {
        this.handleSelectionChange({
            selectedValue: event.detail.value,
            valueProp: CONSTANTS.LEVEL_PROPERTIES.subProductN1Value,
            resetLevel: CONSTANTS.RELATIONSHIP.L3,
            catalog: this.catalogLevel3,
            toLevel: CONSTANTS.RELATIONSHIP.L3
        });
    }

    subProductN2Handler(event) {
        this.subProductN2Value = event.detail.value;
    }

    updateHandler() {
        this.clearHandler();
        this.buildFamilyFromRaw(); 
        this.isEditMode = true;
    }

    clearHandler() {
        this.navigationRequestToken++;

        this.isEditMode = false;
        this.resetAll();

        if (this.rawRecords?.length) {
            this.buildFamilyFromRaw();
        }
    }

    resolveDisplayedLabel(options, selectedValue) {
        if (!selectedValue || !Array.isArray(options)) return null;
        const found = options.find((o) => String(o?.value ?? '') === String(selectedValue));
        return found?.label ?? found?.name ?? null;
    }

    buildUpdatePayload() {
        return {
            recordId: this.recordId,
            family: this.resolveDisplayedLabel(this.cibfamily, this.familyValue),
            product: this.resolveDisplayedLabel(this.cibProducts, this.productValue),
            subProductN1: this.resolveDisplayedLabel(this.cibSubproductsN1, this.subProductN1Value),
            subProductN2: this.resolveDisplayedLabel(this.cibSubproductsN2, this.subProductN2Value)
        };
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    notifyProductFamilySaved(payload) {
        this.dispatchEvent(
            new CustomEvent('productfamilysaved', {
                detail: { ...payload },
                bubbles: true,
                composed: true
            })
        );
    }

    async saveHandler() {
        if (!this.recordId) {
            console.error(CONSTANTS.MESSAGES.ID_REQUIRED_ERROR);
            return;
        }

        const payload = this.buildUpdatePayload();

        try {
            await updateProductCommitment(payload);
            this.isEditMode = false;

            this.showToast(
                CONSTANTS.MESSAGES.SAVED,
                CONSTANTS.MESSAGES.UPDATE_SUCCESS,
                CONSTANTS.MESSAGES.SUCCESS
            );

            this.notifyProductFamilySaved(payload);
        } catch (e) {
            console.error(CONSTANTS.MESSAGES.LOG_SAVE_ERROR, e);
            this.showToast(
                CONSTANTS.MESSAGES.ERROR,
                CONSTANTS.MESSAGES.UPDATE_ERROR,
                CONSTANTS.MESSAGES.ERROR
            );
        }
    }

    get isReadOnly() {
        return !this.isEditMode;
    }

    resetAll() {
        this.familyValue = null;
        this.productValue = null;
        this.subProductN1Value = null;
        this.subProductN2Value = null;

        this.cibfamily = [];
        this.cibProducts = [];
        this.cibSubproductsN1 = [];
        this.cibSubproductsN2 = [];

        this.currentCatalog = null;
        this.catalogLevel2 = null;
        this.catalogLevel3 = null;
    }

    resetFromLevel(level) {
        if (level === CONSTANTS.RELATIONSHIP.L1) {
            // Reset L2 + L3
            this.productValue = null;
            this.catalogLevel2 = null;
            this.cibProducts = [];

            this.subProductN1Value = null;
            this.catalogLevel3 = null;
            this.cibSubproductsN1 = [];

            this.subProductN2Value = null;
            this.cibSubproductsN2 = [];
            return;
        }

        if (level === CONSTANTS.RELATIONSHIP.L2) {
            // Reset L3
            this.subProductN1Value = null;
            this.catalogLevel3 = null;
            this.cibSubproductsN1 = [];

            this.subProductN2Value = null;
            this.cibSubproductsN2 = [];
            return;
        }

        if (level === CONSTANTS.RELATIONSHIP.L3) {
            this.subProductN2Value = null;
            this.cibSubproductsN2 = [];
        }
    }

    async loadNextLevel({ catalog, fromValue, toLevel }) {
        const relationshipId = this.getRelationshipIdForLevel(toLevel);
        if (!relationshipId) return;

        const requestToken = ++this.navigationRequestToken;
        try {
            const result = await getNextLevelValues({
                currentCatalog: catalog,
                currentValue: fromValue,
                relationshipId,
                cacheBreaker: Date.now()
            });

            if (requestToken !== this.navigationRequestToken) return;

            const rows = Array.isArray(result) ? result : [];
            const nextCatalog = rows.length ? rows[0]?.nextCatalog ?? null : null;
            this.applyNextLevelResult(toLevel, rows, nextCatalog);
        } catch (e) {
            console.error(CONSTANTS.MESSAGES.NEXT_LEVEL_ERROR, e);
        }
    }

    applyNextLevelResult(toLevel, rows, nextCatalog) {
        const options = this.mapToOptions(rows);

        if (toLevel === CONSTANTS.RELATIONSHIP.L1) {
            this.cibProducts = options;
            this.catalogLevel2 = nextCatalog;
            return;
        }
        if (toLevel === CONSTANTS.RELATIONSHIP.L2) {
            this.cibSubproductsN1 = options;
            this.catalogLevel3 = nextCatalog;
            return;
        }
        if (toLevel === CONSTANTS.RELATIONSHIP.L3) {
            this.cibSubproductsN2 = options;
        }
    }

    getRelationshipIdForLevel(level) {
        const key =
            level === CONSTANTS.RELATIONSHIP.L1 ? CONSTANTS.RELATIONSHIP.LEVEL_1 :
            level === CONSTANTS.RELATIONSHIP.L2 ? CONSTANTS.RELATIONSHIP.LEVEL_2 :
            level === CONSTANTS.RELATIONSHIP.L3 ? CONSTANTS.RELATIONSHIP.LEVEL_3 :
            String(level);

        return CONSTANTS.RELATIONSHIP[key] ?? null;
    }

    handleSelectionChange({ selectedValue, valueProp, resetLevel, catalog, toLevel }) {
        this[valueProp] = selectedValue;
        this.resetFromLevel(resetLevel);

        if (selectedValue && catalog) {
            this.loadNextLevel({
                catalog,
                fromValue: selectedValue,
                toLevel
            });
        }
    }
}