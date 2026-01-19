import { LightningElement,api } from 'lwc';
import dmt_cl_ProfMin_Text from "@salesforce/label/c.dmt_cl_ProfMin_Text";
import dmt_cl_ProfRange from "@salesforce/label/c.dmt_cl_ProfRange";
import getInitialOptions from '@salesforce/apex/DMT_ProfitabilityAxisSelectorController.getInitialOptions';

export default class Dmt_ProfitabilityAxisSelector extends LightningElement {
    label = {
    dmt_cl_ProfMin_Text,
    dmt_cl_ProfRange};

    @api catalogRating;
    optionsX = [];
    optionsY = [];
    optionsCentral = [];
    xSelected = '';
    ySelected = '';
    centralSelected = '';
    disabledControls = false;
    errorMessage = '';
    xFieldType = 'Decimal';
    yFieldType = 'Decimal';

    connectedCallback() {
        this.loadInitialOptions();
    }

    async loadInitialOptions() {
        try {
            const resp = await getInitialOptions();
            // resp.xOptions / yOptions / centralOptions are lists de OptionDTO { id, label, value }
            this.optionsX = Array.isArray(resp.xOptions) ? resp.xOptions.map(o => ({ label: o.label, value: o.value, dataType: o.dataType })) : [];
            this.optionsY = Array.isArray(resp.yOptions) ? resp.yOptions.map(o => ({ label: o.label, value: o.value, dataType: o.dataType })) : [];
            this.optionsCentral = Array.isArray(resp.centralOptions) ? resp.centralOptions.map(o => ({ label: o.label, value: o.value, dataType: o.dataType })) : [];

            const missing = [];
            if (this.optionsX.length === 0) missing.push('eje X');
            if (this.optionsY.length === 0) missing.push('eje Y');
            if (this.optionsCentral.length === 0) missing.push('valor central');

            if (missing.length) {
                this.disabledControls = true;
                this.errorMessage = 'Faltan datos para usar la calculadora: ' + missing.join(', ') + '. Contacta con el administrador.';
                // limpiar selecciones previas por seguridad
                this.xSelected = '';
                this.ySelected = '';
                this.centralSelected = '';
            } else {
                this.disabledControls = false;
                this.errorMessage = '';
                this.xFieldType = this.optionsX[0]?.dataType || 'Decimal';
                this.yFieldType = this.optionsY[0]?.dataType || 'Decimal';
            }
        } catch (error) {
            // manejo mínimo de errores
            // eslint-disable-next-line no-console
            console.error('Error loading initial options', error);
            this.optionsX = [];
            this.optionsY = [];
            this.optionsCentral = [];
            this.disabledControls = true;
            this.errorMessage = 'Error cargando opciones. Revisa la consola y contacta con el administrador.';
        }
    }

    handleChange(event) {
        const name = event.target.name;
        const value = event.detail.value;
        if (name === 'XAxis') {
            this.xSelected = value;
            const found = this.optionsX.find(o => `${o.value}` === `${value}`);
            this.xFieldType = found?.dataType || 'Decimal';
        } else if (name === 'YAxis') {
            this.ySelected = value;
            const found = this.optionsY.find(o => `${o.value}` === `${value}`);
            this.yFieldType = found?.dataType || 'Decimal';
        } else if (name === 'CentralAxis') {
            this.centralSelected = value;
        }
        // puedes añadir dispatchEvent si necesitas propagar la selección
    }
}