import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfDMT_CLIENT_GROUP_V2_OPPORTUNITY_5_BBVA extends FlexCardMixin(OmniscriptBaseMixin(LightningElement)){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              @track _omniSupportKey = 'cfDMT_CLIENT_GROUP_V2_OPPORTUNITY_5_BBVA';
                  @api get omniSupportKey() {
                    return this._omniSupportKey;
                  }
                  set omniSupportKey(parentRecordKey) {
                    this._omniSupportKey = this._omniSupportKey  + '_' + parentRecordKey;
                  }
              @track record;
              @track _sessionApiVars = {};
              @track Label={dmt_cl_TRI_Title:"TRI",
        dmt_cl_Positioning_Title:"Positioning",
        dmt_cl_CCA_Title:"CCA",
        dmt_cl_CTA_Title:"CTA",
        dmt_cl_TRIEngagementPlan_Title:"TRI Engagement Plan",
        dmt_cl_GroupAlignmentDegree_Title:"Group Alignment Degree",
        dmt_cl_SectorAlignmentDegree_Title:"Sector Alignment Degree",
        dmt_cl_EmissionsIntensity_Title:"Emissions Intensity",
        dmt_cl_Scope_Title:"Scope",
        dmt_cl_Comments_Title:"Comments",
        dmt_cl_ReputationalRisk_Title:"Reputational Risk",
        dmt_cl_EquatorPrinciples_Title:"Equator Principles",
        dmt_cl_CleanTech_Title:"CleanTech",
        dmt_cl_PortfolioAlignment_Title:"Portfolio Alignment",
        dmt_cl_KPILinkMarginAdjustment_Title:"KPI-Link Margin Adjustment"
        };
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
                
                
                this.customLabels = this.Label;
                      
                this.setDefinition(data);
 this.registerEvents();
                this.setAttribute(
                  "class", (this.getAttribute("class") ? this.getAttribute("class") : "") +
                  " card-0koKG000000L5g4YAC"
                );
                this.loadCustomStylesheetAttachement("00PKG000003oi6L2AQ");
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    this.omniSaveState(this.records,this.omniSupportKey,true);
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`Edit`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`Reload`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`OmniSave`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`FinancialsSave`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3),
[interpolateWithRegex(`BusinessSave`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4)
        };
        this.pubsubChannel0 = interpolateWithRegex(`Button`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`Error`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[5],5)
        };
        this.pubsubChannel1 = interpolateWithRegex(`Set`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }