import { LightningElement, api, track } from 'lwc';
import pubsub from 'omnistudio/pubsub';

const TXT_MUSTBENUMBER_ERROR='The value must be a number';
const TXT_GREATEROREQUAL_ERROR='The value must be greater than or equal to ';
const TXT_LESSOREQUAL_ERROR='The value must be less than or equal to ';
const TXT_MULTIPLEOF_ERROR='This field must be a multiple of';
const TXT_NOVALIDSELECTION_ERROR='Not valid selection';
const TXT_CSVALIDATION_ERROR='Custom validation failed because:';
const TXT_CSVALIDATION_ERROR_CLEARING='Error clearing validity: ';
const EVT_CHANNEL_NAME='DMT_ProfitabilityTest_Child';
const EVT_NAME='axisinputchange';
const RORC_API_VALUE=6;
const RAROEC_API_VALUE=5;
const TERM_API_VALUE=1;
const RATING_API_VALUE=2;
const INPUT_X_ID_RANGE='xRange';
const INPUT_Y_ID_RANGE='yRange';


export default class Dmt_profitabilityTestInput extends LightningElement {
    @api inputId;
    @api type = 'Decimal'; // 'Decimal' | 'String'
    @api valuePublic; //for preset value from parent
    @api min; //min for custom val
    @api max; //max for custom val
    @api step = 'any'; //step defult
    @api required = false; //required field
    @api options = []; //Option for string type.Its shows combobox
    @api debounceMs = 200;
    @api placeholder = '';

    @track errors = [];

    _debounce;
    _internalValue;
    _label;
    _fieldSelected;

    connectedCallback() {
        this._internalValue = this.valuePublic;
    }
    @api
    set fieldSelected(value) {
        if( this._fieldSelected!= value){
            this._internalValue = '';
            this.errors = [];
            if (this._debounce) {
                clearTimeout(this._debounce);
                this._debounce = undefined;
            }
            this._clearControlValidity();
        }
        if(value){
            this._fieldSelected = value;
            if ((value === RORC_API_VALUE || value === RAROEC_API_VALUE) && (this.inputId ===INPUT_X_ID_RANGE || this.inputId ===INPUT_Y_ID_RANGE)) {
                this.min = 0;
                this.max = 1;
            }else{
                this.Max = undefined;
            }
            this._internalValue='';
            this.errors=[];
            this._clearControlValidity();

        }
       
    }

    @api
    set label(value) {
        if (value)
        this._label = value;
    }

    get label() {
        if (!this._label) return null;
        // If this is the xRange or yRange input and the selected field is RATING, show "max" in the label
        if ((this.inputId === INPUT_X_ID_RANGE || this.inputId === INPUT_Y_ID_RANGE)
            && Number(this.fieldSelected) === RATING_API_VALUE) {
            return 'Max';
        }
        return this._label;
    }

    get fieldSelected() {
        return this._fieldSelected;
    }

    get isRating() {
        return this.fieldSelected==RATING_API_VALUE && this.options?.length > 0;
        //eturn this.type === 'String' && this.options?.length > 0;
    }

    
    get computedPlaceholder() {
        if (this.placeholder) return this.placeholder;
        if (String(this.inputId).toLowerCase() === 'term' || Number(this.fieldSelected)=== TERM_API_VALUE) {
            return 'Years';
        }
        // fallback vacío (no placeholder)
        return '';
    }

    @api
    validate() {
        const ok = this._validateAndSetErrors();
        this._dispatchChange();
        return ok;
    }

    handleChange(e) {
        const newVal = e.detail?.value ?? e.target.value;
        this._internalValue = newVal;
        if (this._debounce) clearTimeout(this._debounce);
        this._debounce = setTimeout(() => {
            this._debounce = undefined;
            this._validateAndSetErrors();
            this._dispatchChange();
        }, this.debounceMs);
    }

    _validateAndSetErrors() {
        const errs = [];
        const val = this._normalizeDecimal(this._internalValue);

        if (this.required && (this._internalValue === '' || this._internalValue === null || this._internalValue === undefined)) {
            errs.push('This field is required');
        }

        if (this.type === 'Decimal' && val) {
            const step = this.step !== 'any' ? parseFloat(this.step) : 'any';
            if( Number.isNaN(parseFloat(val)) ) {
                errs.push(TXT_MUSTBENUMBER_ERROR);
            }
            if (!Number.isNaN(this.min) && val < this.min) {
                errs.push(TXT_GREATEROREQUAL_ERROR+`${this.min}`);
            }

            if (!Number.isNaN(this.max) && val > this.max) {
                errs.push(TXT_LESSOREQUAL_ERROR+`${this.max}`);
            }

            if (step !== 'any' && !Number.isNaN(step) && step !== 0) {
                const isMultiple = Math.abs((val / step) - Math.round(val / step)) > 1e-10;
                if (isMultiple) {
                    errs.push(TXT_MULTIPLEOF_ERROR+`${step}`);
                }
            }
        }

        if (this.type === 'String' && this._internalValue) {
            const found = (this.options || []).find(o => `${o.value}` === `${this._internalValue}`);
            if (!found) errs.push(TXT_NOVALIDSELECTION_ERROR);
        }

        this.errors = errs;

        const control = this.template.querySelector('lightning-input, lightning-combobox');
        if (control) {
            try {
                control.setCustomValidity(errs.length > 0 ? errs.join(', ') : '');
                control.reportValidity();
            } catch (e) {
                console.warn(TXT_CSVALIDATION_ERROR, e);
            }
        }

        return errs.length === 0;
    }

    _dispatchChange() {
        if(this.type==='Decimal'){
            this._internalValue=this._normalizeDecimal(this._internalValue);
        }
        const payload = {
            inputId: this.inputId,
            value: this._internalValue,
            valid: this.errors.length === 0,
            disabledWithErrors: this.errors.length > 0,
            errors: this.errors.slice()
        };
        this.dispatchEvent(new CustomEvent(EVT_NAME, { detail: payload }));
        pubsub.fire(EVT_CHANNEL_NAME, EVT_NAME, { detail: payload });
    }

    
   _normalizeDecimal(value) {
        if (!value) return value;
        if (typeof value !== 'string') return Number(value);
        return Number.isNaN(Number(value)) ? value : Number(value);
    }

    _clearControlValidity() {
        const control = this.template && this.template.querySelector
            ? this.template.querySelector('lightning-input, lightning-combobox')
            : null;
        if (control) {
            try {
                control.setCustomValidity('');
                control.reportValidity();
            } catch (e) {
                console.warn(TXT_CSVALIDATION_ERROR_CLEARING, e);
            }
        }
    }

}