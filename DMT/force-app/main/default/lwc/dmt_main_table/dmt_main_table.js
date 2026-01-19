import { LightningElement, track, api, wire } from 'lwc';
import { labels } from './dmt_main_table_labels.js';
import { getColumns, getVisibleColumns, getGrillFields } from './dmt_main_table_columns.js';
import callExtensionImperative from '@salesforce/apex/DMT_MainTableCallableClass.callExtensionImperative';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DISABLE_ACTIONS_CLIENT= 'disableactions';

export default class dmt_main_table extends LightningElement {

    @api groupId;
    @api groupCode;
    @api labels = labels;
    @api columns;
    @api scroll;
    @api body;
    @api searchDatevalue;
    searchDate;
    @api countries = ['ALL'];
    @api clientPositionsType = 'Y';
    @api page = '1';
    @api pageSize = '5000';
    @api selectedTab;
    @api grillField = 'una';
    @api recordId;
    @api filterClientsVariable;
    @api filterClientsOperator;
    @api filterClientsValue;
    @api groupsSelected  = new Map();
    @api clientCouldChange = false;

    @api
    get priorselectedRows() {
        return this._priorselectedRows;
    }

    set priorselectedRows(value) {
        this._priorselectedRows = this.normalizeToArray(value);

        this.mainHolderSelectRows = this._priorselectedRows
            .filter(item => item.customerId !== null)     // filter -> eliminar null
            .map(item => item.customerId)   // map -> transformar

        this.mainHolderCustomer = this._priorselectedRows[0]?.mainHolder;
    }

    @api filterClients;

    mainHolderSelectRows;
    mainHolderCustomer;

    currencyvalue;
    filtergroupedData;
    groupSize;
    priorgroupSize;
    //@api customData = {"data":[{"countryId":"ES","countryIfoId":"IT","customerConsmIndType":"Y","customerId":"ES0182049161248","customerName":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX","groupId":"G00000000000200","groupName":"dc2576719e904b1a07b7c189ebca5064befd2065","subGroupId":"G20170809154317","subGroupName":"Subgrupo de ejemplo","taxpayerId":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"},{"countryId":"ES","countryIfoId":"IT","customerConsmIndType":"Y","customerId":"ES0182049161248","customerName":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX","groupId":"G00000000000200","groupName":"dc2576719e904b1a07b7c189ebca5064befd2065","subGroupId":"G20170809154317","subGroupName":"Subgrupo de ejemplo","taxpayerId":"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"}
    //],"pagination":{"links":{"first":"/risk-position/v0/global-position","last":"/risk-position/v0/global-position?paginationKey=LAST","next":"/risk-position/v0/global-position?paginationKey=2&pageSize=100","previous":"/risk-position/v0/global-position?paginationKey=0&pageSize=100"},"page":1,"pageSize":100,"totalElements":44,"totalPages":1},"success":true};
    customDatavalue;
    @api multipleRowSelection;
    @api showSelectRows;
    @track data;
    @track selectedData = {
        groups: [],
        toplevel: {clients:[]}
    };
    key=0;
    visibleColumns;
    groupedData = [];
    _expanded = [];
    _doubleLineHeader = false;
    _notfound = false;
    _rendered = false;
    _callbackNumber = 0;
    _filter = '';
    clientIdvalue;
    groupRow = [];
    clientCount = 0;
    clientsGrouped = [];
    initcomponent = true;
    newselectedrows;
    clientPositionsTypevalue;
    showSpinner = true;
    errorLoading = false;

    normalizeToArray(value) {
        if (Array.isArray(value)) return value.filter(v => v);
        if (value && typeof value === 'object') return [value];
        return [];
    }

    @api
    get  customData() {
      return this.customDatavalue;
    }
  
