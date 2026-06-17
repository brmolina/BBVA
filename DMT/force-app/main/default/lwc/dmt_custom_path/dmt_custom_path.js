import { LightningElement, api } from 'lwc'

export default class dmt_custom_path extends LightningElement {
    @api recordId
    @api objectApiName
    @api status
    @api stages = []
    @api disabledStages = []
    @api readOnlyMode = false

    _selectedStage

    @api
    get selectedStage() {
        return this._selectedStage
    }
    set selectedStage(value) {
        this._selectedStage = value
    }

    isLoading = false
    isDisabled = false

    @api setLoading(value) {
        this.isLoading = value
    }

    @api setIsDisabled(value) {
        this.isDisabled = value
    }

    /* ── Items del path con clases SLDS y estado calculado ───────────────── */
    get computedSteps() {
        if (!this.stages || this.stages.length === 0) return []

        // La selección visual es el stage clickeado, o el actual por defecto
        const visualSelection = this._selectedStage || this.status
        const currentIdx = this.stages.indexOf(this.status)
        const isLostRecord = !this.readOnlyMode && this.status && this.status.includes('Lost')
        const disabledSet = new Set(this.disabledStages || [])

        return this.stages.map((stage, index) => {
            const isSelected = stage === visualSelection
            const isCurrentStatus = stage === this.status
            const isPast = index < currentIdx
            const isStageDisabled = disabledSet.has(stage)
            const isInteractive = !this.readOnlyMode && !isStageDisabled

            let cssClass = 'slds-path__item'

            // Estado base
            if (isCurrentStatus) {
                cssClass += isLostRecord ? ' slds-is-lost slds-is-current' : ' slds-is-current'
            } else if (isPast) {
                cssClass += isLostRecord ? ' slds-is-incomplete' : ' slds-is-complete'
            } else {
                cssClass += ' slds-is-incomplete'
            }

            // slds-is-active: marca el stage seleccionado visualmente (por defecto el actual).
            // Es puramente visual, se aplica también en read-only para que el actual se vea azul.
            // Solo se omite en stages deshabilitados (esos van en gris).
            if (isSelected && !isStageDisabled) {
                cssClass += ' slds-is-active'
            }

            // Stages deshabilitados (gris)
            if (isStageDisabled) {
                cssClass += ' dmt-stage-disabled'
            }

            // Modo read-only (para CSS de cursor / pointer-events)
            if (this.readOnlyMode) {
                cssClass += ' dmt-readonly'
            }

            return {
                label: stage,
                value: stage,
                cssClass,
                isSelected: isSelected && isInteractive ? 'true' : 'false',
                tabindex: isSelected && isInteractive ? '0' : '-1',
                ariaDisabled: isInteractive ? 'false' : 'true'
            }
        })
    }

    /* ── Visibilidad del botón ───────────────────────────────────────────── */
    get showActionButton() {
        return !this.readOnlyMode
    }

    /* ── Botón de acción ─────────────────────────────────────────────────── */
    get buttonLabel() {
        if (this.isLoading) return 'Saving...'
        if (this._selectedStage && this._selectedStage !== this.status) return 'Mark as Current Status'
        return 'Mark Status as Complete'
    }

    /* ── Handlers ────────────────────────────────────────────────────────── */
    handleStageClick(event) {
        event.preventDefault()

        if (this.isLoading || this.readOnlyMode) return

        const stageName = event.currentTarget.dataset.value

        // Bloquear stages deshabilitados
        if (this.disabledStages && this.disabledStages.includes(stageName)) return

        this._selectedStage = stageName

        this.dispatchEvent(new CustomEvent('stageclick', {
            detail: { selectedStage: stageName }
        }))
    }

    handleMarkComplete() {
        if (this.readOnlyMode) return

        this.isLoading = true

        let nextStage
        if (this._selectedStage && this._selectedStage !== this.status) {
            nextStage = this._selectedStage
        } else {
            const currentIndex = this.stages.indexOf(this.status)
            const nextIndex = currentIndex + 1
            if (nextIndex >= this.stages.length) {
                this.isLoading = false
                return
            }
            nextStage = this.stages[nextIndex]
        }

        this.dispatchEvent(new CustomEvent('markcomplete', {
            detail: { nextStage }
        }))
    }
}