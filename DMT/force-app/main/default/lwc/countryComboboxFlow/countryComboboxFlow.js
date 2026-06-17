import { LightningElement, track, wire } from 'lwc';
import Toast from 'lightning/toast';
import getCountryPicklistValues from '@salesforce/apex/SendEmailUserFilter.getCountryPicklistValues';
import getTemplateContentById from '@salesforce/apex/SendEmailUserFilter.getTemplateContentById';
import getPermissiontSetValues from '@salesforce/apex/SendEmailUserFilter.getPermissiontSetValues';
import sendEmails from '@salesforce/apex/SendEmailUserFilter.sendEmails';
import getHistory from '@salesforce/apex/SendEmailUserFilter.getEmailHistory';
import getHistoryUsers from '@salesforce/apex/SendEmailUserFilter.getUserEmailDetails';
import getOrgWideEmailAddresses from '@salesforce/apex/SendEmailUserFilter.getOrgWideEmailAddresses';
import { NavigationMixin } from 'lightning/navigation';

export default class CountryComboboxFlow extends NavigationMixin(LightningElement) {
    @track emailTemplates = [];
    @track selectedTemplateId;
    @track selectedTemplateContent;
    @track isTemplateSelected = false;
    @track isEmailTemplatesLoaded = false;
    @track isFiltersVisible = true;
    @track userTypeOptions = [
        { label: 'Risk', value: 'Riesgos' },
        { label: 'Business', value: 'Negocio' },
    ];
    @track filterOptions = [
        { label: 'All Conditions Are Met(AND)', value: 'AND' },
        { label: 'Any Conditions Is Met(OR)', value: 'OR' },
        { label: 'Custom Condition Logic Is Met', value: 'CustomLogic' },
    ];
    @track selectedFilter = 'AND';
    @track customLogicInput;
    @track isCustomLogic = false;
    @track selectedUserType;
    @track selectedLevels = [];
    @track countryOptions = [];
    @track permissionSetOptions = [];
    @track selectedCountries = [];
    @track selectedPermissionSet = [];
    @track sentEmails = [];
    @track sentEmailBoolean = false;
    @track disableButtonContinue = true;
    @track showInterface = true;
    displayInfo = {
        primaryField: 'Name',
    };
    selectedTemplateHtml = '';
    selectedTemplateSubject='';
    @track historyData;
    @track historyUsers = [];
    @track selectedHistoryId;
    @track showDetailModal = false;
    @track parsedFilters;
    @track scheduledDateTime;

    wiredHistoryResult;
    historyColumns = [
        { label: 'From: ', fieldName: 'DES_fld_FromAddress__c' },
        { label: 'Total Users', fieldName: 'DES_fld_TotalUsers__c', type: 'number' },
        { label: 'Status', fieldName: 'DES_fld_Status__c' },
        { label: 'Template', fieldName: 'DES_fld_EmailTemplate__c' },
        {
            type: 'button',
            typeAttributes: {
                label: 'View Details',
                name: 'view_details',
                variant: 'brand',
            },
        },
    ];

    userColumns = [
        { label: 'User', fieldName: 'UserName' },
        { label: 'Email', fieldName: 'DES_fld_UserEmail__c' },
    ];