    set customData(value) {
       
        if (value && Array.isArray(value)) {
            value.forEach(record => {
                record.selectedRows = this.normalizeToArray(record.selectedRows);
                record.priorselectedRows = this.normalizeToArray(record.priorselectedRows);
                record.firstClients = this.normalizeToArray(record.firstClients); // Por si en alguna parte se itera
            });
        }
        this.customDatavalue = value;
        this.getReactiveData();
    }

    @api
    get  apexMethod() {
      return this.apexMethodvalue;
    }
  
    set apexMethod(value) {
        this.apexMethodvalue = value;
    }

    @api
    get  nonSelect() {
      return this.nonSelectvalue;
    }
  
    set nonSelect(value) {
        const container = 'container';
        if(value == true){
            this.template.querySelector(`[data-id=${container}]`)?.classList.add('nonselect');
        }else{
            this.template.querySelector(`[data-id=${container}]`)?.classList.remove('nonselect');
        }
    }

    @api
    get  currency() {
      return this.currencyvalue;
    }
  
    set currency(value) {
        this.currencyvalue = value;
    }

    @api
    get  clientId() {
      return this.clientIdvalue;
    }
  
    set clientId(value) {
        this.clientIdvalue = value;
        //COndicional only for serarch in the modal of TCM Opp Mitigants
        this.clientCouldChange?  this.handleApexMethod() : null;
    }

    @api
    get  searchDate() {
      return this.searchDatevalue;
    }
  
    set searchDate(value) {
        this.searchDatevalue = value;
        this.handleApexMethod();
    }


    handleApexMethod() {
        try {
            this.showSpinner = true;
            this.errorLoading = false;
            var args = {

                     selectedTab: this.selectedTab,
                     clientId: this.clientId,
                     lCountries: this.countries,
                     searchDate: this.searchDatevalue,
                     clientPositionsType: this.clientPositionsType,
                     page: this.page,
                     pageSize: this.pageSize,
                     timestamp: Date.now()
            
                 };
            callExtensionImperative({ action: this.apexMethodvalue.split('.')[1],  auxiliarClass: this.apexMethodvalue.split('.')[0],  args: args }).then( data => {
                if (data.success) {
                    this.showSpinner = true;
                    this.errorLoading = false;
                    this.groupedData = this.groupedData.concat(data.data);
                    this.groupedData = this.handleRatingExpiration();
                        if(this.filterClientsVariable){
                            this.filtergroupedData = [];
                            this.groupedData.forEach( client => {
                            let customerCode = client.customerId;
                            if((client.subGroupId === this.filterClientsValue || client.groupId === this.filterClientsValue) && customerCode.startsWith(this.booking)){
                                this.filtergroupedData.push(client);
                            }
                            });
                        }
                        this.groupData();
                    //}
                } else {
                    setTimeout(5000);
                    this.showSpinner = false;
                    this.errorLoading = true;
                    
                    this.dispatchEvent(new CustomEvent(DISABLE_ACTIONS_CLIENT, {
                        bubbles: true,
                        composed: true,
                        cancelable: true
                    }));

console.error('[handleApexMethod] ERROR loading more data: ' + data.errorMessage);
                    console.error(`[handleApexMethod] ERROR loading more data: Apex Method '${this.apexMethodvalue}':`, {
                        errorMessage: data.errorMessage,
                        apexResponse: data
                    });
                }
            }).catch((error) => {
                setTimeout(5000);
                this.showSpinner = false;
                this.errorLoading =true;
                console.error('[handleApexMethod] ERROR FETCHING DATA: ' + error)
            });
        } catch (error) {
            this.records = undefined;
            this.error = error;
        }
      }

    connectedCallback() {
        this.columns = getColumns(this.selectedTab);
        this.visibleColumns = getVisibleColumns(this.selectedTab);
        this.handleActiveTab(this.selectedTab);
        this.groupSize = this.template.querySelectorAll('.clientName').length;

    }

