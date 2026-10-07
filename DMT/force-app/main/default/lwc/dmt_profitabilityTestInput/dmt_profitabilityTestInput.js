import { LightningElement, api } from 'lwc';

// Error messages
const TXT_MUSTBENUMBER_ERROR = 'The value must be a number';
const TXT_GREATEROREQUAL_ERROR = 'The value must be greater than or equal to ';
const TXT_LESSOREQUAL_ERROR = 'The value must be less than or equal to ';
const TXT_MULTIPLEOF_ERROR = 'This field must be a multiple of';
const TXT_NOVALIDSELECTION_ERROR = 'Not valid selection';
const TXT_CSVALIDATION_ERROR = 'Custom validation failed because:';
const TXT_CSVALIDATION_ERROR_CLEARING = 'Error clearing validity: ';
const TXT_REQUIRED_ERROR = 'This field is required';
const TXT_NO_RATING_OPTIONS = 'No rating options available';

// Custom event name dispatched to the parent (dmt_ProfitabilityAxisSelector)
const EVT_NAME = 'axisinputchange';

// Field type constants
const FIELD_TYPE_DECIMAL = 'Decimal';
const FIELD_TYPE_STRING = 'String';

// Axis field API value constants
const RORC_API_VALUE = 6;
const RAROEC_API_VALUE = 5;
const TERM_API_VALUE = 1;
const RATING_API_VALUES = new Set([2, 9]);

// Input ID constants
const INPUT_X_ID_RANGE = 'xRange';
const INPUT_Y_ID_RANGE = 'yRange';

// UI constants
const LABEL_MAX = 'Max';
const PLACEHOLDER_YEARS = 'Years';

export default class Dmt_profitabilityTestInput extends LightningElement {
  @api inputId;
  @api type = FIELD_TYPE_DECIMAL;
  @api valuePublic;
  @api min;
  @api max;
  @api step = 'any';
  @api required = false;
  @api options = [];
  @api debounceMs = 200;
  @api placeholder = '';

  // Removed @track — array reassignment already triggers reactivity in modern LWC
  errors = [];
  _debounce;
  _internalValue;
  _label;
  _fieldSelected;
  _externalError = '';
  _isRendered = false;

  connectedCallback() {
    this._internalValue = this.valuePublic;
  }

  renderedCallback() {
    if (!this._isRendered) {
      this._isRendered = true;
      if (this._externalError) {
        this._applyExternalError();
      }
    }
  }

  @api
  set externalError(val) {
    this._externalError = val || '';
    if (this._isRendered) {
      this._applyExternalError();
    }
  }
  get externalError() {
    return this._externalError;
  }

  @api
  set fieldSelected(value) {
    const changed = this._fieldSelected != value;
    if (changed) {
      this._resetInputState();
    }
    this._fieldSelected = value;
    if (value) {
      this._applyFieldConstraints(value);
    }
    if (changed) {
      try {
        this._dispatchChange();
      } catch (e) {
        console.warn('Error dispatching change on fieldSelected', e);
      }
    }
  }
  get fieldSelected() {
    return this._fieldSelected;
  }

  @api
  set label(value) {
    if (value) this._label = value;
  }
  get label() {
    if (!this._label) return null;
    if (this._isRangeInput && this.isRating) {
      return LABEL_MAX;
    }
    return this._label;
  }

  get isRating() {
    return RATING_API_VALUES.has(Number(this.fieldSelected));
  }

  get noRatingOptions() {
    return this.isRating && (!this.options || this.options.length === 0);
  }

  get computedPlaceholder() {
    if (this.placeholder) return this.placeholder;
    if (
      String(this.inputId).toLowerCase() === 'term' ||
      Number(this.fieldSelected) === TERM_API_VALUE
    ) {
      return PLACEHOLDER_YEARS;
    }
    return '';
  }

