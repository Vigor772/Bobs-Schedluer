import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,

      )
    ],
  );

  runApp(MyApp());
}

class Activity {
  String name;
  String goal;
  TimeOfDay reminderTime;
  bool isCompleted;

  Activity({required this.name, required this.goal, required this.reminderTime, this.isCompleted = false});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Goal Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ActivityListScreen(),
    );
  }
}

class ActivityListScreen extends StatefulWidget {
  @override
  _ActivityListScreenState createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    super.initState();
  }

  void triggerNotification(BuildContext context, Activity activity) {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      activity.reminderTime.hour,
      activity.reminderTime.minute,
    );

    if (scheduledTime.isBefore(now) || scheduledTime == now) {
      scheduledTime.add(Duration(days: 1));
    }

    final int notificationId = activities.indexOf(activity); // Generate unique ID based on the activity's index

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId, // Use the generated unique ID
        channelKey: 'basic_channel',
        title: activity.name,
        body: 'Don\'t forget to complete your goal!: ${activity.goal}',
        summary: 'xd',
        displayOnBackground: true,
        displayOnForeground: true,
        category: NotificationCategory.Event,
        ticker:'notif'


      ),
      schedule: NotificationCalendar(
        hour: activity.reminderTime.hour,
        minute: activity.reminderTime.minute,
        preciseAlarm: true,
      ),
    );

    print('Notification scheduled at ${activity.reminderTime.hour}:${activity.reminderTime.minute}');
  }

  List<Activity> activities = [
    Activity(name: 'Exercise', goal: 'go to gym', reminderTime: TimeOfDay(hour: 8, minute: 0)),
    Activity(name: 'Reading', goal: 'read novel', reminderTime: TimeOfDay(hour: 10, minute: 0)),
    Activity(name: 'Learning', goal: 'learn flutter', reminderTime: TimeOfDay(hour: 14, minute: 0)),
    Activity(name: 'Eat', goal: 'eat breakfast', reminderTime: TimeOfDay(hour: 7, minute: 0)),
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
        title: Text('Daily Goal Tracker'),
      ),
      body: ListView.builder(
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              activities[index].name,
              style: TextStyle(
                decoration: activities[index].isCompleted ? TextDecoration.lineThrough : null,
                color: activities[index].isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: Text(
              'Goal: ${activities[index].goal}',
              style: TextStyle(
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
                triggerNotification: triggerNotification, // Pass triggerNotification function
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddActivityDialog extends StatefulWidget {
  final Function(Activity) addActivity;
  final List<Activity> activities;
  final Function(BuildContext, Activity) triggerNotification; // Declare triggerNotification function

  AddActivityDialog({required this.addActivity, required this.activities, required this.triggerNotification});

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
      title: Text('Add New Activity'),
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
              widget.addActivity(Activity(name: name, goal: goal, reminderTime: _selectedTime));
              widget.triggerNotification(context, Activity(name: name, goal: goal, reminderTime: _selectedTime)); // Call triggerNotification function
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
