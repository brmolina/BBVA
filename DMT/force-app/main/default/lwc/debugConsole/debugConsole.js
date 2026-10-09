import { LightningElement, track } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class DebugConsole extends LightningElement {
    channelName = '/event/Debug_Message__e';
    subscription = null;

    @track messages = [];

    connectedCallback() {
        this.handleSubscribe();
        this.handleError();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            const payload = response.data.payload;
            this.messages.unshift({
                id: Date.now(),
                message: payload.Message__c,
                source: payload.Source__c,
                timestamp: payload.Timestamp__c
            });

            if (this.messages.length > 100) {
                this.messages.pop(); // keep it light
            }
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
            console.log('Subscribed to channel:', JSON.stringify(response));
        });
    }

    handleError() {
        onError(error => {
            console.error('EMP API error: ', error);
        });
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('Unsubscribed from channel');
            });
        }
    }

    handleClearLogs() {
        this.messages = [];
    }
}