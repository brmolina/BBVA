public with sharing class FieldForm_ctrl {
	@AuraEnabled
	public static Map<String, Object> getInfo(String recordId, String nameTable) {
		Map<String, Object> mapReturn = new Map<String, Object>();
        String uniqueNameTable = nameTable;
		try{
			//Validaciones de visibilidad de campos para Información general
			List<OpportunityLineItem_Local__c> validacion = [SELECT gipr_Tipo_Garantia__c, gipr_Buy_Type_Option__c, gipr_Origin__c, gipr_Request__c, cpliq_Tipo_amortizacion__c FROM OpportunityLineItem_Local__c WHERE id = :recordId];
			if(uniqueNameTable.substring(0, 2) == 'PC') {
				if((validacion[0].gipr_Tipo_Garantia__c == '01' || validacion[0].gipr_Tipo_Garantia__c == '02') && validacion[0].gipr_Tipo_Garantia__c != null)
					uniqueNameTable += '_Garantia';
				if((validacion[0].gipr_Buy_Type_Option__c == '02') && validacion[0].gipr_Buy_Type_Option__c != null)
					uniqueNameTable += '_Monto';
				if((validacion[0].gipr_Origin__c == '02') && validacion[0].gipr_Origin__c != null && uniqueNameTable != 'PC00030')
					uniqueNameTable += '_Origen';
				if((validacion[0].gipr_Origin__c == '04') && validacion[0].gipr_Origin__c != null && uniqueNameTable == 'PC00030')
					uniqueNameTable += '_Origen_Migracion';
				if((validacion[0].gipr_Request__c == '01' || validacion[0].gipr_Request__c == '02' || validacion[0].gipr_Request__c == '03') && validacion[0].gipr_Request__c != null)
					uniqueNameTable += '_Requerimiento';
			//Validaciones de visibilidad de campos para Criterios de pago
			}else if (uniqueNameTable.substring(0, 4) == 'CRIT') {
				if((validacion[0].cpliq_Tipo_amortizacion__c == '01') && validacion[0].cpliq_Tipo_amortizacion__c != null)
					uniqueNameTable += '_Vencimiento';
				else if((validacion[0].cpliq_Tipo_amortizacion__c == '02') && validacion[0].cpliq_Tipo_amortizacion__c != null)
					uniqueNameTable += '_Cuotas';
				if((validacion[0].cpliq_Tipo_amortizacion__c == '03') && validacion[0].cpliq_Tipo_amortizacion__c != null)
					uniqueNameTable += '_Medida';
				if((validacion[0].cpliq_Tipo_amortizacion__c == '04') && validacion[0].cpliq_Tipo_amortizacion__c != null)
					uniqueNameTable += '_Manual';
			}
			//Recuperación de información de los metadatos
			List<OpportunityLineItem_Local__c> currencyCode = [SELECT CurrencyIsoCode FROM OpportunityLineItem_Local__c WHERE id = :recordId];
			List<Field_form__mdt> lstFieldForm = [SELECT	Id,
															DeveloperName,
															object_api_name__c,
															unique_id__c,
															(SELECT 	Id,
																		default_value__c,
																		field_api_name__c,
																		field_form__c,
																		is_readonly__c,
																		order__c,
																		is_required__c
															FROM Fields__r ORDER BY order__c)
														FROM Field_form__mdt WHERE unique_id__c = :uniqueNameTable];

			Set<String> setFields = new Set<String>();
			Map<String,Object> mapField = new Map<String,Object>();
			for(Field__mdt field : lstFieldForm[0].Fields__r){
				mapField.put(field.field_api_name__c,field);
				setFields.add(field.field_api_name__c);
			}

			List<String> lstField = new List<String>(setFields);
			Map<String, Map<String, String>> mapSchemaInfo = getInfoSchema(setFields, lstFieldForm[0].object_api_name__c);
			String sentenciaRecord = 'SELECT ';
			Integer counter = 0;
			for(String valor : mapSchemaInfo.get('mapType').values()) {
				if (valor == 'PICKLIST' || valor == 'MULTIPICKLIST')
					sentenciaRecord += 'toLabel(' + lstField[counter] + '),';
				else
					sentenciaRecord += lstField[counter] + ',';
				counter++;
			}
			sentenciaRecord = sentenciaRecord.removeEnd(',');
            List<String> ids = new List<String>();
            ids.add(recordId);
			sentenciaRecord += ' FROM ' + lstFieldForm[0].object_api_name__c + ' WHERE Id IN: ids';
            Final String escapedQuery= String.escapeSingleQuotes(sentenciaRecord);
			List<Object> lstRecord = Database.query(escapedQuery);
			mapReturn.put('mapLabel', mapSchemaInfo.get('mapLabel'));
			mapReturn.put('mapType', mapSchemaInfo.get('mapType'));
			mapReturn.put('isOk', true);
			mapReturn.put('record', lstRecord[0]);
			mapReturn.put('setFields', setFields);
			mapReturn.put('fieldForm', lstFieldForm[0]);
			mapReturn.put('mapField', mapField);
            mapReturn.put('needReload', false);
			if (currencyCode[0].CurrencyIsoCode != UserInfo.getDefaultCurrency()){
				mapReturn.put('needReload', true);
				OpportunityLineItem_Local__c currencyUpdate = new OpportunityLineItem_Local__c(id = recordId);
				currencyUpdate.CurrencyIsoCode = UserInfo.getDefaultCurrency();
				update currencyUpdate;
			}
			mapReturn.put('CurrencyIsoCode', currencyCode[0].CurrencyIsoCode);
		}catch(Exception e){
			mapReturn.put('isOk', false);
		}
		return mapReturn;
	}

	public static Map<String, Map<String, String>> getInfoSchema(Set<String> setApiName, String strApiName) {
		Map<String, Map<String, String>> mapReturn = new Map<String, Map<String, String>>();
		Map<String, String> mapLabelSchema = new Map<String, String>();
		Map<String, String> mapTypeSchema = new Map<String, String>();
		String strType = strApiName;
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType leadSchema = schemaMap.get(strType);
		Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
		for (String fieldName: setApiName) {
			mapLabelSchema.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
			mapTypeSchema.put(fieldName, String.valueOf(fieldMap.get(fieldName).getDescribe().getType()));
		}
		mapReturn.put('mapLabel', mapLabelSchema);
		mapReturn.put('mapType', mapTypeSchema);
		return mapReturn;
	}
}