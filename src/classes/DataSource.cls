public with sharing class DataSDateource {
	public interface Provider{
		String getProviderName();
		String getProviderLabel();
		List<DataSource.Event> getEvents(DateTime startTime,DateTime endTime);
	}
	
	/**
	 * A generic implementation of an event object. May be extended by providers,
	 * or may be used as is if no custom behavior is needed.
	**/
	public virtual class Event{
		private DateTime timestamp;
		private String description;
		private Id actor;
		private Provider dataProvider;
		private String detailURL;
		
		public Event(Provider provider, DateTime timestamp, String description, Id actor, String detailUrl){
			this.dataProvider = provider;
			this.timestamp = timestamp;
			this.description = description;
			this.actor = actor;
			this.detailURL = detailURL;
		}
		
		public virtual DateTime getTimestamp(){
			return timestamp;
		}
		public virtual String getDescription(){
			return description;
		}
		public virtual Id getActorId(){
			return actor;
		}
		public virtual String getProviderName(){
			return dataProvider.getProviderName();
		}
		
		 
	}
	
}