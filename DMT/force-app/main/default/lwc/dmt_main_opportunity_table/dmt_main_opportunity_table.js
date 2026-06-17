import { LightningElement, track, api, wire } from 'lwc';
import { labels } from './dmt_main_table_labels.js';
import pubsub from 'omnistudio/pubsub';
import { getColumns, getVisibleColumns, getGrillFields } from './dmt_main_table_columns.js';
import callExtensionImperative from '@salesforce/apex/DMT_MainTableCallableClass.callExtensionImperative';
import fetchInitialData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchInitialData';
import fetchData from '@salesforce/apex/DMT_HPG_MainTableCustomController.fetchData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveOpportunityClients from '@salesforce/apex/DMT_HPG_MainTableCustomController.saveOpportunityClients';
import updateMainHolderOnAssociation from '@salesforce/apex/DMT_HPG_MainTableCustomController.updateMainHolderOnAssociation';
import updateMainHolderApprovalData from '@salesforce/apex/DMT_HPG_MainTableCustomController.updateMainHolderApprovalData';

function setCancelRestoring()   { window[_POST_CANCEL_KEY] = true; }
function clearCancelRestoring() { window[_POST_CANCEL_KEY] = false; }
function isCancelRestoring()    { return window[_POST_CANCEL_KEY] === true; }

const _POST_CANCEL_KEY = 'DMT_postCancelRestoring';
const DISABLE_ACTIONS_CLIENT= 'disableactions';
const PUBSUB_EVENT_RESPONSE = 'saveClientsEvent';
const PUBSUB_CHANNEL = 'DMT_OpportunityClientTable';
let _moduleViewModeClients = null;
const _STORAGE_KEY = 'DMT_manuallyDeselected';
const _SAVED_MH_KEY  = 'DMT_savedNewMainHolder';
const _VIEW_MODE_CLIENTS_KEY = 'DMT_viewModeClients';

const _POST_SAVE_KEY = 'DMT_postSaveRestoring';
function setPostSaveRestoring() { window[_POST_SAVE_KEY] = true; }
function clearPostSaveRestoring() { window[_POST_SAVE_KEY] = false; }
function isPostSaveRestoring() { return window[_POST_SAVE_KEY] === true; }

function getStoredViewModeClients() {
    const v = window[_VIEW_MODE_CLIENTS_KEY];
    return Array.isArray(v) && v.length > 0 ? v : null;
}
function setStoredViewModeClients(clients) {
    window[_VIEW_MODE_CLIENTS_KEY] = clients || null;
}
function clearStoredViewModeClients() {
    window[_VIEW_MODE_CLIENTS_KEY] = null;
}
function getSavedMainHolder() {
    const v = window[_SAVED_MH_KEY];
    return (v && typeof v === 'string' && v !== 'null' && !v.includes('{')) ? v : null;
}
function setSavedMainHolder(val) { window[_SAVED_MH_KEY] = val || null; }
function clearSavedMainHolder()  { window[_SAVED_MH_KEY] = null; }
function getDeselected() {
    try {
        const raw = window[_STORAGE_KEY];
        return raw instanceof Set ? raw : new Set();
    } catch(e) { return new Set(); }
}

function setDeselected(set) {
    window[_STORAGE_KEY] = set;
}

export default class dmt_main_opportunity_table extends LightningElement {

    @api groupId;
    @api groupCode;
    @api labels = labels;
    @api columns;
    @api scroll;
    @api body;
    @api searchDatevalue;
    @api countries = ['ALL'];
    //@api clientPositionsType = 'Y';
    @api page = '1';
    @api pageSize = '5000';
    @api selectedTab;
    @api grillField = 'una';
    @api recordId;
    @api filterClientsVariable;
    @api filterClientsOperator;
    @api filterClientsValue;
    @api groupsSelected  = new Map();
    selectedClients = [];
    _pubsubRegistered = false;
    _savedMainHolder = null;
    
    _manuallyDeselected = new Set();

    @api
    get priorselectedRows() {
        return this._priorselectedRows;
    }

    set priorselectedRows(value) {
        this._isRestoring = true;
        this._settingPriorRows = true;
        this._priorselectedRows = this.normalizeToArray(value);
        if (isPostSaveRestoring()) {
        clearStoredViewModeClients();
        _moduleViewModeClients = null;
    }
        
        const mainHolderFromData = this._priorselectedRows.find(item => 
            item.mainHolder && item.mainHolder !== 'null'
        )?.mainHolder;

        //  FIX: solo usar mainHolderFromData si NO hay una selección más reciente del usuario
        const windowSavedHolder = getSavedMainHolder();
        const userHasSelectedHolder = !!windowSavedHolder;  // el usuario cambió el MH en view mode

        if (mainHolderFromData && !userHasSelectedHolder && mainHolderFromData !== this._savedMainHolder) {
            this._savedMainHolder = mainHolderFromData;
            this._mainHolderCustomer = mainHolderFromData;
            this._mainHolderRestored = false;
        }

    const viewSource = this.isValidViewModeClients(this._viewModeClients)
        ? this.normalizeToArray(this._viewModeClients)
        : [];

    // ← AÑADIR: recuperar de window si viewModeClients aún no llegó
    const windowViewClients = getStoredViewModeClients();

    const deselected = getDeselected();

    if (viewSource.length > 0 || windowViewClients) {
        // Merge: priorselectedRows + viewModeClients (window o prop)
        const mergedMap = new Map();

        this._priorselectedRows.forEach(item => {
            if (!deselected.has(item.customerId)) {
                mergedMap.set(item.customerId, { ...item, mainHolder: null });
            }
        });

        const effectiveViewClients = viewSource.length > 0 ? viewSource : windowViewClients;
        effectiveViewClients.forEach(item => {
            if (!deselected.has(item.customerId)) {
                mergedMap.set(item.customerId, { ...item, mainHolder: null });
            }
        });

        this.selectedClients = [...mergedMap.values()];

    } else {
        this.selectedClients = this._priorselectedRows
            .filter(item => !deselected.has(item.customerId))
            .map(item => ({ ...item, mainHolder: null }));
    }

        this.mainHolderSelectRows = this._priorselectedRows
            .filter(item => item.customerId !== null)
            .map(item => item.customerId);

    this._pendingPriorRowsRestore = true;
            this._pendingClientsRestore = true;
            this._settingPriorRows = false;
            // ← AÑADIR: si veníamos de un save, apagar el spinner ahora que tenemos datos frescos
            if (this.isSaving === false && this.showSpinner) {
                this.showSpinner = false;
            }
            setTimeout(() => {
            clearPostSaveRestoring();
            this._postSaveRestoring = false;
            }, 100);
    }

