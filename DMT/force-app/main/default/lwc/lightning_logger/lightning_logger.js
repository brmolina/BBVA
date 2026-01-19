import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from "lightning/messageService";
import { log } from 'lightning/logger';

//Message Channel name is lightning_logger
import LightningLogger from "@salesforce/messageChannel/lightning_logger__c";

export default class Lightning_logger extends LightningElement {

    subscription = null;

    @wire(MessageContext)
    messageContext;

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe (
                this.messageContext,
                LightningLogger,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(msg) {
        const payload = {
            userId: msg.userid,
            category: msg.category,
            message: msg.message
        };
        log(payload);
        console.log('message logged: ', JSON.stringify(payload));
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

}