  // Cached getter to avoid repeated string comparisons
  get _isRangeInput() {
    return (
      this.inputId === INPUT_X_ID_RANGE || this.inputId === INPUT_Y_ID_RANGE
    );
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

  @api
  refresh() {
    try {
      this._validateAndSetErrors();
      this._dispatchChange();
    } catch (e) {
      console.warn('dmt_profitabilityTestInput.refresh error', e);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  _resetInputState() {
    this._internalValue = '';
    this.errors = [];
    if (this._debounce) {
      clearTimeout(this._debounce);
      this._debounce = undefined;
    }
    this._clearControlValidity(true);
  }

  _applyFieldConstraints(value) {
    if (
      ( Number(value) === RORC_API_VALUE || Number(value) === RAROEC_API_VALUE) &&
      this._isRangeInput
    ) {
      this.min = 0;
      this.max = 1;
    } else {
      this.max = undefined;
    }
  }

  _validateAndSetErrors() {
    const errs = [];
    const val = this._normalizeDecimal(this._internalValue);

    if (
      this.required &&
      (this._internalValue === '' || this._internalValue == null)
    ) {
      errs.push(TXT_REQUIRED_ERROR);
    }

    if (this.type === FIELD_TYPE_DECIMAL && val) {
      this._validateDecimal(val, errs);
    }

    if (this.type === FIELD_TYPE_STRING && this._internalValue) {
      this._validateString(errs);
    }

    this.errors = errs;
    this._applyAllErrors();
    return errs.length === 0;
  }

  _validateDecimal(val, errs) {
    const step = this.step !== 'any' ? parseFloat(this.step) : 'any';
    if (Number.isNaN(parseFloat(val))) {
      errs.push(TXT_MUSTBENUMBER_ERROR);
    }
    if (!Number.isNaN(this.min) && val < this.min) {
      errs.push(TXT_GREATEROREQUAL_ERROR + `${this.min}`);
    }
    if (!Number.isNaN(this.max) && val > this.max) {
      errs.push(TXT_LESSOREQUAL_ERROR + `${this.max}`);
    }
    if (step !== 'any' && !Number.isNaN(step) && step !== 0) {
      if (Math.abs(val / step - Math.round(val / step)) > 1e-10) {
        errs.push(TXT_MULTIPLEOF_ERROR + `${step}`);
      }
    }
  }

  _validateString(errs) {
    if (this.noRatingOptions) {
      errs.push(TXT_NO_RATING_OPTIONS);
    } else {
      const found = (this.options || []).find(
        (o) => `${o.value}` === `${this._internalValue}`
      );
      if (!found) errs.push(TXT_NOVALIDSELECTION_ERROR);
    }
  }

  _dispatchChange() {
    const normalizedValue =
      this.type === FIELD_TYPE_DECIMAL
        ? this._normalizeDecimal(this._internalValue)
        : this._internalValue;
    const payload = {
      inputId: this.inputId,
      value: normalizedValue,
      valid: this.errors.length === 0,
      disabledWithErrors: this.errors.length > 0,
      errors: this.errors.slice()
    };
    this.dispatchEvent(
      new CustomEvent(EVT_NAME, {
        detail: payload,
        bubbles: true,
        composed: true
      })
    );
  }

  _applyAllErrors() {
    const control = this.template.querySelector(
      'lightning-input, lightning-combobox'
    );
    if (!control) return;
    const isInvalid = this.errors.length > 0 || !!this._externalError;
    try {
      control.setCustomValidity(isInvalid ? '\u200B' : '');
      control.reportValidity();
    } catch (e) {
      console.warn(TXT_CSVALIDATION_ERROR, e);
    }
  }

  _applyExternalError() {
    this._applyAllErrors();
  }

  _normalizeDecimal(value) {
    if (!value) return value;
    if (typeof value !== 'string') return Number(value);
    // Incomplete decimal — user is still typing (e.g. '0.' or '0,')
    if (value.endsWith('.') || value.endsWith(',')) return value;
    // Accept comma as decimal separator (European locale)
    const normalized = value.replace(',', '.');
    const num = Number(normalized);
    return Number.isNaN(num) ? value : num;
  }

  _clearControlValidity(clearValue = false) {
    const control = this.template?.querySelector?.(
      'lightning-input, lightning-combobox'
    );
    if (!control) return;
    try {
      control.setCustomValidity('');
      if (clearValue) {
        try {
          control.value = '';
        } catch (inner) {
          console.warn('Could not clear control value', inner);
        }
      }
      control.reportValidity();
    } catch (e) {
      console.warn(TXT_CSVALIDATION_ERROR_CLEARING, e);
    }
  }
}