    renderedCallback() {

        this.selectedData.groups.forEach( group => {
            this.toggleGroup(group.subGroupId);
        });
         if (this._filter) {
             this.filterResults({filter:this._filter});
         }
        if (this.scroll > 0) {
            this.scrollTo(this.scroll);
        }
        
        if (this.priorselectedRows && this.priorselectedRows.length > 0 && this.priorselectedRows[0].customerId !== 'null') {
            this.priorselectedRows.forEach(selectedrow => {
                if (this.template.querySelector(`[data-id=${selectedrow.customerId}]`)) {
                    var selectedCells = this.template.querySelectorAll(`[data-id="${selectedrow.customerId}"]`);
                    for (let i = 0; i < selectedCells.length; i++) {
                        selectedCells[i].classList.add('isSelected');
                    }
                }
            });
        }
        
        var allCells = this.template.querySelectorAll(`c-dmt_main_table_cell`);
        allCells.forEach(element => {
            if(element.title == 'displaytext' || element.classList.value.includes('isSelected')){
                element.classList.remove('showcellclass');
            }
        });

        var allSelectedCells = this.template.querySelectorAll(`td`);
        allSelectedCells.forEach(element => {
            if(element.classList.value.includes('isSelected')){
                element.querySelector(`c-dmt_main_table_cell`).classList.remove('showcellclass');
            }
        });
        if(this.filterClients == 'true'){
            this.filterClientsResults();
        }
         if(this.booking){
             var notBooking = this.template.querySelectorAll(`td:not([data-id^="${this.booking}"])`);
             notBooking.forEach(el => el.classList.add('notfound'));
         }

        this.initcomponent = false;
        this.adjustScrollLines();
    }

    getReactiveData(){
        this.handleActiveTab(this.selectedTab);
        this.selectedData = {groups: [], toplevel: {clients:[]}};
        this.groupedData = [];

                this.groupedData = this.groupedData.concat(this.customDatavalue);
                if (1 === 0) {
                    this.fetchMore(data.pagination.page + 1, data.pagination.pageSize);
                } else {
                    this.groupData();
                }
    }

    // //Fetch Data Imperative
    @api
    fetchData(params) {
         fetchData(params).then( data => {
             if (data.success) {
                 this.groupedData = this.groupedData.concat(data.data);
                if (data.pagination.totalPages > data.pagination.page) {
                     this.fetchMore(data.pagination.page + 1, data.pagination.pageSize);
                 } else {
                     this.groupData();
                 }
             } else {
                 console.error('[fetchData] ERROR loading more data: ' + data.errorMessage);
             }
         }).catch((error) => {
             console.error('[fetchData] ERROR FETCHING DATA: ' + error)
         });
     }

    //MAP DATA TO COLUMNS
    mapData2Columns() {
        return new Promise((resolve, reject) => {
            switch (this.selectedTab) {
                case 'consumption':
                    var riskType = getGrillFields(this.grillField).field;
                    var selectedData = this.groupedData.map (
                        row => this.columns.map (
                            (column, index) => (index < 10) ? row[column.field] : (row.classConsumptions) ? row.classConsumptions.find(con => con.consumptionLastLevelId === column.field) ? row.classConsumptions.find(con => con.consumptionLastLevelId === column.field)[riskType] : null : null
                        )
                    );
                    //selectedData = helper.removeEmptyColumns(component, helper, selectedData);
                    break;
                case 'connectedClients':
                    var riskType = 'unavailableRiskAmount';
                    var selectedData = this.groupedData.map (
                        row => this.columns.map (
                            (column, index) => (index < 10) ? row[column.field] : (row.detailConsumptions) ? row.detailConsumptions.find(con => con.consumptionLastLevelId === column.field) ? row.detailConsumptions.find(con => con.consumptionLastLevelId === column.field)[riskType] : null : null
                        )
                    );
                    break;
                default: {
                    if(this.filterClientsVariable){
                        var selectedData = this.filtergroupedData.map (
                            row => this.columns.map (
                                column => row[column.field]
                            )  
                        );
                            selectedData.forEach( client => {
                              client.push(selectedData.length);
                            });
                          this.fullselectedData = this.groupedData.map (
                             row => this.columns.map (
                                 column => row[column.field]
                             )
                         );
                         this.fullselectedData.forEach( client => {
                             client.push(this.fullselectedData.length);
                           });
                    }else{
                    var selectedData = this.groupedData.map (
                        row => this.columns.map (
                            column => row[column.field]
                        )
                    );
                    selectedData.forEach( client => {
                        client.push(selectedData.length);
                      });
                    }
                    }
                }
                resolve(selectedData);
        });
    }

    //GROUP RESULTS
    groupData() {
        //return new Promise((resolve, reject) => {
        this.mapData2Columns().then( selectedData => {
            var position = [];
            var grouped = [];
            this.groupSubgroups(selectedData).then( data => {
                var i = 0;
                data.forEach( subGrouped => {
                    subGrouped.clients.forEach( function(client, index, object) {
                        if (client[5]) {
                            if (!position.hasOwnProperty(client[5])) {
                                position[client[5]] = i;
                                grouped[i] = {
                                    name: client[4],
                                    type: 'l3group',
                                    groupId: client[1],
                                    groupName: client[0],
                                    subGroupId: client[3],
                                    subGroupName: client[2],
                                    level3GroupId: client[5],
                                    level3GroupName: client[4],
                                    clients: [client]
                                };
                                i++;
                            } else {
                                var pos = position[client[5]];
                                grouped[pos].clients.push(client);
                            }
                            subGrouped.clients.splice(index, 1);
                            subGrouped['level3'] = true;
                        }
                    });
                    subGrouped['l3groups'] = grouped;
                });
                data.forEach( group => {
                    if (group.subGroupId === '-1000') {
                        this.selectedData.toplevel = group;
                    } else {
                        this.selectedData.groups.push(group);

                    }
                })
                this.showSpinner = false;
            });
        });
        //});
        
    }

    //GROUP SUBGROUPS
    groupSubgroups(data) {
        return new Promise((resolve, reject) => {
            var position = []
            var subGrouped = [];
            var i = 0;
            data.forEach( client => {
                if (client[6]) {
                    if (!position.hasOwnProperty(client[3])) {
                        position[client[3]] = i;
                        subGrouped[i] = {
                            name: (client[2]) ? client[2].toUpperCase() : 'GROUP UNDEFINED',
                            type: 'subgroup',
                            groupId: client[1],
                            groupName: client[0],
                            subGroupId: client[3],
                            subGroupName: client[2],
                            clients: [client],
                            key: 'g' + i
                        };
                        i++;
                    } else {
                        var pos = position[client[3]];
                        subGrouped[pos].clients.push(client);
                    }
                }
            });
            subGrouped.sort( function( a, b ) {
                return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
            }).sort( function( a, b ) {
                return a.subGroupId > b.subGroupId ? -1 : a.subGroupId < b.subGroupId ? 1 : 0;
            });;
            resolve(subGrouped);
        });
    }

    handleActiveTab() {
        this.columns = getColumns(this.selectedTab);
        this.visibleColumns = getVisibleColumns(this.selectedTab);
        this._doubleLineHeader = (this.selectedTab === 'consumption' || this.selectedTab === 'connectedClients');
    }

    handleScroll (event) {
        this.scroll = event.target.scrollTop;
    }

    fetchMore(page, pageSize) {
        const params = {
            selectedTab: this.selectedTab,
            clientId: this.clientId,
            lCountries: this.countries,
            searchDate: this.searchDate,
            clientPositionsType: this.clientPositionsType,
            page: page,
            pageSize: pageSize,
            bubbles: false
        };
        this.template.querySelector("c-hpg_fetcher").fireFetchMoreEvent(params);
    }

