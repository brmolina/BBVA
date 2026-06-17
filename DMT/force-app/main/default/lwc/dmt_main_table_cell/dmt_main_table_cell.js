import { LightningElement, api,track } from 'lwc';
import DMT_Main_Holder from '@salesforce/label/c.DMT_Main_Holder';
import DMT_Main_Borrower from '@salesforce/label/c.DMT_Main_Borrower';

export default class dmt_main_table_cell extends LightningElement {

    @api row;
    @api index;
    @api column;
    @api tab;
    @api cellid;
    @api groupselected;
    @api selectedcell;
    @api currencyrow;
    @api isLableHolder = false;

    labels = {
        DMT_Main_Holder,
        DMT_Main_Borrower
    };
    @track ismainholder = false;
    type;
    value;
    groupName;
    groupId
    subGroupName;
    level3GroupName;
    level3GroupId;
    subGroupId;
    clientName;
    clientId;
    country;
    taxpayerId;
    clientType;
    clients = [];
    l3groups = [];
    subgroups = [];
    isSelected = false;
    initComponent = true;
    toogle = false;
    isName = false;
    isText = false;
    isCurrency = false;
    isDate = false;
    isLink = false;
    isPercent = false;
    isTextinput = false;
    isCombobox = false;
    isEmpty = false;
    alignClass = 'slds-truncate';
    get toggleId() {
        return `toggle_${this.clientId}`;
    }

    get mainRoleLabel() {
        return this.isLableHolder ? this.labels.DMT_Main_Holder : this.labels.DMT_Main_Borrower;
    }

    connectedCallback() {

        this.label = this.column.label || '';
        this.type = this.column.type || 'text';
        this.inselectcolumn = this.column.inselectcolumn || false;
        this.field = this.column.field;
        this.title = this.column.title || '';
        this.onclick = this.column.onclick;
        this.sortable = this.column.sortable || false;
        this.currency = this.column.currency || 'EUR';
        this.fractionDigits = this.column.fractionDigits || 2;
        this.alignClass = (this.column.align === 'right') ? 'slds-truncate slds-text-align_right' : 'slds-truncate';

        if (this.index === 0) {
            this.isName = true;
            this.isEmpty = false;

            switch (this.row['type']) {
                case 'subgroup':
                case 'l3group':
                    this.clientType = this.row['type'];
                    this.Id = this.row['type'] === 'subgroup' ? this.row['subGroupId'] : this.row['level3GroupId'];
                    this.Name = this.row['type'] === 'subgroup' ? this.row['subGroupName'] : this.row['level3GroupName'];
                    this.groupName = this.row['groupName'];
                    this.groupId = this.row['groupId'];
                    this.subGroupName = this.row['subGroupName'];
                    this.subGroupId = this.row['subGroupId'];
                    this.level3GroupName = this.row['level3GroupName'];
                    this.level3GroupId = this.row['level3GroupId'];
                    this.countryIfoId = this.row[7];
                    this.taxpayerId = this.row[8];

                    this.row.clients.forEach(client => {
                        this.clients.push({customerId: client[6], customerName: client[9], countryIfoId: client[7], subGroupId: client[3], subGroupName: client[2], taxpayerId: client[8]});
                    });

                    if (this.row.hasOwnProperty('l3groups')) {
                        this.row.l3groups.forEach(l3group => {
                            this.l3groups.push({Id: l3group.level3GroupId, Name: l3group.level3GroupName})
                            l3group.clients.forEach(l3client => {
                                this.clients.push({Id: l3client[6], Name: l3client[9], countryIfoId: l3client[7]});
                            });
                        })
                    }
                    break;

                default:
                   this.clientType = 'client';
                   this.Id = this.row[6];
                   this.Name = this.row[9];
                   this.groupName = this.row[0];
                   this.groupId = this.row[1];
                   this.level3GroupName = this.row[4];
                   this.level3GroupId = this.row[5];
                   this.clientId = this.row[6];
                   this.countryIfoId = this.row[7];
                   this.taxpayerId = this.row[8];
                   this.clientName = this.row[9];
                   this.isEmpty = false;

                   if (this.row[3] !== '-1000') {
                       this.subGroupName = this.row[2];
                       this.subGroupId = this.row[3];
                   }
                   break;
           }

        } else {
            //this.clientId = this.row[6]
            //this.showColumn = (this.inselectcolumn && this.selectedcell.includes(this.row[6])) || !this.inselectcolumn;
            this.clientType = 'client';
            this.Id = this.row[6];
            this.Name = this.row[9];
            this.groupName = this.row[0];
            this.groupId = this.row[1];
            this.level3GroupName = this.row[4];
            this.level3GroupId = this.row[5];
            this.clientId = this.row[6];
            this.countryIfoId = this.row[7];
            this.taxpayerId = this.row[8];
            this.clientName = this.row[9];
            this.isEmpty = false;
            this.value = this.title === 'displaytext' ? this.row[this.index + 13] : '';
            this.isText = this.type === 'text';
            this.isDate = this.type === 'date';
            this.isPercent = this.type === 'percent';
            this.isNumber = this.type === 'number';
            this.isCurrency = this.type === 'currency';
            this.isTextinput = this.type === 'textinput';
            this.isCombobox = this.type === 'combobox';
            this.isLink = this.onclick !== undefined;
            this.isCurrencylabel = this.type === 'isCurrencylabel';
            this.isEmpty = this.value && !this.value.isEmpty;

        
        }

        if(this.selectedcell[0] !== "null" && this.initComponent){
                this.selectedcell.forEach( cell => {
                    if(cell.customerId === this.row[6]){
                        this.isSelected = true;
                        this.initComponent = true;
                        this.ismainholder = false;
                        console.log('%c[CELL connectedCallback] match encontrado:', 'color:cyan',
                        'customerId:', cell.customerId,
                        '| cell.mainHolder:', cell.mainHolder,
                        '| ismainholder calculado: false (controlled by parent)'
                        );
                                        this.handleClick();
                        if(this.inselectcolumn){
                            this.value = cell[this.column.field];
                            setTimeout(() => {
                            }, 100);
                            this.handleChange()
                        }
                    }
                })
            this.initComponent = false;
        }
    }


