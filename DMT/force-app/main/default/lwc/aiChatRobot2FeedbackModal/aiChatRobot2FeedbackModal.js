/* eslint-disable one-var,no-console,no-undef,no-underscore-dangle,class-methods-use-this,sort-imports,id-length,no-magic-numbers,sort-keys*/

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import giveMessageFeedback from '@salesforce/apex/aiChatRobot2Controller.makeServiceRequest';
import aiChatRobot2_Feedback_Title from '@salesforce/label/c.aiChatRobot2_Feedback_Title';
import aiChatRobot2_Feedback_Question from '@salesforce/label/c.aiChatRobot2_Feedback_Question';
import aiChatRobot2_Feedback_PositiveQuestion from '@salesforce/label/c.aiChatRobot2_Feedback_PositiveQuestion';
import aiChatRobot2_Feedback_Incorrect from '@salesforce/label/c.aiChatRobot2_Feedback_Incorrect';
import aiChatRobot2_Feedback_Unclear from '@salesforce/label/c.aiChatRobot2_Feedback_Unclear';
import aiChatRobot2_Feedback_Slow from '@salesforce/label/c.aiChatRobot2_Feedback_Slow';
import aiChatRobot2_Feedback_Irrelevant from '@salesforce/label/c.aiChatRobot2_Feedback_Irrelevant';
import aiChatRobot2_Feedback_Unjustified from '@salesforce/label/c.aiChatRobot2_Feedback_Unjustified';
import aiChatRobot2_Feedback_Other from '@salesforce/label/c.aiChatRobot2_Feedback_Other';
import aiChatRobot2_Feedback_OtherPlaceholder from '@salesforce/label/c.aiChatRobot2_Feedback_OtherPlaceholder';
import aiChatRobot2_Feedback_PositiveDetailsPlaceholder from '@salesforce/label/c.aiChatRobot2_Feedback_PositiveDetailsPlaceholder';
import aiChatRobot2_Feedback_Cancel from '@salesforce/label/c.aiChatRobot2_Feedback_Cancel';
import aiChatRobot2_Feedback_Send from '@salesforce/label/c.aiChatRobot2_Feedback_Send';
import aiChatRobot2_Err_SendFeedback_Title from '@salesforce/label/c.aiChatRobot2_Err_SendFeedback_Title';
import aiChatRobot2_Err_SendFeedback_Generic from '@salesforce/label/c.aiChatRobot2_Err_SendFeedback_Generic';
import aiChatRobot2_Err_SendFeedback_Fallback from '@salesforce/label/c.aiChatRobot2_Err_SendFeedback_Fallback';

export default class AiChatRobot2FeedbackModal extends LightningElement {
    @api isOpen = false;
    @api messageId;
    @api conversationId;
    @api userId;
    @api userCountry;
    @api userSegment;
    @api feedbackState;
    @api category = null; // 'POSITIVE' o 'NEGATIVE'

    selectedReason = '';
    otherReason = '';
    positiveDescription = '';
    isLoading = false;
    isInitialized = false;

    label = {
        aiChatRobot2_Feedback_Title,
        aiChatRobot2_Feedback_Question,
        aiChatRobot2_Feedback_PositiveQuestion,
        aiChatRobot2_Feedback_Incorrect,
        aiChatRobot2_Feedback_Unclear,
        aiChatRobot2_Feedback_Slow,
        aiChatRobot2_Feedback_Irrelevant,
        aiChatRobot2_Feedback_Unjustified,
        aiChatRobot2_Feedback_Other,
        aiChatRobot2_Feedback_OtherPlaceholder,
        aiChatRobot2_Feedback_PositiveDetailsPlaceholder,
        aiChatRobot2_Feedback_Cancel,
        aiChatRobot2_Feedback_Send,
        aiChatRobot2_Err_SendFeedback_Title,
        aiChatRobot2_Err_SendFeedback_Generic,
        aiChatRobot2_Err_SendFeedback_Fallback
    };

    renderedCallback() {
        // Validamos si se ha inicializado y establecido una categoría de Feedback
        if (!this.isInitialized && !this.category) {
            this.category = this.feedbackState && this.feedbackState == 'liked' ? 'POSITIVE' : this.feedbackState && this.feedbackState == 'disliked' ? 'NEGATIVE' : null;
            // Marcamos el componente como inicializado
            this.isInitialized = !this.category ? false : true;          
        }
    }

