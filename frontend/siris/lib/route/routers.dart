import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:siris/dashboard.dart';
import 'package:siris/dosen/daftar_mahasiswa_perwalian_page.dart';
import 'package:siris/mahasiswa/indexMahasiswa.dart';
import 'package:siris/login_page.dart';


final logger = Logger('Routers');

class Routers {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    logger.info('Redirect to ${settings.name}');

    final data = settings.arguments;
    
    // Check if data exists and is a Map
    if (data != null && data is Map<String, dynamic>) {
      switch (settings.name) {
        case '/dashboard':
          return MaterialPageRoute(builder: (context) => Dashboard(userData: data));
        case '/irs':
          return MaterialPageRoute(builder: (context) => IRSPage(userData: data));
        case '/Jadwal':
          return MaterialPageRoute(builder: (context) => AmbilIRS(userData: data));
        case '/Perwalian':
          return MaterialPageRoute(builder: (context) => DaftarMahasiswaPerwalianPage(userData: data));
        default:
          logger.warning('No route defined for ${settings.name}');
          return _noRoutePage();
      }
    } else {
      if (settings.name == '/login'){
          return MaterialPageRoute(builder: (context) => LoginScreen());
      }
      // Handle case where data is null or not a valid map
      logger.warning('Invalid or missing arguments for route ${settings.name}');
      return _noRoutePage();
    }
  }

  // This is the fallback page when no route is matched or arguments are invalid
  static MaterialPageRoute _noRoutePage() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text("No Route defined or Invalid Arguments"),
        ),
      ),
    );
  }
}