    @api
    get viewModeClients() {
        return this._viewModeClients;
    }

set viewModeClients(value) {
    if (this.isValidViewModeClients(value)) {
        this._viewModeClients = this.normalizeToArray(value);
        const deselected = getDeselected();

        if (this._priorselectedRows) {
            // MERGE: unir priorselectedRows + viewModeClients, sin duplicados, sin deseleccionados
            const mergedMap = new Map();

            // Base: los que ya estaban
            this._priorselectedRows.forEach(item => {
                if (!deselected.has(item.customerId)) {
                    mergedMap.set(item.customerId, { ...item, mainHolder: null });
                }
            });

            // Añadir/sobreescribir con los de viewMode (incluye nuevas selecciones de view mode)
            this._viewModeClients.forEach(item => {
                if (!deselected.has(item.customerId)) {
                    mergedMap.set(item.customerId, { ...item, mainHolder: null });
                }
            });

            this.selectedClients = [...mergedMap.values()];
        }

        this._pendingClientsRestore = true;

        if (this._rendered && !this.showSpinner) {
            setTimeout(() => this._restoreClientSelection(), 0);
        }
    } else {
        if (!this._viewModeClients || this._viewModeClients.length === 0) {
            this._viewModeClients = [];
        }
    }
}
_restoreClientSelection() {
     const windowViewClients = getStoredViewModeClients();
    console.log('[RESTORE] _moduleViewModeClients:', _moduleViewModeClients?.length);
    console.log('[RESTORE] _viewModeClients:', this._viewModeClients?.length);
    console.log('[RESTORE] windowViewClients:', windowViewClients?.length);
    console.log('[RESTORE] _viewModeSelectedClients:', this._viewModeSelectedClients?.length);
    console.log('[RESTORE] selectedClients:', this.selectedClients?.length);
    console.log('[RESTORE] _priorselectedRows:', this._priorselectedRows?.length);
    this._isRestoring = true;

        if (!this._mainHolderRestored) {
        this.template.querySelectorAll('c-dmt_main_table_cell').forEach(cell => {
            cell.deactiveMainHolder();
        });
    }
    const sourceRows = (_moduleViewModeClients?.length > 0)
        ? _moduleViewModeClients
        : (this._viewModeClients?.length > 0)
        ? this._viewModeClients
        : (windowViewClients?.length > 0)
        ? windowViewClients
        : (this._viewModeSelectedClients?.length > 0)
        ? this._viewModeSelectedClients
        : (this._priorselectedRows || []);

    const _moduleManuallyDeselected = getDeselected();
    const filteredRows = sourceRows.filter(row => {
        const id = row.customerId || row;
        return !_moduleManuallyDeselected.has(id);
    });


    if (!filteredRows.length && !sourceRows.length) return;

    const filteredIds = new Set(filteredRows.map(r => r.customerId || r));
    if (this._justAddedByToggle) {
        filteredIds.add(this._justAddedByToggle);
        this._justAddedByToggle = null;
    }
    this.template.querySelectorAll('td.isSelected[data-id]').forEach(td => {
        const tdId = td.getAttribute('data-id');
        if (!filteredIds.has(tdId)) {
            td.classList.remove('isSelected');
        }
    });

    let allFound = true;
    filteredRows.forEach(row => {
        const customerId = row.customerId || row;
        if (!customerId || customerId === 'null') return;

        const tds = this.template.querySelectorAll(`[data-id="${customerId}"]`);
        if (tds.length > 0) {
            tds.forEach(td => td.classList.add('isSelected'));

            const nameCell = this.template.querySelector(
                `c-dmt_main_table_cell[data-customerid="${customerId}"]`
            );
            if (nameCell) {
                nameCell.activateSelection();
                nameCell.classList.remove('showcellclass');
            }

            const already = this.selectedClients.find(c => c.customerId === customerId);
            if (!already) {
                const full = this.groupedData.find(c => c.customerId === customerId);
                if (full) this.selectedClients.push({ ...full, mainHolder: null });
            }
        } else {
            allFound = false;
        }
    });

    //  FIX: ocultar toggle MainHolder en clientes deseleccionados
    _moduleManuallyDeselected.forEach(deselectedId => {
        this.getCellsByCustomer(deselectedId).forEach(cell => {
            cell.deactiveMainHolder();
            cell.deactivateSelection();
        });
        // Quitar isSelected del DOM también
        this.template.querySelectorAll(`[data-id="${deselectedId}"]`)
            .forEach(td => td.classList.remove('isSelected'));
    });

    if (allFound) {
        this._pendingClientsRestore = false;
    }

    if (!this._mainHolderRestored) {
        const isValid = (v) => v && typeof v === 'string' && !v.includes('{') && v.trim() !== '' && v !== 'null';

        //  FIX: priorizar el holder guardado en window (sobrevive al reload del FlexCard)
        const windowSavedHolder = getSavedMainHolder();

        const holderToRestore =
            windowSavedHolder ||                                                           // ← PRIMERO
            (isValid(this._savedMainHolder) ? this._savedMainHolder : null) ||
            (isValid(this._mainHolderCustomer) ? this._mainHolderCustomer : null) ||
            (isValid(this.mainHolderCurrentvalue) ? this.mainHolderCurrentvalue : null) ||
            (isValid(this.mainHolderPreviousvalue) ? this.mainHolderPreviousvalue : null);

        if (holderToRestore) {
            const holderCells = this.getCellsByCustomer(holderToRestore);
            if (holderCells.length > 0) {
                this._mainHolderRestored = true;
                this._lastRestoredMainHolder = holderToRestore;
                if (!this.mainHolderSelectRows.includes(holderToRestore)) {
                    this.mainHolderSelectRows = [...this.mainHolderSelectRows, holderToRestore];
                }
                this.mainHolderCustomer = holderToRestore;
                holderCells.forEach(cell => cell.activateMainHolderByDefault());
                this.dispatchMainHolderUpdate(true);

                //  FIX: limpiar window storage SOLO después de activar correctamente
                clearSavedMainHolder();
            }
        }
    }

    setTimeout(() => {
        this.template.querySelectorAll('c-dmt_main_table_cell').forEach(cell => {
            if (cell.title === 'displaytext') {
                cell.classList.remove('showcellclass');
            }
        });

        const filteredIdsTimeout = new Set(filteredRows.map(r => r.customerId || r));
        this.template.querySelectorAll('td.isSelected[data-id]').forEach(td => {
            const tdId = td.getAttribute('data-id');
            if (tdId && !filteredIdsTimeout.has(tdId)) {
                td.classList.remove('isSelected');
            }
        });
    }, 0);
    
}

