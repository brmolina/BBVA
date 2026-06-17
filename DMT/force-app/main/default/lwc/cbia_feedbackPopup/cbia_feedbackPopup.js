import { LightningElement, api, track } from 'lwc';

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import giveMessageFeedback from '@salesforce/apex/CBIA_ChatbotController.giveMessageFeedback';

import optionsTitle from '@salesforce/label/c.CBIA_optionsTitle';
import q1Feedback from '@salesforce/label/c.CBIA_q1Feedback';
import q2Feedback from '@salesforce/label/c.CBIA_q2Feedback';
import q3Feedback from '@salesforce/label/c.CBIA_q3Feedback';
import q4Feedback from '@salesforce/label/c.CBIA_q4Feedback';
import q5Feedback from '@salesforce/label/c.CBIA_q5Feedback';
import feedback from '@salesforce/label/c.CBIA_feedback';
import whatWentWrong from '@salesforce/label/c.CBIA_whatWentWrong';
import moreDetails from '@salesforce/label/c.CBIA_moreDetails';
import noSensitiveData from '@salesforce/label/c.CBIA_noSensitiveData';
import errorSendingFeedback from '@salesforce/label/c.CBIA_errorSendingFeedback';
import errorFeedbackMessage from '@salesforce/label/c.CBIA_errorFeedbackMessage';

export default class Cbia_feedbackPopup extends LightningElement {

    @track showText = false;
    @api conversationId = '';
    @api userCountryCode;
    @api userFederationId;
    @api userUoCode;
    messageId = '';
    selectedOption = '';

    label = {
        optionsTitle,
        q1Feedback,
        q2Feedback,
        q3Feedback,
        q4Feedback,
        q5Feedback,
        feedback,
        whatWentWrong,
        moreDetails,
        noSensitiveData,
        errorSendingFeedback,
        errorFeedbackMessage
    }

    selectedFeedbackReasons = [];

    get feedbackReasonOptions() {
        return [
            { label: this.label.q1Feedback, value: 'INCORRECT_INFORMATION' },
            { label: this.label.q2Feedback, value: 'UNCLEAR_RESPONSE' },
            { label: this.label.q3Feedback, value: 'SLOW_RESPONSE' },
            { label: this.label.q4Feedback, value: 'IRRELEVANT_SOURCES' },
            { label: this.label.q5Feedback, value: 'OTHER' }
        ];
    }

    handleFeedbackReasonChange(event) {
        this.selectedFeedbackReasons = event.detail.value;

        if (this.selectedFeedbackReasons.includes('OTHER')) {
            this.showText = true;
        } else {
            this.showText = false;
        }
    }
    
    handleCerrarPopUp(){
        const selectedEvent = new CustomEvent("closefeedbackmodal", {
            detail: ''
        });
        this.dispatchEvent(selectedEvent);
    }

    handleIsLoading(loading){
        const selectedEvent = new CustomEvent("isloading", {
            detail: { isLoading: loading }
        });
        this.dispatchEvent(selectedEvent);
    }

    sendFeedbackKO(){
        const otherReasonEl = this.template.querySelector('[data-id="feedbackOtherReasonDetail"]');
        const additionalCommentsEl = this.template.querySelector('[data-id="feedbackAdditionalComments"]');
        const otherReasonVal = otherReasonEl && otherReasonEl.value ? otherReasonEl.value.trim() : undefined;
        const additionalCommentsVal = additionalCommentsEl && additionalCommentsEl.value ? additionalCommentsEl.value.trim() : undefined;

        if(this.selectedFeedbackReasons.length === 0 || (this.selectedFeedbackReasons.includes('OTHER') && otherReasonVal === '')){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Campos incompletos',
                    message: 'Seleccione una opción',
                    variant: "error",
                })
            );
        } else {
            this.handleIsLoading(true);

            let requestBody = {
                conversationId: this.conversationId,
                user: {
                    id: this.userFederationId,
                    country: this.userCountryCode,
                    segment: this.userUoCode
                },
                message: {
                    id: this.messageId,
                    category: 'NEGATIVE',
                    reason: this.selectedFeedbackReasons,
                    otherReasonDetail: otherReasonVal,
                    additionalComments: additionalCommentsVal
                },
                channel: 'GLOBAL_DESKTOP',
                creationDate: new Date().toISOString()
            };

            giveMessageFeedback({requestBody: requestBody}).then(result => {
                if (result.isError === true) {
                    this.handleIsLoading(false);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.label.errorSendingFeedback,
                            message: this.label.errorFeedbackMessage,
                            variant: "error"
                        })
                    );

                    // Notify parent about failure
                    this.dispatchEvent(new CustomEvent('feedbacksendingresult', {
                        detail: { success: false, category: 'NEGATIVE', messageId: this.messageId },
                        bubbles: true,
                        composed: true
                    }));

                    return;
                }

                this.handleIsLoading(false);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Feedback recibido',
                        message: 'Muchas gracias por tu opinión. Tu respuesta nos ayuda mucho a mejorar.',
                        variant: "success",
                    })
                );

                // Notify parent (cbia_mainChat) about result so it can inform the bubble
                this.dispatchEvent(new CustomEvent('feedbacksendingresult', {
                    detail: { success: true, category: 'NEGATIVE', messageId: this.messageId },
                    bubbles: true,
                    composed: true
                }));

                this.handleCerrarPopUp();
            }).catch(error => {
                this.handleIsLoading(false);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error al enviar feedback',
                        message: 'No se ha podido enviar tu respuesta. Por favor, inténtalo más tarde.',
                        variant: "error",
                    })
                );
                console.log('Error:', error);

                // Notify parent about failure
                this.dispatchEvent(new CustomEvent('feedbacksendingresult', {
                    detail: { success: false, category: 'NEGATIVE', messageId: this.messageId },
                    bubbles: true,
                    composed: true
                }));
            });
        }
    }

    @api
    setMessageId(value) {
        this.messageId = value;
    }

}