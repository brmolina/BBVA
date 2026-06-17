import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfDMT_Opportunity_Info_Tab_56_BBVA extends FlexCardMixin(LightningElement){
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
               
        firstRender6 = true;
        @wire(getRecord , {recordId: "$recordId" , fields:"Opportunity.Id",optionalFields: $cmp.getWireOptionalFields(data.events[6])})
          wiredRecord6({ error, data }){
            if (this.objectApiName === 'Opportunity'){
              if(data && this.firstRender6){
                this.firstRender6 = false;
                return;
              }else{
                this.recordChangeEventHandler(error,data,6)
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
                this.setAttribute(
                  "class", (this.getAttribute("class") ? this.getAttribute("class") : "") +
                  " card-0koKG000000L8JDYA0"
                );
                this.loadCustomStylesheetAttachement("00PKG000003qzPw2AI");
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`activeEditMode`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`reloadAfterSave`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`changeDataChild`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4),
[interpolateWithRegex(`reloadOpportunityInfo`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[8],8),
[interpolateWithRegex(`setError`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[9],9)
        };
        this.pubsubChannel0 = interpolateWithRegex(`DMT_Opportunity_Info_Tab`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

            this.customEventName0 = interpolateWithRegex(`tableRiskchange`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[0] = this.handleEventAction.bind(this, data.events[0],0);

            this.template.addEventListener(this.customEventName0,this.customEvent[0]);

          
            this.customEventName1 = interpolateWithRegex(`editModeTable`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[1] = this.handleEventAction.bind(this, data.events[3],3);

            this.template.addEventListener(this.customEventName1,this.customEvent[1]);

          
            this.customEventName2 = interpolateWithRegex(`setInfoToParent`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[2] = this.handleEventAction.bind(this, data.events[5],5);

            this.template.addEventListener(this.customEventName2,this.customEvent[2]);

          
            this.customEventName3 = interpolateWithRegex(`isSaveRtC`,this._allMergeFields,this._regexPattern,"noparse");
            this.customEvent[3] = this.handleEventAction.bind(this, data.events[7],7);

            this.template.addEventListener(this.customEventName3,this.customEvent[3]);

          
              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);

            this.template.removeEventListener(this.customEventName0,this.customEvent[0]);

            this.template.removeEventListener(this.customEventName1,this.customEvent[1]);

            this.template.removeEventListener(this.customEventName2,this.customEvent[2]);

            this.template.removeEventListener(this.customEventName3,this.customEvent[3]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }