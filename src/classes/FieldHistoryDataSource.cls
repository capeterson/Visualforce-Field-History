public with sharing class FieldHistoryDataSource implements DataSource.Provider{
	private List<DataSource.Event> events;
	private sObject subject;
	
	public FieldHistoryDataSource(sObject subject){
		this.subject = subject;
		events = new List<DataSource.Event>();	
	}
	public String getProviderName(){
		return 'FieldHistory';
	}
	public String getProviderLabel(){
		return 'Field History Tracking';
	}
	
	public List<DataSource.Event> getEvents(DateTime startTime, DateTime endTime){
		events.clear();
		/*if(injectedResults != null ){
			//this is from inside a test - run some special logic
			addHistory( injectedResults , 'Record Edited');
		} else {*/
			String tblName;
			Schema.DescribeSObjectResult describe = subject.getSObjectType().getDescribe();
			if(describe.isCustom()){ //feeds have different naming schemes for standard vs custom objects
				tblName = describe.getName().replace('__c', '__History');
			}else{
				tblName = describe.getName() + 'History'; 
			}
			String query = 'SELECT id, field, oldValue, newValue, CreatedById, CreatedDate FROM '+tblName+' WHERE ContactId = \''+subject.id+'\'';
			addHistory( Database.Query(query) );
		//}
		return events;
	}

	private void addHistory(List<sObject> fieldChanges){
		DataSource.Event event;
		
		for(sObject fieldChange:fieldChanges){
			String oldValue = ''+ fieldChange.get('oldValue');
			String newValue = ''+ fieldChange.get('newValue');
			/*boolean isJunk = true; //stuff slips past this implementation - we need a better filter
			try{
				id thisId = oldValue;
			}catch(System.StringException e){
				//A junk row with IDs rather than names is inserted for every change, we want to ignore that one.
				isJunk = false;
			}*/
			
			String description = fieldChange.get('Field') + ' changed from "'+oldValue+'" to "'+newValue+'"';
			event = new DataSource.Event(
				this,
				(DateTime) fieldChange.get('CreatedDate'), 
				description,
				(id)fieldChange.get('CreatedById'),
				null
			);
			events.add(event);
		}
	}
}