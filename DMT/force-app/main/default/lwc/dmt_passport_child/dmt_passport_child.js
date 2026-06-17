import { LightningElement, api, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import dmt_case_comment_modal_v2 from 'c/dmt_case_comment_modal_v2';
import TIME_ZONE  from '@salesforce/i18n/timeZone';

export default class Dmt_passport_child extends NavigationMixin(LightningElement) {
    @api showWarning;
    @api showfeaturesTable;
    @api wrapper;
    @api isBig;
    @api messageError;
    @api isTaskModalOpen;
    @api noShowInfo;
    @api graphicModal;
    @api errorModal;
    @api validations;
    @api showAuditDate;
    @api checkStatusProposal
    @api checkStatusApproval
    @api userPermission;
    @api isCaseModalOpen = false;
    @api approver;
    @api featureid;

    @track _columnsWithClass = [];
    _columns = [];

    get columns() {
        return this._columns;
    }

    @api 
    set columns(value) {
        this._columns = value;
        if (value) {
            // Mapping only happens when the columns definition actually changes
            this._columnsWithClass = value.map(col => ({
                ...col,
                class: `slds-is-sortable _slds-is-resizable slds-text-title--caps fixed-header fixed-row-header ${col.isNarrow}`
            }));
        }
    }

    get userTimeZone() {
        return TIME_ZONE;
    }

    openModal(event)
    {
        const fetchMoreEvent = new CustomEvent('openmodal', {detail: event.currentTarget.dataset.id});
        this.dispatchEvent(fetchMoreEvent);
    }

    startCase(event)
    {
        const fetchMoreEvent = new CustomEvent('startcase', {detail: event.currentTarget.dataset.feature});
        this.dispatchEvent(fetchMoreEvent);
    }

    expandedControlEvent(event) {


        const fetchMoreEvent = new CustomEvent('expanded', {detail: event.currentTarget.dataset.id});
        this.dispatchEvent(fetchMoreEvent);
    }
    //Modal de Case
    handleOpenCaseModalClick(event) {
        this.isCaseModalOpen = true;
        this.openCaseModal(event);
    }

   
    handleCaseModalClose() {
        this.isCaseModalOpen = false;
    }

    handleOpenTaskModalClick(event) {
        const params = {};
        this.openTaskModal(event);
    }

    handleTaskModalClose() {
        this.isTaskModalOpen = false;
    }

     handleNavigationToTask(event) {

        var foundTask;
        let taskIdToFind = event.currentTarget.dataset.id;
        
        try {
            this.wrapper.forEach(record => {
                // Parent task
                if (!foundTask && record.sfCurrentTask?.taskId === taskIdToFind) {
                    foundTask = record.sfCurrentTask;
                }
                // Child task
                if (!foundTask && record.featureTasksHistory) {
                    foundTask = record.featureTasksHistory.find(task => task.taskId === taskIdToFind);
                }
            });

        } catch (error) {
            this.handleError(error);
        }
        const urlFinal = (foundTask?.step?.urlValue).replace('/', '');

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  urlFinal,
                objectApiName: 'Case',
                actionName: 'view'
            },
        
        });
    }

        async openTaskModal(event) {
            var foundTask;
            var foundParentTask;
            let taskIdToFind = event.currentTarget.dataset.id;
            try {
                this.wrapper.forEach(record => {
                    // Parent task
                    console.log(record);
                    if (record.sfCurrentTask?.taskId === taskIdToFind) {
                        foundParentTask = record.sfCurrentTask;
                    }
                    // Child task
                    if (record.featureTasksHistory) {
                        foundTask = record.featureTasksHistory.find(task => task.taskId === taskIdToFind);
                    }
                });
                if(foundTask || foundParentTask) {
                    if (foundTask) {
                        this.childProps = {closecallback: this.handleTaskModalClose.bind(this),record: foundTask};
                    } else if(foundParentTask && foundParentTask.openModal === true) {
                        this.childProps = {closecallback: this.handleTaskModalClose.bind(this),record: foundParentTask};
                    }
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
    //Modal de Case
   openCaseModal(event){
        const idProccess = event.currentTarget.dataset.feature;
        var approver;
        var featureid;
        var comment = '';

       this.wrapper.forEach(record => {
            
            if (record.idProccess === idProccess ) {
                approver = record.tasks[0].approvers[0].name;
                featureid = record.idProccess;
            }
        });
        
        try{
            if(approver) {
                
                const result =  dmt_case_comment_modal_v2.open({
                size: 'small',
                description: 'Modal for comment on the case',
                approver: approver,
                featureid: this.featureid
                }).then((result) => {
                
                    if(result !== undefined){
                        
                        comment = result.comment;
                        const fetchMoreEvent = new CustomEvent('startcase', {
                        detail: {
                            idProccess: featureid, 
                            comment: comment
                        }});

                        this.dispatchEvent(fetchMoreEvent);
                    }
                     
                })

            }else{
                console.error('Task not found, its required to open modal');
            }
        }catch (error) {
          this.handleError(error);
        }
    }

    
}