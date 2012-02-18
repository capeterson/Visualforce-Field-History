public with sharing class ChatterTrackingDataSource implements DataSource.Provider{
	public static final String PROVIDER_NAME = 'ChatterTracking';
	public static final String PROVIDER_LABEL = 'Chatter';
	public static final String IMAGE_URL = 'http://a1.mzstatic.com/us/r1000/035/Purple/5e/7f/87/mzl.sjmcmbqs.100x100-75.jpg';
	private sObject subject;
	
	public void init(sObject subject){
		if(!SchemaUtil.isOrgChatterEnabled())
			System.assert(false,'Cannot create a ChatterTrackingDataSource if chatter is disabled!');
		this.subject = subject;
	}
	
	public String getName(){
		return PROVIDER_NAME;
	}
	public String getLabel(){
		return PROVIDER_LABEL;
	}
	public String getImageURL(){
		return IMAGE_URL;
	}
	
	public List<DataSource.Event> getEvents(){
		List<DataSource.Event> result = new List<DataSource.Event>();
		String feedName;
		Schema.DescribeSObjectResult describe = subject.getSObjectType().getDescribe();
		
		if(describe.isCustom()){ //feeds have different naming schemes for standard vs custom objects
			feedName = describe.getName().replace('__c', '__Feed');
		}else{
			feedName = describe.getName() + 'Feed';
		}
		String queryString = 'SELECT id, CreatedDate, CreatedById, (SELECT id, fieldName, oldValue, newValue FROM FeedTrackedChanges ORDER BY Id) FROM '+feedName+' WHERE parentId = \''+subject.id+'\' AND Type = \'TrackedChange\'';
		for(sObject item:Database.query(queryString)){
			FieldHistoryDataSource.FieldUpdateEvent lastEvent;
			for(FeedTrackedChange fieldChange:item.getSObjects('FeedTrackedChanges')){
				String fieldName = (''+fieldChange.get('FieldName')).replaceFirst('.+\\.','').toLowerCase();
				FieldHistoryDataSource.FieldUpdateEvent event = new FieldHistoryDataSource.FieldUpdateEvent(
					this,
					(DateTime) item.get('createdDate'),
					(Id) item.get('CreatedById'),
					fieldName,
					fieldChange.get('oldValue'),
					fieldChange.get('newValue')
				);
				if(lastEvent != null && lastEvent.getTimestamp() == event.getTimestamp() && lastEvent.getTarget() == event.getTarget()){
					lastEvent.oldLookupId = (Id) event.oldValue;
					lastEvent.newLookupId = (Id) event.newValue;
				}else{
					result.add(event);
				}
				lastEvent = event;
			}
		}
		return result;
	}
	
}