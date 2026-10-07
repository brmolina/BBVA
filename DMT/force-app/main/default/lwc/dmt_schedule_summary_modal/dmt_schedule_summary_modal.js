import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import getSubscription from '@salesforce/apex/DMT_NotificationSubscriptionController.getSubscription';
import saveSubscription from '@salesforce/apex/DMT_NotificationSubscriptionController.saveSubscription';
import deleteSubscription from '@salesforce/apex/DMT_NotificationSubscriptionController.deleteSubscription';

const FREQUENCY_OPTIONS = [
    { label: 'Diaria', value: 'diaria' },
    { label: 'Semanal', value: 'semanal' },
    { label: 'Mensual', value: 'mensual' }
];

const CLOSE_WON_TYPE     = 'Closed_Won';
const REVIEW_TYPE        = 'Lines_Opportunities_review';
const TASK_ASSIGNED_TYPE = 'Task_Assigned';
const CLOSE_LOST_TYPE    = 'Closed_Lost'; 

export default class DmtScheduleSummaryModal extends LightningElement {

    _showModal = false;

    @api
    get showModal() {
        return this._showModal;
    }

    set showModal(value) {
        const opening = value && !this._showModal;
        this._showModal = value;
        if (opening) {
            this._refreshSubscriptions();
        }
    }

    showScheduleOptions = false;

    @api accountId;

    _userId = userId;

    taskAssignedMode = '';
    closeWonLineMode = '';
    closeLostLineMode = ''; 
    reviewMode = '';

    taskAssignedDate;
    taskAssignedHour;
    taskAssignedFrequency;

    closeWonLineDate;
    closeWonLineHour;
    closeWonLineFrequency;

    closeLostLineDate;
    closeLostLineHour;
    closeLostLineFrequency;

    reviewDate;
    reviewHour;
    reviewFrequency;

    get frequencyOptions() {
        return FREQUENCY_OPTIONS;
    }

    _savedCloseWonLineMode = '';
    _savedReviewMode = '';
    _savedTaskAssignedMode = '';
    _savedCloseLostLineMode = ''; 

    _wiredCloseWon;
    _wiredReview;
    _wiredTaskAssigned;
    _wiredCloseLost;
 

    @wire(getSubscription, { type: CLOSE_WON_TYPE })
    wiredCloseWonSubscription(result) { 
        this._wiredCloseWon = result;
        const { data } = result;
        if (data !== undefined) {
            this._savedCloseWonLineMode = data ? 'notify' : '';
            this.closeWonLineMode = this._savedCloseWonLineMode;
        }
    }

    @wire(getSubscription, { type: REVIEW_TYPE })
    wiredReviewSubscription(result) { 
        this._wiredReview = result;
        const { data } = result;
        if (data !== undefined) {
            this._savedReviewMode = data ? 'notify' : '';
            this.reviewMode = this._savedReviewMode;
        }
    }

    
    @wire(getSubscription, { type: TASK_ASSIGNED_TYPE })
    wiredTaskAssignedSubscription(result) { 
        this._wiredTaskAssigned = result;
        const { data } = result;
        if (data !== undefined) {
            this._savedTaskAssignedMode = data ? 'notify' : '';
            this.taskAssignedMode = this._savedTaskAssignedMode;
        }
    }

        
    @wire(getSubscription, { type: CLOSE_LOST_TYPE })
    wiredCloseLostSubscription(result) {
        this._wiredCloseLost = result;
        const { data } = result;
        if (data !== undefined) {
            this._savedCloseLostLineMode = data ? 'notify' : '';
            this.closeLostLineMode = this._savedCloseLostLineMode;
        }
    }

    _refreshSubscriptions() {
        const wired = [this._wiredCloseWon, this._wiredReview, this._wiredTaskAssigned, this._wiredCloseLost]
        .filter(Boolean);
        if (wired.length) {
            Promise.all(wired.map(w => refreshApex(w)))
                .catch(error => console.error('DMT subscription refresh error:', error));
        }
    }

    get isTaskAssignedNotify() {
        return this.taskAssignedMode === 'notify';
    }

    get isTaskAssignedSchedule() {
        return this.taskAssignedMode === 'schedule';
    }

    get isCloseWonLineNotify() {
        return this.closeWonLineMode === 'notify';
        
    }

    get isCloseLostLineNotify() {
        return this.closeLostLineMode === 'notify';

    }

