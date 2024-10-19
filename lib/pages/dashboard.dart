import 'package:flutter/material.dart';
import 'package:myapp/pages/kota.dart';
import 'package:myapp/pages/login.dart';
import 'package:myapp/pages/pairedDevice.dart';
import 'package:myapp/pages/siswa.dart';
import 'package:myapp/pages/tentangaplikasi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class Siswa {
  final int kotaId;

  Siswa({required this.kotaId});

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(kotaId: json['id_kota']);
  }
}

class JenkelData {
  final String gender;
  final int count;

  JenkelData({required this.gender, required this.count});
}

class KotaData {
  final int total;
  final String nama;

  KotaData({required this.total, required this.nama});
}

class TahunData {
  final int tahun;
  final int jumlah;

  TahunData({required this.tahun, required this.jumlah});
}

class _DashboardState extends State<Dashboard> {
  Future<String> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? 'No Email Found';
  }

// Suggested code may be subject to a license. Learn more: ~LicenseLog:3578421069.
  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
  }

  Future<List<JenkelData>> fetchJenkel() async {
    try {
      final response = await supabase.from('siswa').select('jenkel');

      // Aggregate counts directly from the response
      int maleCount = response
          .where((data) => data['jenkel'].toLowerCase() == 'male')
          .length;
      int femaleCount = response
          .where((data) => data['jenkel'].toLowerCase() == 'female')
          .length;

      return [
        JenkelData(gender: 'male', count: maleCount),
        JenkelData(gender: 'female', count: femaleCount),
      ];
    } catch (e) {
      if (e
          .toString()
          .contains("Connection closed before full header was received")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan koneksi. Silakan coba lagi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      throw e;
    }
  }

  Future<List<KotaData>> fetchKota() async {
    try {
      // Fetch all kota data
      final kotaResponse = await supabase.from('kota').select('id, nama');
      if (kotaResponse == null) {
        throw Exception('Failed to fetch kota data');
      }

      // Fetch all siswa data
      final siswaResponse = await supabase.from('siswa').select('id_kota');
      if (siswaResponse == null) {
        throw Exception('Failed to fetch siswa data');
      }

      // Convert fetched data into lists
      final List<Map<String, dynamic>> kotaList =
          List<Map<String, dynamic>>.from(kotaResponse);
      final List<Map<String, dynamic>> siswaList =
          List<Map<String, dynamic>>.from(siswaResponse);

      // Parse siswa data into a list of Siswa objects
      List<Siswa> siswaData =
          siswaList.map((siswa) => Siswa.fromJson(siswa)).toList();

      // Create a map to count the number of students per city
      Map<int, int> siswaCountByKota = {};

      for (var siswa in siswaData) {
        siswaCountByKota[siswa.kotaId] =
            (siswaCountByKota[siswa.kotaId] ?? 0) + 1;
      }

      // Create a list of KotaData from the kota list and siswa count map
      List<KotaData> kotaData = kotaList.map((kota) {
        int kotaId = kota['id'];
        String nama = kota['nama'] ?? 'Unknown';
        int total = siswaCountByKota[kotaId] ?? 0;
        return KotaData(nama: nama, total: total);
      }).toList();

      // Filter out cities with a total count of 0
      kotaData = kotaData.where((kota) => kota.total > 0).toList();

      return kotaData;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
      throw e;
    }
  }

  Future<List<TahunData>> fetchTahun() async {
    try {
      final response = await supabase.from('siswa').select('ttl');

      // Extract and count the years
      Map<int, int> yearCounts = {};

      for (var data in response) {
        if (data['ttl'] != null) {
          DateTime date = DateTime.parse(data['ttl']);
          int year = date.year;

          if (yearCounts.containsKey(year)) {
            yearCounts[year] = yearCounts[year]! + 1;
          } else {
            yearCounts[year] = 1;
          }
        }
      }

      // Convert the yearCounts map to a list of YearlyBirthData
      List<TahunData> result = yearCounts.entries
          .map((entry) => TahunData(tahun: entry.key, jumlah: entry.value))
          .toList();

      // Optionally sort the list by year
      result.sort((a, b) => a.tahun.compareTo(b.tahun));

      return result;
    } catch (e) {
      if (e
          .toString()
          .contains("Connection closed before full header was received")) {
        // Handle connection error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan koneksi. Silakan coba lagi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(
        elevation: 4,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff3a57e8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.normal,
            fontSize: 15,
            color: Color(0xffffffff),
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Color(0xffffffff), size: 24),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: GestureDetector(
                onTap: () async {
                  String email = await getUserEmail(); // Fetch user email
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('User Email'),
                        content: Text(email),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Icon(Icons.account_circle,
                    color: Color(0xffffffff), size: 24)),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            DrawerHeader(
              child: Image.asset(
                'images/logo_hori_png.png',
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Siswa'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SiswaPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.location_city),
              title: Text('Kota'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => KotaPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.question_mark),
              title: Text('Tentang Aplikasi'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TentangAplikasi()));
              },
            ),
            Spacer(),
            Divider(
              thickness: 1,
              color: Colors.grey,
            ),
            ListTile(
              leading: Icon(Icons.bluetooth),
              title: Text('Pair Device'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PairedDevicesPage())),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                logout();
                // Perform logout and navigate to the Login page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          GridView(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            physics: const ScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            children: [
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xff3c58e9),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FutureBuilder<List<JenkelData>>(
                      future: fetchJenkel(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(); // Show loading indicator
                        } else if (snapshot.hasError) {
                          return const Text('Error'); // Handle error state
                        } else if (snapshot.hasData) {
                          List<JenkelData> jenkel = snapshot.data!;
                          int femaleCount = jenkel
                              .firstWhere((data) => data.gender == 'female')
                              .count;
                          int maleCount = jenkel
                              .firstWhere((data) => data.gender == 'male')
                              .count;
                          int totalCount = femaleCount + maleCount;
                          return Text(
                            totalCount.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.normal,
                              fontSize: 20,
                              color: Color(0xffffffff),
                            ),
                          );
                        } else {
                          return const Text('N/A'); // Handle empty data
                        }
                      },
                    ),
                    const Text(
                      "Total Siswa",
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontSize: 11,
                        color: Color(0xffffffff),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xff3b57e9),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FutureBuilder<List<JenkelData>>(
                      future: fetchJenkel(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(); // Show loading indicator
                        } else if (snapshot.hasError) {
                          return const Text('Error'); // Handle error state
                        } else if (snapshot.hasData) {
                          List<JenkelData> jenkel = snapshot.data!;
                          int maleCount = jenkel
                              .firstWhere((data) => data.gender == 'male')
                              .count;
                          return Text(
                            maleCount.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.normal,
                              fontSize: 20,
                              color: Color(0xffffffff),
                            ),
                          );
                        } else {
                          return const Text('N/A'); // Handle empty data
                        }
                      },
                    ),
                    const Text(
                      "Laki - Laki",
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontSize: 11,
                        color: Color(0xffffffff),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xff3b57e7),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FutureBuilder<List<JenkelData>>(
                      future: fetchJenkel(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(); // Show loading indicator
                        } else if (snapshot.hasError) {
                          return const Text('Error'); // Handle error state
                        } else if (snapshot.hasData) {
                          List<JenkelData> jenkel = snapshot.data!;
                          int femaleCount = jenkel
                              .firstWhere((data) => data.gender == 'female')
                              .count;

                          return Text(
                            femaleCount.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.normal,
                              fontSize: 20,
                              color: Color(0xffffffff),
                            ),
                          );
                        } else {
                          return const Text('N/A'); // Handle empty data
                        }
                      },
                    ),
                    const Text(
                      "Perempuan",
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontSize: 11,
                        color: Color(0xffffffff),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GridView(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            physics: const ScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            children: [
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xff3c57e3),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(
                          "Jenis Kelamin",
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Color(0xffffffff),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<JenkelData>>(
                          future: fetchJenkel(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            } else {
                              List<JenkelData> jenkel = snapshot.data!;
                              return SfCircularChart(
                                palette: <Color>[
                                  Colors.lightBlue,
                                  Colors.pink,
                                ],
                                tooltipBehavior: null,
                                series: <CircularSeries>[
                                  DoughnutSeries<JenkelData, String>(
                                    dataSource: jenkel,
                                    xValueMapper: (JenkelData data, _) =>
                                        data.gender,
                                    yValueMapper: (JenkelData data, _) =>
                                        data.count,
                                    dataLabelSettings:
                                        DataLabelSettings(isVisible: true),
                                    enableTooltip: true,
                                    sortingOrder: SortingOrder.descending,
                                  )
                                ],
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.all(0),
                width: 200,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xff3d58e8),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(
                          "Kota Siswa",
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Color(0xffffffff),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder(
                          future: fetchKota(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            } else {
                              List<KotaData> kota = snapshot.data!;
                              return SfCircularChart(
                                palette: <Color>[
                                  Colors.amber,
                                  Colors.orange,
                                  Colors.cyan,
                                  Colors.redAccent,
                                  Colors.lightBlue,
                                  Colors.limeAccent,
                                ],
                                tooltipBehavior: null,
                                series: <CircularSeries>[
                                  PieSeries<KotaData, String>(
                                    dataSource: kota,
                                    xValueMapper: (KotaData data, _) =>
                                        data.nama,
                                    yValueMapper: (KotaData data, _) =>
                                        data.total,
                                    //dataLabelMapper: (KotaData data, _) => '${data.nama}: ${data.total}',
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                    ),
                                    enableTooltip: true,
                                  )
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            flex: 1,
            child: GridView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: false,
              scrollDirection: Axis.vertical,
              physics: const ScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              children: [
                Container(
                  margin: const EdgeInsets.all(0),
                  padding: const EdgeInsets.all(0),
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xff3d59e9),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16.0),
                    border:
                        Border.all(color: const Color(0x4d9e9e9e), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Text(
                          "Tahun Kelahiran",
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 14,
                            color: Color(0xffffffff),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            child: FutureBuilder(
                              future: fetchTahun(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                } else {
                                  List<TahunData> tahun = snapshot.data!;
                                  return SfCartesianChart(
                                    primaryXAxis: const CategoryAxis(
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    primaryYAxis: const NumericAxis(
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    legend: const Legend(
                                      isVisible: true,
                                      position: LegendPosition.bottom,
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    tooltipBehavior: null,
                                    series: <CartesianSeries>[
                                      ColumnSeries<TahunData, String>(
                                        name: "Tahun",
                                        dataSource: tahun,
                                        color: Colors.amber,
                                        xValueMapper: (TahunData data, _) =>
                                            data.tahun.toString(),
                                        yValueMapper: (TahunData data, _) =>
                                            data.jumlah,
                                        dataLabelSettings:
                                            const DataLabelSettings(
                                          color: Colors.white,
                                          isVisible: true,
                                        ),
                                        enableTooltip: true,
                                      )
                                    ],
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}