    get showOtherInput() {
        return this.selectedReason === 'OTHER';
    }

    get isNegativeFeedback() {
        return this.feedbackState === 'disliked';
    }

    get isSendDisabled() {
        if (this.isLoading) {
            return true;
        }
        if (this.category == 'NEGATIVE' && !this.selectedReason) {
            return true;
        }
        if (this.selectedReason === 'OTHER' && !this.otherReason.trim()) {
            return true;
        }
        return false;
    }

    handleReasonChange(event) {
        this.selectedReason = event.target.value;
        // Reset other reason when switching options
        if (this.selectedReason !== 'OTHER') {
            this.otherReason = '';
        }
    }

    handleOtherReasonChange(event) {
        this.otherReason = event.target.value;
    }

    handlePositiveDescriptionChange(event) {
        this.positiveDescription = event.target.value;
    }

    handleCancel() {
        this.resetModal();
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSend() {
        this.isLoading = true;
                
        // Construir el request body según la especificación proporcionada
        const requestBody = {
            conversationId: this.conversationId,
            userId: this.userId,
            userCountry: this.userCountry,
            // userSegment: this.userSegment, // No se envía el Área porque desde Salesforce solo se tiene contexto del UUAA y la longitud del valor cambia y puede dar lugar a problemas
            channel: 'GLOBAL_DESKTOP', //Se envía siempre este valor
            creationDate: new Date().toISOString().replace('Z', '')
        };

        // Añadimos el mensaje según la categoría
        requestBody.messageId = this.messageId;
        requestBody.category = this.category;
        
        // Solo agregar reason, otherReasonDetail y additionalComments si es NEGATIVE
        if (this.category === 'NEGATIVE') {
           requestBody.reason = this.selectedReason;
           requestBody.otherReasonDetail = this.selectedReason === 'OTHER' ? this.otherReason : null;
           requestBody.additionalComments = this.selectedReason === 'OTHER' ? this.otherReason : null;
        } else {
            requestBody.additionalComments = this.positiveDescription;
        }

        // Llamar al servicio Apex
        giveMessageFeedback({ serviceName: 'feedback', requestBody: requestBody })
            .then((response) => {
                if (!response.isError) {
                    // Mostrar mensaje de éxito
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Feedback enviado',
                            message: 'Gracias por tu feedback',
                            variant: 'success'
                        })
                    );
                } else {
                    // Mostrar mensaje de error
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.label.aiChatRobot2_Err_SendFeedback_Title,
                            message: error.body?.message || this.label.aiChatRobot2_Err_SendFeedback_Generic || this.label.aiChatRobot2_Err_SendFeedback_Fallback,
                            variant: 'error'
                        })
                    );                   
                }
                
                // Notificar al componente padre que se envió el feedback
                this.dispatchEvent(new CustomEvent('feedbacksent', {
                    detail: { messageId: this.messageId },
                    bubbles: true,
                    composed: true
                }));
                
                this.resetModal();
            })
            .catch((error) => {
                // Mostrar mensaje de error
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.aiChatRobot2_Err_SendFeedback_Title,
                        message: error.body?.message || this.label.aiChatRobot2_Err_SendFeedback_Generic || this.label.aiChatRobot2_Err_SendFeedback_Fallback,
                        variant: 'error'
                    })
                );

                // Notificar al componente padre que se envió el feedback
                this.dispatchEvent(new CustomEvent('feedbacksent', {
                    detail: { messageId: this.messageId },
                    bubbles: true,
                    composed: true
                }));
                
                this.resetModal();
            });
    }

    resetModal() {
        this.selectedReason = '';
        this.otherReason = '';
        this.positiveDescription = '';
        this.category = '';
        this.isOpen = false;
        this.isLoading = false;
        this.isInitialized = false;
    }

    @api
    open(messageId, conversationId, userId, userCountry, userSegment, feedbackState) {
        this.messageId = messageId;
        this.conversationId = conversationId;
        this.userId = userId;
        this.userCountry = userCountry;
        this.userSegment = userSegment;
        this.feedbackState = feedbackState;
        this.isOpen = true;
    }

    @api
    close() {
        this.resetModal();
    }
}