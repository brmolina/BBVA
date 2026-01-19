import { LightningElement,api,track } from 'lwc';
import passportModal from 'c/dmt_passport_modal';
import { NavigationMixin } from "lightning/navigation";
import dmt_case_comment_modal_v2 from 'c/dmt_case_comment_modal_v2';
import startCase from '@salesforce/apex/DMT_Passport_Handler.startCase';
import getStepsFromCase from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromCase';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const LOAD_STYLE_MESSAGE = 'Static Resource Loaded';
const ERROR_MESSAGE = 'error';
const ERROR_PASSPORT_MESSAGE = 'Error processing passport';
const UNSUBCRIBE_MESSAGE = 'Unsubscribed to change events';
const UNKNOWN_MESSAGE = 'Unknown error';
const PASSPORT_ENTITY = 'Passport__c';
const TASK_ENTTITY = 'Task';
const STRING_TYPE = 'string';


export default class Dmt_feature_with_workflow extends NavigationMixin(LightningElement) {
    
    _feature;
    _isbig;
    isExpanded = false;
    haveProducts = false;
    componentConstructor;
    isTaskModalOpen;
    
    @track featureTasksHistory;
    @track currentTask;
    
    @api
    get feature() {
        return this._feature;
    }
    set feature(value) {
        
        console.log('Dmt_feature_with_workflow set feature feature ' +  JSON.stringify(value,2));
        console.log('Dmt_feature_with_workflow set feature name ' + value.name);
        console.log('Dmt_feature_with_workflow set feature hasSftask ' + value.hasSftask);
        console.log('Dmt_feature_with_workflow set feature isNotFinishedTask ' + value.isNotFinishedTask);
        console.log('Dmt_feature_with_workflow set feature workflowColor ' + value.workflowColor);
        console.log('Dmt_feature_with_workflow set feature isApprover ' + value.isApprover);
        console.log('Dmt_feature_with_workflow set feature stateName ' + value.stateName);
        console.log('Dmt_feature_with_workflow set feature value.products?.length > 0 ' + value.products?.length > 0);
        console.log('Dmt_feature_with_workflow set feature value.products !== undefined ' + value.products != undefined);
        console.log('Dmt_feature_with_workflow set feature feature.showTrafficLight ' + value.showTrafficLight);
        console.log('Dmt_feature_with_workflow set feature record.tasks ' + JSON.stringify(value.tasks));
        
        this.haveProducts = value.products != undefined && value.products?.length > 0;
        this.currentTask = value?.currentTask;
        
        console.log('Dmt_feature_with_workflow set feature this.haveProducts ' + this.haveProducts);
        
        var temptValue = JSON.parse(JSON.stringify(value));
        temptValue.showTrafficLight = this.haveProducts ? !this.haveProducts : value.showTrafficLight;
        
        console.log('Dmt_feature_with_workflow set feature temptValue ' +  JSON.stringify(temptValue,2));
        
        this._feature = temptValue;
    }
    
    @api 
    get isbig() {
        return this._isbig;
    }
    set isbig(value) {
        this._isbig = value;
    }
    
    handleExpandedControlEvent(event) {
        this.expandedControlEvent(event);
    }
    
    handleOpenCaseModalClick(event) {
        console.log('Dmt_feature_with_workflow openCaseModal handleOpenCaseModalClick ');
        this.openCaseModal(event);
    }
    
    handleOpenTaskModalClick(event) {
        console.log('Dmt_feature_with_workflow openCaseModal handleOpenTaskModalClick ');
        this.openTaskModal(event);
    }
    
    handleNavigationToTask(event) {
        
        var currentTask = this.feature.currentTask;

        console.log('Dmt_feature_with_workflow handleNavigationToTask currentTask ' +  JSON.stringify(currentTask,2));
        
        const urlFinal = (currentTask?.step?.urlValue).replace('/', '');
        
        console.log('Dmt_feature_with_workflow handleNavigationToTask urlFinal ' +  JSON.stringify(urlFinal,2));
        
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
        
        console.log('Dmt_feature_with_workflow openTaskModal event.currentTarget.dataset ' +  JSON.stringify(event.currentTarget.dataset,2));
        console.log('Dmt_feature_with_workflow openTaskModal event.currentTarget.dataset.approver ' +  JSON.stringify(event.currentTarget.dataset.approver,2));
        
        let taskIdToFind = event.currentTarget.dataset.id;
        
        console.log('Dmt_feature_with_workflow openTaskModal ');
        console.log('Dmt_feature_with_workflow openTaskModal taskIdToFind ' +  JSON.stringify(taskIdToFind,2));
        console.log('Dmt_feature_with_workflow openTaskModal this.feature.tasks ' +  JSON.stringify(this.feature.tasks,2));
        
        try {
            
            currentTask = this.feature.currentTask;
            
            console.log('Dmt_feature_with_workflow openTaskModal currentTask ' +  JSON.stringify(currentTask,2));
            
            if(currentTask) {
                
                this.childProps = {closecallback: this.handleTaskModalClose.bind(this),record: currentTask};
                
                const { default: ctor } = await import('c/dmt_case_history_modal');
                this.componentConstructor = ctor;
                this.isTaskModalOpen = true;
            }else{
                console.error('Task not found, its required to open modal');
            }
        }catch (error) {
            this.handleError(error);
        }
    }
    