    isValidViewModeClients(value) {
        if (!value) return false;
        if (typeof value === 'string') {
            if (value.includes('{') || value.trim() === '') return false;
        }
        const arr = this.normalizeToArray(value);
        return arr.length > 0 && arr.some(item => 
            item?.customerId && 
            item.customerId !== 'null' && 
            !String(item.customerId).includes('{')
        );
    }
    @api filterClients;

    mainHolderSelectRows;
    get mainHolderCustomer() {
        return this._mainHolderCustomer;
    }
    set mainHolderCustomer(value) {
        const isValid = (v) => v && typeof v === 'string' && !v.includes('{') && v.trim() !== '' && v !== 'null';
        
        if (isValid(value)) {
            this._mainHolderCustomer = value;
            this._savedMainHolder = value;
        } else {
            this._mainHolderCustomer = value;
            this._savedMainHolder = null; 
        }
    }


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
    mainHolderSelectRows = [];
    clientCount = 0;
    clientsGrouped = [];
    initcomponent = true;
    newselectedrows;
    clientPositionsTypevalue;
    showSpinner = true;
    errorLoading = false;
    saveEventHandler;
    isSaving = false;

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
        //this.handleApexMethod();
    }
    @api
    get mainHolderCurrent() {
        return this.mainHolderCurrentvalue;
    }

    set mainHolderCurrent(value) {
        const isValid = value && typeof value === 'string' && !value.includes('{') && value.trim() !== '';
        
        if (isValid) {
            this.mainHolderCurrentvalue = value;
            this.mainHolderCustomer = value;
            console.log('mainHolderCurrent seteado:', this.mainHolderCustomer);
        } else {
            console.warn('[mainHolderCurrent] Placeholder sin resolver ignorado:', value);
        }
    }
    @api
    get manuallyDeselectedIds() {
        return this._manuallyDeselectedIds;
    }

