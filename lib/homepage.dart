import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

FlutterLocalNotificationsPlugin? notification;
showNotification(String message) {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    importance: Importance.max,
    priority: Priority.high,
  );
  // var iOSPlatformChannelSpecifics = const IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  notification!
      .show(0, 'Alert', message, platformChannelSpecifics, payload: 'item x');
}

class _HomePageState extends State<HomePage> {
  final _databaseReference = FirebaseDatabase.instance.ref();
  bool showButton = false;

  @override
  void initState() {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    // var initializationSettingsIOS = const IOSInitializationSettings();
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    notification = FlutterLocalNotificationsPlugin();
    notification!.initialize(initializationSettings);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text("Home"),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          // color: const Color.fromRGBO(162, 121, 21, 0.5),
          // padding: const EdgeInsets.only(top: 30),
          child: StreamBuilder(
            stream: _databaseReference.onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.data != null) {
                var data = snapshot.data!.snapshot.value;
                return Column(
                  children: [
                    _buildBody(
                      temperature: data['Temperature'],
                      humidity: data['Humidity'],
                      moisture: data['Soil_Value'],
                      context: context,
                    ),
                    
                    const SizedBox(height: 20),
                    data['Motor_Status'] == 1
                        ? ElevatedButton(
                            onPressed: () {
                              _databaseReference.update({
                                'Motor_Status': 0,
                              });
                            },
                            child: const Text("Motor off"),
                          )
                        : Container()
                  ],
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

Widget _buildBody(
    {required dynamic temperature,
    required dynamic humidity,
    required dynamic moisture,
    required BuildContext context}) {
  return Container(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTemperatureIndicator(
              text: "Temperature",
              value: temperature,
              context: context,
            ),
            _buildContainer(
              text: "Humidity",
              value: humidity,
              context: context,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        _buildMoistureIndicator(
          text: "Moisture",
          value: moisture,
          context: context,
        )
      ],
    ),
  );
}

Widget _buildContainer({
  required String text,
  required dynamic value,
  required BuildContext context,
  required Color color,
}) {
  bool check = text == "Humidity" || text == "Moisture";

  return Container(
    width: MediaQuery.of(context).size.width * 0.5,
    child: ListTile(
      title: CircularPercentIndicator(
        addAutomaticKeepAlive: true,
        animation: true,
        animationDuration: 1500,
        animateFromLastPercent: true,
        radius: 80.0,
        lineWidth: 15,
        percent: check ? value / 100 : 1.0,
        center: Text(
          check ? "${value} %" : "${value} °C",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        progressColor: color,
      ),
      subtitle: Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildTemperatureIndicator({
  required String text,
  required dynamic value,
  required BuildContext context,
}) {
  if (value < 15) {
    return _buildContainer(
      text: text,
      value: value,
      context: context,
      color: Colors.deepPurple,
    );
  } else if (value >= 15 && value <= 45) {
    return _buildContainer(
      text: text,
      value: value,
      context: context,
      color: Colors.green,
    );
  } else {
    return _buildContainer(
      text: text,
      value: value,
      context: context,
      color: Colors.red,
    );
  }
}

Widget _buildMoistureIndicator({
  required String text,
  required dynamic value,
  required BuildContext context,
}) {
  if (value < 60) {
    showNotification("Dangerously low soil moisture, Moisture $value %");
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text("Dangerously low soil moisture"),
              content: const Text("Do you want to switch on the motor"),
              actions: [
                TextButton(
                  child: const Text("Yes"),
                  onPressed: () {
                    var x = FirebaseDatabase.instance.reference();
                    x.update({'Motor_Status': 1});
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text("No"),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          });
    });

    return _buildContainer(
      text: text,
      value: value,
      context: context,
      color: Colors.red,
    );
  } else if (value >= 80 && value <= 100) {
    return _buildContainer(
      text: text,
      value: value,
      context: context,
      color: Colors.green,
    );
  } else {
    return _buildContainer(
      text: text,
      value: value,
      context: context,
      color: Colors.orange,
    );
  }
}