    get isCloseWonLineSchedule() {
        return this.closeWonLineMode === 'schedule';
    }

    get isReviewNotify() {
        return this.reviewMode === 'notify';
    }

    get isReviewSchedule() {
        return this.reviewMode === 'schedule';
    }

    handleModeToggle(event) {
        const section = event.currentTarget.dataset.section;
        const mode = event.currentTarget.dataset.mode;
        const checked = event.detail.checked;
        const value = checked ? mode : '';

        if (section === 'taskAssigned') {
            this.taskAssignedMode = value;
            if (value !== 'schedule') {
                this.taskAssignedDate = null;
                this.taskAssignedHour = null;
                this.taskAssignedFrequency = null;
            }
        }

        if (section === 'closeWonLine') {
            this.closeWonLineMode = value;
            if (value !== 'schedule') {
                this.closeWonLineDate = null;
                this.closeWonLineHour = null;
                this.closeWonLineFrequency = null;
            }
        }

               
        if (section === 'closeLostLine') {
            this.closeLostLineMode = value;
            if (value !== 'schedule') {
                this.closeLostLineDate = null;
                this.closeLostLineHour = null;
                this.closeLostLineFrequency = null;
            }
        }

        if (section === 'review') {
            this.reviewMode = value;
            if (value !== 'schedule') {
                this.reviewDate = null;
                this.reviewHour = null;
                this.reviewFrequency = null;
            }
        }
    }

    handleDateChange(event) {
        const section = event.currentTarget.dataset.section;
        const value = event.detail.value;

        if (section === 'taskAssigned') this.taskAssignedDate = value;
        if (section === 'closeWonLine') this.closeWonLineDate = value;
        if (section === 'closeLostLine') this.closeLostLineHour = value;
        if (section === 'review') this.reviewDate = value;
    }

    handleHourChange(event) {
        const section = event.currentTarget.dataset.section;
        const value = event.detail.value;

        if (section === 'taskAssigned') this.taskAssignedHour = value;
        if (section === 'closeWonLine') this.closeWonLineHour = value;
        if (section === 'closeLostLine') this.closeLostLineDate = value; 
        if (section === 'review') this.reviewHour = value;
    }

    handleFrequencyChange(event) {
        const section = event.currentTarget.dataset.section;
        const value = event.detail.value;

        if (section === 'taskAssigned') this.taskAssignedFrequency = value;
        if (section === 'closeWonLine') this.closeWonLineFrequency = value;
        if (section === 'closeLostLine') this.closeLostLineFrequency = value;
        if (section === 'review') this.reviewFrequency = value;
    }

    handleClose() {
        this.closeWonLineMode = this._savedCloseWonLineMode;
        this.closeLostLineMode = this._savedCloseLostLineMode;
        this.reviewMode = this._savedReviewMode;
        this.taskAssignedMode = this._savedTaskAssignedMode;
        this._closeModal();
    }

    handleApplyModify() {
        const closeWonCall = this.closeWonLineMode === 'notify'
            ? saveSubscription({ type: CLOSE_WON_TYPE })
            : deleteSubscription({ type: CLOSE_WON_TYPE });
        const reviewCall = this.reviewMode === 'notify'
            ? saveSubscription({ type: REVIEW_TYPE })
            : deleteSubscription({ type: REVIEW_TYPE });
        const taskAssignedCall = this.taskAssignedMode === 'notify'
            ? saveSubscription({ type: TASK_ASSIGNED_TYPE })
            : deleteSubscription({ type: TASK_ASSIGNED_TYPE });
        const closeLostCall = this.closeLostLineMode === 'notify'
            ? saveSubscription({ type: CLOSE_LOST_TYPE })
            : deleteSubscription({ type: CLOSE_LOST_TYPE });
        Promise.all([closeWonCall, reviewCall, taskAssignedCall, closeLostCall])
            .then(() => {
                this._savedCloseWonLineMode = this.closeWonLineMode;
                this._savedReviewMode = this.reviewMode;
                this._savedTaskAssignedMode = this.taskAssignedMode;
                this._savedCloseLostLineMode = this.closeLostLineMode;
            })
            .catch(error => {
                console.error('DMT subscription update error:', error);
            })
            .finally(() => {
                this._closeModal();
            });
    }

    _closeModal() {
        this.dispatchEvent(new CustomEvent('closemodal', { bubbles: true, composed: true }));
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
    }
}