import { LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import resources from '@salesforce/resourceUrl/CBIA_Resources';
import giveMessageFeedback from '@salesforce/apex/CBIA_ChatbotController.giveMessageFeedback';
import sendMessage from '@salesforce/apex/CBIA_ChatbotController.sendMessage';

import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_COUNTRY_FIELD from '@salesforce/schema/User.DES_Country__c';
import USER_FEDERATION_ID_FIELD from '@salesforce/schema/User.FederationIdentifier';
import USER_ORG_UNIT_CODE_FIELD from '@salesforce/schema/User.DES_LevelUO_10__c';

import replying from '@salesforce/label/c.CBIA_repliying';
import typeHere from '@salesforce/label/c.CBIA_typeHere';
import translate from '@salesforce/label/c.CBIA_translate';
import newConversation from '@salesforce/label/c.CBIA_newConversation';
import endConversation from '@salesforce/label/c.CBIA_endConversation';
import wantToContinue from '@salesforce/label/c.CBIA_wantToContinue';
import startConversation from '@salesforce/label/c.CBIA_startConversation';
import workCountry from '@salesforce/label/c.CBIA_workCountry';
import employeeId from '@salesforce/label/c.CBIA_employeeId';
import userConfigError from '@salesforce/label/c.CBIA_userConfigError';
import userQueryFailed from '@salesforce/label/c.CBIA_userQueryFailed';
import errorSendingMessage from '@salesforce/label/c.CBIA_errorSendingMessage';
import feedbackTaken from '@salesforce/label/c.CBIA_feedbackTaken';
import feedbackMensaje from '@salesforce/label/c.CBIA_feedbackMensaje';
import errorSendingFeedback from '@salesforce/label/c.CBIA_errorSendingFeedback';
import errorFeedbackMessage from '@salesforce/label/c.CBIA_errorFeedbackMessage';

export default class Cbia_mainChat extends LightningElement {
    
    userName;
    userCountryCode;
    userFederationId;
    userUoCode;
    @track listaMensajes = [];
    @track cargando = false;
    @track clickFAQ = false;
    @track showConfirmationModal = false;
    logoCibia = resources + '/images/logoBlack.png';
    listaEntranteFAQS = [];
    conversationId;
    @track showFeedbackModal = false;
    @track isLoading = false;

    label = { 
        replying, 
        typeHere, 
        translate,
        newConversation,
        endConversation,
        wantToContinue,
        startConversation,
        workCountry,
        employeeId,
        userConfigError,
        userQueryFailed,
        errorSendingMessage,
        feedbackTaken,
        feedbackMensaje,
        errorSendingFeedback,
        errorFeedbackMessage
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME_FIELD, USER_COUNTRY_FIELD, USER_FEDERATION_ID_FIELD, USER_ORG_UNIT_CODE_FIELD] })
    userDetails({ error, data }) {
        if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.userQueryFailed,
                    message: error.body.message,
                    variant: 'error'
                })
            );
        } else if (data) {
            this.userName = data.fields.Name.value;
            this.userCountryCode = data.fields.DES_Country__c.value;
            this.userFederationId = data.fields.FederationIdentifier.value;
            this.userUoCode = data.fields.DES_LevelUO_10__c.value;

            let missingFields = '';
            if(this.userCountryCode === null){
               missingFields = this.label.workCountry;
            }
            if(this.userFederationId === null){
               missingFields = missingFields === '' ? this.label.employeeId : missingFields += ', ' + this.label.employeeId;
            }

            if(missingFields !== ''){
                 this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.userConfigError,
                        message: missingFields,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }
        }
    }

    connectedCallback(){
        this.listaEntranteFAQS = [];
    }

    handleEnter(event){       
        if (event.key === 'Enter' && !event.shiftKey && !this.template.querySelector("[data-id='mensaje-usuario']").value.trim()) {
            event.preventDefault();
            return;
        }

        if (event.key === 'Enter' && !event.shiftKey && this.cargando == false) {
            event.preventDefault();
            this.handleMensajeEnviado();
        }
    }

    handleMensajeEnviado(){
        if (!this.template.querySelector("[data-id='mensaje-usuario']").value.trim()) {
            return;
        }

        this.cargando = true;
        let textArea = this.template.querySelector("[data-id='mensaje-usuario']");
        this.listaMensajes.push({ mensaje: textArea.value, tipoMensaje: 'outbound' });

        if (this.conversationId === undefined) {
            this.conversationId = crypto.randomUUID();
        }

        let requestBody = {
            conversationId: this.conversationId,
            user: {
                id: this.userFederationId,
                country: this.userCountryCode,
                segment: this.userUoCode
            },
            message: {
                id: crypto.randomUUID(),
                content: textArea.value,
                creationDate: (new Date()).toISOString()
            },
            channel: 'GLOBAL_DESKTOP'
        };

        sendMessage({requestBody: requestBody})
        .then(result => {
            if (result.isError === true) {
                this.listaMensajes.push({
                    mensaje: this.label.errorSendingMessage,
                    tipoMensaje: 'error',
                    idMensaje: '1234'
                });
            } else {
                this.listaMensajes.push({
                    mensaje: result.data.message.content,
                    tipoMensaje: 'inbound',
                    idMensaje: result.data.message.id
                });

                this.listaEntranteFAQS = [];
                result.data.documents.forEach(faqItem => {
                    this.listaEntranteFAQS.push({
                        id: faqItem.id,
                        pregunta: faqItem.title,
                        respuesta: faqItem.content.replaceAll('\n', '<br />'),
                        score: faqItem.score
                    });

                    this.listaEntranteFAQS.sort((a, b) => b.score - a.score);
                    if(this.listaEntranteFAQS.length > 0) {
                        this.clickFAQ = true;
                    } 
                });
            }

            setTimeout(() => {
                const mensajes = this.template.querySelectorAll('c-cbia_message-bubble');
                if (mensajes.length > 1) {
                    //!!!! dejar el == no cambiar a === ¡¡¡¡
                    mensajes[(mensajes.values().findLastIndex(elemento => elemento.classList == 'outbound') + 1)].scrollIntoView();
                }
            }, 100);
                       
            this.cargando = false;
        })
        .catch(error => {
            this.cargando = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.errorSendingMessage,
                    message: error.body.message,
                    variant: "error",
                })
            );
        });

        textArea.value = '';
    }

    get horaLocal(){
        const date = new Date();
        return date.getHours() + ':' + (date.getMinutes() < 10 ? '0' + date.getMinutes() : date.getMinutes());
    }

    handleCloseFeedback(){
        this.showFeedbackModal = false;
    }

    handleOpenFeedbackKO(event){
        this.showFeedbackModal = true;
        setTimeout(() => {
            this.template.querySelector('c-cbia_feedback-popup').setMessageId(event.detail.idMensaje);
        }, 100);
    }
    
    handeNewConversation(){
        this.listaEntranteFAQS = [];
        this.conversationId = undefined;
        this.listaMensajes = [];
        this.handleCloseConfirmationModal();
    }

    handleFeedbackOK(event){
        this.isLoading = true;
        let requestBody = {
            user: {
                id: this.userFederationId,
                country: this.userCountryCode,
                segment: this.userUoCode
            },
            conversationId: this.conversationId,
            message: {
                id: event.detail.idMensaje,
                category: 'POSITIVE',
            },
            channel: 'GLOBAL_DESKTOP',
            creationDate: new Date().toISOString()
        };
        
        giveMessageFeedback({requestBody: requestBody}).then(result => {
            if (result.isError === true) {
                this.isLoading = false;

                this.dispatchEvent(new ShowToastEvent({
                    title: this.label.errorSendingFeedback,
                    message: this.label.errorFeedbackMessage,
                    variant: "error"
                }));

                // Notify parent about failure
                this.handleFeedbackSendingResult({detail: { success: false, category: 'POSITIVE', messageId: event.detail.idMensaje }});

                return;
            }

            this.isLoading = false;

            // Notify parent (cbia_mainChat) about result so it can inform the bubble
            this.handleFeedbackSendingResult({detail: { success: true, category: 'POSITIVE', messageId: event.detail.idMensaje }});

            this.dispatchEvent(new ShowToastEvent({
                title: this.label.feedbackTaken,
                message: this.label.feedbackMensaje,
                variant: "success"
            }));
        }).catch(error => {
            this.isLoading = false;

            this.dispatchEvent(new ShowToastEvent({
                title: this.label.errorSendingFeedback,
                message: this.label.errorFeedbackMessage,
                variant: "error"
            }));

            // Notify parent about failure
            this.handleFeedbackSendingResult({detail: { success: false, category: 'POSITIVE', messageId: event.detail.idMensaje }});
        });
    }

    handleLoading(event){
        this.isLoading = event.detail.isLoading;
    }

    // Receives feedback result from cbia_feedbackPopup and forwards it to the matching message bubble
    handleFeedbackSendingResult(event) {
        const bubbles = this.template.querySelectorAll('c-cbia_message-bubble');
        if (!bubbles || bubbles.length === 0) {
            return;
        }
        // Find the bubble matching the message ID
        const target = Array.from(bubbles).find(b => b.idMensaje === event.detail.messageId);
        if (target && typeof target.applyFeedbackResult === 'function') {
            target.applyFeedbackResult(event.detail);
        }
    }

    handleAbrirLateral(){
        this.clickFAQ = !this.clickFAQ;
    }

    handleOpenConfirmationModal(){
        this.showConfirmationModal = true;
    }

    handleCloseConfirmationModal(){
        this.showConfirmationModal = false;
    }

    get conversacionIniciada(){
        return typeof this.conversationId != 'undefined' && this.conversationId != null;
    }

    get conversacionNoIniciada() {
        return !this.conversacionIniciada;
    }

    get hayFAQS(){
        return this.listaEntranteFAQS.length > 0;
    }

    get chatClases(){

        if(this.hayFAQS) {
            return this.clickFAQ ? 'slds-col slds-size_9-of-12 cib-chat-container' : 'slds-col slds-size_11-of-12 cib-chat-container';
        } else {
            return !this.hayFAQS && this.clickFAQ ? 'slds-col slds-size_9-of-12 cib-chat-container' :
                                                    'slds-col slds-size_11-of-12 cib-chat-container';
        }
    }

    get faqsClases(){
        return this.clickFAQ ? 'slds-col slds-size_3-of-12 cib-faqs' : 'slds-col slds-size_1-of-12 cib-faqs';
    }
}