import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfRiskTablesLine_86_BBVA extends FlexCardMixin(LightningElement){
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
               
        firstRender13 = true;
        @wire(getRecord , {recordId: "$recordId" , fields:"DMT_Line__c.Id",optionalFields: $cmp.getWireOptionalFields(data.events[13])})
          wiredRecord13({ error, data }){
            if (this.objectApiName === 'DMT_Line__c'){
              if(data && this.firstRender13){
                this.firstRender13 = false;
                return;
              }else{
                this.recordChangeEventHandler(error,data,13)
              }
            }
          }
        
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
          [interpolateWithRegex(`refresh`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10)
        };
        this.pubsubChannel0 = interpolateWithRegex(`linestab`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`activeEditMode`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[11],11)
        };
        this.pubsubChannel1 = interpolateWithRegex(`formLineEdit`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`errorChild`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[15],15)
        };
        this.pubsubChannel2 = interpolateWithRegex(`risktTermParent`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

            this.customEventName0 = interpolateWithRegex(`tableRiskchange`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[0] = this.handleEventAction.bind(this, data.events[0],0);

            this.template.addEventListener(this.customEventName0,this.customEvent[0]);

          
            this.customEventName1 = interpolateWithRegex(`tableRiskinit`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[1] = this.handleEventAction.bind(this, data.events[1],1);

            this.template.addEventListener(this.customEventName1,this.customEvent[1]);

          
            this.customEventName2 = interpolateWithRegex(`calculateGuidance`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[2] = this.handleEventAction.bind(this, data.events[2],2);

            this.template.addEventListener(this.customEventName2,this.customEvent[2]);

          
            this.customEventName3 = interpolateWithRegex(`tableProductChanges`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[3] = this.handleEventAction.bind(this, data.events[3],3);

            this.template.addEventListener(this.customEventName3,this.customEvent[3]);

          
            this.customEventName4 = interpolateWithRegex(`sendrowsevent`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[4] = this.handleEventAction.bind(this, data.events[4],4);

            this.template.addEventListener(this.customEventName4,this.customEvent[4]);

          
            this.customEventName5 = interpolateWithRegex(`tableSingularCon`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[5] = this.handleEventAction.bind(this, data.events[5],5);

            this.template.addEventListener(this.customEventName5,this.customEvent[5]);

          
            this.customEventName6 = interpolateWithRegex(`tableSingularConInit`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[6] = this.handleEventAction.bind(this, data.events[6],6);

            this.template.addEventListener(this.customEventName6,this.customEvent[6]);

          
            this.customEventName7 = interpolateWithRegex(`updatedDerivativesAmount`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[7] = this.handleEventAction.bind(this, data.events[7],7);

            this.template.addEventListener(this.customEventName7,this.customEvent[7]);

          
            this.customEventName8 = interpolateWithRegex(`updatedDeposAmount`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[8] = this.handleEventAction.bind(this, data.events[8],8);

            this.template.addEventListener(this.customEventName8,this.customEvent[8]);

          
            this.customEventName9 = interpolateWithRegex(`updatedEquitiesAmount`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[9] = this.handleEventAction.bind(this, data.events[9],9);

            this.template.addEventListener(this.customEventName9,this.customEvent[9]);

          
            this.customEventName10 = interpolateWithRegex(`reloadCard`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[10] = this.handleEventAction.bind(this, data.events[12],12);

            this.template.addEventListener(this.customEventName10,this.customEvent[10]);

          
            this.customEventName11 = interpolateWithRegex(`textfieldchange`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[11] = this.handleEventAction.bind(this, data.events[14],14);

            this.template.addEventListener(this.customEventName11,this.customEvent[11]);

          
              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);

            this.template.removeEventListener(this.customEventName0,this.customEvent[0]);

            this.template.removeEventListener(this.customEventName1,this.customEvent[1]);

            this.template.removeEventListener(this.customEventName2,this.customEvent[2]);

            this.template.removeEventListener(this.customEventName3,this.customEvent[3]);

            this.template.removeEventListener(this.customEventName4,this.customEvent[4]);

            this.template.removeEventListener(this.customEventName5,this.customEvent[5]);

            this.template.removeEventListener(this.customEventName6,this.customEvent[6]);

            this.template.removeEventListener(this.customEventName7,this.customEvent[7]);

            this.template.removeEventListener(this.customEventName8,this.customEvent[8]);

            this.template.removeEventListener(this.customEventName9,this.customEvent[9]);

            this.template.removeEventListener(this.customEventName10,this.customEvent[10]);

            this.template.removeEventListener(this.customEventName11,this.customEvent[11]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }