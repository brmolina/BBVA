import { LightningElement, track, api, wire } from 'lwc';
import { labels } from './dMT_main_table_products_labels.js';
import { getColumns, getVisibleColumns } from './dMT_main_table_products_columns.js';
import fetchInitialData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchInitialData';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSelectedClients from '@salesforce/apex/DMT_TaxonomyMultipleProducts.saveSelectedClients';

const DISABLE_ACTIONS_CLIENT = 'disableactions';

export default class dmt_main_table extends LightningElement {
    // Flexcard properties
    clientIdvalue;
    clientPositionsTypevalue;
    currencyvalue;
    _filter = '';
    searchDate;
    @api productSelectedRows = [];
    selectedClients = [];
    @track showFooter = false; // Mostrar/ocultar footer

    @api clientId;

    @api clientPositionsType = 'Y';

    @api
    get currency() {
        return this.currencyvalue;
    }

    set currency(value) {
        this.currencyvalue = value;
    }

    @api filterClientsOperator;
    @api filterClientsValue;
    @api filterClientsVariable;
    @api multipleRowSelection;

    @api
    get priorselectedRows() {
        return this._priorselectedRows;
    }

    set priorselectedRows(value) {
        this._priorselectedRows = this.normalizeToArray(value);
        this.selectedClients = this._priorselectedRows;
        this.mainHolderSelectRows = this._priorselectedRows
            .filter(item => item.customerId !== null)
            .map(item => item.customerId);
    }

    @api searchDatevalue;

    @api
    get searchDate() {
        return this.searchDatevalue;
    }

    set searchDate(value) {
        this.searchDatevalue = value;
    }

    @api selectedTab = 'tcmotherlines';
    @api showSelectRows;
    @api filterClients;


    @api booking; // eliminado del uso
    @api priorityId;
    @api lineId;
    @api groupAccount;
    // Component properties
    labels = labels;
    mainHolderSelectRows;
    @api mainHolderCustomer;
    filtergroupedData;
    groupSize;
    priorgroupSize;
    customDatavalue;
    data;
    selectedData = {
        groups: [],
        toplevel: { clients: [] }
    };
    key = 0;
    visibleColumns;
    groupedData = [];
    _expanded = [];
    _doubleLineHeader = false;
    _notfound = false;
    _rendered = false;
    _callbackNumber = 0;
    groupRow = [];
    clientCount = 0;
    clientsGrouped = [];
    initcomponent = true;
    showSpinner = true;
    errorLoading = false;
    apexMethodvalue = 'DMT_ExtensionCallableMainTable.fetchData';

    @api groupId;
    @api groupCode;
    @api columns;
    @api scroll;
    @api body;
    @api countries = ['ALL'];
    @api page = '1';
    @api pageSize = '5000';
    @api grillField = 'una';
    @api recordId;
    @api groupsSelected = new Map();

    normalizeToArray(value) {
        if (Array.isArray(value)) return value.filter(v => v);
        if (value && typeof value === 'object') return [value];
        return [];
    }

    @wire(fetchInitialData, {
        selectedTab: '$selectedTab',
        clientId: '$clientId',
        lCountries: '$countries',
        searchDate: '$searchDate',
        clientPositionsType: '$clientPositionsType',
        page: '$page',
        pageSize: '$pageSize',
        timestamp: Date.now()
    })
    response({ error, data }) {
        this.handleActiveTab(this.selectedTab);
        this.selectedData = { groups: [], toplevel: { clients: [] } };
        this.groupedData = [];

        if (data) {
            if (data.success) {
                this.priorData = JSON.parse(JSON.stringify(data.data));
                var finalData = [];
                if(this.productSelectedRows && this.productSelectedRows.length > 0 && Array.isArray(this.productSelectedRows)){
                    this.priorData.forEach(client => {
                    this.productSelectedRows?.forEach(selected => {
                        if (selected.customerId == client.customerId) {
                            finalData.push(client);
                        }
                    });
                });
                this.groupedData = this.groupedData.concat(finalData);
                this.groupData();
                }else{
                    this.groupedData = this.groupedData.concat(data.data);
                    this.groupData();
                }
                
            } else {
                console.error('ERROR loading initial data: ' + data.errorMessage);
                this.showSpinner = false;
            }
        } else if (error) {
            this.error = error;
            console.error('error ' + error);
            this.isLoading = false;
            this.showSpinner = false;
        }
    }

