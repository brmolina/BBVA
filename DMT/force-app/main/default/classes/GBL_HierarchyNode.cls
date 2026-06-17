public class GBL_HierarchyNode {
  //General Attributes
  public String label {get; set;} //This will store the node Label
  public String extendedInfo {get; set;} //This will store the extended info to enclose in parenthesis
  public String name {get; set;} //This will store the Id of the Account relationship item
  public String type {get; set;} //type of relationship within the hierarchy
  public String vision {get; set;} //type of hierarchy
  public String objectName {get; set;} //type of Salesforce object this node represents
  public String objectId {get; set;} //Salesforce object Id for this node
  public String recordId {get; set;} //Salesforce object record Id
  public List<GBL_HierarchyNode> children = new List<GBL_HierarchyNode>();	//List of Child nodes for D3 visual hierarchy display
  public String labelExtended {
    get {
      if (this.extendedInfo == null) {
        return this.label;
      } else {
        return this.label + ' (' + this.extendedInfo + ')';
      }
    }
  }
  public String hRef {
    get {
      return '/lightning/r/' + this.objectName + '/' + this.objectId + '/view';
    }
  }
}