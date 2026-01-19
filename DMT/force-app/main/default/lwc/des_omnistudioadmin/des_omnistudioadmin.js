import { LightningElement, track } from 'lwc';
import refreshAllFlexcards from '@salesforce/apex/DES_OmnistudioAdmin_Controller.refreshAllFlexcardsLatestVersion';
import returnAllIntegrationProcedureWithVersions from '@salesforce/apex/DES_OmnistudioAdmin_Controller.returnAllIntegrationProcedureWithVersions';
import returnAllFlexcardsWithVersions from '@salesforce/apex/DES_OmnistudioAdmin_Controller.returnAllFlexcardsWithVersions';
import refreshSpecificIntegrationProcedure from '@salesforce/apex/DES_OmnistudioAdmin_Controller.refreshSpecificIntegrationProcedure';
import refreshSpecificFlexcard from '@salesforce/apex/DES_OmnistudioAdmin_Controller.refreshSpecificFlexcard';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Des_omnistudioadmin extends LightningElement {

    @track isLoading = false;
    @track isModalOpen = false;
    @track isCheckboxChecked = false;
    @track isConfirmButtonDisabled = true;
    @track ipsWithVersions = {};
    @track flexcardsWithVersions = {};
    @track optionsIPs = [];
    @track optionsVersionNumIP = [];
    @track optionsFlexcards = [];
    @track optionsVersionNumFlexcards = [];
    @track selectedIP = {label:"",value:""};
    @track searchIP = {label: "", value: ""};
    @track searchVersionNumIP = {label: "", value: ""};
    @track selectedVersionNumIP = {label:"",value:""};
    @track selectedFlexcard = {label:"",value:""};
    @track searchFlexcard = {label: "", value: ""};
    @track searchVersionNumFlexcard = {label: "", value: ""};
    @track selectedVersionNumFlexcard = {label:"",value:""};
    @track isButtonIPDisabled = true;
    @track selectedIPValue;
    @track isVersionNumIPDisabled = true;
    @track selectedIPId;
    @track isButtonFlexcardDisabled = true;
    @track selectedFlexcardValue;
    @track isVersionNumFlexcardDisabled = true;
    @track selectedFlexcardId;


    compareVersionNumbers(a, b) {
        return b - a;
    }

    connectedCallback() {
        this.isLoading = true;
        this.retrieveAllIP();
    }

    handleRefresh() {
        this.isCheckboxChecked = false;
        this.isConfirmButtonDisabled = true;
        this.isModalOpen = true;
    }

    handleCancel() {
        this.isModalOpen = false;
    }

    handleCheckboxChange(event) {
        this.isCheckboxChecked = event.target.checked;
        this.isConfirmButtonDisabled = !this.isCheckboxChecked;
    }

    /**
     * @description Ejecuta la lógica de refresco y cierra el modal
     */
    handleConfirmRefresh() {
        this.confirmRefreshLogic();
        this.isModalOpen = false;
    }

    /**
     * @description Contiene la lógica original que refresca las Flexcards
     */
    confirmRefreshLogic() {
        this.isLoading = true;
        const userAgent = navigator.userAgent;
        const isChrome = userAgent.includes('Chrome') && !userAgent.includes('Edg');

        if (isChrome) {
            console.log('Navegador detectado: Chrome. Navegando...');
            refreshAllFlexcards({})
                .then(result => {
                    console.log('URL recibida: ' + result);
                    const url = 'microsoft-edge:' + result;
                    //window.open(url);
                    this.isLoading = false;
                })
                .catch(error => {
                    console.error('Error returning url: ', error);
                    this.isLoading = false; // Asegurarse de quitar el spinner en caso de error
                });
        } else {
            console.log('Navegador no compatible detectado:', userAgent);
            const evt = new ShowToastEvent({
                title: "Navegador no compatible",
                message: "Esta funcionalidad solo está disponible en Google Chrome.",
                variant: "warning",
                mode: 'dismissible'
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        }
    }

    /*handleRefresh() {
        this.isLoading = true;
        const userAgent = navigator.userAgent;
        const isChrome = userAgent.includes('Chrome') && !userAgent.includes('Edg');
        if (isChrome) {
            // ✅ SI ES CHROME: Ejecuta la acción normal (abrir una nueva pestaña)
            console.log('Navegador detectado: Chrome. Navegando...');
            refreshAllFlexcards({})
            .then(result => {
                console.log('URL recibida: ' + result);
                const url = 'microsoft-edge:' + result;
                window.open(url, '_blank');
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error returning url: ', error);
            });
        } else {
            // ❌ NO ES CHROME: Muestra una notificación de error y no hagas nada más.
            console.log('Navegador no compatible detectado:', userAgent);
            const evt = new ShowToastEvent({
                title: "Navegador no compatible",
                message: "Esta funcionalidad solo está disponible en Google Chrome.",
                variant: "warning", // Puede ser 'error', 'warning', 'success' o 'info'
                mode: 'dismissible'
            });
            this.dispatchEvent(evt);
            this.isLoading = false;
        }
    }*/


    retrieveAllIP() {
        returnAllIntegrationProcedureWithVersions()
            .then(result => {
                let auxArray = [];
                for (let i in result) {
                    if (!this.ipsWithVersions[result[i].omniName]) {
                        const obj = {
                            label: result[i].omniName,
                            value: result[i].omniName
                        }
                        this.ipsWithVersions[result[i].omniName] = {
                            label: result[i].omniName,
                            value: result[i].omniName,
                            versions: []
                        }
                        auxArray.push(obj);
                    }
                    const obj = {
                        label: result[i].omniVersionNumber.toString(),
                        value: result[i].omniId
                    }
                    this.ipsWithVersions[result[i].omniName].versions.push(obj);
                }
                this.optionsIPs = JSON.parse(JSON.stringify(auxArray))
                this.retrieveAllFlexcards();
            });
    }


    handleChangeIP(event) {
        this.isLoading = true;
        if (event.detail.data.value != null && event.detail.data.value != undefined && event.detail.data.value != '') {
            this.optionsVersionNumIP = JSON.parse(JSON.stringify(this.ipsWithVersions[event.detail.data.value].versions));
            this.optionsVersionNumIP.sort((a, b) => b.label - a.label);
            this.isVersionNumIPDisabled = false;
            this.selectedIPValue = event.detail.data.value;
        } else {
            this.optionsVersionNumIP = [];
            this.selectedIPId = null;
            this.isButtonIPDisabled = true;
            this.isVersionNumIPDisabled = true;
            this.selectedIPValue = null;
        }
        this.isLoading = false;
    }

    handleChangeVersionNumIP(event) {
        this.isLoading = true;
        if (event.detail.data.value != null && event.detail.data.value != undefined && event.detail.data.value != '') {
            this.selectedIPId = event.detail.data.value;
            this.isButtonIPDisabled = false;
        } else {
            this.selectedIPId = null;
            this.isButtonIPDisabled = true;
        }
        this.isLoading = false;
    }

    handleRefreshIP() {
        this.isLoading = true;
        refreshSpecificIntegrationProcedure({integrationProcedureId: this.selectedIPId, ipName: this.selectedIPValue})
            .then(result => {
                console.log('URL recibida de los IPs: ' + result);
                const url = 'microsoft-edge:' + result;
                window.open(url, '_blank');
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error returning url: ', error);
            });
    }

    retrieveAllFlexcards() {
        returnAllFlexcardsWithVersions()
            .then(result => {
                let auxArray = [];
                for (let i in result) {
                    if (!this.flexcardsWithVersions[result[i].omniName]) {
                        const obj = {
                            label: result[i].omniName,
                            value: result[i].omniName
                        }
                        this.flexcardsWithVersions[result[i].omniName] = {
                            label: result[i].omniName,
                            value: result[i].omniName,
                            versions: []
                        }
                        auxArray.push(obj);
                    }
                    const obj = {
                        label: result[i].omniVersionNumber.toString(),
                        value: result[i].omniId
                    }
                    this.flexcardsWithVersions[result[i].omniName].versions.push(obj);
                }
                this.optionsFlexcards = JSON.parse(JSON.stringify(auxArray))
                this.isLoading = false;
            });
    }


    handleChangeFlexcard(event) {
        this.isLoading = true;
        if (event && event.detail && event.detail.data && event.detail.data.value != null && event.detail.data.value != undefined && event.detail.data.value != '') {
            this.optionsVersionNumFlexcards = JSON.parse(JSON.stringify(this.flexcardsWithVersions[event.detail.data.value].versions));
            this.optionsVersionNumFlexcards.sort((a, b) => b.label - a.label);
            this.isVersionNumFlexcardDisabled = false;
            this.selectedFlexcardValue = event.detail.data.value;
        } else {
            this.optionsVersionNumFlexcards = [];
            this.selectedFlexcardId = null;
            this.isButtonFlexcardDisabled = true;
            this.isVersionNumFlexcardDisabled = true;
            this.selectedFlexcardValue = null;
        }
        this.isLoading = false;
    }



    handleChangeVersionNumFlexcard(event) {
        this.isLoading = true;
        if (event && event.detail && event.detail.data && event.detail.data.value != null && event.detail.data.value != undefined && event.detail.data.value != '') {
            this.selectedFlexcardId = event.detail.data.value;
            this.isButtonFlexcardDisabled = false;
        } else {
            this.isButtonFlexcardDisabled = true;
            this.selectedFlexcardId = null;
        }
        this.isLoading = false;
    }

    handleRefreshFlexcard() {
        this.isLoading = true;
        refreshSpecificFlexcard({flexcardId: this.selectedFlexcardId, flexcardName: this.selectedFlexcardValue})
            .then(result => {
                console.log('URL recibida de las Flexcards: ' + result);
                const url = 'microsoft-edge:' + result;
                window.open(url, '_blank');
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error returning url: ', error);
            });
    }


}