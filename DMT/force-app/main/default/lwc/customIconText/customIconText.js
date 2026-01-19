import { LightningElement, api } from 'lwc';

export default class customIconText extends LightningElement {
  @api value;
  @api iconName;
  @api textColor;
  @api tooltip;
  @api iconPosition; // 'left' | 'right'
  @api iconVariant;  // 'success' | 'warning' | 'error' | 'inverse'
  @api iconColor;    // '#00C853' | 'rgb(...)' | 'red' ...

  get normalizedPosition() {
    return (this.iconPosition || 'left').toLowerCase() === 'right' ? 'right' : 'left';
  }

  get hasIcon() {
    return !!this.iconName;
  }

  get showIconLeft() {
    return this.hasIcon && this.normalizedPosition === 'left';
  }

  get showIconRight() {
    return this.hasIcon && this.normalizedPosition === 'right';
  }

  get computedTextStyle() {
    return this.textColor ? `color: ${this.textColor};` : '';
  }

  // PRIORIDAD: iconColor > iconVariant > nada
  get computedIconStyle() {
    if (!this.iconColor) return ''; // <- si no viene, NO ponemos style
    const c = this.iconColor;
    return `--sds-c-icon-color-foreground-default: ${c}; --sds-c-icon-color-foreground: ${c};`;
  }

  get normalizedVariant() {
    // Si hay iconColor, el variant queda fuera siempre
    if (this.iconColor) return undefined;

    const v = (this.iconVariant || '').toLowerCase();
    return ['success', 'warning', 'error', 'inverse'].includes(v) ? v : undefined;
  }

  get containerClass() {
    return 'slds-grid slds-grid_vertical-align-center slds-truncate';
  }
}