    handleFetchMoreEvent(event) {
        const params = {
            selectedTab: event.detail.selectedTab,
            clientId: event.detail.clientId,
            lCountries: event.detail.countries,
            searchDate: event.detail.searchDate,
            clientPositionsType: event.detail.clientPositionsType,
            page: event.detail.page,
            pageSize: event.detail.pageSize
        }
        this.fetchData(params);
    }

    selectRow(event) {
            if(this.showSelectRows === 'true'){
                if(this.multipleRowSelection === 'true'){   
                    if(event.detail.clientType.includes('group')){
                        let rows = this.template.querySelectorAll(`td[id="${event.detail.subGroupId}"]`);
                        if (this.template.querySelector(`[data-id="${event.detail.cellid}"]`).classList.value.includes('isSelected')) {
                            rows.forEach( row => {
                                row.classList.remove('isSelected');
                            })
                            this.template.querySelector(`[data-id="${event.detail.cellid}"]`).classList.remove('isSelected');
                            this.groupsSelected.set(event.detail.subGroupId, false);
                        }else{
                            rows.forEach( row => {
                                row.classList.add('isSelected');
                            })
                            this.template.querySelector(`[data-id="${event.detail.cellid}"]`).classList.add('isSelected');
                            this.groupsSelected.set(event.detail.subGroupId, true);
                        }
                    }else{
                        var selectedCells = this.template.querySelectorAll(`[data-id="${event.detail.customerId}"]`);
                        if (this.template.querySelector(`[data-id="${event.detail.customerId}"]`).classList.value.includes('isSelected')) {
                           
                            for (let i = 0; i < selectedCells.length; i++) {
                                selectedCells[i].classList.remove('isSelected');
                                if(i != 0 && selectedCells[i].querySelector(`c-dmt_main_table_cell`).title != 'displaytext'){
                                     selectedCells[i].querySelector(`c-dmt_main_table_cell`).classList.add('showcellclass');
                                }
                            }
                        }else{
                            for (let i = 0; i < selectedCells.length; i++) {
                                selectedCells[i].classList.add('isSelected');
                                if(selectedCells[i].querySelector(`c-dmt_main_table_cell`).title != 'displaytext'){
                                    selectedCells[i].querySelector(`c-dmt_main_table_cell`).classList.remove('showcellclass');
                                }                               
                            }
                        }
                    }   
                }else{
                    let selected = this.template.querySelector('.isSelected');
                    if (selected) {
                    selected.classList.remove('isSelected');
                    }
                    this.template.querySelector(`[data-id="${event.detail.customerId}"]`).classList.add('isSelected');
                } 
            }
    }

    handleToggleGroup(event) {
        event.preventDefault();
        let group = event.target.id.split('-')[0]
        this.toggleGroup(group);
    }

    toggleGroup(group) {
        let rows = this.template.querySelectorAll('[data-id="mainTableRow"]');
        if (!this._filter) {
            rows.forEach( row => {
                if (row.id.split('-')[0] === group) {
                    if (row.className.includes(' collapsed')) {
                        row.classList.remove('collapsed');
                        row.classList.add('expanded');
                        this._expanded.push(group);
                    } else if (row.className.includes('clientcollapsed')) {
                        row.classList.remove('clientcollapsed');
                        row.classList.add('clientexpanded');
                    } else if (row.className.includes('clientexpanded')) {
                        row.classList.remove('clientexpanded');
                        row.classList.add('clientcollapsed');
                    } else {
                        row.classList.remove('expanded');
                        row.classList.add('collapsed');
                        this._expanded = this._expanded.filter(id => id !== group)
                    }
                    this._expanded = [... new Set(this._expanded)]; //remove duplicates in array
                }
            });
            let l3rows = this.template.querySelectorAll(`[data-subgroup="${group}"]`);
            l3rows.forEach(row => {
                if (this._expanded.includes(group)) {
                    row.classList.remove('l3collapsed');
                } else {
                    row.classList.add('l3collapsed');
                }
            });
        }
    }

    @api
    get nextIteratorKey() {
        if(this.selectedData.groups.length !== 0 && this.key < 1){
            for (let i = 0; i < this.selectedData.groups.length; i++) {
                this.groupRow.push(this.clientCount);
                this.clientsGrouped.push(this.selectedData.groups[i])
                this.clientCount += 1;
                if(this.selectedData.groups[i].l3groups){
                    for (let j = 0; j < this.selectedData.groups[i].l3groups.length; j++){
                        this.clientCount += 1;
                        this.clientsGrouped.push(this.selectedData.groups[i].l3groups[j]);
                        for (let k = 0; k < this.selectedData.groups[i].l3groups[j].clients.length; k++){
                            this.clientCount += 1;
                            this.clientsGrouped.push(this.selectedData.groups[i].l3groups[j].clients[k]);
                        }
                    }
                }
                if(this.selectedData.groups[i].clients){
                    for (let j = 0; j < this.selectedData.groups[i].clients.length; j++){
                        this.clientCount += 1;
                        this.clientsGrouped.push(this.selectedData.groups[i].clients[j]);
                    }
                }
                
            }
        }
            for (let i = 0; i < this.selectedData.toplevel.clients.length; i++) {
                this.clientsGrouped.push(this.selectedData.toplevel.clients[i])
            }
        if(!this.groupRow.includes(this.key)){
            
            try{
                if(this.clientsGrouped[this.key]){
                    this.customerId = this.clientsGrouped[this.key][6];
                }else{
                    this.customerId = this.clientsGrouped[this.key - 2][6];
                }
            }catch{
                
            }    
        }
        this.key += 1;               
        return 'keytr' + this.key;
    }

    @api
    get iteratorKey() {
        return 'key' + this.key;
    }


    @api
    get doubleLineHeader() {
        return this._doubleLineHeader;
    }

    @api
    get selectedGrillField() {
        return getGrillFields(this.grillField).label;
    }

    @api
    get filter() {
        return this._filter;
    }
    set filter(text) {
        //if(text !== '{filter}'){console.log('received in ' + text)
            this.filterResults({filter:text});
        //}
    }

    // @api
    // get filterClients() {
    //     return this.filterClientsvalue;
    // }
    // set filterClients(value) {
    //     if(value == 'true'){
    //         this.filterClientsResults();
    //     }else{
    //         var allClients = this.template.querySelectorAll(`td:not(.isSelected)`);
    //         allClients.forEach(el => el.classList.remove('notfound'));
    //         if(value == 'Y' && this.clientPositionsType != 'Y' && this.selectedData.length){
    //             this.clientPositionsType = 'Y';
    //             this.selectedData = {
    //                 groups: [],
    //                 toplevel: {clients:[]}
    //             };
    //             this.groupedData = [];
    //             this.filtergroupedData = [];
    //             this.handleApexMethod();
    //             this.nextIteratorKey ++;
    //             this.iteratorKey ++;
    //         }
    //         if(value == 'Y/N' && this.clientPositionsType != 'Y/N' && this.selectedData.length){
    //             this.clientPositionsType = 'Y/N';
    //             this.selectedData = {
    //                 groups: [],
    //                 toplevel: {clients:[]}
    //             };
    //             this.groupedData = [];
    //             this.filtergroupedData = [];
    //             this.handleApexMethod();
    //             this.nextIteratorKey ++;
    //             this.iteratorKey ++;
    //         }
    //     }
    // }

    filterClientsResults(){
        var notSelected = this.template.querySelectorAll(`td:not(.isSelected)`);
        notSelected.forEach(el => el.classList.add('notfound'));
    }

    @api booking;


