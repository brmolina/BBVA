import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';

export default class Onb_toggle extends LightningElement {
    @api recordId;
    @api text;
    @api fieldApiName; // ---> NUEVO: Recibe el nombre del campo dinámicamente

    handleToggleChange(event) {
        const isChecked = event.target.checked;
        const fields = {};
        fields.Id = this.recordId;
        // ---> NUEVO: Actualiza el campo que le hayamos pasado
        fields[this.fieldApiName] = isChecked;

        updateRecord({ fields })
            .then(() => {
                // Avisamos hacia arriba del cambio
                this.dispatchEvent(new CustomEvent('togglechange', {
                    detail: { checked: isChecked }
                }));
            })
            .catch(error => console.error('Error guardando toggle', error));
    }
}