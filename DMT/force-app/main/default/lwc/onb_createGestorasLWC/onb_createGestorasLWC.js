import { LightningElement, api, track } from 'lwc';
import getGestorasByContrato from '@salesforce/apex/ONB_createGestorasController.getGestorasByContrato';
import getFondosByGestoras from '@salesforce/apex/ONB_createGestorasController.getFondosByGestoras';
import createAccount from '@salesforce/apex/ONB_createGestorasController.createAccount';
import asociarFondoGestoras from '@salesforce/apex/ONB_createGestorasController.asociarFondoGestoras';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import emptyFunds from '@salesforce/resourceUrl/emptyFunds'; 
import ONB_ACTIVITY_FUND from '@salesforce/label/c.ONB_ACTIVITY_FUND';
import ONB_ACTIVITY_ASSET_MANAGER from '@salesforce/label/c.ONB_ACTIVITY_ASSET_MANAGER';

const PAGE_SIZE = 8;

export default class ContratoManager extends LightningElement {
    
    emptyFundsImage = emptyFunds;

    @track isBusy = true;              
    @track hasLoadedGestoras = false;  
    @track hasLoadedFondos = false;

    _recordId;

    @api 
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.isBusy = true;
            Promise.resolve().then(() => this.loadGestorasFresh());
        }
    }
    get recordId() { return this._recordId; }

    @track currentStep = 'gestoras';
    @track headerCurrentPage = 'Select an Asset Manager';

    get isGestorasStep() { return this.currentStep === 'gestoras'; }
    get isFondosStep() { return this.currentStep === 'fondos'; }
    get isCreateGestoraStep() { return this.currentStep === 'createGestora'; }
    get isCreateFondoStep() { return this.currentStep === 'createFondo'; }

    connectedCallback() {
        if (this.recordId) {
            this.isBusy = true;
            this.loadGestorasFresh();
        }
    }

    // ===== NAV =====
    async goToGestoras({ preserveSelection = false, skipReload = false } = {}) {
        this.headerCurrentPage = 'Select an Asset Manager';
        this.currentStep = 'gestoras';

        if (!preserveSelection) {
            this.selectedGestoraIds.clear();
            this.selectedGestoras = [];
        }

        this.clearValues();

        if (!skipReload && this.recordId) {
            this.isBusy = true;
            await this.loadGestorasFresh({ preserveSelection });
        }
    }

    async goToFondos({ preserveSelection = false, skipReload = false } = {}) {
        if (this.selectedGestoraIds.size === 0)
            return this.showToast('Error','Select at least one Asset Manager','error');

        this.headerCurrentPage = 'Select a Fund';
        this.currentStep = 'fondos';
        this.clearValues();

        if (!skipReload) {
            this.isBusy = true;
            await this.cargarFondos({ preserveSelection });
        }
    }

    goToCreateGestora() { 
        this.headerCurrentPage = 'New Asset Manager'; 
        this.currentStep = 'createGestora'; 
    }

    goToCreateFondo() {
        this.headerCurrentPage = 'New Fund'; 
        this.currentStep = 'createFondo';
        const arr = this.getSelectedGestoras();
        this.newFondoParentId = arr.length === 1 ? arr[0].Id : null;
    }

    // ===== GESTORAS =====
    @track gestoras = [];
    @track filteredGestoras = [];
    @track displayedGestoras = [];
    @track selectedGestoras = [];
    @track searchGestoraTerm = '';
    @track currentGestoraPage = 1;
    totalGestoraPages = 1;
    selectedGestoraIds = new Set();

    gestoraColumns = [
        { label: 'Asset Manager Name', fieldName: 'Name', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200},
        { label: 'LEI', fieldName: 'lei_id__c', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200},
        { label: 'STAR Code', fieldName: 'Client_STAR_ID__c', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200},
        { label: 'Client Code', fieldName: 'SER_CClient__c', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200}
    ];

    async loadGestorasFresh({ preserveSelection = false } = {}) {
        try {
            const data = await getGestorasByContrato({ contratoMarcoId: this.recordId });
            this.gestoras = (data || [])
                .sort((a, b) => (a.Name || '').toLowerCase().localeCompare((b.Name || '').toLowerCase()));

            this.currentGestoraPage = 1;
            // NO limpiar búsqueda aquí si quieres conservarla al volver atrás
            this.applyGestoraFilters();

            if (!preserveSelection) {
                this.selectedGestoraIds?.clear?.();
                this.selectedGestoras = [];
            } else {
                this.selectedGestoras = this.gestoras.filter(g => this.selectedGestoraIds.has(g.Id));
            }

            this.hasLoadedGestoras = true;
        } catch (e) {
            console.error('loadGestorasFresh error', e);
            this.showToast('Error', 'Could not load Asset Managers', 'error');
        } finally {
            this.isBusy = false;
        }
    }

    handleGestoraSearch(event) {
        this.searchGestoraTerm = (event?.target?.value || '').toLowerCase();
        this.currentGestoraPage = 1;
        this.applyGestoraFilters();
    }

    applyGestoraFilters() {
        const term = this.searchGestoraTerm ? this.searchGestoraTerm.toLowerCase() : '';
        this.filteredGestoras = term
            ? this.gestoras.filter(g =>
                (g.Name && g.Name.toLowerCase().includes(term)) ||
                (g.lei_id__c && g.lei_id__c.toLowerCase().includes(term)) ||
                (g.Client_STAR_ID__c && g.Client_STAR_ID__c.toLowerCase().includes(term)) ||
                (g.SER_CClient__c && g.SER_CClient__c.toLowerCase().includes(term))
              )
            : [...this.gestoras];
        this.totalGestoraPages = Math.ceil(this.filteredGestoras.length / PAGE_SIZE) || 1;
        this.updateGestoraPagination();
    }

    updateGestoraPagination() {
        const start = (this.currentGestoraPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.displayedGestoras = this.filteredGestoras.slice(start, end);
    }

    handleGestoraPrevPage() {
        if (this.currentGestoraPage > 1) {
            this.currentGestoraPage--;
            this.updateGestoraPagination();
        }
    }
    handleGestoraNextPage() {
        if (this.currentGestoraPage < this.totalGestoraPages) {
            this.currentGestoraPage++;
            this.updateGestoraPagination();
        }
    }

    get selectedGestoraIdsArray() { return Array.from(this.selectedGestoraIds); }

    handleGestorasSelection(event) {
        const selectedOnPage = new Set((event.detail.selectedRows || []).map(r => r.Id));
        const currentPageIds = this.displayedGestoras.map(r => r.Id);
        currentPageIds.forEach(id => {
            if (selectedOnPage.has(id)) this.selectedGestoraIds.add(id);
            else this.selectedGestoraIds.delete(id);
        });
        this.selectedGestoras = this.gestoras.filter(g => this.selectedGestoraIds.has(g.Id));
    }

    // ===== FONDOS =====
    @track fondos = [];
    @track filteredFondos = [];
    @track displayedFondos = [];
    @track selectedFondos = [];
    @track searchFondoTerm = '';
    @track currentFondoPage = 1;
    @track newFondoParentId = null;
    totalFondoPages = 1;
    selectedFondoIds = new Set();
    get selectedFondoIdsArray(){ return Array.from(this.selectedFondoIds); }

    fondoColumns = [
        { label: 'Fund Name', fieldName: 'Name', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200 },
        { label: 'Asset Manager', fieldName: 'parentName', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200 },
        { label: 'LEI', fieldName: 'lei_id__c', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200},
        { label: 'Client Code', fieldName: 'SER_CClient__c', type: 'clampedText', wrapText: true, hideDefaultActions: true, fixedWidth: 200}
    ];

    async cargarFondos({ preserveSelection = false } = {}) {
        const ids = this.getSelectedGestoras().map(g => g.Id);
        if (!ids.length) { this.isBusy = false; return; }
        try {
            const data = await getFondosByGestoras({
                gestoraIds: ids,
                contratoMarcoId: this.recordId
            });
            this.fondos = (data || [])
                .map(f => ({
                    ...f,
                    parentName: (f?.Parent && f.Parent.Name) || f?.ParentName || f?.['Parent.Name'] || ''
                }))
                .sort((a, b) => (a.Name || '').toLowerCase().localeCompare((b.Name || '').toLowerCase()));

            this.currentFondoPage = 1;
            this.applyFondoFilters();

            if (!preserveSelection) {
                this.selectedFondoIds?.clear?.();
                this.selectedFondos = [];
            } else {
                this.selectedFondos = this.fondos.filter(f => this.selectedFondoIds.has(f.Id));
            }

            this.hasLoadedFondos = true;
        } catch (e) {
            console.error(e);
        } finally {
            this.isBusy = false;
        }
    }

    handleFondoSearch(event) {
        this.searchFondoTerm = (event?.target?.value || '').toLowerCase();
        this.currentFondoPage = 1;
        this.applyFondoFilters();
    }

    applyFondoFilters() {
        const term = this.searchFondoTerm ? this.searchFondoTerm.toLowerCase() : '';
        this.filteredFondos = term
            ? this.fondos.filter(f =>
                (f.Name && f.Name.toLowerCase().includes(term)) ||
                (f.parentName && f.parentName.toLowerCase().includes(term)) ||
                (f.lei_id__c && f.lei_id__c.toLowerCase().includes(term)) ||
                (f.SER_CClient__c && f.SER_CClient__c.toLowerCase().includes(term))
              )
            : [...this.fondos];
        this.totalFondoPages = Math.ceil(this.filteredFondos.length / PAGE_SIZE) || 1;
        this.updateFondoPagination();
    }

    updateFondoPagination() {
        const start = (this.currentFondoPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.displayedFondos = this.filteredFondos.slice(start, end);
    }

    handleFondoPrevPage() {
        if (this.currentFondoPage > 1) {
            this.currentFondoPage--;
            this.updateFondoPagination();
        }
    }
    handleFondoNextPage() {
        if (this.currentFondoPage < this.totalFondoPages) {
            this.currentFondoPage++;
            this.updateFondoPagination();
        }
    }

    handleFondoSelection(event){
        const selectedOnPage = new Set((event.detail.selectedRows || []).map(r => r.Id));
        const currentPageIds = this.displayedFondos.map(r => r.Id);
        currentPageIds.forEach(id => {
            if (selectedOnPage.has(id)) this.selectedFondoIds.add(id);
            else this.selectedFondoIds.delete(id);
        });
        this.selectedFondos = this.fondos.filter(f => this.selectedFondoIds.has(f.Id));
    }

    // ===== HELPERS =====
    getSelectedGestoras() {
        if (this.selectedGestoraIds && this.selectedGestoraIds.size)
            return this.gestoras.filter(g => this.selectedGestoraIds.has(g.Id));
        return this.selectedGestoras || [];
    }
    get isSingleGestoraSelected() {
        return this.getSelectedGestoras().length === 1;
    }
    get singleSelectedGestoraName() {
        const arr = this.getSelectedGestoras();
        return arr.length ? arr[0].Name+' - '+(arr[0].lei_id__c === '' || arr[0].lei_id__c == undefined ? 'NO LEI': arr[0].lei_id__c) : '';
    }
    get selectedGestoraOptions() {
        return this.getSelectedGestoras().map(g => ({ label: g.Name+' - '+(g.lei_id__c === '' || g.lei_id__c == undefined ? 'NO LEI': g.lei_id__c), value: g.Id }));
    }

    // ===== CREAR =====
    handleNameChange(e) { this.newGestoraName = e.target.value; }
    handleLeiChange(e) { this.newGestoraLei = e.target.value; }
    handleStarChange(e) { this.newGestoraStar = e.target.value; }
    handleCodigoClienteChange(e) { this.newGestoraCodigoCliente = e.target.value; }
    handleFondoNameChange(e) { this.newFondoName = e.target.value; }
    handleFondoCodigoChange(e) { this.newFondoCodigo = e.target.value; }
    handleFondoGestoraChange(e) { this.newFondoParentId = e.detail.value; }
    handleFondoLeiChange(e) { this.newFondoLei = e.target.value; }

    async crearGestora() {
        if (!this.newGestoraName)
            return this.showToast('Error','The Name is mandatory','error');
        try {
            const acc = await createAccount({
                contratoMarcoId: this.recordId,
                name: this.newGestoraName,
                clientType: ONB_ACTIVITY_ASSET_MANAGER,
                parentId: null,
                lei: this.newGestoraLei || null,
                star: this.newGestoraStar || null,
                codigoCliente: this.newGestoraCodigoCliente || null
            });
            const newId = acc.Id;

            this.isBusy = true;
            await this.loadGestorasFresh({ preserveSelection: true });
            if (newId) this.selectedGestoraIds.add(newId);

            // volver a la vista de gestoras sin limpiar selección ni recargar
            this.currentStep = 'gestoras';
            this.headerCurrentPage = 'Select an Asset Manager';
            this.isBusy = false;

            this.showToast('Éxito','Asset Manager created','success');
        } catch (e) {
            console.error(e);
            this.isBusy = false;
            this.showToast('Error','The asset manager could not be created','error');
        }
    }

    async crearFondo() {
        if (!this.newFondoName)
            return this.showToast('Error','The Name is mandatory','error');
        const selectedG = this.getSelectedGestoras();
        if (!selectedG.length)
            return this.showToast('Error','Select an asset manager','error');
        if (selectedG.length > 1 && !this.newFondoParentId)
            return this.showToast('Error','Select an asset manager for the fund','error');

        try {
            const acc = await createAccount({
                contratoMarcoId: this.recordId,
                name: this.newFondoName,
                clientType: ONB_ACTIVITY_FUND,
                parentId: this.newFondoParentId || selectedG[0].Id,
                lei: null,
                star: null,
                codigoCliente: this.newFondoCodigo || null
            });
            const newId = acc.Id;

            this.isBusy = true;
            await this.cargarFondos({ preserveSelection: true });
            if (newId) this.selectedFondoIds.add(newId);

            // volver a la vista de fondos sin limpiar selección ni recargar
            this.currentStep = 'fondos';
            this.headerCurrentPage = 'Select a Fund';
            this.isBusy = false;

            this.showToast('Éxito','Fund created','success');
        } catch (e) {
            console.error(e);
            this.isBusy = false;
            this.showToast('Error','The fund could not be created','error');
        }
    }

    clearValues(){
        this.newGestoraName = '';
        this.newGestoraLei = '';
        this.newGestoraStar = '';
        this.newGestoraCodigoCliente = '';
        this.newFondoName = '';
        this.newFondoLei = '';
        this.newFondoCodigo = '';
    }

    async finalizar() {
        if (this.selectedFondoIds.size === 0)
            return this.showToast('Error','Select at least one fund','error');
        const fondoIds = Array.from(this.selectedFondoIds);
        try {
            await asociarFondoGestoras({ contratoId: this.recordId, fondosId: fondoIds });
            this.showToast('Success','Funds associated correctly','success');
            this.cerrarAction();
            setTimeout(() => window.location.reload(), 500);
        } catch(e){
            console.error(e);
            this.showToast('Error','The fund could not be associated','error');
        }
    }

    // ===== CONDICIONALES =====
    get isPreviousDisabledGestora(){ return this.currentGestoraPage === 1; }
    get isNextDisabledGestora(){ return this.currentGestoraPage === this.totalGestoraPages; }
    get isPreviousDisabledFondo(){ return this.currentFondoPage === 1; }
    get isNextDisabledFondo(){ return this.currentFondoPage === this.totalFondoPages; }
    get gestorasLength(){ return this.gestoras.length > PAGE_SIZE; }
    get fondosLength(){ return this.fondos.length > PAGE_SIZE; }

    // ===== UTILS =====
    showToast(title,message,variant){
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    cerrarAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}