    async openCaseModal(event){
        
        console.log('Dmt_feature_with_workflow openCaseModal this.feature.tasks[0].approvers[0].name ' + JSON.stringify(this.feature.tasks?.[0].approvers?.[0].name));
        console.log('Dmt_feature_with_workflow openCaseModal this.feature.id ' + JSON.stringify(this.feature.id));
        
        try{
            if(this.feature.tasks[0].approvers[0].name) {
                
                const result =  dmt_case_comment_modal_v2.open({
                    size: 'small',
                    description: 'Modal for comment on the case',
                    approver: this.feature.tasks[0].approvers[0].name,
                    featureid: this.feature.id
                }).then((result) => {
                    
                    console.log('Dmt_feature_with_workflow openCaseModal result ' + JSON.stringify(result));
                    
                    if(result !== undefined){
                        this.startCase(result.comment);       
                    }    
                })
                
            } else {
                console.error('Task not found, its required to open modal');
            }
        }catch (error) {
            //ns que cojones hacer
            this.handleError(error);
        }
    }
    
    startCase(comment) {
        
        console.log('Dmt_feature_with_workflow startCase comment ' + comment);
        console.log('Dmt_feature_with_workflow startCase this.feature.tasks[0].approvers[0].id ' + this.feature.tasks[0].approvers[0].id);
        console.log('Dmt_feature_with_workflow startCase this.feature.tasks[0].id ' + this.feature.tasks[0].id);
        console.log('Dmt_feature_with_workflow startCase this.feature.tasks ' + JSON.stringify(this.feature.tasks));
        console.log('Dmt_feature_with_workflow startCase this.feature.id ' + this.feature.id);
        console.log('Dmt_feature_with_workflow startCase this.feature.name ' + this.feature.name);
        console.log('Dmt_feature_with_workflow startCase this.feature.passportSanction ' + this.feature.passportSanction);
        console.log('Dmt_feature_with_workflow startCase this.feature.opportunityId ' + this.feature.opportunityId);
        
        startCase({
            externalLineid: this.feature.opportunityId,
            approverId: this.feature.tasks[0].approvers[0].id,
            taskId: this.feature.tasks[0].id,
            taskList: this.feature.tasks,
            featureId: this.feature.id,
            featureName: this.feature.name,
            comment: comment,
            passportSanction: this.feature.passportSanction
        }).then(response => {
            
            console.log('Dmt_feature_with_workflow startCase response ' + JSON.stringify(response));
            
            //this.initRefreshTasksInProgress();
            
        }).catch((error) => {
            this.handleError(error);
        });
        
    }
    
    expandedControlEvent() {
        
        this.isExpanded = !this.isExpanded;
        
        console.log('Dmt_feature_with_workflow expandedControlEvent this.isExpanded ' + JSON.stringify(this.isExpanded));
        
        if(this.isExpanded){
            this.getTaskHistory();
        }
    }
    
    getTaskHistory() {
        
        console.log('Dmt_feature_with_workflow getTaskHistory this.feature.id ' + JSON.stringify(this.feature.id));
        console.log('Dmt_feature_with_workflow getTaskHistory this.feature.opportunityId ' + JSON.stringify(this.feature.opportunityId));
        
        const idToSend = this.feature.currentTask?.step?.urlValue.replace('/', '');
        
        getStepsFromCase({
            caseId: idToSend
        }).then(responseTasks => {
            
            console.log('Dmt_feature_with_workflow getTaskHistory responseTasks ' + JSON.stringify(responseTasks));
            
            if(responseTasks) {

                console.log('Dmt_feature_with_workflow getTaskHistory responseTasks ' + JSON.stringify(responseTasks));
            
                
                responseTasks.forEach(task =>{

                    console.log('Dmt_feature_with_workflow getTaskHistory task ' + JSON.stringify(task));
                    console.log('Dmt_feature_with_workflow getTaskHistory task.step ' + JSON.stringify(task?.step));
                    console.log('Dmt_feature_with_workflow getTaskHistory task.step.urlLabel ' + JSON.stringify(task?.step?.urlLabel));
            
                    /*if(task?.startDate != ''){
                        task.startDate = this.formatDate(task.startDate);
                    }
                    if(task?.endDate != ''){
                        task.endDate = this.formatDate(task.endDate);
                    }*/

                    console.log('Dmt_feature_with_workflow getTaskHistory task salida ');
                });

                console.log('Dmt_feature_with_workflow getTaskHistory responseTasks ' + JSON.stringify(responseTasks));
                
                this.featureTasksHistory = responseTasks;
                
                console.log('Dmt_feature_with_workflow getTaskHistory this.featureTasksHistory ' + JSON.stringify(this.featureTasksHistory));
            }     
        }).catch((error) => {
            this.handleError(error);
        });
    }
    
    handleError(error){
        
        console.error(ERROR_MESSAGE,JSON.stringify(error));
        
        let message = UNKNOWN_MESSAGE;
        
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(", ");
        } else if (typeof error?.body?.message === STRING_TYPE) {
            message = error.body.message;
        } else if (typeof error === STRING_TYPE) {
            message = error;
        }else if(Array.isArray(error) && error.length > 0 && typeof error[0] === STRING_TYPE){
            message =  this.csLabels.requiredMsg+' '+error.join(", ")+'.';
        }
        
        this.messageError = message;
        this.setToast(ERROR_PASSPORT_MESSAGE,message,ERROR_MESSAGE);
        this.showSpinner = false;
    }
    
    setToast(title,message,variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message,
                variant: variant,
            }),
        );
    }
    
    formatDate(dateToFormat){
        var [date, hour] = (dateToFormat).split(" ");
        var [day, mnt, year] = date.split("/");
        return day+'-'+mnt+'-'+year;
    }
}