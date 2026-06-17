import { LightningElement , api, track} from 'lwc';

export default class Dmt_custom_tree_row extends LightningElement {
    @api item;
    @api columns;
    @api depth;
    @api isSelectionMode = false;
    @api selectedRowKeys = [];


    @api
    get expanded() {
        return this.isExpanded;
    }

    set expanded(value) {
        this.isExpanded = value;
        this.expandedIcon = this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }
    childProps;
    componentConstructor;
    isModalOpen = false;
    isExpanded = false;
    expandedIcon = 'utility:chevronright';

    get indentStyle() {
        let margin = parseInt(this.depth, 10) * 1.3;
        return 'margin-left: ' + margin + 'em';
    }

    get colourStyle() {
        return (this.item.isParent && parseInt(this.depth, 10) === 0)
            ? 'slds-hint-parent group slds-theme_shade collapsed'
            : 'slds-hint-parent';
    }

    get hasChildren() {
        return this.item.subitems && this.item.subitems.length > 0;
    }

    get nextDepth() {
        return parseInt(this.depth, 10) + 1;
    }

    toggleExpand() {
        this.isExpanded = !this.isExpanded;
        this.expandedIcon = this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    async openModal() {
        try {
            this.childProps = {closecallback : this.handleModalClose.bind(this),record: this.item.originalItem}
            const { default: ctor } = await import("c/dmt_case_history_modal");
            this.componentConstructor = ctor;
            this.isModalOpen = true;
        }
        catch (error) {
            console.error('Error loading the modal dynamically', JSON.stringify(error));
        }
    }

    handleModalClose() {
        this.isModalOpen = false;
    }

    handleOpenModalClick() {
        const params = {};
        this.openModal();
    }

    //DESARROLLO ACCIONES MASIVAS

    get isSelectable() {
        return this.depth === "0" || this.depth === 0;
    }

    get isChecked() {
        return this.isSelectable && Array.isArray(this.selectedRowKeys) && this.selectedRowKeys.includes(this.item.itemKey);
    }

    // NUEVO: Manejador del clic en el checkbox
    handleCheckboxChange(event) {
        console.log('JACG evento ' + JSON.stringify(event.target.checked));
        const isChecked = event.target.checked;

        // Avisamos a la tabla de que esta fila se ha marcado/desmarcado
        this.dispatchEvent(new CustomEvent('rowselect', {
            detail: {
                itemKey: this.item.itemKey,
                isSelected: isChecked
            },
            bubbles: true,
            composed: true
        }));
    }

    // NUEVO: Si una sub-fila lanza un evento (aunque en tu caso no sean seleccionables,
    // es buena práctica para mantener la estructura recursiva), lo reenviamos hacia arriba.
    forwardSelectionEvent(event) {
        this.dispatchEvent(new CustomEvent('rowselect', {
            detail: event.detail,
            bubbles: true,
            composed: true
        }));
    }
}