    // Fetch Data Imperative
    @api
    fetchData(params) {
        this.showSpinner = true;
        fetchData(params)
            .then(data => {
                if (data.success) {
                    this.groupedData = this.groupedData.concat(data.data);
                    this.groupData();
                } else {
                    console.error('ERROR loading more data: ' + data.errorMessage);
                }
            })
            .catch(error => {
                console.error('ERROR FETCHING DATA: ' + error);
            });
    }

    connectedCallback() {
        console.log('Connected Callback de DMT_main_table_products');
        this.columns = getColumns(this.selectedTab);
        this.visibleColumns = getVisibleColumns(this.selectedTab);
        this.handleActiveTab(this.selectedTab);
    }

    renderedCallback() {
        if (this._filter) {
            this.filterResults({ filter: this._filter });
        }

        if (this.scroll > 0) {
            this.scrollTo(this.scroll);
        }

        this.markSelectedClients(this.selectedClients);
        this.initcomponent = false;
    }

    markSelectedClients(rows) {
        if (rows && rows.length > 0){
            const selectedIds = rows.map(r => r.customerId);
            const allCells = this.template.querySelectorAll('td[data-id]');
            allCells.forEach(cell => { 
                const id = cell.getAttribute('data-id');
                if (selectedIds.includes(id) && !cell.classList.value.includes('isSelected')) {
                    cell.classList.add('isSelected');
                }
                else if (!selectedIds.includes(id) && cell.classList.value.includes('isSelected')){
                    cell.classList.remove('isSelected');
                }
            });
            this.selectedClients = rows;
        }else{
            const allCells = this.template.querySelectorAll('td[data-id]');
            
            allCells.forEach(cell => {
                cell.classList.remove('isSelected');
            });
            this.selectedClients = [];
        }
        
    }

    // MAP DATA TO COLUMNS
    mapData2Columns() {
        return new Promise(resolve => {
            const selectedData = this.groupedData.map(row =>
                this.columns.map(column => row[column.field])
            );
            selectedData.forEach(client => client.push(selectedData.length));
            resolve(selectedData);
        });
    }

    groupData() {
        this.mapData2Columns().then(selectedData => {
            const clients = selectedData.map(client => {
                return {
                    customerId: client[6],
                    data: client
                };
            });

            this.selectedData = {
                groups: [],
                toplevel: { clients: clients }
            };

            this.showSpinner = false;
        });
    }

    handleActiveTab() {
        this.columns = getColumns(this.selectedTab);
        this.visibleColumns = getVisibleColumns(this.selectedTab);
        this._doubleLineHeader =
            this.selectedTab === 'consumption' || this.selectedTab === 'connectedClients';
    }

    handleScroll(event) {
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
        this.template.querySelector('c-hpg_fetcher').fireFetchMoreEvent(params);
    }


    selectRowComplete(event) {
            if(this.showSelectRows === 'true'){
                var sendRows = this.selectedClients;
                var row = {"customerId":event.target.getAttribute("data-id"), "mainHolder": this.mainHolderCustomer};
                    if(this.selectedClients.filter(row => row.customerId == event.target.getAttribute("data-id")).length > 0 ){
                        sendRows = this.selectedClients.filter(row => row.customerId != event.target.getAttribute("data-id"));
                    }else{
                        sendRows.push(row);
                    }
                    this.markSelectedClients(sendRows);
                    this.checkIfModified();
            }
    }


    handleSave(){
		
		saveSelectedClients({ 
                selectedClients: this.selectedClients,
                groupAccount: this.groupAccount,
                groupCode: this.groupCode,
                lineId: this.lineId,
                recordId: this.recordId,
                booking: this.booking,
                mainHolderCustomerId: this.mainHolderCustomer,
                priorityId: this.priorityId
             })
		.then(result => {
			this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Clients saved successfully.',
                    variant: 'success'
                })
            );
            this.priorSelectedRows = JSON.parse(JSON.stringify(this.selectedClients));
            this.showFooter = false;
		})
		.catch(error => {
			console.error('Error saving clients:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to save client',
                    variant: 'error'
                })
            );
		})
	} 

    // Cancelar → volver al estado original
    handleCancel() {
        this.selectedClients = [...this.priorSelectedRows];
        this.markSelectedClients(this.priorSelectedRows);
        this.showFooter = false;
    }

    handleToggleGroup(event) {
        event.preventDefault();
        let group = event.target.id.split('-')[0];
        this.toggleGroup(group);
    }

    checkIfModified() {
        const oldIds = new Set(this.priorSelectedRows?.map(c => c.customerId));
        const newIds = new Set(this.selectedClients?.map(c => c.customerId));console.log('check',newIds);

        this.showFooter = oldIds.size !== newIds.size || [...newIds].some(id => !oldIds.has(id));
    }
}