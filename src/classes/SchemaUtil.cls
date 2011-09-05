public with sharing class SchemaUtil {
	private static Map<String, Schema.SObjectType> globalDescribe;
	private static Map<String, Map<String, Schema.SObjectField>> fieldDescribes;
	
	/**
	 * A version of Schema.getpublicDescribe() with caching to help
	 * avoid govenor limits. It also ensures the sObject types are lower case and that namespaced objects include their namespace.
	 * @author cpeterson
	 **/
	public static Map<String, Schema.SObjectType> getGlobalDescribe(){
		if(globalDescribe == null){
			globalDescribe = new Map<String, Schema.sObjectType>();
			Map<String, Schema.SObjectType> sfDescribe = Schema.getGlobalDescribe();
			for(String key:sfDescribe.keySet()){
				String objName = sfDescribe.get(key).getDescribe().getName().toLowerCase(); //get the object name with namespace in lower case
				globalDescribe.put(objName,sfDescribe.get(key));
			}
		}
		return globalDescribe;
	}
	
	public static Map<String, Schema.sObjectField> getFieldDescribes(Schema.sObjectType subject){
		Map<String, Schema.sObjectField> result = new Map<String, Schema.sObjectField>();
		if(fieldDescribes != null && fieldDescribes.containsKey(subject.getDescribe().getName())){ //cache hit!
			 result = fieldDescribes.get(subject.getDescribe().getName());
		} else { //cache miss
			fieldDescribes = new Map<String, Map<String, Schema.sObjectField>>();
			Map<String,Schema.sObjectField> fields = subject.getDescribe().fields.getMap();
			for(String key:fields.keySet()){
				Schema.sObjectField fld = fields.get(key);
				String fieldName = fld.getDescribe().getName().toLowerCase(); //this gets us the field, with namespace prefix and all lower case
				if(!fld.getDescribe().isCustom() && fld.getDescribe().getSOAPType() == Schema.SOAPType.Id && !fieldName.endsWith('id') ){ //hack for the convention breaking standard lookup fields
					result.put(fieldName+'id',fld);
				}
				result.put(fieldName,fld);
			}
			fieldDescribes.put(subject.getDescribe().getName(),result);
		}
		return result;
	}
	
	/**
	 * If chatter is enabled the user sObject is ALWAYS chatter enabled, and cannot be disabled,
	 * so we use it as a quick and easy test for chatter-ness.
	 * @author cpeterson
	 **/
	public static boolean isOrgChatterEnabled(){
		return Schema.sObjectType.User.isFeedEnabled();
	}
}