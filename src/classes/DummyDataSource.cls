public with sharing class DummyDataSource implements DataSource.Provider{
	private sObject subject;
	
	public void init(sObject subject){
		this.subject = subject;
		//any other constructor logic shoudl be done inside init	
	}
	public String getName(){
		return 'DummyDataSource'; //a unique name for this plugin
	}
	public String getLabel(){
		return 'A sample dummy plugin'; //the label to shown on the UI where these events came from
	}
	public String getImageURL(){
		return '/img/alohaSkin/feeds/cloud.png';
	}
	
	public List<DataSource.Event> getEvents(){
		List<DataSource.Event> result = new List<DataSource.Event>{
			new DataSource.Event(this, DateTime.now(), 'A dummy event happened.', 'A dummy event', UserInfo.getUserId(), null)
		};		
		return result;
	}
}