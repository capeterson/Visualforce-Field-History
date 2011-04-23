global with sharing class Util {
	/**
	 * Get all the IDs out of an array into a set.
	 * Really useful for bulkifying triggers
	 * @author cpeterson
	 **/
	global static Set<id> getIds(sObject[] objList){
		Set<id> retval = new Set<id>();
		for(sobject thisObj: objList){
			retval.add(thisObj.id);
		}
		return retval;
	}
	
	/**
	 * Get a string field from an array of objects, and return those fields in an array.
	 * @author cpeterson
	 **/ 
	global static List<string> getStringFields(List<sObject> objectList, string fieldName){
		List<string> result = new List<string>();
		for(sObject thisObject:objectList){
			result.add(String.valueOf(thisObject.get(fieldName)));
		}		
		System.assertEquals(result.size(),objectList.size());
		return result;
	}
	
	/**
	 * Wrapper around getStringFeilds, but returns an ID rather than a string
	 * usefull for use in SOQL queries.
	 * @author cpeterson
	 **/
	 global static List<Id> getIDFields(List<sObject> objectList, string fieldName){
	 	List<ID> idList = Util.getStringFields(objectList, fieldName);
	 	return idList;
	 }

}