    @api
    filterResults(filter) {
        this._filter = (filter && filter.filter !== '{filter}') ? filter.filter || '' : '';
        var rows = this.template.querySelectorAll(`[data-id="mainTableRow"]`);
        var groups = [];
        rows.forEach( row => {
            if (!this._filter) {
                row.classList.remove('found');
                row.classList.remove('notfound');
            } else if (row.outerText.toUpperCase().includes(this._filter.toUpperCase())) {
                row.classList.add('found');
                row.classList.remove('notfound');
                if (row.id.includes('G')) {
                    groups.push(row.id.split('-')[0]);
                }
                if (row.getAttribute('data-subgroup')) {
                    groups.push(row.getAttribute('data-subgroup'));
                }
            } else {
                
                 if(this._filter == 'emptyFilter'){
                    row.classList.add('found');
                    row.classList.remove('notfound');
                    if (row.id.includes('G')) {
                        groups.push(row.id.split('-')[0]);
                    }
                    if (row.getAttribute('data-subgroup')) {
                        groups.push(row.getAttribute('data-subgroup'));
                    }
                }else{
                    row.classList.add('notfound');
                    row.classList.remove('found');
                }
            }
            row.classList.remove('foundGroup');
        });
        [... new Set(groups)].forEach( groupid => {
            let groupFound = this.template.querySelector(`[id^="${groupid}"].group`);
            if (groupFound) {
                groupFound.classList.remove('notfound');
                groupFound.classList.add('found');
                groupFound.classList.add('foundGroup');
            }
        });
    }

    @api
    changeCurrency(params) {
        console.log(params);
    }

    scrollTo(pos) {
        console.log('scroll to', pos);
    }

    handleRatingExpiration(){
        var today = new Date();
        var dataRating = JSON.parse(JSON.stringify(this.groupedData));
        var ratingExpirationList = [];
        dataRating.forEach( client => {
            var scaleLast = new Date(client.scaleLastUpdDate);
            var ratingValidity = new Date(client.ratingValidityStartDate);
            var currentRating = new Date(client.currentRatingToolDate);
            var ffssRegulatory = new Date(client.ffssRegulatoryRatingDate);
            if(client.scaleLastUpdDate){
                if(Date.parse(today) - scaleLast >= 31556952000 ){
                    //client.expirationRatingDate = scaleLast.setMonth(12).toString();
                    ratingExpirationList.push((scaleLast.getTime() + 31556952000).toString());
                }else{
                    //client.expirationRatingDate = ratingValidity.setMonth(19).toString();
                    ratingExpirationList.push((ratingValidity.getTime() + 49965174000).toString());
                }
            }
            else{
                client.updSmsclInternalRatgType = client.smsclInternalRatgType;
                if(Date.parse(today) - currentRating >= 31556952000 ){
                    //client.expirationRatingDate = currentRating.setMonth(12).toString();
                    ratingExpirationList.push((currentRating.getTime() + 31556952000).toString());
                }
                else{
                    //client.expirationRatingDate = ffssRegulatory.setMonth(19).toString();
                    ratingExpirationList.push((ffssRegulatory.getTime() + 49965174000).toString());
                }
            }
            client.expirationRatingDate = Math.max(ratingExpirationList)
            ratingExpirationList = [];
        })
        //console.log('in rating data',JSON.stringify(ratingExpirationList));
        return dataRating
	}
    
    adjustScrollLines(){

        let lineLeft = this.template.querySelector('.lineLeft');
        let lineRight = this.template.querySelector('.lineRight');
        let table = this.template.querySelector('[data-id="mainTable"]');      

        if(table && lineLeft && lineRight){
            lineLeft.style.height = table.offsetHeight + 'px';
            lineRight.style.height = table.offsetHeight + 'px';
        }
    }
    scrollLeft(){
        const scrollContainer = this.template.querySelector('.slds-scrollable');
        scrollContainer.scrollBy({ left: -120, behavior: 'smooth' });
        
    }
    scrollRight(){
        const scrollContainer = this.template.querySelector('.slds-scrollable');
        scrollContainer.scrollBy({ left: 120, behavior: 'smooth' });
        
    }
    showArrowLeft(event) {
        const arrow = event.currentTarget.querySelector('.arrowCustom');
        arrow.style.top = (event.offsetY -24) + 'px'; 
        arrow.style.display = 'block';
        arrow.style.right = '7px';
    }

