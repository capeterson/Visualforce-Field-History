public with sharing class FieldHistoryDataSource implements DataSource.Provider{
	private List<DataSource.Event> events;
	private sObject subject;
	
	public void init(sObject subject){
		this.subject = subject;
		events = new List<DataSource.Event>();	
	}
	public String getName(){
		return 'FieldHistory';
	}
	public String getLabel(){
		return 'Field History Tracking';
	}
	public String getImageURL(){
		return '/resource/diagonia/icons/16/165.png';
	}
	public List<DataSource.Event> getEvents(){
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
			String query = 'SELECT id, field, oldValue, newValue, CreatedById, CreatedDate FROM ' +
				tblName+' WHERE ContactId = \''+subject.id+'\' ORDER BY Id';
			System.debug('Query to run: '+query);
			addHistory( Database.Query(query) );
		//}
		return events;
	}

	private void addHistory(List<sObject> fieldChanges){
		FieldUpdateEvent lastEvent;		
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
			FieldUpdateEvent event = new FieldUpdateEvent(
				this,
				(DateTime) fieldChange.get('CreatedDate'), 
				(id)fieldChange.get('CreatedById'),
				(String) fieldChange.get('Field'),
				oldValue,
				newValue
			);
			//a hack for the fact that lookup changes generate two history objects
			if(lastEvent != null && lastEvent.getTimestamp() == event.getTimestamp() && lastEvent.getTarget() == event.getTarget()){
				if(event.oldValue != null && event.oldValue != 'null')
					lastEvent.oldLookupId = (Id) event.oldValue;
				if(event.newValue != null && event.newValue != 'null')
					lastEvent.newLookupId = (Id) event.newValue;
			}else{
				events.add(event);
			}
			lastEvent = event;
		}
	}
	
	public class FieldUpdateEvent extends DataSource.Event{
		public Object oldValue {public get; protected set;}
		public Object newValue {public get; protected set;}
		public String oldLookupId {get; set;}
		public String newLookupId {get; set;}
		
		public FieldUpdateEvent(Provider provider, DateTime timestamp, Id actor, String fieldName, Object oldValue, Object newValue){
			this.dataProviders = new List<Provider>{ provider };
			this.timestamp = timestamp;
			this.actor = actor;
			this.target = fieldName;
			this.oldValue = oldValue;
			this.newValue = newValue;
		}
		
		public override String getShortDescription(){
			return target+' changed to "'+newValue+'"';
		}
		
		public override String getDescription(){
			return target + ' changed from "'+oldValue+'" to "'+newValue+'"'; //need to translate the name into label!
		}
	}
}