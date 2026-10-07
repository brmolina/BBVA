import { LightningElement, api, track } from 'lwc';
import pubsub from 'omnistudio/pubsub';

const EVT_CLOSE_LWC = 'close_modal';

export default class DmtRiskApproval extends LightningElement {

    @api oppId;
    @api customerId;
    @api linerecordType;

    _lineName = '';
    _lineId = '';
    _status = '';
    @track selectedOption = 'Limit'; // opción radio seleccionada
    @track showLine = false;
    @track isReadOnly = false;
    @track variantLimit = 'brand'
    @track variantLine = 'neutral'

    @api
    set lineName(value) {
        if(this.linerecordType != 'Risk Approval'){
            if (value && value !== 'null' && value !== 'undefined') {
                this.variantLimit = 'neutral';
                this.variantLine = 'brand';
                this._lineName = value;
                this.showLine = true;
            } else {
                this._lineName = '';
                this.showLine = false;
            }
        }else{
            this.variantLimit = 'brand';
            this.variantLine = 'neutral';
            this._lineName = '';
            this.isReadOnly = true;
            this.showLine = false;
        }
        
        
    }

    get status() {
        return this._status;
    }
    @api
    set status(value) {
        this._status = value;
        if(this._status != 'Draft' && this.status != 'Proposal'){
            this.isReadOnly = true;
        }
        
        
    }

    get lineName() {
        return this._lineName;
    }
    @api
    set lineId(value) {
        this._lineId = value || '';
    }

    get lineId() {
        return this._lineId;
    }
    get options() {
        return [
            { label: 'Limit', value: 'Limit' },
            { label: 'Line', value: 'Line' }
        ];
    }

    handleOptionChange(event) {
       
        const value = event.detail.value;
        this.selectedOption = value;

        if (value === 'Line') {
            this.openModal();
        } else {
            this.handleUnassociateLine();
        }
    }
    /**
     * Lanza evento para abrir el modal desde la FlexCard o el padre
     */
    openModal() {
        this.dispatchEvent(new CustomEvent('openriskapprovalmodal', {
            bubbles: true,
            composed: true,
            detail: {
                oppId: this.oppId,
                customerId: this.customerId,
                lineId: this._lineId,      // pasa línea previamente asociada
                lineName: this._lineName   // pasa nombre de línea previamente asociada
            }
        }));
    }
    handleLimitClick(){
        this.variantLimit = 'brand';
        this.variantLine = 'neutral';
    }
    /**
     * Recibe los datos cuando se guarda el modal
     */
    handleModalSave(event) {
        const { lineId, lineName } = event.detail;

        this._lineId = lineId;
        this._lineName = lineName;
        this.selectedOption = 'Line'; // asegura que el radio quede en Line
    }

    /**
     * Maneja la desasociación de la línea al seleccionar Limit
     */
    handleUnassociateLine() {

        // NO borramos lineName ni lineId para mantener el link visible
        console.log('Línea desasociada internamente, link permanece visible');
    }
    handleLineLinkClick() {
        this.openModal();
    }
}