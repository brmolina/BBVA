import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfProductOpportunityFields_54_BBVA extends FlexCardMixin(LightningElement){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              @track _sessionApiVars = {};
              
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setThemeClass(data);
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                
                this.setDefinition(data);
 this.registerEvents();
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`activeEditMode`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`reloadParent`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`updateTenorsData`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`updateMitigansData`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6)
        };
        this.pubsubChannel0 = interpolateWithRegex(`productOpportunityFields`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`errorTenorValidation`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[7],7)
        };
        this.pubsubChannel1 = interpolateWithRegex(`errorTenorValidation`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

            this.customEventName0 = interpolateWithRegex(`sentToParent`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[0] = this.handleEventAction.bind(this, data.events[3],3);

            this.template.addEventListener(this.customEventName0,this.customEvent[0]);

          
            this.customEventName1 = interpolateWithRegex(`setTenorsToParentFields`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[1] = this.handleEventAction.bind(this, data.events[4],4);

            this.template.addEventListener(this.customEventName1,this.customEvent[1]);

          
            this.customEventName2 = interpolateWithRegex(`setFundingToParent`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[2] = this.handleEventAction.bind(this, data.events[5],5);

            this.template.addEventListener(this.customEventName2,this.customEvent[2]);

          
            this.customEventName3 = interpolateWithRegex(`setAmortizationParent`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[3] = this.handleEventAction.bind(this, data.events[8],8);

            this.template.addEventListener(this.customEventName3,this.customEvent[3]);

          
            this.customEventName4 = interpolateWithRegex(`isSaveRtC`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[4] = this.handleEventAction.bind(this, data.events[9],9);

            this.template.addEventListener(this.customEventName4,this.customEvent[4]);

          
              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);

            this.template.removeEventListener(this.customEventName0,this.customEvent[0]);

            this.template.removeEventListener(this.customEventName1,this.customEvent[1]);

            this.template.removeEventListener(this.customEventName2,this.customEvent[2]);

            this.template.removeEventListener(this.customEventName3,this.customEvent[3]);

            this.template.removeEventListener(this.customEventName4,this.customEvent[4]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }