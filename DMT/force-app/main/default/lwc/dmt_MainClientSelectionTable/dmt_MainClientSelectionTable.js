import { LightningElement, track, api, wire } from 'lwc';
import { labels } from './dmt_MainClientSelectionTable_Labels';
import { getColumns, getVisibleColumns } from './dmt_MainClientSelectionTable_Columns.js';
import fetchInitialData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchInitialData';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';
import getStructureTypeByGroupCode from '@salesforce/apex/DMT_Client_Selector.getStructureTypeByGroupCode';
import getRecordCode from '@salesforce/apex/DMT_HPG_MainTableCustomController.getRecordCode';
import getSalesforceAccountIdsByCustomerIds from '@salesforce/apex/DMT_HPG_MainTableCustomController.getSalesforceAccountIdsByCustomerIds';

export default class Dmt_MainClientSelectionTable extends LightningElement {

    @api clientId;
    @api groupId;
    @api groupCode;
    @api labels = labels;
    @api columns;
    @api scroll;
    @api body;
    @api searchDate;
    @api countries = ['ALL'];
    @api clientPositionsType = 'Y';
    @api page = '1';
    @api pageSize = '500';
    @api selectedTab;
    @api groupName;
    @track showErrorMessage = false;

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
    showSpinner = true;
    _recordCode = {data: 'NONE'};
    _preselectedOrigin = false;
    _isSupraGroup = false;
    _isClientSalesforce = true;

    connectedCallback() {
        this.columns = getColumns(this.selectedTab);
        this.visibleColumns = getVisibleColumns(this.groupName);
        this.handleActiveTab(this.selectedTab);
    }

    renderedCallback() {
        if (this._expanded) {
            [... new Set(this._expanded)].forEach( group => {
                this.toggleGroup(group);
            });
        }
        if (this._filter) {
            this.filterResults({filter:this._filter});
        }
        this.isClientSalesforce();
        this.preselectOrigin();

    }

    //INIT
    @wire(getRecordCode, {clientId: '$clientId'}) _recordCode;

    @wire(fetchInitialData, {

        selectedTab: '$selectedTab',
        clientId: '$clientId',
        lCountries: '$countries',
        searchDate: '$searchDate',
        clientPositionsType: '$clientPositionsType',
        page: '$page',
        pageSize: '$pageSize',
        customerId: ''
      //  timestamp: Date.now()

    }) response ({error, data}) {

        this.handleActiveTab(this.selectedTab);
        this.selectedData = {groups: [], toplevel: {clients:[]}};
        this.groupedData = [];
        
        if (data) {
            
            if (data.success) {
                this.groupedData = this.groupedData.concat(data.data);
                if (data.pagination.totalPages > data.pagination.page) {
                    this.fetchMore(data.pagination.page + 1, data.pagination.pageSize);
                } else {
                    this.groupData();
                }
            } else {    
                console.error('ERROR loading initial data: ' + data.errorMessage);
                this.showErrorMessage = true;
                this.fireErrorEvent();
                this.showSpinner = false;
            }
            
        } else if (error) {
            this.error = error;
            console.error('ERROR:  ' + error);
            this.isLoading = false;
            this.showErrorMessage = true;
            this.fireErrorEvent();
            this.showSpinner = false;
        }
    };

    //Fetch Data Imperative
    @api
    fetchData(params) {
        this.showSpinner = true;
        fetchData(params).then( data => {
            if (data.success) {

                this.groupedData = this.groupedData.concat(data.data);
                if (data.pagination.totalPages > data.pagination.page) {
                    this.fetchMore(data.pagination.page + 1, data.pagination.pageSize);
                } else {
                    this.groupData();
                }
            } else {
                console.error('ERROR loading more data: ' + data.errorMessage);
                this.showErrorMessage = true;
                this.fireErrorEvent();
            }
        }).catch((error) => {
            console.error('ERROR FETCHING DATA: ' + error);
            this.showErrorMessage = true;
            this.fireErrorEvent();
        });
    }

    fireErrorEvent() {
        const event = new CustomEvent('lwcerror', {
            bubbles: true,
            composed: true,
            detail: {
                error: true,
                message: 'An error occurred while loading data.'
            }
        });
        this.dispatchEvent(event);
    }

    //MAP DATA TO COLUMNS
    mapData2Columns() {
        return new Promise((resolve, reject) => {  
            var selectedData = this.groupedData.map (
                row => this.columns.map (
                    column => row[column.field]
                )
            );
            resolve(selectedData);
        });
    }

