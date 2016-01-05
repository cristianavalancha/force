(function() {
  'use strict';

  if(location.pathname.match(/artwork/)) analytics.track('Artwork page', { id: sd.ARTWORK.id, nonInteraction: 1 });

  // DOM events
  var $document = $(document);

  $document.on('click', '.show-phone-number', function(e){
    analytics.track("Clicked 'Show phone number'");
  });

  $document.on('click', '.artwork-download-button', function(e){
    analytics.track('Downloaded lo-res image');
  });

  $document.on('click', '.circle-icon-button-share', function(e){
    analytics.track('Viewed sharing_is_caring form');
  });

  $document.on('click', '.artwork-buy-button', function(e){
    analytics.track('Clicked "Buy" on the artwork page');
  });

  $document.on('click', '.artwork-download-button', function(e){
    analytics.track('Downloaded lo-res image');
  });

  $document.on('click', '.artwork-partner-name', function(e){
    analytics.track('Clicked partner name link in detail sidebar');
  });

  $document.on('click', '.artwork-auction-results-button', function(e){
    analytics.track("Viewed 'Comparables'");
  });

  analyticsHooks.on('artwork:zoom', function(){
    analytics.track('Clicked to zoom in on artwork');
  });

  analyticsHooks.on('artwork:view-in-room', function(){
    analytics.track("Entered 'View In Room'");
  });

  analyticsHooks.on('artwork:contact-gallery', function(){
    analytics.track("Clicked 'Contact Gallery'");
  });

  analyticsHooks.on('artwork:contact-specialist', function(){
    analytics.track("Clicked 'Contact Artsy Specialist'");
  });

  analyticsHooks.on('artwork:confirm-registration', function(){
    analytics.track("Showed 'Confirm registration on artwork page'");
  });

})();
