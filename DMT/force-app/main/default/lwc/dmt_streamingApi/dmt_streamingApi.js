import { LightningElement,api, track } from 'lwc';
import { FlexCardMixin  } from 'omnistudio/flexCardMixin';

export default class Dmt_streamingApi extends FlexCardMixin(LightningElement) {

  _payload;
  _record;

  dataDeserialice;

  trafficLight;
  trafficLightOn;
  trafficLightOff;
  initialTrafficLight;
  finishTrafficLight;
  spinner;

  @track array;

  @api
  get record() {
    return this._record;
  }

  set record(value) {

      this._record = value;

      if(this.payload != null) {
          this.setOpportunityValues();
      }
  }

  @api
  get payload() {
    return this._payload;
  }

  set payload(value) {

      this._payload = value;

      if(this.record != null) {
          this.setOpportunityValues();
      }
  }

  setOpportunityValues() {

      console.log("this.payload.opportunity__c " + this.payload.opportunity__c);
      console.log("this.record " + this.record);

      if(this.payload.opportunity__c == this.record)  {

        this.dataDeserialice = JSON.parse(this.payload.Data__c);

        //this.dataDeserialice.forEach((element) => this.template.querySelector('.div[data-id="' + element.id + '"]').innerHTML = this.setTrafficLight(element.color));
        this.dataDeserialice.forEach((element) => element = this.setColor(element));

        console.log("this.dataDeserialice " + this.dataDeserialice);

        this.array = this.dataDeserialice;
        this.opportunity = this.payload.opportunity__c;
      }
  }

  setColor(element) {

    element.isGreen = false;
    element.isYellow = false;
    element.isRed = false;

    switch (element.color) {
      case "Green":
        element.isGreen = true;
        break;
      case "Yellow":
        element.isYellow = true;
        break;
      case "Red":
        element.isRed = true;
        break;
    }

    return element;
  }

  /*setTrafficLight(color) {

    this.trafficLightOn = '<div style="flex: 1; border: 0.2vh solid #000; border-radius: 3vh; aspect-ratio: 1; margin: 0 0.7vh; background-color: ' + color +';"></div>' ;
    this.trafficLightOff = '<div style="flex: 1; border: 0.2vh solid #000; border-radius: 3vh; aspect-ratio: 1; margin: 0 0.7vh; background-color: white;"></div>';

    this.initialTrafficLight = '<div style="display: flex; justify-content: center; align-items: center; width: 12vh; height: 5vh; border-radius: 3vh; overflow: hidden; background-color: #939393;">';
    this.finishTrafficLight = '</div>';

    this.spinner = '<lightning-spinner alternative-text="Loading" size="x-small"></lightning-spinner>'
      
    switch (color) {

        case "Green":
          this.trafficLight = this.initialTrafficLight + this.trafficLightOn + this.trafficLightOff + this.trafficLightOff + this.finishTrafficLight;
          break;
        case "Yellow":
          this.trafficLight = this.initialTrafficLight + this.trafficLightOff + this.trafficLightOn + this.trafficLightOff + this.finishTrafficLight;
          break;
        case "Red":
          this.trafficLight = this.initialTrafficLight + this.trafficLightOff + this.trafficLightOff + this.trafficLightOn + this.finishTrafficLight;
          break;
        default:
          this.trafficLight = this.spinner;
          break;
    }
    
    return this.trafficLight;
  }*/
}