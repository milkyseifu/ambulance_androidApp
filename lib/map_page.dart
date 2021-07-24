import 'package:amblance/secrets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' show cos, sqrt, asin;


class MapPage extends StatefulWidget {
  final double incidentLatitude, incidentLongitude;
  const MapPage({Key? key, required this.incidentLatitude, required this.incidentLongitude}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _initialCameraPosition = CameraPosition(
                      target: LatLng(9.1450, 40.4897),
                      zoom: 6
                );

  late GoogleMapController _googleMapController;
  late Marker _origin;
  late Marker _destination;
  late Position _currentPosition, _lastPosition;
  late String _currentAddress, _startAddress, _destinationAddress;
  Set<Marker> markers = {};
  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  String? _placeDistance;

  final startAddressController = TextEditingController();

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text('Map'),
        flexibleSpace: ClipRRect(
          // borderRadius: BorderRadius.only(bottomRight: Radius.circular(50), bottomLeft: Radius.circular(50)),
          child: Container(
            color: Colors.blueAccent,
            // decoration: BoxDecoration(
            //     image: DecorationImage(
            //         image: AssetImage('assets/emer.jpg'),
            //         fit: BoxFit.fill,
            //         colorFilter: ColorFilter.mode(Colors.red.withOpacity(0), BlendMode.darken)
            //     )
            // ),
          ),
        ),
      ),

      body: GoogleMap(
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        initialCameraPosition: _initialCameraPosition,
        mapType: MapType.normal,
        onMapCreated: (controller) => _googleMapController = controller,
        markers: markers,
        onTap: (pos){

          Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) async {
            // print(pos);
            _currentPosition = position;

            double startLatitude = _currentPosition.latitude;
            double startLongitude = _currentPosition.longitude;

            double destinationlatitude = widget.incidentLatitude;
            double destinationlongitude = widget.incidentLongitude;

            String startCoordinateString = '($startLatitude, $startLongitude)';
            String destinationCoordinateString = '($destinationlatitude, $destinationlongitude)';

            Marker startmarker = Marker(
                markerId: MarkerId(startCoordinateString),
                position: LatLng(startLatitude, startLongitude),
                infoWindow: InfoWindow(
                  title: 'Start $startCoordinateString',
                ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            );

            Marker destinationmarker = Marker(
              markerId: MarkerId(destinationCoordinateString),
              position: LatLng(destinationlatitude, destinationlongitude),
              infoWindow: InfoWindow(
                title: 'Destination $destinationCoordinateString',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            );

            markers.clear();
            markers.add(startmarker);
            markers.add(destinationmarker);

            double miny = (startLatitude <= destinationlatitude)
                ?startLatitude : destinationlatitude;

            double minx = (startLongitude <= destinationlongitude)
                ?startLongitude : destinationlongitude;

            double maxy = (startLatitude <= destinationlatitude)
                ?destinationlatitude : startLatitude;

            double maxx = (startLongitude <= destinationlongitude)
                ?destinationlongitude : startLongitude;


            double southWestLatitude = miny;
            double southWestLongitude = minx;
            double northEastLatitude = maxy;
            double northEastLongitude = maxx;

            _googleMapController.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                    southwest: LatLng(southWestLatitude, southWestLongitude),
                    northeast: LatLng(northEastLatitude, northEastLongitude),
                ),
                100.0,
              ),
            );
            
            await _createPolylines(startLatitude, startLongitude, destinationlatitude, destinationlongitude);

            double totalDistance = 0.0;

            for(int i = 0; i<polylineCoordinates.length-1; i++){
              totalDistance  += _coordinateDistance(
                polylineCoordinates[i].latitude,
                polylineCoordinates[i].longitude,
                polylineCoordinates[i+1].latitude,
                polylineCoordinates[i+1].longitude
              );
            }
            _placeDistance = totalDistance.toStringAsFixed(2);

            Fluttertoast.showToast(
                msg: '${_placeDistance}',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0);

            await _getAddress();
          });
        },
        ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        onPressed: () => _googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        ),
        child: const Icon(Icons.center_focus_strong),
      ),
      );

  }
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationlatitude,
      double destinationlongitude,
      ) async {
          polylinePoints = PolylinePoints();
          PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
            Secrets.API_KEY, // Google Maps API Key
            PointLatLng(startLatitude, startLongitude),
            PointLatLng(destinationlatitude, destinationlongitude),
            travelMode: TravelMode.transit,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }


  @override
  void initState() {
    super.initState();
    // _getCurrentLocation();
  }

  _getAddress() async {
    try{
      List<Placemark> p = await
      placemarkFromCoordinates(_currentPosition.latitude, _currentPosition.longitude);
      Placemark placemark = p[0];

      setState(() {
        _currentAddress = "${placemark.name}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
        _startAddress = _currentAddress;
        Fluttertoast.showToast(
            msg: '${_startAddress}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
      });
    }catch(e){
      print(e);
    }
  }
}
