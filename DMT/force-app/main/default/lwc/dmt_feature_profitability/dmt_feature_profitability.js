import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import dmt_case_comment_modal_v2 from 'c/dmt_case_comment_modal_v2';
import startCase from '@salesforce/apex/DMT_Passport_Handler.startCase';
import getStepsFromCase from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromCase';
import passportModal from 'c/dmt_passport_modal';


export default class Dmt_feature_profitability extends NavigationMixin(LightningElement) {

    _feature;
    _isbig;
    isExpanded = false;
    haveProducts = false;
    componentConstructor;
    isTaskModalOpen;
    haveTaskHistory;
    @api oppId;
    @track featureTasksHistory;
    @track currentTask;

 
    @api
    get feature() {
        return this._feature;
    }
    set feature(value) {

        this.haveProducts = value.products != undefined && value.products?.length > 0;
        this.currentTask = value?.currentTask;

        var temptValue = JSON.parse(JSON.stringify(value));

        console.log('feature temptValue ' + JSON.stringify(temptValue));

        temptValue.showTrafficLight = this.haveProducts ? !this.haveProducts : value.showTrafficLight;
        temptValue.request = temptValue == undefined ? true : temptValue.request;

        this._feature = temptValue;
        this.getTaskHistory();

        console.log('feature this._feature ' + JSON.stringify(this._feature));
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

    openModal(event){

        let noShowInfo = false;

        passportModal.open({
            noShowInfo: noShowInfo,
            graphicModal: true,
            limits: null,
            featureName: this.feature?.name,
            featureLight: null,
            validations: null,
            errorModal: false,
            profitability: this.feature?.profitability,
            showProfitabilityChart: true,
            opportunityId: this.oppId
        }).then((result) => {
            this.graphicModal = false;
            this.errorModal = false;
            this.errorMessages = [];
        });
    }

    handleExpandedControlEvent(event) {
        this.expandedControlEvent(event);
    }

    handleOpenCaseModalClick(event) {
        this.openCaseModal(event);
    }

    handleOpenTaskModalClick(event) {
        this.openTaskModal(event);
    }

    handleNavigationToTask(event) {

        var currentTask = this.feature.currentTask;

        const urlFinal = (currentTask?.step?.urlValue).replace('/', '');

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  urlFinal,
                objectApiName: 'Case',
                actionName: 'view'
            },

        });
    }

    handleTaskModalClose() {
        this.isTaskModalOpen = false;
    }

    async openTaskModal(event) {

        var currentTask;

        try {

            currentTask = this.feature.currentTask;

            if(currentTask) {

                this.childProps = {closecallback: this.handleTaskModalClose.bind(this),record: currentTask};

                const { default: ctor } = await import('c/dmt_case_history_modal');
                this.componentConstructor = ctor;
                this.isTaskModalOpen = true;
            }else{
                console.error('Task not found, its required to open modal');
            }
        }catch (error) {
            this.notifyParentError(error);
        }
    }

    async openCaseModal(event){

        try{
            if(this.feature.tasks[0].approvers[0].name) {

                const result =  dmt_case_comment_modal_v2.open({
                    size: 'small',
                    description: 'Modal for comment on the case',
                    approver: this.feature.tasks[0].approvers[0].name,
                    featureid: this.feature.id
                }).then((result) => {

                    if(result !== undefined){
                        this.startCase(result.comment);
                    }
                })

            } else {
                console.error('Task not found, its required to open modal');
            }
        }catch (error) {
            this.notifyParentError(error);
        }
    }

    startCase(comment) {

        //this.notifyShowSpinner(true);
        var externalLineid = this.feature.opportunityId;
        var approverId = this.feature.tasks[0].approvers[0].id;
        var taskId = this.feature.tasks[0].id;
        var featureId = this.feature.id;
        var featureName = this.feature.name;
        var passportSanction = this.feature.passportSanction
        var taskList = this.feature.tasks
        taskList.shift();
        startCase({
            externalLineid: externalLineid,
            approverId: approverId,
            taskId: taskId,
            taskList: taskList,
            featureId: featureId,
            featureName: featureName,
            comment: comment,
            passportSanction: passportSanction
        }).then(response => {
            if (!response.success) {
                this.notifyParentError(response.message);
                this._showSpinner = false;
                return;
            }

            this.notifyParentReload();

        }).catch((error) => {
            this.notifyParentError(error);
        });

    }

    expandedControlEvent() {

        this.isExpanded = !this.isExpanded;

        if(this.isExpanded){
            this.getTaskHistory();
        }
    }

    getTaskHistory() {

         const idToSend = this.feature.currentTask?.caseId

        if(idToSend == undefined || idToSend == 'c-modal-container') {
            return;
        }

        getStepsFromCase({
            caseId: idToSend
        }).then(responseTasks => {
              const processedResponseTasks = responseTasks[0].itemKey === "Finished" ? responseTasks[0].subitems[0] : responseTasks[0];

            if(processedResponseTasks.taskId) {

                this.featureTasksHistory = processedResponseTasks?.subitems?.filter(task => {

                    return String(task.taskId) != String(this.currentTask?.taskId);
                }).map(task =>{

                    let newTask = { ...task };

                    newTask.urlLabel = task?.step?.urlLabel;

                    if(task?.startDate) {
                        newTask.startDate = this.formatDate(task?.startDate);
                    }

                    if(task?.endDate) {
                        newTask.endDate = this.formatDate(task?.endDate);
                    }

                    return newTask;
                });

                this.featureTasksHistory.length <= 0 ? this.haveTaskHistory = false : this.haveTaskHistory = true;

            }else {
                this.haveTaskHistory = false;
            }
        }).catch((error) => {
            console.error(JSON.stringify(error.message));
            this.notifyParentError(error.message);
        });
    }

    notifyShowSpinner(showSpinner) {

        const errorEvent = new CustomEvent('notifyshowspinner', {
            detail: { message: showSpinner }
        });

        this.dispatchEvent(errorEvent);
    }

    notifyParentError(errorMessage) {

        const errorEvent = new CustomEvent('notifyparenterror', {
            detail: { message: errorMessage }
        });

        this.dispatchEvent(errorEvent);
    }

    notifyParentReload() {

        const event = new CustomEvent('notifyparentreload', {
            detail: {  }
        });

        this.dispatchEvent(event);
    }

    formatDate(dateToFormat){

        try {
            var [date, hour] = (dateToFormat).split(" ");
            var [day, mnt, year] = date.split("/");
            return day+'-'+mnt+'-'+year;
        }catch (error) {
            this.notifyParentError(error);
            return null;
        }

    }
}