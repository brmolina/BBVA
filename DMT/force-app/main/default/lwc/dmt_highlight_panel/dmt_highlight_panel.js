import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getHighlightConfig from '@salesforce/apex/DMT_HighlightPanelController.getHighlightConfig';
import surveyNotification from '@salesforce/apex/DES_cls_BotonNoteBookLm.surveyNotification';

export default class Dmt_highlight_panel extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    _isConfidential;
    CHANNEL_OBJECT = '/event/DMT_LINES__e';
    subscriptionObject;
    @track config = {};
    @track processedFields = [];
    @track processedPrimaryActions = [];
    @track processedMenuActions = [];
    isLoading = true;
    error = null;
    refreshValue;
    
    @track mainIcon = {
        hasIcon: false,
        isStandardOrUtility: false,
        isStaticResource: false,
        isCustom: false,
        iconName: '',
        staticResourceUrl: '',
        customIconUrl: '',
        alternativeText: '',
        size: 'medium'
    };

     @api
     get status(){
         //this.loadConfiguration();
         return this.refreshValue;
     }
     set status(value){console.log('loadconget1',value);
        if( value != this.refreshValue && this.refreshValue != null){console.log('loadconget2',this.refreshValue);
            this.loadConfiguration();
        }
        
         this.refreshValue = value;
    }

    @api
    get isConfidential() {
        return this._isConfidential;
    }
    set isConfidential(value) {
        this._isConfidential = value === true || value === 'true';
        console.log('isconf:', this._isConfidential);
    }


    connectedCallback() {
        //this.CHANNEL_OBJECT = this.objectApiName?.includes('__c') ? '/event/'+ 'DMT_Line__e' : '/data/'+this.objectApiName+'__ChangeEvent';
        console.log('channel',this.CHANNEL_OBJECT);
        //subscribe(this.CHANNEL_OBJECT, -2, this.loadConfiguration).then(subscription => {
            //this.subscriptionObject = subscription;
       // });
        //this.registerErrorListener();
        this.loadConfiguration();

    }

    registerErrorListener() {
        onError(error => {
            console.log('err',error);
        });
    }
    disconnectedCallback(){
        //unsubscribe(this.subscriptionObject, () => console.info(UNSUBCRIBE_MESSAGE + this.CHANNEL_OBJECT));
    }

    
    async loadConfiguration() {
        try {
            
            this.isLoading = true;
            const result = await getHighlightConfig({
                objectApiName: this.objectApiName,
                recordId: this.recordId
            });console.log('loadcon',JSON.stringify(result));
            
            if (result) {
                this.config = result;console.log('json',JSON.stringify(this.config));
                this.processDataForHTML();
            }
        } catch (error) {
            this.error = error;
            this.showToast('Error', 'error', error.body?.message || error.message);
        } finally {
            this.isLoading = false;
        }
    }
    
    processDataForHTML() {
        this.processMainIcon();
        this.processVisibleFields();
        this.processVisibleActions();
    }
    
    processMainIcon() {
        const iconConfig = this.config.iconConfig || {};
        const type = iconConfig.type || 'none';
        
        // Crear propiedades booleanas SIMPLES para el HTML
        this.mainIcon.hasIcon = type !== 'none';
        this.mainIcon.isStandardOrUtility = type === 'standard' || type === 'utility';
        this.mainIcon.isStaticResource = type === 'staticresource';
        this.mainIcon.isCustom = type === 'custom';
        this.mainIcon.iconName = (type === 'standard' || type === 'utility') ? 
            `${type}:${iconConfig.name || ''}` : '';
        this.mainIcon.staticResourceUrl = (type === 'staticresource' && iconConfig.staticResource) ? 
            `/resource/${iconConfig.staticResource.resourceName}/${iconConfig.staticResource.iconPath}` : '';
        this.mainIcon.customIconUrl = (type === 'custom' && iconConfig.customIcon) ? 
            iconConfig.customIcon.src : '';
        this.mainIcon.alternativeText = iconConfig.alternativeText || '';
        this.mainIcon.size = iconConfig.size || 'medium';
    }
    
    processVisibleFields() {
        const visibleFields = this.config.visibleFields || [];
        
        this.processedFields = visibleFields.map(field => {
            // Crear propiedades booleanas SIMPLES
            const processedField = {
                ...field,
                // Propiedades calculadas en JavaScript (no en HTML)
                _isBadge: field.type === 'badge',
                _isPhone: field.type === 'phone',
                _isEmail: field.type === 'email',
                _isUrl: field.type === 'url',
                _hasAction: !!field.action,
                _hasIcon: !!field.icon,
                _phoneUrl: field.type === 'phone' ? `tel:${field.value || ''}` : '',
                _emailUrl: field.type === 'email' ? `mailto:${field.value || ''}` : '',
                // Para debug
                _debugActionType: field.action?.type
            };
            
            // Determinar si es icono standard/utility
            if (field.icon) {
                processedField._isStandardUtilityIcon = field.icon.type === 'standard' || field.icon.type === 'utility';
                processedField._fieldIconName = processedField._isStandardUtilityIcon ? 
                    `${field.icon.type}:${field.icon.name}` : '';
            } else {
                processedField._isStandardUtilityIcon = false;
                processedField._fieldIconName = '';
            }
            
            // Determinar si es campo básico (sin acción ni tipo especial)
            processedField._isBasicField = !processedField._isBadge && 
                                         !processedField._isPhone && 
                                         !processedField._isEmail && 
                                         !processedField._isUrl && 
                                         !processedField._hasAction;
            
            return processedField;
        });
    }
    
    processVisibleActions() {
        // Procesar acciones principales visibles
        this.processedPrimaryActions = (this.config.visiblePrimaryActions || []).map(action => {
            const iconConfig = action.iconConfig || {};
            const type = iconConfig.type || 'none';
            
            const processedAction = {
                ...action,
                _hasStandardUtilityIcon: type === 'standard' || type === 'utility',
                _hasCustomIcon: type === 'staticresource' || type === 'custom'
            };
            
            if (processedAction._hasStandardUtilityIcon && iconConfig.name) {
                processedAction._iconName = `${type}:${iconConfig.name}`;
            } else {
                processedAction._iconName = '';
            }
            
            if (processedAction._hasCustomIcon) {
                if (type === 'staticresource' && iconConfig.staticResource) {
                    processedAction._iconUrl = `/resource/${iconConfig.staticResource.resourceName}/${iconConfig.staticResource.iconPath}`;
                } else if (type === 'custom' && iconConfig.customIcon) {
                    processedAction._iconUrl = iconConfig.customIcon.src;
                } else {
                    processedAction._iconUrl = '';
                }
            } else {
                processedAction._iconUrl = '';
            }
            
            return processedAction;
        });
        
        // Procesar acciones del menú visibles
        this.processedMenuActions = (this.config.visibleMenuActions || []).map(action => {
            const iconConfig = action.iconConfig || {};
            const type = iconConfig.type || 'none';
            
            const processedAction = {
                ...action,
                _hasStandardUtilityIcon: type === 'standard' || type === 'utility',
                _hasCustomIcon: type === 'staticresource' || type === 'custom'
            };
            
            if (processedAction._hasStandardUtilityIcon && iconConfig.name) {
                processedAction._iconName = `${type}:${iconConfig.name}`;
            } else {
                processedAction._iconName = '';
            }
            
            if (processedAction._hasCustomIcon) {
                if (type === 'staticresource' && iconConfig.staticResource) {
                    processedAction._iconUrl = `/resource/${iconConfig.staticResource.resourceName}/${iconConfig.staticResource.iconPath}`;
                } else if (type === 'custom' && iconConfig.customIcon) {
                    processedAction._iconUrl = iconConfig.customIcon.src;
                } else {
                    processedAction._iconUrl = '';
                }
            } else {
                processedAction._iconUrl = '';
            }
            
            return processedAction;
        });
    }
    
    // ===== GETTERS BOOLEANOS SIMPLES (sin operadores) =====
    
    get hasConfig() {
        return this.config && Object.keys(this.config).length > 0;
    }
    
    get recordInfo() {
        return this.config.recordInfo || {};
    }
    
    get hasFields() {
        return this.processedFields && this.processedFields.length > 0;
    }
    
    get hasPrimaryActions() {
        return this.processedPrimaryActions && this.processedPrimaryActions.length > 0;
    }
    
    get hasMenuActions() {
        return this.processedMenuActions && this.processedMenuActions.length > 0;
    }
    
    get isRecordTypeSpecific() {
        return this.config.recordTypeSpecific === true;
    }
    
    get recordInfoHasLabel() {
        return this.config.recordInfo && this.config.recordInfo.label;
    }
    
    // ===== MANEJADORES DE EVENTOS =====
    
    handleFieldClick(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const fieldApiName = event.currentTarget.dataset.fieldname;
        const field = this.processedFields.find(f => f.fieldApiName === fieldApiName);
        
        if (!field || !field._hasAction) return;
        
        // Ejecutar acción según el tipo
        switch(field.action.type) {
            case 'navigate':
                this.handleNavigateAction(field.action.params);
                break;
            case 'call':
                window.open(`tel:${field.value}`, '_blank');
                break;
            case 'email':
                window.open(`mailto:${field.value}`, '_blank');
                break;
            case 'url':
                window.open(field.value, '_blank');
                break;
            case 'quickaction':
                if (field.action.params?.quickActionApiName) {
                    this.executeQuickAction(field.action.params.quickActionApiName);
                }
                break;
        }
    }
    
    handleNavigateAction(params) {
        if (!params || !params.recordId || !params.objectApiName) return;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: params.recordId,
                objectApiName: params.objectApiName,
                actionName: 'view'
            }
        });
    }
    
    handlePrimaryAction(event) {
        const actionName = event.currentTarget.dataset.name;
        const action = (this.config.primaryActions || []).find(a => a.name === actionName);
        
        if (action) {
            this.publishSurveyIfHelpAction(action);
            this.executeAction(action);
        }
    }

    publishSurveyIfHelpAction(action) {
        if (!this.isHelpAction(action)) {
            return;
        }

        surveyNotification({
            survey: 'SupportWUT',
            moduleName: 'Deal Management'
        }).catch((error) => {
            console.error('Error publishing survey event:', JSON.stringify(error));
        });
    }

    isHelpAction(action) {
        return action?.label?.toLowerCase() === 'help';
    }
    
    handleMenuAction(event) {
        const actionName = event.detail.value;
        const action = (this.config.menuActions || []).find(a => a.name === actionName);
        
        if (action) {
            this.executeAction(action);
        }
    }
    
    executeAction(action) {
        if (!action.actionType) return;
        
        switch(action.actionType) {
            case 'quickaction':
                if (action.actionConfig?.quickActionApiName) {
                    this.executeQuickAction(action.actionConfig.quickActionApiName);
                }
                break;
            case 'url':
                if (action.actionConfig?.url) {
                    window.open(action.actionConfig.url, action.actionConfig.target);
                }
                break;
            case 'navigate':
                if (action.actionConfig?.recordId && action.actionConfig?.objectApiName) {
                    this.handleNavigateAction(action.actionConfig);
                }
                break;
        }
    }
    
    executeQuickAction(apiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__quickAction',
            attributes: {
                apiName: apiName
            },
            state: {
                recordId: this.recordId,
                objectApiName: this.objectApiName
            }
        });
    }
    
    showToast(title, variant, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            variant: variant,
            message: message,
            mode: 'dismissable'
        }));
    }
}