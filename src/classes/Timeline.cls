public with sharing class Timeline {
	private Map<DateTime,List<DataSource.Event>> eventHistory;
	private Map<String,DataSource.Provider> providers; //key is the getProviderName() from the provider
	public boolean orderDesc {get; set;}
	
	public Timeline(sObject subject){
		providers = new Map<String,DataSource.Provider>();
		orderDesc = true;
	}
	public void addProvider(DataSource.Provider p){
		String providerName = p.getProviderName();
		if(providers.containsKey(providerName)){
			System.assert(false,'Provider name '+providerName+' is not unique!');
		}else{
			providers.put(providerName,p);
		}
	}
	private void buildEventHistory(){
		eventHistory = new Map<DateTime,List<DataSource.Event>>();
		for(DataSource.Provider p:providers.values()){
			for(DataSource.Event e:p.getEvents()){
				List<DataSource.Event> eventList;
				if( !eventHistory.containsKey(e.getTimestamp()) ){
					eventList = new List<DataSource.Event>();
					eventHistory.put(e.getTimestamp(),eventList);
				}else{
					eventList = eventHistory.get(e.getTimestamp());
				}
				eventList.add(e);
			}
		}
	}
	public List<DataSource.Event> getEvents(){
		if(eventHistory == null)
			buildEventHistory();
		List<DataSource.Event> result = new List<DataSource.Event>();
		List<DateTime> keyList = new List<DateTime>();
		keyList.addAll( eventHistory.keySet() );
		keyList.sort();
		for(DateTime key:keyList){
			result.addAll(
				eventHistory.get(key)
			);
		}
		return result;
	}
}