import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import checkEditPermissionOpp from '@salesforce/apex/DMT_LineController.checkEditPermissionOpp';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DMT_STAGE_NAME_FIELD from '@salesforce/schema/Opportunity.StageName';
import DMT_CURRENCY_FIELD from '@salesforce/schema/Opportunity.DMT_CurrencyText__c';
import DMT_OPP_USER_LOCK_FIELD from '@salesforce/schema/Opportunity.DMT_Opp_User_Lock__c';
import DMT_CONFIDENTIAL_FIELD from '@salesforce/schema/Opportunity.DMT_Confidential__c';
import USER_ID from '@salesforce/user/Id';
import getOppLockUser from '@salesforce/apex/DMT_Opportunity_Utils.getOppLockUser';
import pubsub from 'omnistudio/pubsub';

// Labels
import DMT_LABEL_TOAST_RECORD_LOCKED from '@salesforce/label/c.DMT_Label_Toast_Record_Locked';
import DMT_LABEL_TOAST_ERROR from '@salesforce/label/c.DMT_Label_Toast_Error';
import DMT_LABEL_MSG_RECORD_LOCKED_BY_USER from '@salesforce/label/c.DMT_Label_Msg_Record_Locked_By_User';
import DMT_LABEL_MSG_UNSAVED_CHANGES from '@salesforce/label/c.DMT_Label_Msg_Unsaved_Changes';
import DMT_LABEL_MSG_ERROR_LOCK from '@salesforce/label/c.DMT_Label_Msg_Error_Lock';
import DMT_LABEL_MSG_ERROR_RELEASE from '@salesforce/label/c.DMT_Label_Msg_Error_Release';
import DMT_LABEL_MSG_ERROR_VERIFY_LOCK from '@salesforce/label/c.DMT_Label_Msg_Error_Verify_Lock';
import DMT_LABEL_MSG_ERROR_RELEASE_LOCK from '@salesforce/label/c.DMT_Label_Msg_Error_Release_Lock';

const FIELDS = [
    DMT_STAGE_NAME_FIELD,
    DMT_CURRENCY_FIELD,
    DMT_OPP_USER_LOCK_FIELD,
    DMT_CONFIDENTIAL_FIELD
];

export default class Dmt_opp_custom_page extends LightningElement {
    labels = {
        toastRecordLocked: DMT_LABEL_TOAST_RECORD_LOCKED,
        toastError: DMT_LABEL_TOAST_ERROR,
        msgRecordLockedByUser: DMT_LABEL_MSG_RECORD_LOCKED_BY_USER,
        msgUnsavedChanges: DMT_LABEL_MSG_UNSAVED_CHANGES,
        msgErrorLock: DMT_LABEL_MSG_ERROR_LOCK,
        msgErrorRelease: DMT_LABEL_MSG_ERROR_RELEASE,
        msgErrorVerifyLock: DMT_LABEL_MSG_ERROR_VERIFY_LOCK,
        msgErrorReleaseLock: DMT_LABEL_MSG_ERROR_RELEASE_LOCK
    };

    /**
     * Replace {0}, {1}... with dynamic values in label templates
     */
    _formatLabel(template, ...args) {
        return template.replace(/\{(\d+)\}/g, (_, i) => args[i] ?? '');
    }

