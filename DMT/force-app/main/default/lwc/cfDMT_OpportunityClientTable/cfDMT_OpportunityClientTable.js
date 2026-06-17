import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfDMT_OpportunityClientTable extends FlexCardMixin(LightningElement){
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
              @track Label={dmt_cl_Filter_Selected:"Filter by selected"
        };
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setThemeClass(data);
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
                this.setDefinition(data);
 this.registerEvents();
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`saveClientsEvent`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`Reload`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6)
        };
        this.pubsubChannel0 = interpolateWithRegex(`DMT_OpportunityClientTable`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`ReloadChild`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10)
        };
        this.pubsubChannel1 = interpolateWithRegex(`Button`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

            this.customEventName0 = interpolateWithRegex(`inputfielddmt`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[0] = this.handleEventAction.bind(this, data.events[0],0);

            this.template.addEventListener(this.customEventName0,this.customEvent[0]);

          
            this.customEventName1 = interpolateWithRegex(`selectclientdmt`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[1] = this.handleEventAction.bind(this, data.events[1],1);

            this.template.addEventListener(this.customEventName1,this.customEvent[1]);

          
            this.customEventName2 = interpolateWithRegex(`disableactions`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[2] = this.handleEventAction.bind(this, data.events[3],3);

            this.template.addEventListener(this.customEventName2,this.customEvent[2]);

          
            this.customEventName3 = interpolateWithRegex(`selectedAccount`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[3] = this.handleEventAction.bind(this, data.events[4],4);

            this.template.addEventListener(this.customEventName3,this.customEvent[3]);

          
            this.customEventName4 = interpolateWithRegex(`editmode`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[4] = this.handleEventAction.bind(this, data.events[5],5);

            this.template.addEventListener(this.customEventName4,this.customEvent[4]);

          
            this.customEventName5 = interpolateWithRegex(`viewmodeselection`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[5] = this.handleEventAction.bind(this, data.events[7],7);

            this.template.addEventListener(this.customEventName5,this.customEvent[5]);

          
            this.customEventName6 = interpolateWithRegex(`viewmodemainholder`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[6] = this.handleEventAction.bind(this, data.events[8],8);

            this.template.addEventListener(this.customEventName6,this.customEvent[6]);

          
            this.customEventName7 = interpolateWithRegex(`viewmodedeselection`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[7] = this.handleEventAction.bind(this, data.events[9],9);

            this.template.addEventListener(this.customEventName7,this.customEvent[7]);

          
              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);

            this.template.removeEventListener(this.customEventName0,this.customEvent[0]);

            this.template.removeEventListener(this.customEventName1,this.customEvent[1]);

            this.template.removeEventListener(this.customEventName2,this.customEvent[2]);

            this.template.removeEventListener(this.customEventName3,this.customEvent[3]);

            this.template.removeEventListener(this.customEventName4,this.customEvent[4]);

            this.template.removeEventListener(this.customEventName5,this.customEvent[5]);

            this.template.removeEventListener(this.customEventName6,this.customEvent[6]);

            this.template.removeEventListener(this.customEventName7,this.customEvent[7]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }