import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import dmt_case_comment_modal_v2 from 'c/dmt_case_comment_modal_v2';
import startCase from '@salesforce/apex/DMT_Passport_Handler.startCase';
import getStepsFromCase from '@salesforce/apex/DMT_Case_Steps_Controller.getStepsFromCase';
import passportModal from 'c/dmt_passport_modal';
import getProductIds from '@salesforce/apex/DMT_Opportunity_Selector.getProductIds';
import getAssociatedSanctionLine from '@salesforce/apex/DMT_Opportunity_Handler.getAssociatedSanctionLine';
import sendRequest from '@salesforce/apex/DMT_DynamicIntegrationServices.sendRequest';



export default class Dmt_feature_with_workflow extends NavigationMixin(LightningElement) {
    
    _feature;
    _isbig;
    isExpanded = false;
    haveProducts = false;
    componentConstructor;
    isTaskModalOpen;
    haveTaskHistory;
    
    @track featureTasksHistory;
    @track currentTask;
    @api oppId;
    @api isreadytoclose = false;

    @api
    get feature() {
        return this._feature;
    }
    set feature(value) {
        
        this.haveProducts = value.products != undefined && value.products?.length > 0;
        this.currentTask = value?.currentTask;
        
        var temptValue = JSON.parse(JSON.stringify(value));

        temptValue.showTrafficLight = value.showTrafficLight;
        temptValue.request = temptValue == undefined ? true : temptValue.request;
        
        this._feature = temptValue;
        this.getTaskHistory();
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

    get disableReadyToCloseBusinessClick() {
        const currentFeature = this.feature || {};
        const isReadyToCloseFeature = currentFeature?.passportSanction === 'readytoclose';
        const isBusinessReadyToClose = currentFeature?.motorDesc === 'Line Engine - Profitability Engine';
        const isGrayState = (currentFeature?.stateName || '').toUpperCase() === 'GRAY';

        return isReadyToCloseFeature && isBusinessReadyToClose && isGrayState;
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
        try {
            // 1. Get the specific Task ID that was clicked
            const clickedTaskId = event.currentTarget.dataset.id;
            let taskToPass = null;

            // 2. Determine if they clicked the Current Task
            if (this.feature.currentTask && this.feature.currentTask.taskId === clickedTaskId) {
                taskToPass = this.feature.currentTask;
            }
            // 3. Or if they clicked a task in the History table
            else if (this.featureTasksHistory && this.featureTasksHistory.length > 0) {
                taskToPass = this.featureTasksHistory.find(task => task.taskId === clickedTaskId);
            }

            // 4. Open the modal with the correct record
            if (taskToPass) {
                this.childProps = { closecallback: this.handleTaskModalClose.bind(this), record: taskToPass };
                const modalModule = this.feature?.name === 'Portfolio Alignment Simulation' || this.feature?.pawif
                    ? await import('c/dmt_case_history_modal_pawif')
                    : await import('c/dmt_case_history_modal');
                this.componentConstructor = modalModule.default;
                this.isTaskModalOpen = true;
            } else {
                console.error('Task not found, its required to open modal');
            }
        } catch (error) {
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


   async openModalLimit(event) {

        // READY TO CLOSE business modal
        const profitability = this.feature?.profitability;
        const profitabilityPayload = profitability && typeof profitability === 'object'
            ? profitability
            : { results: [] };
        const isProfitabilityReadyToClose = this.feature?.passportSanction === 'readytoclose' &&
            this.feature?.motorDesc === 'Line Engine - Profitability Engine';

        if (isProfitabilityReadyToClose) {

            try {
                const conditionDesc = this.feature?.products
                    ?.find(p => p?.opportunityValidation?.conditionDesc)
                    ?.opportunityValidation?.conditionDesc || null;

                await passportModal.open({
                    noShowInfo: false,
                    graphicModal: true,
                    noShowInfoMessage: conditionDesc,
                    limits: null,
                    featureName: this.feature?.name,
                    featureLight: null,
                    validations: null,
                    errorModal: false,
                    profitability: profitabilityPayload,
                    showProfitabilityChart: true,
                    opportunityId: this.oppId
                });

            } catch (error) {
                this.notifyParentError(error);
            }
            return;
        }

        // RIESGO
        const products = this.feature?.products || [];

        if (products.length === 0) return;

        // Resolver IDs reales de OpportunityLineItem
        const opportunityExternalId = this.feature?.opportunityId;
        const productIds = products.map(p => p.productId);

        let resolvedIdMap = {};
        try {
            const lineItems = await getProductIds({ opportunityExternalId, productIds });

            console.log('Resolved Line Items:', JSON.stringify(lineItems));
            lineItems.forEach(item => {
                resolvedIdMap[item.gf_group_priority_opportunity_id__c] = {
                        id: item.Id,
                        name: item.DES_Product_Name__c
                    };
                });
        } catch (error) {
            this.notifyParentError(error);
            return;
        }

        let associatedLineUrl = null;
        let associatedLineLabel = null;
        if (this.feature?.passportSanction === 'readytoclose') {
            try {
                const associatedLine = await getAssociatedSanctionLine({ opportunityExternalId });
                if (associatedLine?.lineId) {
                    associatedLineUrl = `/lightning/r/DMT_Line__c/${associatedLine.lineId}/view`;
                    associatedLineLabel = associatedLine.lineLabel;
                }
            } catch (error) {
                console.error('Error resolving associated sanction line:', error);
            }
        }

        let labels = [];
        let targets = [];
        let conditions = [];
        let conditionLineDiffs = [];
        let limitLights = [];
        let dataDraw = [];
        let currencies = [];
        let originCurrency = null;

        products.forEach(p => {
            const conditionDesc = p.opportunityValidation?.conditionDesc || '';
            const currencyId = p.opportunityValidation?.currencyId || null;
            const resolved = resolvedIdMap[p.productId];
            const resolvedName = resolved.name;
            const conditionLineAmount = Number(p.opportunityValidation?.conditionLineAmount || 0);
            const authorizedRiskAmount = Number(p.opportunityValidation?.authorizedRiskAmount || 0);

            labels.push(`${resolvedName} # ${conditionDesc}`);
            targets.push(conditionLineAmount);
            conditions.push(conditionDesc);
            conditionLineDiffs.push(conditionLineAmount - authorizedRiskAmount > 0 ? conditionLineAmount - authorizedRiskAmount : null);
            limitLights.push(p.stateName);
            dataDraw.push(p.opportunityValidation?.productAmount || 0);
            currencies.push(currencyId);

            if (!originCurrency && currencyId) {
                originCurrency = currencyId;
            }
        });

        console.log('DEBUG: conditionLineDiffs', JSON.stringify(conditionLineDiffs));
        console.log('DEBUG: dataDraw', JSON.stringify(dataDraw));

        const limits = {
            labels,
            sections: ["Consumption", "New Opportunity"],
            datasets: [{
                label: "Consumption",
                data: conditionLineDiffs,
                backgroundColor: "rgba(36, 150, 234, 1)"
            }, {
                label: "New Opportunity",
                data: dataDraw,
                backgroundColor: "rgba(189, 189, 189, 1)"
            }],
            targetColor: "red",
            targets,
            conditions,
            limitLights,
            currencies,
            originCurrency
        };

        try {
            await passportModal.open({
                noShowInfo: false,
                graphicModal: true,
                limits: limits,
                featureName: this.feature?.name,
                featureLight: this.feature?.stateName?.toLowerCase(),
                validations: null,
                errorModal: false,
                profitability: null,
                showProfitabilityChart: false,
                showConditionDesc: conditions.some(c => c && c.trim().length > 0),
                associatedLineUrl,
                associatedLineLabel
            });

            this.isExpanded = false;

        } catch (error) {
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
            if (this.feature.name == 'Portfolio Alignment Simulation') {
                const caseTaskId = response.TASK;
                sendRequest({
                    developerName: 'DMT_Create_PAWIF',
                    opportunityId: this.oppId,
                    taskId: caseTaskId
                }).then(() => {
                    this.notifyParentReload();
                }).catch((error) => {
                    this.notifyParentError(error);
                });
            } else {
                this.notifyParentReload();
            }
            
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