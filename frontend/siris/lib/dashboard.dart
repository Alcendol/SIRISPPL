import 'dart:convert';  
import 'package:flutter/material.dart';
import 'package:siris/navbar.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


final loggerDashboard = Logger('DashboardState');

class Dashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const Dashboard({super.key, required this.userData});

  @override
  DashboardState createState() => DashboardState();

}

class DashboardState extends State<Dashboard> {
  get userData => widget.userData;
  String totalSks = '0';
  String ipk = '0.0';
  SharedPreferences? prefs; 
  @override
  void initState() {
    super.initState();
        _loadPrefs();
    if (userData['currentLoginAs'] == 'Mahasiswa'){
      fetchDataMahasiswa();
    }
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }
  
  Future<void> fetchDataMahasiswa() async {
   final nim = widget.userData['identifier'];
    final semester = widget.userData['semester'];
    final String apiUrl = 'http://localhost:8080/mahasiswa/info-mahasiswa/$nim?semester=$semester'; // Ganti dengan endpoint API Anda

    try {
      loggerDashboard.info("Fetching Data Mahasiswa URL: $apiUrl"); 
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        // Decode the JSON response
        final data = json.decode(response.body);
        setState(() {
          totalSks = data['total_sks'].toString();
          ipk = data['ipk'].toString();
        });
      } else {
        setState(() {
          totalSks = 'Error';
          ipk = 'Error';
        });
        debugPrint('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        totalSks = 'Error';
        ipk = 'Error';
      });
      debugPrint('Error fetching data: $e');
    }
  }

  Widget _getDashboard(BuildContext context, String role){
    loggerDashboard.info(userData['nama_prodi']);
    switch (role){
      case "Mahasiswa":
        return _dashboardMahasiswa(context);
      case "Dosen":
        return _dashboardDosen(context);
      case "Dekan":
        return _dashboardDekan(context);
      case "Kaprodi":
        return _dashboardKaprodi(context);
      case "Bagian Akademik":
        return _dashboardBaka(context);
      default:
        loggerDashboard.warning("Role hasn't been set");
        return Column(
          children: [
            Text('This account has no role'),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
    }
  }



  Widget _dashboardMahasiswa(BuildContext context){
    return Transform.translate(
      offset: Offset(0, -30),
      child: Column(
        children: [
          //Status Akademik
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 160, vertical: 0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:16, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        bottom: BorderSide(
                          color: Color(0xFF162953), // Bottom border color
                          width: 6.0,               // Bottom border width
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school, size: 30, color: Color(0xFF162953)),
                            SizedBox(width: 8),
                            Text(
                              'Status Akademik',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Dosen Wali',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text('${userData['dosen_wali_name']}', style: const TextStyle(fontSize: 16)),
                        Text('${userData['dosen_wali_nip']}', style: const TextStyle(fontSize: 16)),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00549C),
                                Color(0xFF003664),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.headset, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Konsultasi', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),

                        const Divider(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSemesterInfo('Semester Akademik Sekarang', '2024/2025 Ganjil', Colors.green, Colors.white),
                            _buildSemesterInfo('Semester Studi', '${userData['semester']}', Colors.transparent, Colors.black),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Other Information or button here
        ],
      )
    );
  }

  Widget _dashboardDekan(BuildContext context){
    // return Row(
    //   children: [
    //     Flexible(
    //       flex: 2,
    //       fit: FlexFit.tight,
    //       child: Container(
    //         color: Colors.black,
    //         child: Text("Test"),
    //       ),
    //     ),
    //     Flexible(
    //       flex: 2,
    //       fit: FlexFit.tight,
    //       child: Expanded(
    //         child:Row(
    //           children: [
    //             Container(
    //               margin: const EdgeInsets.all(4.0),
    //               padding: const EdgeInsets.all(4.0),
    //               decoration: const BoxDecoration(
    //                 borderRadius: BorderRadius.all(Radius.circular(10)),
    //                 color: Color(0xFF00549C)
    //               ),
    //               child: GestureDetector(
    //                 onTap: () => Navigator.pushNamed(context, '/dekan/ruang/', arguments: userData),
    //                 child: Column(
    //                   children: [
    //                     Icon(Icons.room, color: Colors.white),
    //                     const SizedBox(width: 5),
    //                     Text("Ruangan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),)
    //                   ]
    //                 ),
    //               ),
    //             ),
    //             Container(
    //               margin: const EdgeInsets.all(4.0),
    //               padding: const EdgeInsets.all(4.0),
    //               decoration: const BoxDecoration(
    //                 borderRadius: BorderRadius.all(Radius.circular(10)),
    //                 color: Color(0xFF00549C)
    //               ),
    //               child: SizedBox(
    //                 width: 300,
    //                 height: 300,
    //                 child: ElevatedButton(
    //                   onPressed: () => Navigator.pushNamed(context, '/dekan/jadwal/', arguments: userData),
    //                   child: Column(
    //                     children: [
    //                       Icon(Icons.schedule, color: Colors.white),
    //                       const SizedBox(width: 5),
    //                       Text("Jadwal", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),)
    //                     ]
    //                   ),
    //                 ),
    //               )
    //             )  
    //           ],
    //         )
    //       ),
    //     )
    //   ],
    // );
    
    // return Row(
    //   children: [
    //     _buildMenuItem(Icons.schedule, "Jadwal", onTap: () {
    //       Navigator.pushNamed(context, '/dekan/jadwal/', arguments: userData);
    //     }),
    //     _buildMenuItem(Icons.meeting_room, "Ruang", onTap: () {
    //       Navigator.pushNamed(context, '/dekan/ruang/', arguments: userData);
    //     }),
    //   ]
    // );

    return Container();
  }

  Widget _dashboardDosen(BuildContext context){
    return Container();
  }

  Widget _dashboardKaprodi(BuildContext context){
    // return Row(
    //   children: [
    //     _buildMenuItem(Icons.schedule, "Jadwal", onTap: () {
    //       Navigator.pushNamed(context, '/kaprodi/jadwal/', arguments: userData);
    //     }),
    //     _buildMenuItem(Icons.meeting_room, "Ruang", onTap: () {
    //       Navigator.pushNamed(context, '/kaprodi/ruang/', arguments: userData);
    //     }),
    //   ]
    // );
    return Container();
  }

  Widget _dashboardBaka(BuildContext context){
    return Container();
  }

  Widget _getProfile(BuildContext context){
    return 
      Transform.translate(
        offset: const Offset(0, -80),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 64),
              padding: const EdgeInsets.symmetric(horizontal: 100),
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00549C),
                    Color(0xFF003664),
                    Color(0xFF001D36),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Profile Image
                  Transform.translate( 
                    offset: const Offset(0, -20),
                    child: Container( 
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ), 
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: userData['profile_image_base64'] != null && userData['profile_image_base64'].isNotEmpty
                            ? MemoryImage(base64Decode(userData['profile_image_base64']))
                            : AssetImage('images/Default_pfp.png'),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),

                  // Profile Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 1,
                          fit: FlexFit.tight,
                          child: Text(
                          'Hi, ${userData['name']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                                                    )
                        ),
                        Flexible(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(
                                '${userData['identifier']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '|',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              Text(
                                '${userData['jurusan'] ?? userData['nama_prodi']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              )
                            ],
                          )
                        ),
                      ],
                    ),
                  ),
                  // Sudah registrasi here
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal:64),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildStatus(userData['currentLoginAs'])
            ),
          ],
        ));
  }

    Widget _buildMenuItem(IconData icon, String label, {required VoidCallback onTap}) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(width: 16),
            ],
          ) 
        ),
      ]
    );
  }

  Widget _buildStatus(String role){
    if(role == "Mahasiswa"){
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusWidget('Status Mahasiswa:', '${userData['status']}', Colors.green, Colors.white),
          _buildStatusWidget('IPK:', ipk,Colors.transparent, Colors.black),
          _buildStatusWidget('SKS:', totalSks,Colors.transparent, Colors.black),
        ],
      );
    }
    else{
      return Container();
    }
  }

  Widget _buildStatusWidget(String title, String value, Color color, Color fontcolor ) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container( 
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: color, borderRadius:BorderRadius.circular(8),),  // Corrected here
          child: Text(value, style: TextStyle(fontSize: 16, color: fontcolor),
          )
        )
      ],
    );
  }

  Widget _buildSemesterInfo(String title, String value, Color color, Color fontcolor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: color, borderRadius:BorderRadius.circular(8),),  // Corrected here
          child: Text(value, style: TextStyle(fontSize: 16, color: fontcolor)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(userData: userData),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color:Color(0xFF162953),
              ),
            ),
            _getProfile(context),
            _getDashboard(context, userData['currentLoginAs']),
          ]
        )
      )
    );
  }
 
  
}

