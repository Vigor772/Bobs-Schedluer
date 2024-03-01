import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:async';

void main() async {
  Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('onNotificationCreatedMethod');
  }

  Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('onNotificationDisplayedMethod');
  }

  Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('onDismissActionReceivedMethod');
  }

  Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Handle the action received
// Access the payload from the received action

    // Check if we are running in a web environment
    if (kIsWeb) {
      // Handle navigation for web
      // Replace the line below with your web navigation logic
      print('Navigation not supported in web');
    } else {
      // Navigate in non-web environments
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
            builder: (BuildContext context) => ActivityListScreen()),
      );
    }
  }

  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelShowBadge: true,
            criticalAlerts: true,
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            enableVibration: true,
            importance: NotificationImportance.High),
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group', channelGroupName: "tada"),
      ],
      debug: true);
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
    onNotificationCreatedMethod: onNotificationCreatedMethod,
    onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: onDismissActionReceivedMethod,
  );

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Activity {
  String name;
  String goal;
  TimeOfDay reminderTime;
  bool isCompleted;

  Activity(
      {required this.name,
      required this.goal,
      required this.reminderTime,
      this.isCompleted = false});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Daily Goal Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ActivityListScreen(),
    );
  }
}

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  _ActivityListScreenState createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  //TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();

    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications(
            permissions: [NotificationPermission.Alert]);
      }
    });
  }

  Future<void> triggerNotification(context, Activity activity) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      activity.reminderTime.hour,
      activity.reminderTime.minute,
    );

    if (scheduledTime.isBefore(now) || scheduledTime == now) {
      scheduledTime.add(const Duration(days: 1));
    }

    final int notificationId = activities
        .indexOf(activity); // Generate unique ID based on the activity's index
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        payload: {
          "navigate": "true",
        },
        notificationLayout: NotificationLayout.Messaging,
        id: notificationId, // Use the generated unique ID
        channelKey: 'basic_channel',
        title: activity.name,
        body: 'Don\'t forget to complete your goal!: ${activity.goal}',
        summary: 'xd',
        displayOnBackground: true,
        displayOnForeground: true,
      ),
      schedule: NotificationCalendar(
        hour: activity.reminderTime.hour,
        minute: activity.reminderTime.minute,
        preciseAlarm: true,
      ),
    );

    print(
        'Notification scheduled at ${activity.reminderTime.hour}:${activity.reminderTime.minute}');
  }

  List<Activity> activities = [
    Activity(
        name: 'Exercise',
        goal: 'go to gym',
        reminderTime: const TimeOfDay(hour: 8, minute: 0)),
    Activity(
        name: 'Reading',
        goal: 'read novel',
        reminderTime: const TimeOfDay(hour: 10, minute: 0)),
    Activity(
        name: 'Learning',
        goal: 'learn flutter',
        reminderTime: const TimeOfDay(hour: 14, minute: 0)),
    Activity(
        name: 'Eat',
        goal: 'eat breakfast',
        reminderTime: const TimeOfDay(hour: 7, minute: 0)),
  ];

  void addActivity(Activity activity) {
    setState(() {
      activities.add(activity);
    });
  }

  void deleteActivity(int index) {
    setState(() {
      activities.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Daily Goal Tracker'),
      ),
      body: ListView.builder(
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              activities[index].name,
              style: TextStyle(
                decoration: activities[index].isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: activities[index].isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: Text(
              'Goal: ${activities[index].goal}',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            trailing: Checkbox(
              value: activities[index].isCompleted,
              onChanged: (value) {
                setState(() {
                  activities[index].isCompleted = value ?? false;
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddActivityDialog(
                addActivity: addActivity,
                activities: activities,
                triggerNotification:
                    triggerNotification, // Pass triggerNotification function
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddActivityDialog extends StatefulWidget {
  final Function(Activity) addActivity;
  final List<Activity> activities;
  final Function(BuildContext, Activity)
      triggerNotification; // Declare triggerNotification function

  const AddActivityDialog(
      {super.key,
      required this.addActivity,
      required this.activities,
      required this.triggerNotification});

  @override
  _AddActivityDialogState createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _goalController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Activity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Activity Name'),
          ),
          TextField(
            controller: _goalController,
            decoration: InputDecoration(labelText: 'Goal'),
          ),
          SizedBox(height: 10),
          Text('Select Notification Time:'),
          TextButton(
            onPressed: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (pickedTime != null) {
                setState(() {
                  _selectedTime = pickedTime;
                });
              }
            },
            child: Text(
              _selectedTime.format(context),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            String name = _nameController.text;
            String goal = _goalController.text;
            if (name.isNotEmpty && goal.isNotEmpty) {
              widget.addActivity(Activity(
                  name: name, goal: goal, reminderTime: _selectedTime));
              widget.triggerNotification(
                  context,
                  Activity(
                      name: name,
                      goal: goal,
                      reminderTime:
                          _selectedTime)); // Call triggerNotification function
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
