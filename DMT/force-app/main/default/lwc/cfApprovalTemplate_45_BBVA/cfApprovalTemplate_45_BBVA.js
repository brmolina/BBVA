import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfApprovalTemplate_45_BBVA extends FlexCardMixin(LightningElement){
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
                
            this.customEventName0 = interpolateWithRegex(`reloadcard`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[0] = this.handleEventAction.bind(this, data.events[0],0);

            this.template.addEventListener(this.customEventName0,this.customEvent[0]);

          
            this.customEventName1 = interpolateWithRegex(`finishCaseConditionCard`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[1] = this.handleEventAction.bind(this, data.events[1],1);

            this.template.addEventListener(this.customEventName1,this.customEvent[1]);

          
            this.customEventName2 = interpolateWithRegex(`approvalValidationCard`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[2] = this.handleEventAction.bind(this, data.events[2],2);

            this.template.addEventListener(this.customEventName2,this.customEvent[2]);

          
            this.customEventName3 = interpolateWithRegex(`returnToProposalCard`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[3] = this.handleEventAction.bind(this, data.events[3],3);

            this.template.addEventListener(this.customEventName3,this.customEvent[3]);

          
            this.customEventName4 = interpolateWithRegex(`textfieldchange`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[4] = this.handleEventAction.bind(this, data.events[4],4);

            this.template.addEventListener(this.customEventName4,this.customEvent[4]);

          
              }

              unregisterEvents(){
                
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