import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crud_page.dart';  // Dynamic CRUD page

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = false;
  int notificationCount = 3;

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Dashboard"),
          centerTitle: true,
          actions: [

            /// 🔔 Notification Badge
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    setState(() => notificationCount = 0);
                  },
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        notificationCount.toString(),
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),

            /// 🌙 Dark Mode Toggle
            Switch(
              value: isDarkMode,
              onChanged: (value) {
                setState(() => isDarkMode = value);
              },
            ),

            /// 🚪 Logout
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => logout(context),
            ),
          ],
        ),

        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 👋 Welcome Section
              Text(
                "Welcome Back 👋",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                user?.email ?? "Firebase User",
                style: TextStyle(color: Colors.grey),
              ),

              SizedBox(height: 25),

              /// 📊 Dashboard Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard("Tasks", "12", Icons.task_alt, Colors.green),
                  _statCard("Completed", "7", Icons.check_circle, Colors.blue),
                  _statCard("Pending", "5", Icons.pending, Colors.orange),
                ],
              ),

              SizedBox(height: 30),

              /// 🧩 Feature Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [

                    /// TASKS CARD
                    _featureCard(
                      icon: Icons.list_alt,
                      title: "Tasks",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CrudPage(type: "task")),
                        );
                      },
                    ),

                    /// PROFILE CARD
                    _featureCard(
                      icon: Icons.person,
                      title: "Profile",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CrudPage(type: "profile")),
                        );
                      },
                    ),

                    /// SETTINGS
                    _featureCard(
                      icon: Icons.settings,
                      title: "Settings",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Settings coming soon ⚙️")),
                        );
                      },
                    ),

                    /// ABOUT
                    _featureCard(
                      icon: Icons.info,
                      title: "About",
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: "Firebase App",
                          applicationVersion: "1.0.0",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Stat Card Widget
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(height: 5),
              Text(value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  /// 🧩 Feature Card Widget
  Widget _featureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50),
            SizedBox(height: 10),
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
