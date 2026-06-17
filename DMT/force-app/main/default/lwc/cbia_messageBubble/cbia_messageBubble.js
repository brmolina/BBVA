import { LightningElement, api, track } from 'lwc';
import { loadScript } from "lightning/platformResourceLoader";
import resources from "@salesforce/resourceUrl/CBIA_Resources";

export default class Cbia_messageBubble extends LightningElement {
    @api tipoMensaje = '';
    @api mensaje = '';
    @api hora = '';
    @api nombre = '';
    @track clickado = false;
    @api idMensaje = '';
    feedbackSendingResult;

    markdownItScript = resources + '/javascript/markdown-it_14.1.0.js';
    /** Instancia de la librería que transforma texto en formato Markdown en HTML */
    markdownIt;
    /** Opciones de configuración para código HTML */
    messageHtmlCustomization = {
        tags: [
            {
                name: 'table',
                attributes: [
                    {
                        name: 'style',
                        value: 'border: 1px solid;'
                    }
                ]
            },
            {
                name: 'th',
                attributes: [
                    {
                        name: 'style',
                        value: 'border: 1px solid;'
                    }
                ]
            },
            {
                name: 'td',
                attributes: [
                    {
                        name: 'style',
                        value: 'border: 1px solid;'
                    }
                ]
            },
            {
                name: 'pre',
                attributes: [
                    {
                        name: 'style',
                        value: 'white-space: pre-wrap; word-wrap: break-word; /* legacy support */ overflow-x: hidden; /* optional: hide overflow cutoff */'
                    }
                ]
            }
        ]
    };
    /** String: HTML con el mensaje mostrado al usuario */
    messageAsHtml;

    connectedCallback() {
        // Inicialización de librerías de Javascript
        if (this.markdownIt === undefined) {
            loadScript(this, this.markdownItScript).then(() => {
                this.markdownIt = window.markdownit();
                this.renderMessage();
            });
        }
    }

    /**
     * Receives the result of feedback sending from the "cbia_feedbackPopup" or "cbia_mainChat" LWC and updates internal state and styles.
     * POSITIVE -> highlight Like icon, NEGATIVE -> highlight Dislike icon
     * @param {object} result
     */
    @api
    applyFeedbackResult(result) {
        this.feedbackSendingResult = result;

        if (result.success === true) {
            // Lock to avoid multiple clicks
            this.clickado = true;
            if (result.category === 'POSITIVE') {
                const likeIcon = this.template.querySelector('lightning-icon[title="Like"]');
                likeIcon.style = '--slds-c-icon-color-foreground-default: #0250d9;';
            } else if (result.category === 'NEGATIVE') {
                const dislikeIcon = this.template.querySelector('lightning-icon[title="Dislike"]');
                dislikeIcon.style = '--slds-c-icon-color-foreground-default: #0250d9;';
            }
        }
    }

    renderedCallback() {
        this.renderMessage();
    }

    /**
     * Muestra o refresca el mensaje recibido en formato Markdown
     * 
     * Como no es posible aplicar estilos al contenido de "lightning-formatted-rich-text", se hace sobre el HTML que devuelve la librería
     */
    renderMessage() {
        if (this.markdownIt !== undefined && !!this.mensaje) {
            let html = this.markdownIt.render(this.mensaje);

            this.messageHtmlCustomization.tags.forEach(tag => {
                let attributeList = '';

                tag.attributes.forEach(attribute => {
                    if (attribute.value) {
                        attributeList += attribute.name + '="' + attribute.value + '" ';
                    } else {
                        attributeList += + attribute.name + ' ';
                    }
                });
                attributeList = attributeList.trim();

                html = html.replaceAll('<' + tag.name + '>', '<' + tag.name + ' ' + attributeList + '>');
            });

            this.messageAsHtml = html;
    }  
}

    get liClaseMensaje(){
        let clase;
        if (this.tipoMensaje === 'outbound') {
            clase = 'slds-chat-listitem slds-chat-listitem_outbound cib-out';
        } else if (this.tipoMensaje === 'inbound') {
            clase = 'slds-chat-listitem slds-chat-listitem_inbound cib-in';
        } else if (this.tipoMensaje === 'error') {
            clase = 'slds-chat-listitem slds-chat-listitem_inbound cib-in';
        }
        return clase;
    }

    get divClaseMensaje(){
        let clase;
        if (this.tipoMensaje === 'outbound') {
            clase = 'slds-chat-message__text slds-chat-message__text_outbound';
        } else if (this.tipoMensaje === 'inbound') {
            clase = 'slds-chat-message__text slds-chat-message__text_inbound';
        } else if (this.tipoMensaje === 'error') {
            clase = 'slds-chat-message__text slds-chat-message__text_inbound cib-error';
        }
        return clase;
    }

    get divClaseBodyMessage(){
        let clase;
        if (this.tipoMensaje === 'outbound') {
            clase = 'slds-chat-message__body';
        } else if (this.tipoMensaje === 'inbound') {
            clase = 'slds-chat-message__body cib-flex-row';
        } else if (this.tipoMensaje === 'error') {
            clase = 'slds-chat-message__body cib-flex-row';
        }
        return clase;
    }

    get divClaseChatMessage(){
        let clase;
        if (this.tipoMensaje === 'outbound') {
            clase = 'slds-chat-message cib-just-cont-end';
        } else if (this.tipoMensaje === 'inbound') {
            clase = 'slds-chat-message';
        } else if (this.tipoMensaje === 'error') {
            clase = 'slds-chat-message cib-just-cont-end';
        }
        return clase;
    }

    get mensajeEntrante(){
        return this.tipoMensaje === 'inbound';
    }

    handleFeedbackOK(event){
        if(this.clickado === false){
            this.dispatchEvent(
                new CustomEvent('feedbackok', {
                    detail: {
                        idMensaje: this.idMensaje
                    }
                })
            );
        }
    }   

    handleFeedbackKO(event){
        if(this.clickado === false){
            this.dispatchEvent(
                new CustomEvent('feedbackko', {
                    detail: {
                        idMensaje: this.idMensaje
                    }
                })
            );
        }
    }  
}