    //GROUP RESULTS
    async groupData() {
        //await this.isClientSalesforce(null, this.groupCode);
        //return new Promise((resolve, reject) => {
        if(this.groupedData.length == 0) {
            const params = {
                groupId: this.groupCode || '',
                groupCode: this.groupCode || '',
                groupName: this.groupName || '',
                countryIfoId: '',
                taxpayerId:'',
                clientId: this.clientId || '',
                clientName: this.groupName || '',
                clientType: ('group' || ''),
                level3GroupName : this.groupName || '',
                isSupragroup : this._isSupraGroup,
                isClientSalesforce: this._isClientSalesforce,
                generalGroupCode: this.groupCode || ''
            };
            var evt = new CustomEvent('selectclient', {
                bubbles: true,
                composed: true,
                cancelable: true,
                detail: params
            });
            this.dispatchEvent(evt);
        }
        this.mapData2Columns().then( selectedData => {
            var position = [];
            var grouped = [];
            this.groupSubgroups(selectedData).then( data => {
                var i = 0;
                data.forEach( subGrouped => {
                    subGrouped.clients.forEach( function(client, index, object) {
                        if (client[5]) {

                            if (client[6] === this._recordCode.data) {
                                client[17] = true;
                                this._expanded.push(client[3]);
                                this._expanded.push(client[5]);
                            }

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
                    }.bind(this));
                    subGrouped['l3groups'] = grouped;
                });
                data.forEach( group => {
                    if (group.subGroupId === '-1000') {
                        this.selectedData.toplevel = group;                        
                    } else {
                        this.selectedData.groups.push(group);

                    }
                });
                this.showSpinner = false;
                // resolve true;
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

                    if (client[6] === this._recordCode.data) {
                        this._expanded.push(client[3]);
                    }

                    if (!position.hasOwnProperty(client[3])) {
                        position[client[3]] = i;
                        subGrouped[i] = {
                            name: (client[2]) ? client[2].toUpperCase() : 'GROUP UNDEFINED',
                            type: 'subgroup',
                            groupId: client[1],
                            groupName: client[0],
                            subGroupId: client[3],
                            subGroupName: client[2],
                            key: 'g' + i,
                            clients: [client]
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
    //Clients Supra/Group by Entific.
    getClientsByCountryArray(clients) {
        const result = [];

        clients.forEach(client => {
            const externalClientId = client[6]; // g_customer_id__c
            const country = c[6] ? c[6].substring(0, 2) : null;         // país

            if (!externalClientId || !country) {
                return;
            }

            if (!result.some(item => item.country === country)) {
                result.push({
                    country,
                    externalClientId,
                    salesforceId: null 
                });
            }
        });

        return result;
    }

    resolveSalesforceIds(clientsByGroup) {
        const customerIds = clientsByGroup
            .map(c => c.externalClientId)
            .filter(Boolean);

        return getSalesforceAccountIdsByCustomerIds({ customerIds })
            .then(mapResult => {
                return clientsByGroup.map(c => ({
                    country: c.country,
                    clientId: mapResult[c.externalClientId] || null
                }));
            });
    }


    handleActiveTab() {
        this.columns = getColumns(this.selectedTab);
        this.visibleColumns = getVisibleColumns(this.groupName);
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
        this.template.querySelector("c-dmt_fetcher").fireFetchMoreEvent(params);
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
        
        if (event.detail.clientType === 'subgroup' || event.detail.clientType === 'l3group') {
        const selectionObject = event.detail;
        const countryMap = {};

        selectionObject.clients.forEach(c => {
            const externalClientId = c.customerId;
            const country = c.customerId ? c.customerId.substring(0, 2) : null;;

            if (!externalClientId || !country) {
                return;
            }

            if (!countryMap[country]) {
                countryMap[country] = [];
            }

            countryMap[country].push(externalClientId);
        });

        const allExternalIds = [
            ...new Set(Object.values(countryMap).flat())
        ];

        getSalesforceAccountIdsByCustomerIds({
            customerIds: allExternalIds
        }).then(resultMap => {

            const clientsByCountry = [];

            Object.keys(countryMap).forEach(country => {
                const externalIds = countryMap[country];
                const found = externalIds.find(id => resultMap[id]);

                clientsByCountry.push({
                    country,
                    clientId: found ? resultMap[found] : null
                });
            });

            console.log(
                'ABS SUBGROUP FINAL:',
                JSON.stringify(clientsByCountry)
            );

            this.dispatchEvent(new CustomEvent('clientsAssociation', {
                bubbles: true,
                composed: true,
                cancelable: true,
                detail: {
                    clientsByCountry
                }
            }));
        });
    }


        let selected = this.template.querySelector('.isSelected');
        if (selected) {
            selected.classList.remove('isSelected');
        }
        this.template.querySelector(`[data-id="${event.detail.cellid}"]`).classList.add('isSelected');
    }

    selectGroup(event) {
        this.sendGroupEvent(event);
    }

    isClientSalesforce() {
        getStructureTypeByGroupCode({
            groupCode: this.groupCode
        }).then( response => {
          this._isSupraGroup = response.DES_Structure_Type__c == "Supragroup";
        }).catch((error) => {
          console.error('ERROR FETCHING DATA: ' + JSON.stringify(error))
          this._isClientSalesforce = false;
        });
    }

    sendGroupEvent(event) {
        const clients =
            this.selectedData?.toplevel?.clients || [];
        const countryMap = {};

        clients.forEach(c => {
            const externalClientId = c[6];
            const country = c[6] ? c[6].substring(0, 2) : null;
            if (!externalClientId || !country) {
                return;
            }

            if (!countryMap[country]) {
                countryMap[country] = [];
            }

            countryMap[country].push(externalClientId);
        });

        const allExternalIds = [
            ...new Set(Object.values(countryMap).flat())
        ];


        getSalesforceAccountIdsByCustomerIds({
            customerIds: allExternalIds
        }).then(resultMap => {

            console.log('ABS resultmap '+ JSON.stringify(resultMap));
            const clientsByCountry = [];

            Object.keys(countryMap).forEach(country => {
                const externalIds = countryMap[country];
                const found = externalIds.find(id => resultMap[id]);

                clientsByCountry.push({
                    country,
                    clientId: found ? resultMap[found] : null
                });
            });

            console.log(
                'ABS GROUP / SUPRAGROUP FINAL:',
                JSON.stringify(clientsByCountry)
            );

            this.dispatchEvent(new CustomEvent('clientsAssociation', {
                bubbles: true,
                composed: true,
                cancelable: true,
                detail: {
                    clientsByCountry
                }
            }));
        });
        if (event) {
            event.preventDefault();
        }

        let selected = this.template.querySelector('.isSelected');

        if (selected) {
            selected.classList.remove('isSelected');
        }

        this.template.querySelector(`th`).classList.add('isSelected');

        const params = {
            groupId: this.groupCode || '',
            groupCode: this.groupCode || '',
            groupName: this.groupName || '',
            countryIfoId: '',
            taxpayerId:'',
            clientId: this.clientId || '',
            clientName: this.groupName || '',
            clientType: ('group' || ''),
            level3GroupName : this.groupName || '',
            isSupragroup : this._isSupraGroup,
            isClientSalesforce: this._isClientSalesforce,
            generalGroupCode: this.groupCode || ''
        };
        var evt = new CustomEvent('selectclient', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: params
        });
        this.dispatchEvent(evt);

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
    get filter() {
        return this._filter;
    }

    set filter(text) {
        this.filterResults({filter:text});
    }

    get isSupragroup() {
        return this._isSupraGroup;
    }

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
                //Modify for CIBGLOBALD-1120
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

    preselectOrigin() {
        if (!this._preselectedOrigin) {
            var rows = this.template.querySelectorAll(`[data-id="mainTableRow"]`);
            if (rows.length > 0) {
                rows.forEach( row => {
                    if (row.outerText.includes(this._recordCode.data)) {
                        var cellid = row.innerHTML.toString().match(/data-id="(key\d+)"/)[1];
                        row.scrollIntoView({
                            behavior: "smooth",
                            block: "end",
                            inline: "nearest"
                        });
                        this.selectRow({detail:{cellid: cellid}});
                        var cell = this.template.querySelector('c-dmt_client_table_cell[data-id="' + cellid + '"]');
                        if (cell) {
                            cell.handleClick();
                        }
                        this._preselectedOrigin = true;
                    };
                });
                if (!this._preselectedOrigin) {
                    this.selectGroup(null);
                    this._preselectedOrigin = true;
                }
            }
        }
    }

}