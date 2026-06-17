import { LightningElement, wire, track} from 'lwc';
import { getRecord, getRecordUi, getFieldValue, createRecord, deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import hasLineGodPermission from '@salesforce/customPermission/DMT_Line_God';

import LINE_ID_FIELD from '@salesforce/schema/DMT_Line__c.Id';
import LINE_STATE_FIELD from'@salesforce/schema/DMT_Line__c.Status__c';
import RECORDTYPE_FIELD from '@salesforce/schema/DMT_Line__c.DMT_RecordTypeName__c';
import OPPORTUNITY_ID_FIELD from '@salesforce/schema/Opportunity.Id';
import OPPORTUNITY_RECORDTYPE_FIELD from '@salesforce/schema/Opportunity.RecordType.Name';
import OPPORTUNITY_STATE_FIELD from '@salesforce/schema/Opportunity.StageName';
import DMT_SELECTED_FEATURE_OBJECT from '@salesforce/schema/DMT_Selected_Features__c';
import SELECTED_FEATURE_LINE_FIELD from '@salesforce/schema/DMT_Selected_Features__c.Line__c';
import SELECTED_FEATURE_OPP_FIELD from '@salesforce/schema/DMT_Selected_Features__c.Opportunity__c';
import SELECTED_FEATURE_NAME_FIELD from '@salesforce/schema/DMT_Selected_Features__c.Name';
import SELECTED_FEATURE_FEATURES_FIELD from '@salesforce/schema/DMT_Selected_Features__c.Feature__c';
import FEATURE_NAME_DESC_FIELD from '@salesforce/schema/DMT_Feature__c.gf_feature_name_desc__c';
import FEATURE_SANCTION_TYPE_FIELD from '@salesforce/schema/DMT_Feature__c.gf_passport_sanction_feature_type_desc__c';
import FEATURE_CODE_VALUE_FIELD from '@salesforce/schema/DMT_Feature__c.gf_code_value_id__c';
import FEATURE_GLOBAL_ID_NUMBER_FIELD from '@salesforce/schema/DMT_Feature__c.gf_global_feature_id_number__c';
import PASSPORT_ID_FIELD from '@salesforce/schema/Passport__c.Id';
import OBSOLETED_FIELD from "@salesforce/schema/Passport__c.DMT_Is_Obsoleted_Passport_Save__c";
import ACTIVE_FEATURE_FIELD from "@salesforce/schema/DMT_Feature__c.gf_active_feature_ind_type__c";

import checkEditPermission from '@salesforce/apex/DMT_LineController.checkEditPermission';
import checkEditPermissionOpp from '@salesforce/apex/DMT_LineController.checkEditPermissionOpp';
import loadFeatures from '@salesforce/apex/DMT_FeaturesController.loadFeatures';
import getPassportIdFromLineOrOpportunity from '@salesforce/apex/DMT_FeaturesController.getPassportIdFromLineOrOpportunity';
import getObligatoryFeatures from '@salesforce/apex/DMT_FeaturesController.getObligatoryFeatures';
import dataTableWithoutTruncate from '@salesforce/resourceUrl/DataTableTruncateCss';
import labelFeatures from '@salesforce/label/c.DMT_Features';

const OBJECT_NAME_LINE= 'DMT_Line__c';
const OBJECT_NAME_OPPORTUNITY = 'Opportunity';
const FEATURE_DEAL_TYPE_OTHER = 'OTHERLIN';
const FEATURE_DEAL_TYPE_TRS = 'SETTLTRS';

const RECORD_TYPE_NAME_TREASURY_LINE = 'Treasury Line';
const RECORD_TYPE_NAME_OTHER_LINE = 'Line';
const RECORD_STATUS_DRAFT = 'Draft';
const RECORD_STATUS_PROPOSAL = 'Proposal';
const TITLE_WARNING_PASSPORT = 'Warning';


const PASSPORT_CHANGES = 'There have been changes in the passport.';
const ERROR_CODE = 'ENTITY_IS_DELETED';
const ERROR_TITLE_DELETE = 'You encountered some errors when trying to delete this feature';
const ERROR_TITLE_CREATE = 'You encountered some errors when trying to create this feature';
const ERROR_CREATE_FEATURE = 'Error creating feature:';
const ERROR_DELETE_FEATURE = 'Error deleting feature:';
const ERROR_RECORD_INFO = 'Error retrieving record info:';
const ERROR_EDITION_COLUMN = 'Error determining edition:';
const ERROR_LOADING_FEATURES = 'Error loading features:';
const ERROR_PASSPORT_ID = 'Error retrieving Passport ID:';
const ERROR_FEATURE_NOT_FOUND = 'Feature not found in the list';
const ERROR_PASSPORT_OBSOLETED = 'Error marking passport as obsoleted:';
const ERROR_FEATURE_ID = 'Feature ID is not available:';
const ERROR_LOADING_FLOW = 'Error in the loading flow';
const WARN_SELECTED_FEATURE_ID = 'No selected feature Id to delete';
const ERROR_OBLIGATORY_FEATURES  = 'Error loading obligatory features:';

export default class Dmt_features_selected extends LightningElement {

    recordId;
    passportId;
    lineOrOpportunityId;
    records = [];
    label = {labelFeatures};
    @track features = [];
    @track selectedFeatureIds = [];
    @track selectedFeatures = [];
    @track wiredFields = [];
    @track labelFeatures = this.label.labelFeatures;
    @track wiredSelectedFeaturesResult;
    @track obligatoryFeatureCodeIds = new Set();
    isLoading = true;
    isEditable = false;
    wiredLinesResult;
    recordTypeName;
    objectApiName;
    error;
    isDataLoaded = false;

    columns = [
        { label: 'Name',  fieldName: FEATURE_NAME_DESC_FIELD.fieldApiName, hideDefaultActions:true },
        { label: 'Sanction Feature Type',  fieldName: FEATURE_SANCTION_TYPE_FIELD.fieldApiName, hideDefaultActions:true },
        { label: 'Features Selected' , fieldName: 'isSelected', type:'customselectRow',cellAttributes:{style: 'text-align: center;'}, hideDefaultActions:true,
        typeAttributes: {
            aviableItem: {fieldName: 'isEditable'}, checkedItem: { fieldName: 'isSelected' }, fieldName: 'isSelected', context: { fieldName: 'Id' }
        }}
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.recordId || currentPageReference.state?.c__recordId || currentPageReference.attributes?.recordId;
        }
    }

    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: ['Full'], modes: ['View'] })
    wiredRecordUi({ error, data }) {
        if (data) {
            const record = data.records[this.recordId];
            this.objectApiName = data.records[this.recordId].apiName;
            if (this.objectApiName === OBJECT_NAME_LINE) {
                this.wiredFields = [LINE_ID_FIELD, RECORDTYPE_FIELD, LINE_STATE_FIELD];
            } else if (this.objectApiName === OBJECT_NAME_OPPORTUNITY) {
                this.wiredFields = [OPPORTUNITY_ID_FIELD, OPPORTUNITY_RECORDTYPE_FIELD, OPPORTUNITY_STATE_FIELD];
            }
        } else if (error) {
            console.error(ERROR_RECORD_INFO, error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$wiredFields' })
    wiredRecord(result) {
        const { error, data } = result;

        if (data) {
            this.wiredLinesResult = data;
            if (this.objectApiName === OBJECT_NAME_LINE) {
                this.recordTypeName = getFieldValue(data, RECORDTYPE_FIELD);
                this.lineOrOpportunityId = getFieldValue(data, LINE_ID_FIELD);
                this.lineStatus = getFieldValue(data, LINE_STATE_FIELD);

                this.loadFeaturesFlow();

            } else if (this.objectApiName == OBJECT_NAME_OPPORTUNITY) {
                this.recordTypeName = getFieldValue(data, OPPORTUNITY_RECORDTYPE_FIELD);
                this.lineOrOpportunityId = getFieldValue(data, OPPORTUNITY_ID_FIELD);
                this.oppStatus = getFieldValue(data, OPPORTUNITY_STATE_FIELD);

                this.loadFeaturesFlow();
            }
        } else if (error) {
            console.error(ERROR_RECORD_INFO, error);
        }
    }
    
    async loadFeaturesFlow() {
        this.isLoading = true;
        this.isDataLoaded = false;

        try {
            await this.getPassportId(this.lineOrOpportunityId);
            await this.loadObligatoryFeatures(this.lineOrOpportunityId);
            await this.editablefeatures();
            await this.handleLoadFeatures();
        } catch (error) {
            console.error(ERROR_LOADING_FLOW, error);
        } finally {
            this.isLoading = false;
            this.isDataLoaded = true;
        }
    }

    

    async editablefeatures() {

        let isInEditableStatus = false;

        if (this.objectApiName === OBJECT_NAME_LINE) {
            isInEditableStatus = (this.lineStatus === RECORD_STATUS_DRAFT || this.lineStatus === RECORD_STATUS_PROPOSAL);
        }

        if (this.objectApiName === OBJECT_NAME_OPPORTUNITY) {
            isInEditableStatus = (this.oppStatus === RECORD_STATUS_DRAFT || this.oppStatus === RECORD_STATUS_PROPOSAL);
        }

        if (!isInEditableStatus) {
            this.isEditable = false;
            return;
        }

        if (hasLineGodPermission) {
            this.isEditable = true;
            return;
        }

        try {
            const result = this.objectApiName === OBJECT_NAME_LINE
                ? await checkEditPermission({ recordId: this.recordId })
                : await checkEditPermissionOpp({ oppId: this.recordId });

            const { isAdmin, accessLevel_edit } = result;
            this.isEditable = (isAdmin || accessLevel_edit);
        } catch (error) {
            console.error('Error checking edit permission', error);
            this.isEditable = false;
        }

        this.features = this.features.map(f => ({
            ...f,
            isEditable: this.isEditable
        }));
    }

   async handleLoadFeatures() {
        let featureType = '';
        if(this.recordTypeName == RECORD_TYPE_NAME_OTHER_LINE){
            featureType = FEATURE_DEAL_TYPE_OTHER;
        } else if (this.recordTypeName == RECORD_TYPE_NAME_TREASURY_LINE){
            featureType = FEATURE_DEAL_TYPE_TRS;
        }

        loadFeatures({recordId: this.recordId, featureType: featureType})
        .then(result => {
                const featureAux = result
                .filter(feature => feature['gf_active_feature_ind_type__c'] === 'Y')
                .filter(feature => feature['g_entific_id__c'] === 'HO')

                .map(feature => {
                const isObligatory = this.obligatoryFeatureCodeIds?.has(feature[FEATURE_GLOBAL_ID_NUMBER_FIELD.fieldApiName]);
                return {
                    ...feature,
                    isSelected: feature.isSelected,
                    isEditable: this.isEditable
                };
            });
            this.features = [...featureAux];
            this.wiredSelectedFeaturesResult = this.features.filter(feature => feature.isSelected);

            // for (const feature of this.features) {
            //     const isObligatory = this.obligatoryFeatureCodeIds?.has(feature[FEATURE_GLOBAL_ID_NUMBER_FIELD.fieldApiName]);
            //     if (isObligatory && !feature.selectedFeatureId) {
            //         continue;
            //     } else if (isObligatory && feature.selectedFeatureId) {
            //         this.deleteSelectedFeature(feature);
            //     }
            // }
            this.isDataLoaded = true;
        })
        .catch((error) => {
            console.error(ERROR_LOADING_FEATURES, error);
            this.error = error;
            this.features = [];
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    getPassportId(lineOrOpportunityId) {
        getPassportIdFromLineOrOpportunity({ lineOrOpportunityId: lineOrOpportunityId })
            .then(passportIdResult => {
                this.passportId = passportIdResult;
            })
            .catch(error => {
                console.error(ERROR_PASSPORT_ID, error);
            });
    }

    async loadObligatoryFeatures(lineOrOpportunityId) {
        try {
            const obligatoryFeatures = await getObligatoryFeatures({lineOrOpportunityId});
            this.obligatoryFeatureCodeIds = new Set(obligatoryFeatures.map(feature => feature.id));
        } catch (error) {
            console.error(ERROR_OBLIGATORY_FEATURES, error);
            this.obligatoryFeatureCodeIds = new Set();
        }
    }

    checkDataAndApplyFilter() {
        if (this.recordTypeName && this.features.length > 0) {
            this.applyFilter();
        }
    }

    handleCheckboxChange(event) {
        this.isLoading = true;

        const { context, value } = event.detail.data;
        const featureIndex = this.features.findIndex(feature => feature.Id === context);
      
        if (!this.features[featureIndex].isEditable) {
            this.isLoading = false;
            return;
        }

        if (featureIndex !== -1) {
            this.features[featureIndex].isSelected = value;
            this.features = [...this.features];
        } else {
            console.error(ERROR_FEATURE_NOT_FOUND);
            this.isLoading = false;
            return;
        }

        const selectedFeatureIds = this.features
            .filter(feature => feature.isSelected)
            .map(feature => feature.Id);

        this.dispatchEvent(
            new ShowToastEvent({
                title: TITLE_WARNING_PASSPORT,
                message: PASSPORT_CHANGES,
                variant: 'warning'
            })
        );

        this.markPassportAsObsoleted();

        if (this.features[featureIndex].isSelected) {
            this.createSelectedFeature(this.features[featureIndex]);
        } else {
            this.deleteSelectedFeature(this.features[featureIndex]);
        }
    }

    markPassportAsObsoleted() {
        const fields = {};
        fields[PASSPORT_ID_FIELD.fieldApiName] = this.passportId;
        fields[OBSOLETED_FIELD.fieldApiName] = true;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
            })
            .catch(error => {
                console.error(ERROR_PASSPORT_OBSOLETED, error);
            });
    }

    async createSelectedFeature(feature){

        if (!feature.Id) {
            console.error(ERROR_FEATURE_ID, feature);
            this.isLoading = false;
            return;
        }

        this.isLoading = true;

        const selectedFeatureRecord = {
            apiName: DMT_SELECTED_FEATURE_OBJECT.objectApiName,
            fields: {
                [SELECTED_FEATURE_NAME_FIELD.fieldApiName]: feature.gf_feature_name_desc__c,
                [SELECTED_FEATURE_FEATURES_FIELD.fieldApiName]: feature.Id,
                
            } 
        };

        if (this.objectApiName === OBJECT_NAME_LINE) {
            selectedFeatureRecord.fields[SELECTED_FEATURE_LINE_FIELD.fieldApiName] = this.recordId;
        } else if (this.objectApiName === OBJECT_NAME_OPPORTUNITY) {
            selectedFeatureRecord.fields[SELECTED_FEATURE_OPP_FIELD.fieldApiName] = this.recordId;
        }

        createRecord(selectedFeatureRecord)
            .then(createdRecord => {
                this.handleLoadFeatures();
            })
            .catch(error => {
                console.error(ERROR_CREATE_FEATURE, error);

                const errorMessageToast  = error.body.output.errors[0].errorCode;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: ERROR_TITLE_CREATE,
                        message: errorMessageToast,
                        variant: 'error'
                    })
            );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    

    deleteSelectedFeature(feature) {
        this.isLoading = true;

        if (!feature.selectedFeatureId) {
            console.warn(WARN_SELECTED_FEATURE_ID);
            this.handleLoadFeatures();
            this.isLoading = false;
            return;
        }

        deleteRecord(feature.selectedFeatureId)
            .then(() => {
                this.handleLoadFeatures();
            })
            .catch(error => {
                let errorCode = null;
                let errorMessage = '';

                if (error.body) {
                    if (error.body.output && error.body.output.errors && error.body.output.errors.length > 0) {
                        errorCode = error.body.output.errors[0].errorCode;
                    }
                    if (error.body.message) {
                        errorMessage = error.body.message.toLowerCase();
                    }
                }

                if (errorCode === ERROR_CODE || errorMessage.includes('entity is deleted')) {
                    this.handleLoadFeatures();
                } 
                else {
                    console.error(ERROR_DELETE_FEATURE, error);
                    this.handleLoadFeatures();
                }

                const errorMessageToast = error.body.output.errors[0].errorCode;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: ERROR_TITLE_DELETE,
                        message: errorMessageToast,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    connectedCallback() {
        loadStyle(this, dataTableWithoutTruncate);
    }
}