/**
* Autor: Cristian Jimeno Fuertes
*/
public class DES_QVC_Json {
	/**
	* inputJsonCs
	*/
	public InputJsonCs inputJsonCs {get; set;}
	/**
	* defaultCardSelected
	*/
	public String defaultCardSelected {get; set;}//NOSONAR
	/**
	* inputJsonData
	*/
	public List<List<InputJsonData>> inputJsonData {get; set;}
	/**
	* Autor: Cristian Jimeno Fuertes
	*/
	public class InputJsonCs {
		/**
		* GBLshowTitle
		 */
		public boolean GBLshowTitle {get; set;}//NOSONAR
		/**
		* Id
		 */
		public String Id {get; set;}//NOSONAR
		/**
		* GBLorientation
		 */
		public Integer GBLorientation {get; set;}//NOSONAR
		/**
		* GBLTitle
		 */
		public String GBLTitle {get; set;}//NOSONAR
		/**
		* Name
		 */
		public String Name {get; set;}//NOSONAR
	}
	/**
	* Autor: Cristian Jimeno Fuertes
	*/
	public class InputJsonData {
		/**
		* Label
		 */
		public String label {get; set;}
		/**
		* value
		 */
		public String value {get; set;}
		/**
		* type
		 */
		public String type {get; set;}
		/**
		* format
		 */
		public String format {get; set;}
		/**
		* icon
		 */
		public String icon {get; set;}
		/**
		* typeIcon
		 */
		public String typeIcon {get; set;}
		/**
		* idRecord
		 */
		public String idRecord {get; set;}
		/**
		* isSubtitle
		 */
		public String isSubtitle {get; set;}
	}
	/**
	* Autor: Cristian Jimeno Fuertes
	*/
    public String toJson () {
        String json = JSON.serialize(this);
        json = json.replace('GBLshowTitle', 'qvcd__GBL_Show_title__c');
        json = json.replace('GBLorientation', 'qvcd__GBL_Orientation__c');
		json = json.replace('GBLTitle', 'qvcd__GBL_Title__c');
        return json;
    }

}