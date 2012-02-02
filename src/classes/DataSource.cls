public with sharing class DataSource {
	public interface Provider{
		String getProviderName();
		String getProviderLabel();
		List<DataSource.Event> getEvents();
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
		public virtual String getLocalizedTimestamp(){
			return timestamp.format();
		}
		public virtual String getDescription(){
			return description;
		}
		public virtual Id getActorId(){
			return actor;
		}
		public virtual String getDetailURL(){
			return detailURL;
		}
		public virtual String getProviderName(){
			return dataProvider.getProviderName();
		}
		public virtual String getProviderLabel(){
			return dataProvider.getProviderLabel();
		}
		
		 
	}
	
}