    handleClick(event) {
        console.log('eveeent',event);
        if(event){
            event.preventDefault();
            this.isSelected = !this.isSelected;          
            this.dispatchMainHolderUpdate(this.isSelected ? 'ADD_ACCOUNT' : 'REMOVE_ACCOUNT');
            this.initComponent = false;
        }
        else{
            this.initComponent = true;
        }
        if( this.clientType !== 'client'){
            if(this.groupselected.get(this.subGroupId) !== true){
                this.isSelected = true;
            }else{
                this.isSelected = false;
            }
        }
        const params = {
            groupId: this.groupId || '',
            groupName: this.groupName || '',
            subGroupId: this.subGroupId || '',
            subGroupName: this.subGroupName || '',
            customerId: this.clientId || '',
            customerName: this.clientName || '',
            level3GroupId: this.level3GroupId || '',
            level3GroupName: this.level3GroupName || '',
            clientType: (this.clientType || ''),
            index: this.index || ''
        };
        console.log('tab: ',this.tab);
        switch (this.tab) {
            case 'tcm':
                //extra info for TCM
                params.countryIfoId = this.countryIfoId || '';
                // params.riskAnalystId = this.row[10] || '';
                // params.updLmsclInternalRatgType = this.row[11] || '';
                // params.assetAllocationActvyType = this.row[12] || '';
                // params.assetAllocationSubSecType = this.row[13] || '';
                params.taxpayerId = this.taxpayerId || '';
                params.clients = this.clients || [];
                params.l3groups = this.l3groups || [];
                params.subgroups = [];
                params.cellid = this.cellid;
                params.groupsize = this.row[10] || '';
                params.initComponent = this.initComponent.toString() || '';
                params.currency = this.currencyrow || '';
                params.riskAnalystId = this.row[10] || '';
                params.customerCounterpartiesCodesDesc = this.row[14] || '';
                params.operationMitigantDesc = this.row[15] || '';
                params.updSmsclInternalRatgType = this.row[16] || '';
                params.currentRatingToolDate = this.row[17] || '';
                var evt = new CustomEvent('selectclientdmt', { 
                    bubbles: true,
                    composed: true,
                    cancelable: true,
                    detail: params
                });
                this.dispatchEvent(evt);
                console.log('eveeent treasury',JSON.stringify(evt.detail));
            break;
            case 'tcmotherlines':
                //extra info for TCM
                params.countryIfoId = this.countryIfoId || '';
                // params.riskAnalystId = this.row[10] || '';
                // params.updLmsclInternalRatgType = this.row[11] || '';
                // params.assetAllocationActvyType = this.row[12] || '';
                // params.assetAllocationSubSecType = this.row[13] || '';
                params.taxpayerId = this.taxpayerId || '';
                params.clients = this.clients || [];
                params.l3groups = this.l3groups || [];
                params.subgroups = [];
                params.cellid = this.cellid;
                params.groupsize = this.row[10] || '';
                params.initComponent = this.initComponent?.toString() || '';
                params.currency = this.currencyrow || '';
                params.riskAnalystId = this.row[10] || '';
                params.customerCounterpartiesCodesDesc = this.row[14] || '';
                params.operationMitigantDesc = this.row[15] || '';
                params.updSmsclInternalRatgType = this.row[16] || '';
                params.currentRatingToolDate = this.row[17] || '';
                var evt = new CustomEvent('selectclientdmt', { 
                    bubbles: true,
                    composed: true,
                    cancelable: true,
                    detail: params
                });
                this.dispatchEvent(evt);console.log('eveeent2',JSON.stringify(evt.detail));
            break;

            case 'tcmopp':
                params.countryIfoId = this.countryIfoId || '';
                // params.riskAnalystId = this.row[10] || '';
                // params.updLmsclInternalRatgType = this.row[11] || '';
                // params.assetAllocationActvyType = this.row[12] || '';
                // params.assetAllocationSubSecType = this.row[13] || '';
                params.taxpayerId = this.taxpayerId || '';
                params.clients = this.clients || [];
                params.l3groups = this.l3groups || [];
                params.subgroups = [];
                params.cellid = this.cellid;
                params.groupsize = this.row[10] || '';
                params.initComponent = this.initComponent?.toString() || '';
                params.currency = this.currencyrow || '';
                params.riskAnalystId = this.row[10] || '';
                params.customerCounterpartiesCodesDesc = this.row[14] || '';
                params.operationMitigantDesc = this.row[15] || '';
                params.updSmsclInternalRatgType = this.row[16] || '';
                params.currentRatingToolDate = this.row[17] || '';
                var evt = new CustomEvent('selectclientdmt', { 
                    bubbles: true,
                    composed: true,
                    cancelable: true,
                    detail: params
                });
                this.dispatchEvent(evt);
            break;
            

            default:
                var evt = new CustomEvent('opendetail', {
                    bubbles: true,
                    composed: true,
                    cancelable: true,
                    detail: params
                });
                this.dispatchEvent(evt);
            break;
        }
    }
    renderedCallback() {
    if (this.index === 0 && this.isSelected) {
        const container = this.template.querySelector('.toggle-container');
        const toggle = this.template.querySelector('input[type="checkbox"]');
        console.log('%c[CELL rendered]', 'color:orange',
            'clientId:', this.clientId,
            '| ismainholder:', this.ismainholder,
            '| isSelected:', this.isSelected,
            '| isName:', this.isName,
            '| index:', this.index,
            '| container:', container ? 'SÍ' : 'NO',
            '| checkbox:', toggle ? 'SÍ' : 'NO'
        );
    }
}
    handleChange(event){
        var params={};
        if(event){
            params = {
                customerId: this.row[6],
                value: event.target.value ,
                context: this.column.field,
                initComponent : this.initComponent
            }
        }else{
            params = {
                customerId: this.row[6],
                value: this.value,
                context:  this.column.field
            }
        }

        var evt = new CustomEvent('inputfielddmt', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: params
        });
        this.dispatchEvent(evt);
        this.initComponent = false;
    }



    get getcustomerId() {
        return this.row[6];
    }

    get isClient() {
        return this.clientType === 'client';
    }

    get isGroup() {
        return this.clientType === 'group' || this.clientType === 'subgroup' || this.clientType === 'l3group';
    }

    get clientInfo() {        
        // Prospects do not have taxpayerId
        if (!this.taxpayerId) {
            return this.countryIfoId + ' - ' + this.Id;
        }
        return this.countryIfoId + ' - ' + this.Id + ' - ' + this.taxpayerId;
    }

    get currencyCode() {
        return typeof this.value === 'number' ? ' ' + this.currency : '';
    }
    @api activateSelection() {
    this.isSelected = true;
    }

    @api deactivateSelection() {
        this.isSelected = false;
    }
    @api deactiveMainHolder() {
        this.ismainholder = false;
        
    }
    @api activateMainHolderByDefault() {
        console.log('%c[CELL activate] ANTES ismainholder:', 'color:red', this.ismainholder);
        console.log('%c[CELL activate] isSelected:', 'color:red', this.isSelected);
        console.log('%c[CELL activate] clientType:', 'color:red', this.clientType);
        console.log('%c[CELL activate] clientId:', 'color:red', this.clientId);
        this.ismainholder = true;
        console.log('%c[CELL activate] DESPUÉS ismainholder:', 'color:red', this.ismainholder);
    }
    handleToggleChange(event) {
        const isChecked = event?.target.checked;
        this.dispatchMainHolderUpdate(isChecked ? 'UPDATE_MAIN_HOLDER' : 'CHECK_LAST_MAIN_HOLDER');

    }

    dispatchMainHolderUpdate(context) {
          
        const detail = {
            customerId: this.clientId,
            context: context,
            initComponent : this.initComponent
        };

        this.dispatchEvent(new CustomEvent('updatemainholder', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail
        }));
    }

}