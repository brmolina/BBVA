import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMyRequests from '@salesforce/apex/CLT_My_Request_Ctrl.getMyRequests';

export default class CLT_My_Request extends LightningElement {
    rows = [];
    errorMessage;
    warningMessage;

    page = 1;
    pageSize = 20;
    totalCount = 0;
    totalPages = 1;

    sortedBy = 'lastUpdated';
    sortedDirection = 'desc';

    columns = [
        {label:'Group name',fieldName:'nameCompany',sortable:true},
        {label:'Rol',fieldName:'nameRole',sortable:true},
        {label:'Request action',fieldName:'requestType',sortable:true},
        {label:'Status',fieldName:'status',sortable:true},
        {label:'Approver comment',fieldName:'comment',sortable:true,wrapText:true}
    ];

    get disabledPrev(){ return this.page <= 1;}

    get disabledNext(){ return this.page >= this.totalPages; }

    connectedCallback(){
        this.load();
    }

    async load(){
        try{
            const res = await getMyRequests({page:this.page, pageSize: this.pageSize});
            if(res?.statusCode !== 200){
                this.showToast('Error Service '+res?.statusCode, res?.statusMessage, 'error');
                return;
            }
            this.rows = res?.myRequestList || [];
            console.log('Rows: '+JSON.stringify(this.rows));
            this.totalCount = res?.pagination?.totalCount ?? this.rows.length;
            this.totalPages = res?.pagination?.totalPages ?? 1;
        } catch(e){
            this.rows = [];
            this.totalCount = 0;
            this.totalPages = 1;
            this.errorMessage = this.normalizeError(e);
        }
    }

    handlePrev(){
        if(this.page > 1){
            this.page -=1;
            this.load();
        }    
    }

    handleNext(){
        if(this.page < this.totalPages){
            this.page +=1;
            this.load();
        }
    }

    handleSort(event){
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;

        const field = this.sortedBy;
        const direction = this.sortedDirection === 'asc' ? 1 : -1;

        this.rows = [...this.rows].sort((a,b) => {
            const av = a[field] ?? '';
            const bv = b[field] ?? '';

            if(field === 'lastUpdated'){
                const ad = av ? new Date(av).getTime() : 0;
                const bd = bv ? new Date(bv).getTime() : 0;
                return (ad-bd) *direction;
            }
            return av.toString().localeCompare(bv.toString()) * direction;
        });
    }

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
         })
        );
    }
}