    showArrowRight(event) {
        const arrow = event.currentTarget.querySelector('.arrowCustom');
        arrow.style.top = (event.offsetY -24) + 'px'; 
        arrow.style.display = 'block';
        arrow.style.left = '7px';
    }

    hideArrow(event) {
        const arrow = event.currentTarget.querySelector('.arrowCustom');
        arrow.style.display = 'none';
    }

    // Helper to get cells by customerId
    getCellsByCustomer(customerId) {
        return this.template.querySelectorAll(
            `c-dmt_main_table_cell[data-customerid="${customerId}"]`
        );
    }

    // Helper to update the main holder (deactivate old, update new, activate new)
    updateMainHolder(newCustomerId) {
        
        if (this.mainHolderCustomer && this.mainHolderCustomer !== newCustomerId) {
            this.getCellsByCustomer(this.mainHolderCustomer).forEach(cell => cell.deactiveMainHolder());
        }
        this.mainHolderCustomer = newCustomerId;
        this.getCellsByCustomer(newCustomerId).forEach(cell => cell.activateMainHolderByDefault());
    }

    //  Main handler to update the main holder (deactivate old, update new, activate new)
    handleMainHolderSelection(event) {
        const { context, customerId, initComponent } = event.detail;

        switch (context) {
            case 'ADD_ACCOUNT':
                // Add new account if not already in the list
                if (!this.mainHolderSelectRows.includes(customerId)) {
                    this.mainHolderSelectRows = [...this.mainHolderSelectRows, customerId];
                } 
                break;

            case 'REMOVE_ACCOUNT':
                // Remove account and handle if it was the current mainHolder
                this.mainHolderSelectRows = this.mainHolderSelectRows.filter(id => id !== customerId);

                if (this.mainHolderCustomer === customerId || this.mainHolderCustomer == '') {
                    // Update to the next available mainHolder (or empty if none)
                    const nextCustomer = this.mainHolderSelectRows[0] || "";
                    this.updateMainHolder(nextCustomer);

                }
                break;

            case 'UPDATE_MAIN_HOLDER':
                // Explicit update of the main holder
                if (this.mainHolderSelectRows.includes(customerId)) {
                    this.updateMainHolder(customerId);
                }
                break;
            case 'CHECK_LAST_MAIN_HOLDER':
                if(this.mainHolderSelectRows.length > 0 && this.mainHolderCustomer === customerId){
                    this.getCellsByCustomer(customerId).forEach(cell => cell.deactiveMainHolder());
                    this.mainHolderCustomer = '';
                    this.showWarningToast(this.labels.DMT_Warning_Main_Holder, this.labels.DMT_WarningToastTitle);
                }  
                break;
        }

        // If only one account remains → force it as default mainHolder
        if (this.mainHolderSelectRows.length === 1) {
            const onlyCustomerId = this.mainHolderSelectRows[0];
            if (this.mainHolderCustomer && this.mainHolderCustomer !== onlyCustomerId) {
                this.getCellsByCustomer(this.mainHolderCustomer).forEach(cell => cell.deactiveMainHolder());
            }

            this.updateMainHolder(onlyCustomerId);
        }

        //  Dispatch update event
        this.dispatchMainHolderUpdate(initComponent);

    }

    
    dispatchMainHolderUpdate(initComponent) {
            const detail = {
                value: this.mainHolderCustomer,
                context:  'mainHolder',
                initComponent : initComponent,
                error: this.mainHolderCustomer === '' && this.mainHolderSelectRows.length > 0 ,
            };
            this.dispatchEvent(new CustomEvent('inputfielddmt', {
                bubbles: true,
                composed: true,
                cancelable: true,
                detail
            })); 
    }
    
    showWarningToast(message, title = 'Advertencia') {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'warning',
                mode: 'dismissable'
            })
        );
    }

}