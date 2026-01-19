import { LightningElement, track, api, wire } from 'lwc';
import Toast from 'lightning/toast'
import getCountryPicklistValues from '@salesforce/apex/SendEmailUserFilter.getCountryPicklistValues';
import getEmailTemplates from '@salesforce/apex/SendEmailUserFilter.getEmailTemplates';
import getTemplateContentById from '@salesforce/apex/SendEmailUserFilter.getTemplateContentById';
import sendEmails from '@salesforce/apex/SendEmailUserFilter.sendEmails';

export default class CountryComboboxFlow extends LightningElement {

    @track emailTemplates = [];
    @track selectedTemplateId;
    @track selectedTemplateContent;
    @track isTemplateSelected = false;
    @track isEmailTemplatesLoaded = false;
    @track isFiltersVisible = false;
    @track userTypeOptions = [
        { label: 'Risk', value: 'Riesgos' },
        { label: 'Business', value: 'Negocio' }
    ];
    @track selectedUserType; 
    @track countryOptions=[];
    @track selectedCountries=[];
    @track sentEmails = [];
    @track sentEmailBoolean =false;
    @track disableButtonContinue=true;
    selectedTemplateHtml = '';

        // Cargar las plantillas de correo al iniciar el componente
    @wire(getEmailTemplates)
    wiredEmailTemplates({ error, data }) {
        if (data) {
            this.emailTemplates = data.map(template => {
                return { label: template.Name, value: template.Id};
            });
            this.isEmailTemplatesLoaded = true;
        } else if (error) {
            console.error('Error al obtener plantillas de correo:', JSON.stringify(error));
        }
    }

    // Manejar cambio de template
    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
        this.loadTemplateContent(this.selectedTemplateId);
    }

    loadTemplateContent(templateId) {
        getTemplateContentById({ templateId })
            .then(result => {
                this.selectedTemplateHtml = result; // Asigna el HTML devuelto
                console.log('Template HTML:', this.selectedTemplateHtml);
            })
            .catch(error => {
                console.error('Error al obtener el contenido de la plantilla:', error);
            });
    } 

    // Cargar países
    @wire(getCountryPicklistValues)
    wiredCountries({ error, data }) {
        if (data) {
            this.countryOptions = data.map(country => {
                return { label: country.label, value: country.value }; // Asegúrate de usar los nombres correctos
            });
        } else if (error) {
            console.error('Error al obtener países:', error);
        }
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
        this.isTemplateSelected = true;
        this.disableButtonContinue=false;
        // Aquí podrías cargar el contenido de la plantilla
        this.loadTemplateContent(this.selectedTemplateId);
    }

    

    handleNext() {
        this.isFiltersVisible = true;
    }
    handleBack() {
         // Vuelve a la selección de plantilla
        this.isFiltersVisible = false; // Oculta la sección de filtros
        this.isTemplateSelected = false; // Resetea la selección de la plantilla
        this.selectedTemplateId = null; // Limpia el ID de la plantilla seleccionada
        this.selectedTemplateHtml = ''; // Limpia el HTML de la plantilla seleccionada
        this.sentEmailBoolean = false;   
        console.log('this.sentEmailBoolean: '+this.sentEmailBoolean);     
    }

    handleFinish() {
        // Restablecer los valores del flujo
        this.selectedTemplateId = null;
        this.selectedTemplateHtml = '';
        this.isTemplateSelected = false;
        this.isFiltersVisible = false;
        this.sentEmailBoolean = false;
        this.sentEmails = [];
        this.selectedCountries = [];
        this.selectedUserType = null;
        console.log('this.sentEmailBoolean: '+this.sentEmailBoolean);     
    }

    handleUserTypeChange(event) {
        this.selectedUserType = event.detail.value;
    }

    handleCountryChange(event){
        this.selectedCountries =event.detail.value;
    }

    handleSendEmails() {
         
        const  templateId= this.selectedTemplateId;
        const  countries= this.selectedCountries;
        const  userType= this.selectedUserType;

        sendEmails({ templateId, countries, userType })  // Llamada al método Apex para enviar los correos
        .then(result => {
            // Asegúrate de que `result` sea un array y que puedas iterar sobre él
            console.log('Errors:', JSON.stringify(result)); // Verifica el resultado
            console.log('Tamaño result: ', result.length);
            if (result.length==0) {
                this.sentEmailBoolean = true;
                Toast.show({
                    label:'Success',
                    message:'Emails enviados correctamente',
                    variant: 'success',
                    mode: 'dismissible'})
                this.handleFinish();
                
            }
            if (Array.isArray(result) && result.length > 0) {
                this.sentEmails = result; // Guardar la lista de usuarios a los que se envió el email
                Toast.show({
                    label:'Error',
                    message:'Error al enviar el email: '+result,
                    variant: 'error',
                    mode: 'dismissible '
                })
            }
        })
        .catch(error => {
            console.error('Error enviando emails:', error);
        });
    }
   
}