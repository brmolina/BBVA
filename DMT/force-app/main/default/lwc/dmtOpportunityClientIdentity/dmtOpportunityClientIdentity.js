import { LightningElement, api } from "lwc";

export default class DmtOpportunityClientIdentity extends LightningElement {
  _client;
  _fields;

  @api accountName = "Client";
  @api accountId;

  // UI model (already formatted in the setter)
  valuesString = "—";
  tooltip = "—";

  @api
  get client() {
    return this._client;
  }
  set client(value) {
    this._client = value;
    this.initialize();
  }

  // CSV fields in order: "countryIfoId,customerId,taxpayerId"
  @api
  get fields() {
    return this._fields;
  }
  set fields(value) {
    this._fields = value;
    this.initialize();
  }

  // You said you compute it like this
  get computeAccountUrl() {
    return "/" + (this.accountId || "");
  }

  initialize() {
    this.buildValuesString();
  }

  buildValuesString() {
    if (!this._client || !this._fields) {
      this.valuesString = "—";
      this.tooltip = "—";
      return;
    }

    const fieldNames = this._fields
      .split(",")
      .map((f) => f.trim())
      .filter(Boolean);

    const values = [];

    for (const fieldName of fieldNames) {
      const value = this._client?.[fieldName];

      // Render only meaningful values
      if (value === null || value === undefined || value === "") continue;

      values.push(String(value));
    }

    this.valuesString = values.length ? values.join(" - ") : "—";
    this.tooltip = this.valuesString;
  }
}