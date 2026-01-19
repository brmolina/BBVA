import { LightningElement , api, track} from 'lwc';

export default class Dmt_custom_tree_row extends LightningElement {
    @api item;
    @api columns;
    @api depth;
    

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
        return this.item.isParent ? 'slds-hint-parent group slds-theme_shade collapsed' : 'slds-hint-parent';
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

}