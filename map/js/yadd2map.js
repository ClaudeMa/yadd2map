	function TimedRefresh( t ) {
		setTimeout("location.reload(true);", t);
	}
	
	var mylat = 0.0;
	var mylon = 0.0;
		
	var coords = []; 
    var mapboxTiles = L.tileLayer('http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {
        attribution: '<a href="http://www.mapbox.com/about/maps/" target="_blank">Terms &amp; Feedback</a>'
    });
    //possible colors 'red', 'darkred', 'orange', 'green', 'darkgreen', 'blue', 'purple', 'darkpuple', 'cadetblue'
    var ship = L.AwesomeMarkers.icon({
        prefix: 'fa', //font awesome rather than bootstrap
        markerColor: 'blue', // see colors above
        icon: 'ship' //http://fortawesome.github.io/Font-Awesome/icons/
    });	
	var coast = L.AwesomeMarkers.icon({
        prefix: 'fa', //font awesome rather than bootstrap
        markerColor: 'green', // see colors above
        icon: 'wifi' //http://fortawesome.github.io/Font-Awesome/icons/
    });
	var home = L.AwesomeMarkers.icon({
        prefix: 'fa', //font awesome rather than bootstrap
        markerColor: 'orange', // see colors above
        icon: 'home' //http://fortawesome.github.io/Font-Awesome/icons/
    });
    var map = L.map('map')
        .addLayer(mapboxTiles);
	var rxposition = $.getJSON("/data/home.json");
	rxposition.then(function(data) {
		var rxhome = L.geoJson(data, {
            pointToLayer: function(feature, latlng) {
				mylat = latlng.lat;
				mylon = latlng.lng;
				map.setView([mylat, mylon], 2);
                return L.marker(latlng, {
                    icon: home
                }).on('mouseover', function() {
                    this.bindPopup('RX Position').openPopup();
                });
            }
        });
		rxhome.addTo(map)
	});
	
	
    var promise = $.getJSON("/data/data.json");
    promise.then(function(data) {
        var allrx = L.geoJson(data);
        var rxshipq = L.geoJson(data, {
            filter: function(feature, layer) {
                return feature.properties.Description == "SHIP";
            },
            pointToLayer: function(feature, latlng) {
				var mydistance = distance(mylat, mylon, latlng.lat, latlng.lng, 'K');
                return L.marker(latlng, {
                    icon: ship
                }).on('mouseover', function() {				    
                    this.bindPopup("MMSI: <a href='https://www.marinetraffic.com/en/ais/details/ships/mmsi:" + feature.properties.Mmsi + "' target='_blank'>" + feature.properties.Mmsi + 
					"</a><br/>Name: <b>" + feature.properties.Name + "</b><br/>Last heard: " + feature.properties.Date + " at " + feature.properties.Hour + 
                    "<br/>On " + feature.properties.frequency + " Khz" +
                    "<br/>distance: " + mydistance.toFixed(2) + " km").openPopup();
                }).bindLabel(feature.properties.Name, {
					noHide: true,
					direction: 'auto',
					className: 'my-label'
				});
            }
    });
    var rxcoasts = L.geoJson(data, {
            filter: function(feature, layer) {
                return feature.properties.Description != "SHIP";
            },
            pointToLayer: function(feature, latlng) {
				var mydistance = distance(mylat, mylon, latlng.lat, latlng.lng, 'K');
                return L.marker(latlng, {
				icon: coast
                }).on('mouseover', function() {
					var mydistance = distance(mylat, mylon, latlng.lat, latlng.lng, 'K');
                     this.bindPopup("MMSI: " + feature.properties.Mmsi + 
					"<br/>Name: <b>" + feature.properties.Name + "</b><br/>Last heard: " + feature.properties.Date + " at " + feature.properties.Hour +
                    "<br/>On " + feature.properties.frequency + " Khz" +
					"<br/>distance: " + mydistance.toFixed(2) + " km").openPopup();
                }).bindLabel(feature.properties.Name, {
					noHide: true,
					direction: 'auto',
					className: 'my-label'
				});
            }
    });
     
        rxshipq.addTo(map)
        rxcoasts.addTo(map)
		
        $("#rxcoasts").click(function() {
            map.addLayer(rxcoasts)
            map.removeLayer(rxshipq)
        });
        $("#rxships").click(function() {
            map.addLayer(rxshipq)
            map.removeLayer(rxcoasts)
        });
        $("#rxall").click(function() {
            map.addLayer(rxshipq)
            map.addLayer(rxcoasts)
        });
		$("#monitor").click(function() {
           window.open("http://www.yaddnet.org:8000/index.php");
        });
		$("#aprs").click(function() {
           window.open("http://www.aprs.fi");
        });
    });
	
