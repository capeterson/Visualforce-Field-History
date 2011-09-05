@isTest
private class SchemaUtil_test {
	
	//This test only runs in it's managed package form
	static testmethod void getGlobalDescribe(){
		try{
			UserInfo.isCurrentUserLicensed('vfh');
		}catch(TypeException e){
			//This org isn't using the managed package, skip this test
			return;
		}
		
		Map<String, Schema.SObjectType> describeResults;
		//Test the caching - the std library method can only be called 10 times
		for(integer i = 0; i < 15; i++){
			describeResults = SchemaUtil.getGlobalDescribe();
		}
		Map<String, Schema.SObjectType> systemResults = Schema.getGlobalDescribe();
		
		System.assertEquals(systemResults.keySet().size(),describeResults.keySet().size(),'global describe is missing keys');
		
		boolean foundCustom;
		for(String objType:describeResults.keySet()){
			if(objType.equalsIgnoreCase('custom_object__c'))
				System.assert(false,'Found a custom object without a namespace prefix. (custom_object__c)');
			if(objType.equals('vfh__custom_object__c'))
				foundCustom = true;
		}
		System.assert(foundCustom,'Did not find vfh__Custom_Object__c object type, or it had wrong case.');
	}
	
	static testmethod void getFieldDescribes(){
		Map<String, Schema.sObjectField> fields;
		//Test the caching - the std library method can only be called 10 times
		for(integer i = 0; i < 15; i++){
			fields = SchemaUtil.getFieldDescribes(Schema.Contact.sObjectType);
		}
		Map<String, Schema.sObjectField> systemFields = Schema.Contact.sObjectType.getDescribe().fields.getMap();
		System.assert(fields.keySet().size() >= systemFields.keySet().size(),'getFieldDescribes is missing keys.');
	}
	
	static testmethod void isOrgChatterEnabled(){
		System.assertNotEquals(null, SchemaUtil.isOrgChatterEnabled(),'Unable to determine if chatter is enabled in this org.');
	}
}