import { LightningElement, api } from 'lwc'
import { loadStyle } from 'lightning/platformResourceLoader'
import DMT_Styles from '@salesforce/resourceUrl/DMT_Styles'

export default class dmt_custom_path_refactor extends LightningElement {
  @api recordId
  @api objectApiName
  @api status
  @api stages = []

  _selectedStage

  @api
  get selectedStage() {
    return this._selectedStage;
  }
  set selectedStage(value) {
    this._selectedStage = value;
  }

  isLoading = false
  isDisabled = false
  _stylesLoaded = false

  @api
  setLoading(value) {
    this.isLoading = value;
    this.isDisabled = value;
  }

  @api
  setIsDisabled(value) {
    this.isDisabled = value;
  }

  get computedSteps() {
    if (!this.stages || this.stages.length === 0) return [];

    const visualSelection = this._selectedStage || this.status;
    const currentStatusIndex = this.stages.indexOf(this.status);
    const isLostRecord = this.status && this.status.includes('Lost');

    return this.stages.map((stage, index) => {
      const isSelected = (stage === visualSelection);
      const isCurrentStatus = (stage === this.status);
      const isPast = (index < currentStatusIndex);

      // --- CONSTRUCCIÓN DE CLASES (ORDEN ESTRICTO) ---
      // Empezamos con la base
      let classList = 'slds-path__item';

      // 1. ESTADO BASE (Color de fondo)
      if (isCurrentStatus) {
         if (isLostRecord) classList += ' slds-is-lost'; // Rojo
         else classList += ' slds-is-current'; // Azul claro
      }
      else if (isPast) {
         if (isLostRecord) classList += ' slds-is-incomplete'; // Blanco (Efecto Ghost para Lost)
         else classList += ' slds-is-complete'; // Verde (Normal)
      }
      else {
         classList += ' slds-is-incomplete'; // Blanco/Gris (Futuro)
      }

      // 2. ESTADO ACTIVO (Selección manual)
      // Esta clase añade el Z-Index 100 y el color Azul Oscuro
      if (isSelected) {
         classList += ' slds-is-active';
      }

      return {
        label: stage,
        value: stage,
        className: classList,
        // Check icon: Solo en pasos pasados verdes que NO están seleccionados
        showCheckIcon: isPast && !isLostRecord && !isSelected
      };
    });
  }

  // ... (Tus getters buttonLabel, buttonIcon, renderedCallback, handlers siguen igual)
  get buttonLabel() {
    if (this.isLoading) return 'Saving...';
    if (this._selectedStage && this._selectedStage !== this.status) return 'Mark as Current Status';
    return 'Mark Status as Complete';
  }

  get buttonIcon() {
    return this.isLoading || (this._selectedStage && this._selectedStage !== this.status) ? null : 'utility:check';
  }

  renderedCallback() {
    if (!this._stylesLoaded) {
        Promise.all([loadStyle(this, DMT_Styles)])
        .then(() => { this._stylesLoaded = true; })
        .catch(error => { console.error('Error loading styles', error); });
    }
  }

  handleStageClick(event) {
    event.preventDefault();
    const stageName = event.currentTarget.dataset.value;

    // Actualización visual INMEDIATA
    this._selectedStage = stageName;

    // Avisar al padre
    this.dispatchEvent(new CustomEvent('stageclick', { detail: { selectedStage: stageName } }));
  }

  handleMarkComplete() {
    this.isLoading = true;
    this.isDisabled = true;

    let nextStage;
    if (this._selectedStage && this._selectedStage !== this.status) {
      nextStage = this._selectedStage;
    } else {
      const currentIndex = this.stages.indexOf(this.status);
      const nextIndex = currentIndex + 1;
      if (nextIndex >= this.stages.length) {
        this.isLoading = false;
        this.setIsDisabled(false);
        return;
      }
      nextStage = this.stages[nextIndex];
    }
    this.dispatchEvent(new CustomEvent('markcomplete', { detail: { nextStage: nextStage } }));
  }
}