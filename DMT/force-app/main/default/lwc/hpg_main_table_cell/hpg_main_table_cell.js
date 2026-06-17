import { LightningElement, api } from 'lwc';

export default class Hpg_main_table_cell extends LightningElement {

    @api row;
    @api index;
    @api column;
    @api tab;
    @api cellid;
    @api hassupragroup;

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

    isName = false;
    isText = false;
    isCurrency = false;
    isDate = false;
    isLink = false;
    isPercent = false;
    isEmpty = false;
    alignClass = 'slds-truncate';

    connectedCallback() {

        this.label = this.column.label || '';
        this.type = this.column.type || 'text';
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
                    this.level3GroupId = this.row['level3GroupId'] || '';
                    this.countryIfoId = this.row['countryIfoId'] || '';
                    this.taxpayerId = this.row['taxpayerId'];
                    this.row.clients.forEach(client => {
                        //this.clients.push({Id: client[6], Name: client[9], countryIfoId: client[7], taxpayerId: client[8]});
                        this.clients.push({customerId: client[6], customerName: client[9], countryIfoId: client[7], subGroupId: client[3], subGroupName: client[2], taxpayerId: client[8]});
                    });

                    if (this.row.hasOwnProperty('l3groups')) {
                        this.row.l3groups.forEach(l3group => {
                            this.l3groups.push({Id: l3group.level3GroupId, Name: l3group.level3GroupName})
                            l3group.clients.forEach(l3client => {
                                //this.clients.push({Id: l3client[6], Name: l3client[9], countryIfoId: l3client[7]});
                                this.clients.push({customerId: l3client[6], customerName: l3client[9], countryIfoId: l3client[7], subGroupId: l3client[3], subGroupName: l3client[2], taxpayerId: l3client[8]});
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

            this.value = this.row[this.index + 9];
            this.isText = this.type === 'text';
            this.isDate = this.type === 'date';
            this.isPercent = this.type === 'percent';
            this.isNumber = this.type === 'number';
            this.isCurrency = this.type === 'currency';
            this.isLink = this.onclick !== undefined;
            this.isEmpty = this.value && !this.value.isEmpty;
        }
    }

    @api
    handleClick(event) {

        if (event) {
            event.preventDefault();
        }

        const params = {
            groupId: this.groupId || '',
            groupName: this.groupName || '',
            subGroupId: this.subGroupId || '',
            subGroupName: this.subGroupName || '',
            clientId: this.clientId || '',
            clientName: this.clientName || '',
            level3GroupId: this.level3GroupId || '',
            level3GroupName: this.level3GroupName || '',
            clientType: (this.clientType || ''),
            generalGroupCode: (this.clientType === 'group') ? this.groupId : ((this.clientType === 'subgroup') ?  this.subGroupId: ((this.clientType === 'l3group') ?  this.level3GroupId : ''))
        };
        switch (this.tab) {
            case 'tcm':
                //extra info for TCM
                params.countryIfoId = this.countryIfoId || '';
                params.riskAnalystId = this.row[10] || '';
                params.updLmsclInternalRatgType = this.row[11] || '';
                params.assetAllocationActvyType = this.row[12] || '';
                params.assetAllocationSubSecType = this.row[13] || '';
                params.customerCounterpartiesCodesDesc = this.row[14] || '';
                params.updSmsclInternalRatgType = this.row[15] || '';
                params.currentRatingToolDate = this.row[16] || '';
                params.taxpayerId = this.taxpayerId || '';
                params.clients = this.clients || [];
                params.l3groups = this.l3groups || [];
                params.subgroups = [];
                params.cellid = this.cellid;
                params.hasSupraGroup = !!this.hassupragroup;
                var evt = new CustomEvent('selectclient', {
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

    get getClientId() {
        return (this.clientId) ? this.clientId : 'Unknown Id';
    }

    get isClient() {
        return this.clientType === 'client';
    }

    get isGroup() {
        return this.clientType === 'group' || this.clientType === 'subgroup' || this.clientType === 'l3group';
    }

    get currencyCode() {
        return typeof this.value === 'number' ? ' ' + this.currency : '';
    }

}