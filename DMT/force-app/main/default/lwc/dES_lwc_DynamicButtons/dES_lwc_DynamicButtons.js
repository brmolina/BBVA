import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getButtonsConfig from '@salesforce/apex/DES_cls_DynamicButtonsCtrlLWC.getButtonsConfig';
import surveyNotification from '@salesforce/apex/DES_cls_DynamicButtonsCtrlLWC.surveyNotification';

export default class DES_lwc_DynamicButtons extends NavigationMixin(LightningElement) {
    @api ListConfigButtons;
    @track buttons = [];
    error;
    survey;
    enabled = false;

    connectedCallback(){
        this.getConfig();
    }

    async getConfig(){
        console.log('ListConfigButtons: ' + this.ListConfigButtons);
        try{
            const data = await getButtonsConfig({metasToSearch: this.ListConfigButtons});

            if(data) {
                this.enabled = true;
                this.buttons = data.map((config, index) =>({
                    label: config.label,
                            action: config.action,
                            type: config.type,
                            icon: config.icon,
                            survey: config.survey,
                            key: index
                }));
            } 
        }catch(e) {
            this.error = e;
            console.log('error: ' + error);
        }
    }

    handleClick(event) {
                    console.log('handleClick');
        const idx = event.currentTarget.dataset.key;
        const btn = this.buttons.find(b => b.key == idx);
        if (!btn) return;
        console.log('handleClick');
        console.log('handleClick: '+JSON.stringify(btn));

        switch (btn.type) {

            case 'URL':
                console.log('handleClick'+btn.survey);
                const url = btn.action;
                /*if(btn.survey != null){
                    
            console.log('handleClick');
                    this.survey = btn.survey;
                    this.sendSurvey();
                }*/
                window.open(url, '_blank');
                break;
            
            case 'COMPONENT':
                this[NavigationMixin.Navigate]({
                    type: 'standard__component',
                    attributes: {
                        componentName: cName
                    }
                });
                break;
        }
        if(btn.survey != null){
            console.log('handleClick');
            surveyNotification({
                    survey: btn.survey
                })
                .then(() => {
                    console.log('Evento publicado');
                })
                .catch((e) => {
                    console.error('Error publicando evento', e);
                });
        }
    }
}