    recordId = null;
    oppId;
    isEditing = false;
    _hasInitialized = false;
    permissionUserRecord = {
        isAdmin: false,
        accessLevel_read: false,
        accessLevel_edit: false
    };
    prevOppStatus = null;
    prevOppCurrency = null;
    prevUserLock = null;
    isLoading = true;
    showConfidentialModal = false;
    isViewDisabled;
    _hasCheckedPermission = false;
    _isLocking = false;
    _isReleasingLock = false;
    _confidentialModalShown = false;
    isConfidential = false;

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (!pageRef) return;
        const id =
            pageRef.state?.recordId ||
            pageRef.state?.c__recordId ||
            pageRef.attributes?.recordId;
        if (id && id !== this.recordId) {
            this.recordId = id;
            this.oppId = id;
        }
        if (this.recordId && !this._hasCheckedPermission) {
            this.handleCheckEditPermission();
            this._hasCheckedPermission = true;
        }
    }

    _boundBeforeUnload = this.handleBeforeUnload.bind(this);
    _boundPageHide = this.handlePageHide.bind(this);
    _boundFlexCardSaveConfidential = this.handleFlexCardSaveConfidential.bind(this);

    connectedCallback() {
        window.addEventListener('beforeunload', this._boundBeforeUnload);

        window.addEventListener('pagehide', this._boundPageHide);
        pubsub.register('DMT_Opportunity_Info_Tab_Details', {
            saveEventConfidential: this._boundFlexCardSaveConfidential
        });
    }

    disconnectedCallback() {
        window.removeEventListener('beforeunload', this._boundBeforeUnload);
        window.removeEventListener('pagehide', this._boundPageHide);
        pubsub.unregister('DMT_Opportunity_Info_Tab_Details', {
            saveEventConfidential: this._boundFlexCardSaveConfidential
        });
        if (this.isEditing) {
            // Best-effort: free the lock when the component is destroyed.
            this.releaseRecordLock();
        }
    }

    handleFlexCardSaveConfidential(message) {
        if (message.confidential) this.isConfidential = message.confidential;
    }


    handlePageHide(event) {
        if (event && event.persisted) {
            return;
        }
        if (this.isEditing) {
            this.releaseRecordLock();
        }
    }

    handleCheckEditPermission() {
        checkEditPermissionOpp({ oppId: this.recordId })
            .then((result) => {
                

                if (this.hasPermissionsChanged(result)) {
                    this.permissionUserRecord = result;
                }

                this.isViewDisabled = !(result.isAdmin || result.accessLevel_read || result.accessLevel_edit);
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.isViewDisabled = true;
                console.error('[handleCheckEditPermission] ERROR in Apex:', error);
            });
    }

    hasPermissionsChanged(newPermissions) {
        return JSON.stringify(newPermissions) !== JSON.stringify(this.permissionUserRecord);
    }

    handleBeforeUnload(event) {
        if (this.isEditing) {
            const message = this.labels.msgUnsavedChanges;
            event.preventDefault();
            event.returnValue = message;
            return message;
        }
    }


    releaseRecordLock() {
        if (this._isReleasingLock || !this.oppId) {
            return Promise.resolve();
        }
        this._isReleasingLock = true;
        return updateRecord({
            fields: {
                Id: this.oppId,
                [DMT_OPP_USER_LOCK_FIELD.fieldApiName]: null
            }
        })
            .then(() => {
                this.prevUserLock = null;
                notifyRecordUpdateAvailable([{ recordId: this.oppId }]);
            })
            .catch(error => {
                console.error(this.labels.msgErrorReleaseLock, error);
            })
            .finally(() => {
                this._isReleasingLock = false;
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (!data) return;
        const newStatus = getFieldValue(data, DMT_STAGE_NAME_FIELD);
        const newCurrency = getFieldValue(data, DMT_CURRENCY_FIELD);
        const newUserLock = getFieldValue(data, DMT_OPP_USER_LOCK_FIELD);

        this.isConfidential = getFieldValue(data, DMT_CONFIDENTIAL_FIELD) === true;

        if (!this._hasInitialized) {
            this.prevOppStatus = newStatus;
            this.prevOppCurrency = newCurrency;
            this.prevUserLock = newUserLock;
            this._hasInitialized = true;

            if (this.isConfidential && !this._confidentialModalShown) {
                this.showConfidentialModal = true;
                this._confidentialModalShown = true;
            }

            return;
        }

        // When stage or currency changes, reload all tabs
        if (newStatus !== this.prevOppStatus || newCurrency !== this.prevOppCurrency) {
            this.prevOppStatus = newStatus;
            this.prevOppCurrency = newCurrency;
            this.reloadAllTabs();
        }
    }

    /**
     * Reload the current tab and exit edit mode
     */
    async handleReloadEditMode() {
        await this.reloadCurrentTab();
        this.isEditing = false;
        await this.releaseRecordLock();
    }

    /**
     * Handles switching in/out of edit mode, manages record locking
     */
    handleEditMode(payload) {
        const isEditMode = payload?.detail?.editMode === true || payload?.detail?.editMode === 'true';

        if (isEditMode) {
            // Avoid issuing a second lock while a previous acquire is still in flight.
            if (this._isLocking || this.isEditing) {
                return;
            }
            this._isLocking = true;
            this.isEditing = true;

            getOppLockUser({ oppId: this.oppId })
                .then(opp => {
                    const lockedById = opp?.DMT_Opp_User_Lock__c;
                    const lockedBy = opp?.DMT_Opp_User_Lock__r?.Name;
                    if (lockedById && lockedById !== USER_ID) {
                        this.isEditing = false;
                        this.reloadCurrentTab();
                        this.dispatchEvent(new ShowToastEvent({
                            title: this.labels.toastRecordLocked,
                            message: this._formatLabel(this.labels.msgRecordLockedByUser, lockedBy),
                            variant: 'warning',
                            mode: 'dismissable'
                        }));
                        return null;
                    }
                    return updateRecord({
                        fields: {
                            Id: this.oppId,
                            [DMT_OPP_USER_LOCK_FIELD.fieldApiName]: USER_ID
                        }
                    })
                        .then(() => {
                            notifyRecordUpdateAvailable([{ recordId: this.oppId }]);
                        })
                        .catch(error => {
                            this.isEditing = false;
                            this.dispatchEvent(new ShowToastEvent({
                                title: this.labels.toastError,
                                message: error.body?.message || this.labels.msgErrorLock,
                                variant: 'error'
                            }));
                        });
                })
                .catch(error => {
                    this.isEditing = false;
                    this.dispatchEvent(new ShowToastEvent({
                        title: this.labels.toastError,
                        message: error.body?.message || this.labels.msgErrorVerifyLock,
                        variant: 'error'
                    }));
                })
                .finally(() => {
                    this._isLocking = false;
                });
        } else {
            this.isEditing = false;
            this.releaseRecordLock()
                .then(() => {
                    this.reloadAllTabs();
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: this.labels.toastError,
                        message: error.body?.message || this.labels.msgErrorRelease,
                        variant: 'error'
                    }));
                });
        }
    }

    /**
     * Reloads all tabs in the custom tab component
     */
    reloadAllTabs() {
        this.handleCheckEditPermission();
        const tabComponent = this.template.querySelector('c-dmt_opp_tab');
        if (tabComponent) {
            tabComponent.reloadAllTabsContent();
        }
    }

    /**
     * Reloads the current tab in the custom tab component
     */
    reloadCurrentTab() {
        const tabComponent = this.template.querySelector('c-dmt_opp_tab');
        if (tabComponent) {
            tabComponent.reloadCurrentTabContent();
        }
    }

    handleCloseConfidentialModal() {
        this.showConfidentialModal = false;
    }
}