    @wire(getHistory)
    wiredHistory({ data, error }) {
        if (data) {
            this.historyData = data.map(record => {
                return {
                    ...record,
                    CreatedByName: record.CreatedBy ? record.CreatedBy.Name : ''
                };
            });
        } else if (error) {
            console.error(error);
        }
    }
   handleRowAction(event) {

    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === 'view_details') {

            this.selectedHistoryRecord = row;
            this.showDetailModal = true;
            if (row.DES_fld_FilterJSON__c) {
                try {
                    this.parsedFilters = JSON.parse(row.DES_fld_FilterJSON__c);
                } catch (e) {
                    console.error('Error parsing filters', e);
                    this.parsedFilters = null;
                }
            }

            this.loadUsers(row.Id);
        }
    }
    loadUsers(historyId) {
    getHistoryUsers({ historyId })
        .then(result => {

            this.historyUsers = result.map(record => {
                return {
                    ...record,
                    UserName: record.DES_fld_User__r
                        ? record.DES_fld_User__r.Name
                        : ''
                };
            });

        })
        .catch(error => {
            console.error(error);
        });
    }
    get isFailed() {
        return this.selectedHistoryRecord?.DES_fld_Status__c === 'Failed';
    }
    get formattedCountries() {
        return this.parsedFilters?.countries?.join(', ') || '';
    }

    get formattedPermissionSets() {
        return this.parsedFilters?.permissionSets?.join(', ') || '';
    }
    closeModal() {
        this.showDetailModal = false;
        this.selectedHistoryRecord = null;
    }
    @wire(getOrgWideEmailAddresses)
    wiredOrgWide({ error, data }) {
        if (data) {
            this.orgWideOptions = data;
            if (!this.selectedOrgWideId) {

                const defaultOption = data.find(option =>
                    option.label.toLowerCase().includes('globaldesktop@bbva.com')
                );

                if (defaultOption) {
                    this.selectedOrgWideId = defaultOption.value;
                } else if (data.length > 0) {
                    this.selectedOrgWideId = data[0].value;
                }
            
            
            } else if (error) {
                console.error(error);
            }
        }
    }
    handleOrgWideChange(event) {
        this.selectedOrgWideId = event.detail.value;
    }
    // Manejar cambio de template
    handleTemplateSelect(event) {
        this.selectedTemplateId = event.detail.recordId;
        this.loadTemplateContent(this.selectedTemplateId);
        this.isTemplateSelected = true;
        this.isFiltersVisible = false;
    }

    loadTemplateContent(templateId) {
       getTemplateContentById({ templateId })
        .then((result) => {
            this.selectedTemplateHtml = result.body; 
            this.selectedTemplateSubject = result.subject; 
        })
        .catch((error) => {
            console.error('Error al obtener el contenido:', error);
        });
    }

    // Cargar países
    @wire(getCountryPicklistValues)
    wiredCountries({ error, data }) {
        if (data) {
            this.countryOptions = data.map((country) => {
                return { label: country.label, value: country.value }; // Asegúrate de usar los nombres correctos
            });
        } else if (error) {
            console.error('Error al obtener países:', error);
        }
    }
    @wire(getPermissiontSetValues)
    wiredPermissionSets({ error, data }) {
        if (data) {
            this.permissionSetOptions = data.map((ps) => {
                return { label: ps.label, value: ps.value };
            });
        } else if (error) {
            console.error('Error al obtener los conjuntos de permisos:', error);
        }
    }

    handleFinish() {
        this.showInterface = false;
        // **NUEVO: Lógica para vaciar el lightning-record-picker**
        const picker = this.template.querySelector('lightning-record-picker');
        if (picker) {
            picker.clearSelection();
        }
        Promise.resolve().then(() => {
            // Restablecer los valores del flujo
            this.selectedTemplateId = null;
            this.selectedTemplateHtml = '';
            this.selectedTemplateSubject='';
            this.isTemplateSelected = false;
            this.isFiltersVisible = true;
            this.sentEmailBoolean = false;
            this.sentEmails = {};
            this.selectedCountries = [];
            this.selectedPermissionSet = [];
            this.selectedLevels = {};
            this.selectedUserType = null;
            this.selectedFilter = 'AND';
            this.customLogicInput = '';
            this.isCustomLogic = false;

            // **NUEVO: Limpiar los valores de los inputs de Nivel UO**
            // Recorrer y limpiar los inputs del Nivel UO
            this.template.querySelectorAll('lightning-input[data-field]').forEach((input) => {
                input.value = '';
            });
            this.showInterface = true;
        }, 50);
    }

    levelOptions = [
        { label: 'UO - Nivel 1', value: 'DES_LevelUO_1__c' },
        { label: 'UO - Nivel 2', value: 'DES_LevelUO_2__c' },
        { label: 'UO - Nivel 3', value: 'DES_LevelUO_3__c' },
        { label: 'UO - Nivel 4', value: 'DES_LevelUO_4__c' },
        { label: 'UO - Nivel 5', value: 'DES_LevelUO_5__c' },
        { label: 'UO - Nivel 6', value: 'DES_LevelUO_6__c' },
        { label: 'UO - Nivel 7', value: 'DES_LevelUO_7__c' },
        { label: 'UO - Nivel 8', value: 'DES_LevelUO_8__c' },
        { label: 'UO - Nivel 9', value: 'DES_LevelUO_9__c' },
        { label: 'UO - Nivel 10', value: 'DES_LevelUO_10__c' },
    ];

    handleLevelChange(event) {
        const fieldName = event.target.dataset.field;
        const value = event.target.value.trim();

        if (value) {
            this.selectedLevels = { ...this.selectedLevels, [fieldName]: value };
        } else {
            const updatedFilters = { ...this.selectedLevels };
            delete updatedFilters[fieldName];
            this.selectedLevels = updatedFilters;
        }
    }
    handleSelectFilterType(event) {
        this.selectedFilter = event.detail.value;
        if (this.selectedFilter === 'CustomLogic') {
            this.isCustomLogic = true;
        } else {
            this.isCustomLogic = false;
        }
    }

    handleCustomLogicInput(event) {
        this.customLogicInput = event.detail.value;
    }

    handleCountryChange(event) {
        this.selectedCountries = event.detail.value;
    }
    handlePermissionSetChange(event) {
        this.selectedPermissionSet = event.detail.value;
    }

    handleUserTypeChange(event) {
        this.selectedUserType = event.detail.value;
    }
    handleClearFilters() {
        this.selectedUserType = null;
    }

    navigateToEmailTemplates() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'EmailTemplate',
                actionName: 'home', // 'home' lleva a la lista de registros (la pestaña)
            },
        });
    }

    
    // Evita que el usuario seleccione una fecha pasada
    get minDateTime() {
        return new Date().toISOString();
    }

    // Para mostrar un texto amigable si está programado
    get formattedScheduleLabel() {
        return this.scheduledDateTime ? new Date(this.scheduledDateTime).toLocaleString() : '';
    }
    handleScheduleChange(event) {
        this.scheduledDateTime = event.detail.value;
    }

    clearSchedule() {
        this.scheduledDateTime = null;
    }
    handleSendEmails() {
        const templateId = this.selectedTemplateId;
        const countries = this.selectedCountries;
        const levels = this.selectedLevels;
        const userType = this.selectedUserType;
        const filterLogic = this.selectedFilter;
        const customLogic = this.customLogicInput;
        const permissionSets = this.selectedPermissionSet;
        const oweaId = this.selectedOrgWideId;
        const scheduledDateTime = this.scheduledDateTime;

        console.log(
            'Parametros:: ' + templateId,
            countries,
            levels,
            levels.length,
            countries.length,
            userType,
            filterLogic,
            customLogic,
            JSON.stringify(permissionSets),
            oweaId,
            scheduledDateTime
        );

        sendEmails({
            templateId,
            countries,
            levels,
            userType,
            filterLogic,
            customLogic,
            permissionSets,
            oweaId,
            scheduledDateTime
        }) // Llamada al método Apex para enviar los correos
            .then((result) => {
                // Asegúrate de que `result` sea un array y que puedas iterar sobre él
                console.log('Errors:', JSON.stringify(result)); // Verifica el resultado
                if (result.length === 0) {
                    this.sentEmailBoolean = true;
                    Toast.show({
                        label: 'Success',
                        message: 'Emails enviados correctamente',
                        variant: 'success',
                        mode: 'dismissible',
                    });
                    this.handleFinish();
                }
                if (Array.isArray(result) && result.length > 0) {
                    this.sentEmails = result; // Guardar la lista de usuarios a los que se envió el email
                    Toast.show({
                        label: 'Error',
                        message: 'Error al enviar el email: ' + result,
                        variant: 'error',
                        mode: 'dismissible ',
                    });
                }
            })
            .catch((error) => {
                console.error('Error enviando emails:', error);
            });
    }
}