import { LightningElement,api } from 'lwc';
import { FlexCardMixin  } from 'omnistudio/flexCardMixin';

import pubsub from 'omnistudio/pubsub';

export default class Dmt_selectlabel_flexcard extends FlexCardMixin(LightningElement) {

    @api catalog;
    _list;
    _hasRendered = false;

    @api
    set list(value) {
        // Convertir objeto en array si es necesario
        if (!Array.isArray(value) && typeof value === 'object' && value !== null && value.hasOwnProperty('value')) {
            value = [value];
        }

        if (Array.isArray(value) && value.length > 0 && value[0].hasOwnProperty('value')) {

           const clonedValue = value.map(item => ({ ...item }));
           const hasDefault = clonedValue.some(item => item.defaultValue === true);

           if (!hasDefault) {
            clonedValue[0].defaultValue = true;
           }

            this._list = clonedValue;
            
            //const firstOption = value[0];

            //if (firstOption.defaultValue === false) {
                //this.dispatchEvent(new CustomEvent('enableButton', { detail: true, bubbles: true, composed: true }));
            //}

        } else {
            // Si no es una lista válida, vacía la lista y fuerza el botón deshabilitado
            this._list = [];
            this.dispatchEvent(new CustomEvent('enableButton', { detail: true, bubbles: true, composed: true }));
        }
    }

    get list() {
        return this._list;
    }

    @api type;

    get displayType() {
        switch (this.type?.trim()) {
            case 'Line_Treasury':
                return 'Line Treasury';
            case 'Opportunity':
                return 'Opportunity';
            case 'Line':
                return 'Line (Other Products)';
            default:
                return this.type;
        }
    }

    renderedCallback() {

        if (this._hasRendered || !this._list || this._list.length === 0) return;
        
            this._hasRendered = true;

            const defaultOption = this._list.find(opt => opt.defaultValue);
            const selectedValue = defaultOption?.value || 'KO';
            const selectedLabel = defaultOption?.label || '--None--';

            let eventName = 'changeValues';
            const typeClean = this.type?.trim();

            if (typeClean === 'Line'){
                 eventName = 'changeValuesOthers';
            }else if (typeClean === 'Opportunity'){
                 eventName = 'changeValuesOpportunity';
            }else if (typeClean === 'Line_Treasury'){
                 eventName = 'changeValuesTreasury';
            }
           
            pubsub.fire("select", eventName, {
                        catalog: this.catalog,
                        label: selectedLabel,
                        value: selectedValue
            });
    }

    handleChangeValue(event) {
        
        const selectedValue = event.target.value;
        const shouldDisable = !selectedValue || selectedValue === 'KO';

        // Determinar el nombre del evento segun type
        let eventName = 'changeValues'; // valor por defecto
        const typeClean = this.type?.trim();

        if (typeClean === 'Line') {
            eventName = 'changeValuesOthers';
        } else if (typeClean === 'Opportunity') {
            eventName = 'changeValuesOpportunity';
        } else if (typeClean === 'Line_Treasury') {
            eventName = 'changeValuesTreasury';
        }

        pubsub.fire("select", eventName, {catalog: this.catalog, label: event.target.label, value: selectedValue })
    
        if (shouldDisable) {
            this.dispatchEvent(new CustomEvent('enableButton',{detail:true, bubbles:true, composed: true}));
        } else {
            this.dispatchEvent(new CustomEvent('allowSave',{detail:false, bubbles:true, composed: true}));
        }
    
    }
}