set manuallyDeselectedIds(value) {
    this._manuallyDeselectedIds = value;
    
    if (!value || (typeof value === 'string' && (value.includes('{') || value.trim() === ''))) {
        return;
    }

    const arr = Array.isArray(value) ? value : [];
    if (arr.length > 0) {
        const deselected = getDeselected();
        arr.forEach(id => deselected.add(id));
        setDeselected(deselected);
        
        if (this._rendered && !this.showSpinner) {
            setTimeout(() => this._restoreClientSelection(), 0);
        }
    }
}

    @api
    get  searchDate() {
      return this.searchDatevalue;
    }
  
    set searchDate(value) {
        this.searchDatevalue = value;
        //this.handleApexMethod();
    }

    @api
    get  oppId() {
      return this.oppIdvalue;
    }
  
    set oppId(value) {
        this.oppIdvalue = value;
    }

    @api
    get  isReadOnlyUser() {
      return this.isReadOnlyUservalue;
    }
  
    set isReadOnlyUser(value) {
        this.isReadOnlyUservalue = value;
        console.log('value isReadOnlyUser', value);
    }

    @api
    get editState() {
        return this._editState;
    }

    set editState(value) {
        const prev = this._editState;
        this._editState = value === true || value === 'true';
        console.log('EditState normalizado:', this._editState);

        if (!prev && this._editState) {
            this._pendingMainHolderRestore = true;
            this._mainHolderRestored = false;
            this._lastRestoredMainHolder = null;
        }

        if (prev && !this._editState) {
            this._mainHolderRestored = false;
            this._lastRestoredMainHolder = null;
        }
    }


    @api
    get  mainHolderPrevious() {
      return this.mainHolderPreviousvalue;
    }
  
    set mainHolderPrevious(value) {
        this.mainHolderPreviousvalue = value;
        console.log('mainHolderPreviousvalue Irene', value);

        // Si ya estamos en editState y aún no se restauró, marcar pendiente
        if (this._editState && value && !this._mainHolderRestored) {
            this._pendingMainHolderRestore = true;
        }
    }

    @api
    get  clientPositionsType() {
      return this.clientPositionsTypevalue;
    }
  
    set clientPositionsType(value) {
        if(value == true){
            this.clientPositionsTypevalue = 'true';
        }else{
            this.clientPositionsTypevalue = value;
        }
        console.log('set clientPositionsType Irene', this.clientPositionsTypevalue);
    }

    @api
    get isSubsidiary() {
        return this.isSubsidiaryvalue;
    }

    set isSubsidiary(value) {
        this.isSubsidiaryvalue = value === true || value === 'true';

        if (this.isSubsidiaryvalue) {
                console.log('Subsidiary = true LWC desactivado');
        }
    }

    @api
    get  StageName() {
      return this.StageNamevalue;
    }
  
    set StageName(value) {
        this.StageNamevalue = value;
    }
    handleManuallyDeselectedReady(payload) {
        if (!payload?.deselectedIds || !Array.isArray(payload.deselectedIds)) {
            return;
        }
        
        const deselected = getDeselected();
        payload.deselectedIds.forEach(id => deselected.add(id));
        setDeselected(deselected);
        

        if (this._rendered && !this.showSpinner) {
            setTimeout(() => this._restoreClientSelection(), 0);
        } else {
            this._pendingClientsRestore = true;
        }
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
                //console.log('entra en callExtensionImperative JSON.stringify(data)' +  JSON.stringify(data));
                if (data.success) {
                    this.showSpinner = true;
                    this.errorLoading = false;
                    this.groupedData = this.groupedData.concat(data.data);
                    this.groupedData = this.handleRatingExpiration();
                        if(this.filterClientsVariable){
                            this.filtergroupedData = [];
                            this.groupedData.forEach( client => {
                            let customerCode = client?.customerId;
                            //console.log('this.filterClientsValue',this.filterClientsValue);console.log('this.booking',this.booking);console.log('this.clientId',this.clientId);
                            if((client.subGroupId === this.filterClientsValue || client.groupId === this.filterClientsValue) && this.booking && this.booking != null && customerCode?.startsWith(this.booking) && customerCode?.includes(this.filter)){
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
                    console.log('data.errorMessage ' , JSON.stringify(data.errorMessage))
                    console.log('data ' , JSON.stringify(data))
                }
            }).catch((error) => {
                setTimeout(5000);
                this.showSpinner = false;
                this.errorLoading =true;
                console.error('[handleApexMethod] ERROR FETCHING DATA: ' + JSON.stringify(error))
            });
        } catch (error) {
            this.showSpinner = false;
            this.errorLoading =true;
            this.records = undefined;
            this.error = error;
            console.log('this.error test irene', this.error);
        }
    }
_pubsubHandler = null;
_pubsubHandlerObj = null;
    connectedCallback() {
        console.log('Jimmy CONNECTED CALLBACK');

        if (this.isSubsidiaryvalue) {
            return;
        }

        if (isCancelRestoring()) {
            setDeselected(new Set());
            clearStoredViewModeClients();
            clearSavedMainHolder();
            _moduleViewModeClients = null;
            clearCancelRestoring();
        }

        this.columns = getColumns(this.selectedTab);
        this.visibleColumns = getVisibleColumns(this.selectedTab);
        this.handleActiveTab(this.selectedTab);
        this.groupSize = this.template.querySelectorAll('.clientName').length;
        console.log('ABS TEST');

        this._pubsubHandlerObj = {
            [PUBSUB_EVENT_RESPONSE]: this.handleSaveFromFlexCard.bind(this),
            'viewModeClientsReady': this.handleViewModeClientsReady.bind(this),
            'manuallyDeselectedReady': this.handleManuallyDeselectedReady.bind(this)
        };

        this._pubsubButtonHandlerObj = {
            'ReloadChild': this.handleCancelFromFlexCard.bind(this)
        };
        try {
            pubsub.register('Button', this._pubsubButtonHandlerObj);
        } catch (error) {
            console.error('Error registering Button PubSub listener:', error);
        }
    }

  disconnectedCallback() {
    console.log('Jimmy disconnect EVENT');
    this.unregisterPubSubListener();
  }

  // =========================================================
  // PubSub: Register listener
  // =========================================================
  registerPubSubListener() {
    if (this._pubsubRegistered || !pubsub) return;

    try {
      console.log('Jimmy register EVENT');
      pubsub.register(PUBSUB_CHANNEL, this._pubsubHandlerObj);
      this._pubsubRegistered = true;
    } catch (error) {
      console.error("Error registering PubSub listener:", error);
    }
  }
    // =========================================================
  // PubSub: Unregister listener
  // =========================================================
  unregisterPubSubListener() {
    if (!this._pubsubRegistered || !pubsub) return;

    try {
        console.log('Jimmy unregister EVENT');

      pubsub.unregister(PUBSUB_CHANNEL, this._pubsubHandlerObj);
      this._pubsubRegistered = false;
    } catch (error) {
      console.error("Error unregistering PubSub listener:", error);
    }
  }

  handleCancelFromFlexCard() {
        setCancelRestoring();
    }

    handleViewModeClientsReady(payload) {
        if (payload?.viewModeClients && this.isValidViewModeClients(payload.viewModeClients)) {
            this._viewModeClients = this.normalizeToArray(payload.viewModeClients);
            this._pendingClientsRestore = true;
            if (this._rendered && !this.showSpinner) {
                setTimeout(() => this._restoreClientSelection(), 0);
            }
        }
    }
    renderedCallback() {
        this.selectedData.groups.forEach(group => {
            this.toggleGroup(group.subGroupId);
        });
        if (this._filter) {
            this.filterResults({filter: this._filter});
        }

        const isValid = (v) => v && typeof v === 'string' && !v.includes('{') && v.trim() !== '' && v !== 'null';

        const windowSavedHolder = getSavedMainHolder();

        if (windowSavedHolder && isValid(this.mainHolderPreviousvalue) && 
            this.mainHolderPreviousvalue !== windowSavedHolder) {
            this.getCellsByCustomer(this.mainHolderPreviousvalue)
                .forEach(cell => cell.deactiveMainHolder());
        }

        const holderToRestore =
            windowSavedHolder ||
            (isValid(this._savedMainHolder) ? this._savedMainHolder : null) ||
            (isValid(this.mainHolderCustomer) ? this.mainHolderCustomer : null) ||
            (isValid(this.mainHolderCurrentvalue) ? this.mainHolderCurrentvalue : null) ||
            (isValid(this.mainHolderPreviousvalue) ? this.mainHolderPreviousvalue : null);

        const effectiveHolderToRestore = holderToRestore;

        const holderMatchesCurrent = 
            !this._lastRestoredMainHolder ||  // primer restore: sin restricción
            effectiveHolderToRestore === this._lastRestoredMainHolder;  // restores posteriores: solo si coincide

        const shouldRestore = (this._editState || isValid(this._savedMainHolder) || !!windowSavedHolder) 
            && !this._mainHolderRestored
            && holderMatchesCurrent;

        if (effectiveHolderToRestore && shouldRestore) {
            if (this._lastRestoredMainHolder && this._lastRestoredMainHolder !== effectiveHolderToRestore) {
                this.getCellsByCustomer(this._lastRestoredMainHolder)
                    .forEach(cell => cell.deactiveMainHolder());
            }

            if (!this.mainHolderSelectRows.includes(effectiveHolderToRestore)) {
                this.mainHolderSelectRows = [...this.mainHolderSelectRows, effectiveHolderToRestore];
            }

            this.mainHolderCustomer = effectiveHolderToRestore;

            const cells = this.getCellsByCustomer(effectiveHolderToRestore);
            if (cells.length > 0) {
                this._mainHolderRestored = true;
                this._lastRestoredMainHolder = effectiveHolderToRestore;
                cells.forEach(cell => cell.activateMainHolderByDefault());
                this.dispatchMainHolderUpdate(true);
                this._justSaved = false;
                clearSavedMainHolder(); // ✅ limpiar solo tras activación confirmada
            }
        }

        if (!this._editState && !isValid(this._savedMainHolder) && !windowSavedHolder) { // ← añadir !windowSavedHolder
            this._mainHolderRestored = false;
        }

        if (this._viewModeSelectedClients && this._pendingClientsRestore) {
            const allTds = this.template.querySelectorAll('td.isSelected');
            allTds.forEach(td => td.classList.remove('isSelected'));
        }

        const sourceRows = (this._viewModeClients && this._viewModeClients.length > 0)
            ? this._viewModeClients
            : (this._viewModeSelectedClients && this._viewModeSelectedClients.length > 0)
            ? this._viewModeSelectedClients
            : (this._priorselectedRows || []);

        if (this._pendingClientsRestore || (sourceRows.length > 0 && !this.showSpinner)) {
            this._restoreClientSelection();
            Promise.resolve().then(() => { this._isRestoring = false; });
        }

        if (this.filterClients == true) {
            this.filterClientsResults();
        }

        if (this.booking) {
            var notBooking = this.template.querySelectorAll(`td:not([data-id^="${this.booking}"])`);
            notBooking.forEach(el => el.classList.add('notfound'));            
        }

        this.initcomponent = false;
        this.adjustScrollLines();
        this._rendered = true;
        if (this._editState && this._pendingMainHolderRestore && !this._mainHolderRestored && !this.showSpinner) {
            this._restoreMainHolderDeferred();
        }

        console.log('Jimmy rendered ', JSON.stringify(this.priorselectedRows));
        if (this._editState) {
            console.log('Jimmy estoy modo edificion');
            this.registerPubSubListener();
        }
    }

    _restoreMainHolderDeferred() {
        const isValid = (v) => v && typeof v === 'string' && !v.includes('{') && v.trim() !== '' && v !== 'null';

        const holderToRestore =
            (isValid(this._savedMainHolder) ? this._savedMainHolder : null) ||
            (isValid(this._mainHolderCustomer) ? this._mainHolderCustomer : null) ||
            (isValid(this.mainHolderCurrentvalue) ? this.mainHolderCurrentvalue : null);

        if (!holderToRestore) {
            console.warn('[_restoreMainHolderDeferred] No hay holder que restaurar');
            this._pendingMainHolderRestore = false; 
            return;
        }

        console.log('[_restoreMainHolderDeferred] Intentando restaurar:', holderToRestore);

        if (!this.mainHolderSelectRows.includes(holderToRestore)) {
            this.mainHolderSelectRows = [...this.mainHolderSelectRows, holderToRestore];
        }

        this.mainHolderCustomer = holderToRestore;

        const cells = this.getCellsByCustomer(holderToRestore);
        if (cells.length > 0) {
            if (this._lastRestoredMainHolder && this._lastRestoredMainHolder !== holderToRestore) {
                this.getCellsByCustomer(this._lastRestoredMainHolder)
                    .forEach(cell => cell.deactiveMainHolder());
            }

            this._mainHolderRestored = true;
            this._pendingMainHolderRestore = false;
            this._lastRestoredMainHolder = holderToRestore;

            cells.forEach(cell => cell.activateMainHolderByDefault());
            this.dispatchMainHolderUpdate(true);
            console.log('[_restoreMainHolderDeferred]  MainHolder restaurado:', holderToRestore);
        } else {

            console.warn('[_restoreMainHolderDeferred] Celdas no encontradas, esperando siguiente render');
            this._pendingMainHolderRestore = true;
        }
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

        //INIT
    @wire(fetchInitialData, {

        selectedTab: '$selectedTab',
        clientId: '$clientId',
        lCountries: '$countries',
        searchDate: '$searchDate',
        clientPositionsType: '$clientPositionsType',
        page: '$page',
        pageSize: '$pageSize',
        //timestamp: Date.now()

    }) response ({error, data}) {

        if (this.isSubsidiaryvalue) {
            return;
        }

        //c/addSoldOrderFormconsole.log('WIRE JSON Irene:', JSON.stringify(data));
        this.handleActiveTab(this.selectedTab);
        this.selectedData = {groups: [], toplevel: {clients:[]}};
        this.groupedData = [];

        if (data) {
            if (data.success) {
                this.groupedData = this.groupedData.concat(data.data);
                this.filtergroupedData = [];
                this.groupedData.forEach( client => {
                let customerCode = client?.customerId;
                    if((client.subGroupId === this.filterClientsValue || client.groupId === this.filterClientsValue) && customerCode?.startsWith(this.booking) && customerCode?.includes(this.filter)){
                    this.filtergroupedData.push(client);
                        }
                            });
                this.groupData();
            } else {
                console.error('ERROR loading initial data: ' + data.errorMessage);
                this.showSpinner = false;
                this.errorLoading = true;
            }
        } else if (error) {
            this.error = error;
            console.error('error ' +error);
            this.isLoading = false;
            this.showSpinner = false;
            this.errorLoading = true;

            this.dispatchEvent(new CustomEvent(DISABLE_ACTIONS_CLIENT, {
                bubbles: true,
                composed: true
            }));
        }
    };

    // //Fetch Data Imperative
    @api
    fetchData(params) {

        if (this.isSubsidiaryvalue) {
            return;
        }
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
                    var selectedData = this.filtergroupedData.map (
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
            if (this.filterClientsVariable) {
                const sortedClients = [...data].sort((a, b) => {
                    if (a[3] !== b[3]) {
                        return a[3] > b[3] ? -1 : 1;
                    }
                    const idA = a[6] || '';
                    const idB = b[6] || '';
                    return idA.localeCompare(idB);
                });

                resolve([
                    {
                        type: 'subgroup',
                        subGroupId: '-1000',
                        subGroupName: 'toplevelclients',
                        clients: sortedClients
                    }
                ]);
                return;
            }
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

    _viewModeSelectedClients = null; 

    selectRow(event) {
        if (this._isRestoring) return;
        if (!this.editState) {
            const customerId = event.detail.customerId;
            if (!customerId) return;

            this._userHasInteracted = true;

            const idx = this.selectedClients.findIndex(c => c.customerId === customerId);
            if (idx !== -1) {
                this.selectedClients.splice(idx, 1);

                // Quitar isSelected del DOM
                const cells = this.template.querySelectorAll(`[data-id="${customerId}"]`);
                cells.forEach(cell => cell.classList.remove('isSelected'));

                // ✅ Actualizar estado para el siguiente render
                this._priorselectedRows = (this._priorselectedRows || [])
                    .filter(r => r.customerId !== customerId);
                _moduleViewModeClients = (_moduleViewModeClients || [])
                    .filter(c => c.customerId !== customerId);

                // Notificar al hijo
                const nameCell = this.template.querySelector(
                    `c-dmt_main_table_cell[data-customerid="${customerId}"]`
                );
                if (nameCell) nameCell.deactivateSelection();

                if (this.mainHolderCustomer === customerId) {
                    this.getCellsByCustomer(customerId).forEach(cell => cell.deactiveMainHolder());
                    this.mainHolderCustomer = '';
                    this._savedMainHolder = null;
                    this._mainHolderRestored = false;
                    this._dispatchViewModeMainHolder(true);
                }
                const deselected = getDeselected();
                deselected.add(customerId);
                setDeselected(deselected);
                this._dispatchViewModeDeselection(true);

                } else {
                    const fullClient = this.groupedData.find(c => c.customerId === customerId);
                    if (fullClient) this.selectedClients.push(fullClient);
                    const cells = this.template.querySelectorAll(`[data-id="${customerId}"]`);
                    cells.forEach(cell => cell.classList.add('isSelected'));
                    const nameCell = this.template.querySelector(
                        `c-dmt_main_table_cell[data-customerid="${customerId}"]`
                    );
                    if (nameCell) {
                        nameCell.activateSelection();
                        nameCell.classList.remove('showcellclass');
                    }
                    // ← AÑADIR: solo borrar del Set si NO fue gestionado por REMOVE_ACCOUNT
                    if (this._justRemovedByMainHolder !== customerId) {
                        const deselected = getDeselected();
                        deselected.delete(customerId);
                        setDeselected(deselected);
                    }
                    this._justRemovedByMainHolder = null; // ← limpiar siempre
                }

            this._viewModeSelectedClients = [...this.selectedClients];
            this._dispatchViewModeSelection(true);
            return;
    }
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
            //console.log('selectclientdmt recibido', JSON.stringify(event.detail));
            
        //Para ver el log en la console de los clientes al seleccionar antes del save.
        const customerId = event.detail.customerId;

        console.log('CustomerId recibido:', customerId);

        if (!customerId) {
            console.warn('No viene customerId en el evento');
            console.groupEnd();
            return;
        }

        const fullClient = this.groupedData.find(
            client => client.customerId === customerId
        );

        //console.log('Cliente completo JSON IRENE:', JSON.stringify(fullClient));

    }

    getSelectedClients() {
        const selectedCells = this.template.querySelectorAll('td.isSelected[data-id]');
    
        const selectedIds = new Set();
        selectedCells.forEach(cell => {
            selectedIds.add(cell.getAttribute('data-id'));
        });

        const selectedClientsFull = this.groupedData.filter(client =>
            selectedIds.has(client.customerId)
        );

        //console.group('CLIENTES SELECCIONADOS - FULL DATA');
        //console.log('IDs seleccionados:', [...selectedIds]);
        //console.log('Clientes completos:', selectedClientsFull);
        //console.log('JSON completo Seleccionados Irene:', JSON.stringify(selectedClientsFull));
        //console.groupEnd();

        return selectedClientsFull;
    }
    

    saveSelection() {

    if (this.isSaving) {
        console.log('Save already in progress. Ignoring duplicate call.');
        return;
    }

    console.log('Jimmy He lanzado el evento saveSelection: ');

    this._savedMainHolder = this.mainHolderCustomer;
    this.isSaving = true;

    if (this.isSubsidiaryvalue) {
        return;
    }

    const newMainHolder = this.mainHolderCustomer;
    console.log('newMainHolder', newMainHolder);
    if (!this.mainHolderCustomer || this.mainHolderCustomer === '') {
        this.showWarningToast(
            this.labels?.DMT_Warning_Main_Holder || 
            'You must select at least one Main Holder before saving.',
            this.labels?.DMT_WarningToastTitle || 'Validation Error'
        );
        return;
    }

    const selectedClients = this.getSelectedClients();

    this.showSpinner = true;
    
    //  FIX: marcar que acabamos de guardar para bloquear restauraciones visuales incorrectas
    this._justSaved = true;
    this._savedNewMainHolder = newMainHolder;
    setSavedMainHolder(newMainHolder); 

    saveOpportunityClients({
        selectedClients: JSON.parse(JSON.stringify(selectedClients)),
        opportunityId: this.oppId
    })
    .then(() => {
        if (this.mainHolderPrevious !== newMainHolder) {
            console.log('this.mainHolderCustomer pase a Apex updateMainHolderOnAssociation:', this.mainHolderCustomer);
            return updateMainHolderOnAssociation({
                opportunityId: this.oppId,
                alphaCode: newMainHolder
            });
        }
    })
    .then(() => {
        if (this.mainHolderPrevious && this.mainHolderPrevious !== newMainHolder) {
            console.log('newMainHolder updateMainHolderApprovalData', newMainHolder);
            console.log('this.mainHolderPrevious updateMainHolderApprovalData', this.mainHolderPrevious);
            return updateMainHolderApprovalData({
                opportunityId: this.oppId,
                mainHolderPrevious: this.mainHolderPrevious,
                mainHolderNew: newMainHolder
            });
        }
    })
    .finally(() => {
        console.log('[saveSelection finally] limpiando window deselected');

        this.isSaving = false;
        this._postSaveRestoring = true;
        setPostSaveRestoring();
        this._mainHolderRestored = false;
        this._viewModeSelectedClients = null;
        this._userHasInteracted = false;
        _moduleViewModeClients = null;
        setDeselected(new Set());
        clearStoredViewModeClients();
        
        //  FIX: limpiar el mainHolder anterior para que renderedCallback 
        // no lo restaure cuando lleguen los nuevos priorselectedRows
        this._lastRestoredMainHolder = null;
        
        //  FIX: forzar que _savedMainHolder apunte al nuevo, 
        // así si renderedCallback restaura, restaura el correcto
        this._savedMainHolder = newMainHolder;
        this._mainHolderCustomer = newMainHolder;

        this.dispatchEvent(new CustomEvent('viewmodedeselection', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: { deselectedIds: [], isUserAction: false }
        }));
    })
    .catch(error => {
        this.showSpinner = false;
        this.isSaving = false; //  FIX: también limpiar isSaving en catch
        this._justSaved = false;
        console.error(error);
        console.error('ERROR COMPLETO:', JSON.stringify(error));
        console.error('BODY:', JSON.stringify(error.body));
        console.error('PAGE ERRORS:', JSON.stringify(error.body?.pageErrors));

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Error saving clients.',
                variant: 'error'
            })
        );
    });
}


    handleSaveFromFlexCard() {
        console.log('He lanzado el evento jimmy');
        console.log('He lanzado el evento jimmy y ejecutado');

        this.saveSelection();
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
    set filter(value) {

        if (!value || value === 'null') {
            return;
        }

        this._filter = value;
        this.filterResults({ filter: this._filter });
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
        
        //  FIX: solo marcar como restaurado si estamos en edit mode
        // En view mode NO tocar _mainHolderRestored para que la transición view→edit
        // pueda restaurar correctamente en renderedCallback
        if (this._editState) {
            this._mainHolderRestored = true;
            this._lastRestoredMainHolder = newCustomerId;
        }
        
        this.getCellsByCustomer(newCustomerId).forEach(cell => cell.activateMainHolderByDefault());
    }

    //  Main handler to update the main holder (deactivate old, update new, activate new)
    handleMainHolderSelection(event) {
        const { context, customerId, initComponent } = event.detail;
        console.log('%c[Jimmy] 🟡 handleMainHolderSelection:', 'color: #f9a825;',  JSON.stringify(event.detail));


        switch (context) {
            case 'ADD_ACCOUNT':
                if (!this.mainHolderSelectRows.includes(customerId)) {
                    this.mainHolderSelectRows = [...this.mainHolderSelectRows, customerId];
                }
                // Añadir a selectedClients si no está ya
                if (!this.selectedClients.find(c => c.customerId === customerId)) {
                    const fullClient = this.groupedData.find(c => c.customerId === customerId);
                    if (fullClient) {
                        this.selectedClients = [...this.selectedClients, { ...fullClient, mainHolder: null }];
                    }
                }
                // Sincronizar window y _moduleViewModeClients inmediatamente
                _moduleViewModeClients = this.selectedClients.map(c => ({ ...c, mainHolder: null }));
                setStoredViewModeClients(_moduleViewModeClients);

                const addTds = this.template.querySelectorAll(`[data-id="${customerId}"]`);
                addTds.forEach(td => td.classList.add('isSelected'));
                const addNameCell = this.template.querySelector(
                    `c-dmt_main_table_cell[data-customerid="${customerId}"]`
                );
                if (addNameCell) {
                    addNameCell.activateSelection();
                    addNameCell.classList.remove('showcellclass');
                }
                this._justAddedByToggle = customerId;  // ← ya estaba propuesto, confirmar que está
                 setTimeout(() => this._restoreClientSelection(), 0);
                break;

            case 'REMOVE_ACCOUNT':
                this.mainHolderSelectRows = this.mainHolderSelectRows.filter(id => id !== customerId);
                this.selectedClients = this.selectedClients.filter(c => c.customerId !== customerId);
                _moduleViewModeClients = (_moduleViewModeClients || []).filter(c => c.customerId !== customerId);
                
                // ← AÑADIR: sincronizar window inmediatamente tras quitar
                setStoredViewModeClients(this.selectedClients.map(c => ({ ...c, mainHolder: null })));
                _moduleViewModeClients = this.selectedClients.map(c => ({ ...c, mainHolder: null }));
               
                this._justRemovedByMainHolder = customerId;
                const deselected = getDeselected();
                deselected.add(customerId);
                setDeselected(deselected);
                this._dispatchViewModeDeselection(true);

                // ← Desactivar celda nombre
                const removedCell = this.template.querySelector(
                    `c-dmt_main_table_cell[data-customerid="${customerId}"]`
                );
                if (removedCell) removedCell.deactivateSelection();

                // ← AÑADIR: ocultar toggle MainHolder en TODAS las celdas del cliente
                this.getCellsByCustomer(customerId).forEach(cell => cell.deactiveMainHolder());

                if (this.mainHolderCustomer === customerId || this.mainHolderCustomer === '') {
                    const nextCustomer = this.mainHolderSelectRows[0] || '';
                    this.updateMainHolder(nextCustomer);
                }
                break;

            case 'UPDATE_MAIN_HOLDER':
                if (this.mainHolderSelectRows.includes(customerId)) {
                    this.dispatchEvent(new CustomEvent('editmode', {
                        bubbles: true,
                        composed: true,
                        cancelable: true
                    }));

                    if (this.editState || !this.editState) {
                        this.updateMainHolder(customerId); 
                        console.log('dentro del case ', customerId);
                    }
                } else {
                    const existsInData = this.groupedData?.some(c => c.customerId === customerId);
                    if (existsInData) {
                        this.mainHolderSelectRows = [...this.mainHolderSelectRows, customerId];
                        this.updateMainHolder(customerId); 
                    }
                }

                if (!this.editState) {
                    this._dispatchViewModeMainHolder(true);
                }
                break;

            case 'CHECK_LAST_MAIN_HOLDER':
                if (this.mainHolderSelectRows.length > 0 && this.mainHolderCustomer === customerId) {
                    this.getCellsByCustomer(customerId).forEach(cell => cell.deactiveMainHolder());
                    this.mainHolderCustomer = '';
                     this.dispatchEvent(new CustomEvent('editmode', {
                        bubbles: true,
                        composed: true,
                        cancelable: true
                    }));
                    this.showWarningToast(this.labels.DMT_Warning_Main_Holder, this.labels.DMT_WarningToastTitle);

                    // ── Emitir también al limpiar mainHolder ──
                    if (!this.editState) {
                        this._dispatchViewModeMainHolder(true);
                    }
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


    _dispatchViewModeSelection(isUserAction = false) {
        console.log('[DISPATCH_VM_SELECTION] selectedClients count:', this.selectedClients.length,
    '| includes new client:', this.selectedClients.some(c => c.customerId === 'ES0182020462747'),
    '| _settingPriorRows:', this._settingPriorRows);
            if (this._postSaveRestoring || isPostSaveRestoring()) return;  // ← usar ambos
            _moduleViewModeClients = this.selectedClients.map(c => ({ ...c, mainHolder: null }));
            setStoredViewModeClients(_moduleViewModeClients);
        
        if (this._settingPriorRows) return; // ← solo corta el dispatch del evento, no la escritura
        
        const selectedDetail = {
            selectedClients: this.selectedClients.map(c => ({
                customerId: c.customerId,
                mainHolder: null
            })),
            isUserAction: isUserAction
        };

        this.dispatchEvent(new CustomEvent('viewmodeselection', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: selectedDetail
        }));
    }


    _dispatchViewModeMainHolder(isUserAction = false) {
        if (this._settingPriorRows) return;

        const isValid = (v) => v && typeof v === 'string' && !v.includes('{') && v.trim() !== '' && v !== 'null';

        const effectiveMainHolder =
            (isValid(this._mainHolderCustomer) ? this._mainHolderCustomer : null) ||
            (isValid(this._savedMainHolder) ? this._savedMainHolder : null) ||
            (isValid(this.mainHolderPreviousvalue) ? this.mainHolderPreviousvalue : null);

        if (effectiveMainHolder === this._lastDispatchedMainHolder) return;
        this._lastDispatchedMainHolder = effectiveMainHolder;

        this.dispatchEvent(new CustomEvent('viewmodemainholder', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: { 
                mainHolder: effectiveMainHolder || null,
                isUserAction: isUserAction 
            }
        }));
    }
    _dispatchViewModeDeselection(isUserAction = false) {
    if (this._settingPriorRows) return;
    
    const selectedDetail = {
        deselectedIds: [...getDeselected()],
        isUserAction: isUserAction
    };

    this.dispatchEvent(new CustomEvent('viewmodedeselection', {
        bubbles: true,
        composed: true,
        cancelable: true,
        detail: selectedDetail
    }));
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

    get tableBodyClass() {
        return ((this.StageNamevalue === 'Draft' || this.StageNamevalue === 'Ready to close') /*&& (this.isReadOnlyUservalue == false || this.isReadOnlyUservalue == 'false')*/) ? '' : 'tableDisabled';
    }

}