import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfDMT_Opportunity_Client_EDIT_v3_7_BBVA extends FlexCardMixin(LightningElement){
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
              @track Label={dmt_cl_threshold_Type:"Client Threshold Type",
        dmt_cl_Industry_Text:"Industry",
        dmt_cl_LeveragedLending_Text:"Leveraged Lending",
        dmt_cl_CAMN_Text:"CAMN",
        DMT_ErrorToastTitle:"Something went wrong",
        DMT_ErrorToastSubTitle:"Please check the details below",
        DMT_Error_MainHolder:"No main holder has been selected for the multiclient group"
        };
              pubsubEvent = [];
              customEvent = [];
               
        firstRender1 = true;
        @wire(getRecord , {recordId: "$recordId" , fields:"DMT_Line__c.Id",optionalFields: $cmp.getWireOptionalFields(data.events[1])})
          wiredRecord1({ error, data }){
            if (this.objectApiName === 'DMT_Line__c'){
              if(data && this.firstRender1){
                this.firstRender1 = false;
                return;
              }else{
                this.recordChangeEventHandler(error,data,1)
              }
            }
          }
         
        firstRender5 = true;
        @wire(getRecord , {recordId: "$recordId" , fields:"Opportunity.Id",optionalFields: $cmp.getWireOptionalFields(data.events[5])})
          wiredRecord5({ error, data }){
            if (this.objectApiName === 'Opportunity'){
              if(data && this.firstRender5){
                this.firstRender5 = false;
                return;
              }else{
                this.recordChangeEventHandler(error,data,5)
              }
            }
          }
        
              connectedCallback() {
                super.connectedCallback();
                this.setThemeClass(data);
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
                this.setDefinition(data);
 this.registerEvents();
                this.setAttribute(
                  "class", (this.getAttribute("class") ? this.getAttribute("class") : "") +
                  " card-0koKG000000L8I0YAK"
                );
                this.loadCustomStylesheetAttachement("00PKG000003qxAq2AI");
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`changeValues`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0)
        };
        this.pubsubChannel0 = interpolateWithRegex(`select`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`Edit`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`Reload`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3)
        };
        this.pubsubChannel1 = interpolateWithRegex(`Button`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`errorValidationClient`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6)
        };
        this.pubsubChannel2 = interpolateWithRegex(`errorValidationClient`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

        this.pubsubEvent[3] = {
          [interpolateWithRegex(`updatedatasource`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[9],9)
        };
        this.pubsubChannel3 = interpolateWithRegex(`update`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel3,this.pubsubEvent[3]);

        this.pubsubEvent[4] = {
          [interpolateWithRegex(`editState`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10),
[interpolateWithRegex(`setMainHolderAndSelection`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[11],11),
[interpolateWithRegex(`mainholderChange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[12],12),
[interpolateWithRegex(`setDeselectionIds`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[13],13)
        };
        this.pubsubChannel4 = interpolateWithRegex(`DMT_Opportunity_Client_v3`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel4,this.pubsubEvent[4]);

            this.customEventName0 = interpolateWithRegex(`isSaveRtC`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[0] = this.handleEventAction.bind(this, data.events[4],4);

            this.template.addEventListener(this.customEventName0,this.customEvent[0]);

          
            this.customEventName1 = interpolateWithRegex(`editingtab`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[1] = this.handleEventAction.bind(this, data.events[7],7);

            this.template.addEventListener(this.customEventName1,this.customEvent[1]);

          
            this.customEventName2 = interpolateWithRegex(`errorMainHolder`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[2] = this.handleEventAction.bind(this, data.events[8],8);

            this.template.addEventListener(this.customEventName2,this.customEvent[2]);

          
              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);
pubsub.unregister(this.pubsubChannel3,this.pubsubEvent[3]);
pubsub.unregister(this.pubsubChannel4,this.pubsubEvent[4]);

            this.template.removeEventListener(this.customEventName0,this.customEvent[0]);

            this.template.removeEventListener(this.customEventName1,this.customEvent[1]);

            this.template.removeEventListener(this.customEventName2,this.customEvent[2]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }