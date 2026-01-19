import { LightningElement, track, wire, api } from 'lwc';
import pubsub from 'c/pubsub';
import getTypeItemOptions from '@salesforce/apex/DMT_ItemController.getTypeItemOptions';
import getComponentItemOptions from '@salesforce/apex/DMT_ItemController.getFilteredComponentItemOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Dmt_item_selector extends LightningElement {
    @api viewName = '';
    @api viewType = '';
    @api isProfitability = false;

    @track selectedType = '';
    @track selectedComponentItem = '';
    @track typeOptions = [];
    @track componentOptions = [];
    @track filteredComponentOptions = [];
    @track isComponentDisabled = true;
    @track isTextComponent = false;
    @track textValue = '';
    @track items = [];
    draggedItemIndex = null;

    @track _writeAccess = false;
    @track _inputsDisabled = false;

    @api viewTypeOptions = [];

    selectComponentItemLabel = 'Select Component Item';
    @api searchIdLabel = 'Search Id';

    get ViewTypeInputDisabled() {
        return this.viewType !== '' || this.inputsDisabled;
    }

    // -------------------------------
    // Reactive writeAccess setter
    // -------------------------------
    @api
    set writeAccess(value) {
        this._writeAccess = value;
    }
    get writeAccess() {
        return this._writeAccess;
    }

    // -------------------------------
    // Reactive inputsDisabled setter
    // -------------------------------
    @api
    set inputsDisabled(value) {
        this._inputsDisabled = value;
    }
    get inputsDisabled() {
        return this._inputsDisabled;
    }

    // -------------------------------
    // Reactive getters used in HTML
    // -------------------------------
    get draggable() {
        // Row draggable only if user has write access and inputs are enabled
        return this._writeAccess && !this._inputsDisabled;
    }

    get areInputsDisabled() {
        // Delete button disabled if no write access or inputs disabled
        return !this._writeAccess || this._inputsDisabled;
    }

    get isViewNameInputsDisabled() {
        return !this._writeAccess || this.isProfitability || this.viewType == '' || this._inputsDisabled;
    }

    get isAddComponentDisabled() {
        return !this._writeAccess || this.isComponentDisabled || this._inputsDisabled;
    }

    get isTypeInputsDisabled() {
        return !this._writeAccess || this.viewName == '' || this._inputsDisabled;
    }

    @api
    set selectedItems(value) {
        if (value) {
            this.items = [...value].sort((a, b) => a.orderDisplay - b.orderDisplay);
        } else {
            this.items = [];
        }
    }

    get selectedItems() {
        return this.items;
    }

    get itemsWithKeys() {
        return this.items.map((item, index) => ({
            ...item,
            key: `${item.type}-${item.component}-${index}`
        }));
    }

    connectedCallback() {
        console.log('dmt_item_selector connectedCallback writeAccess:', this.writeAccess);
        console.log('dmt_item_selector connectedCallback viewType:', this.viewType);
        console.log('dmt_item_selector viewTypeOptions:', JSON.stringify(this.viewTypeOptions));
        this.updateComponentItemLabel();
    }

    renderedCallback() {
        if(this.viewType == '') {
            setTimeout(() => {
                const input = this.template.querySelector('[data-id="viewTypeInput"]');
                if (input) {
                    input.focus();
                }
            }, 0);
        }
    }

    updateComponentItemLabel() {
        const matchedOption = this.viewTypeOptions.find(option => option.value === this.viewType);
        if (matchedOption) {
            this.selectComponentItemLabel = `Select ${matchedOption.label} Component Item`;
            this.searchIdLabel = `Search ${matchedOption.label} Id`;
            this.dispatchViewTypeChanged();
        } else {
            console.warn('Selected viewType not recognized:', this.viewType);
        }
    }

    handleViewTypeChange(event) {
        this.viewType = event.target.value;
        this.viewName = '';
        this.isComponentDisabled = true;
        this.updateComponentItemLabel();
        this.selectedComponentItem = null;
        this.selectedType = '';
        this.items = [];
        this.dispatchViewTypeChanged();

        setTimeout(() => {
            const input = this.template.querySelector('[data-id="viewNameInput"]');
            if (input) {
                input.focus();
            }
        }, 0);
    }

    dispatchViewTypeChanged() {
        this.dispatchEvent(new CustomEvent('viewtypechanged', {
            detail: { searchIdLabel: this.searchIdLabel, viewType: this.viewType }
        }));
    }

    @wire(getTypeItemOptions)
    wiredTypeOptions({ error, data }) {
        if (data) {
            this.typeOptions = data.map(option => ({ label: option, value: option }));
        } else if (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'No se pudieron cargar las opciones de Type Item.',
                variant: 'error'
            }));
        }
    }

    @wire(getComponentItemOptions, { viewType: '$viewType' })
    wiredComponentOptions({ error, data }) {
        if (data) {
            this.componentOptions = data.map(option => ({ label: option, value: option }));
        } else if (error) {
            this.componentOptions = [];
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'No se pudieron cargar las opciones de Component Item.',
                variant: 'error'
            }));
        }
    }

    handleNameChange(event) {
        this.viewName = event.target.value;
        this.dispatchEvent(new CustomEvent('viewnamechanged', { detail: { viewName: this.viewName } }));
    }

    handleTypeChange(event) {
        this.selectedType = event.target.value;
        this.selectedComponentItem = null;
        this.isTextComponent = this.selectedType === 'Text';
        this.filterComponentOptions();
    }

    handleComponentChange(event) {
        this.selectedComponentItem = event.target.value;
    }

    handleTextChange(event) {
        this.textValue = event.target.value;
    }

    filterComponentOptions() {
        if (this.selectedType === 'Component') {
            this.filteredComponentOptions = this.componentOptions;
            this.isComponentDisabled = false;
        } else if (this.selectedType === 'Break') {
            this.filteredComponentOptions = [{"label":"Line Break","value":"Line Break"},{"label":"Page Break","value":"Page Break"}];
            this.isComponentDisabled = false;
        } else if (this.selectedType === 'Text') {
            this.filteredComponentOptions = [{"label":"Text 18px","value":"Text 18px"},{"label":"Text 14px","value":"Text 14px"},{"label":"Text 12px","value":"Text 12px"}];
            this.isComponentDisabled = false;
        } else {
            this.filteredComponentOptions = [];
            this.isComponentDisabled = true;
        }
    }

    addItem() {
        if (this.selectedType && this.selectedComponentItem) {
            const newItem = {
                type: this.selectedType,
                component: this.selectedComponentItem,
                orderDisplay: this.items.length + 1,
                textValue: this.isTextComponent ? this.textValue : ''
            };
            this.items = [...this.items, newItem];
            this.selectedComponentItem = null;
            this.dispatchUpdatedItems();
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Selecciona un tipo y un componente.',
                variant: 'error'
            }));
        }
    }

    dispatchUpdatedItems() {
        this.dispatchEvent(new CustomEvent('itemselected', { detail: [...this.items] }));
    }

    handleDragStart(event) {
        this.draggedItemIndex = event.target.dataset.index;
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        const dropIndex = event.target.closest('tr').dataset.index;
        const items = JSON.parse(JSON.stringify(this.items));
        if (dropIndex !== this.draggedItemIndex) {
            const draggedItem = items.splice(this.draggedItemIndex, 1)[0];
            items.splice(dropIndex, 0, draggedItem);
            items.forEach((item, index) => item.orderDisplay = index + 1);
            this.items = [...items];
            this.dispatchUpdatedItems();
        }
    }

    handleRemoveItem(event) {
        const index = parseInt(event.target.dataset.index, 10);
        if (index >= 0 && index < this.items.length) {
            const items = JSON.parse(JSON.stringify(this.items));
            items.splice(index, 1);
            items.forEach((item, idx) => item.orderDisplay = idx + 1);
            this.items = items;
            this.dispatchUpdatedItems();
        }
    }
}