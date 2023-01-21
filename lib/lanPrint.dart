import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ESmartPOS/sqllist.dart';
import 'package:ESmartPOS/testersappjson.dart';
import 'package:ads/ads.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_admob/firebase_admob.dart';

import 'package:get_version/get_version.dart';
import 'package:http/http.dart';
import 'package:image/image.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:ping_discover_network/ping_discover_network.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wifi/wifi.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:http/http.dart' as http;

const String testDevice = 'MobileId';

class Lanprintss extends StatefulWidget {
  String urlchangetext;
  String ip_text;
  Lanprintss({this.urlchangetext, this.ip_text});

  @override
  State<Lanprintss> createState() => _LanprintState();
}

class _LanprintState extends State<Lanprintss> {
  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    testDevices: testDevice != null ? <String>[testDevice] : null,
    nonPersonalizedAds: true,
    keywords: <String>['Game', 'Mario'],
  );

  // BannerAd _bannerAd;
  // InterstitialAd _interstitialAd;

  // BannerAd createBannerAd() {
  //   return BannerAd(
  //       adUnitId: BannerAd.testAdUnitId,
  //     //Change BannerAd adUnitId with Admob ID
  //       size: AdSize.banner,
  //       targetingInfo: targetingInfo,
  //       listener: (MobileAdEvent event) {
  //         print("BannerAd $event");
  //       });
  // }

  InterstitialAd createInterstitialAd() {
    return InterstitialAd(
        adUnitId: InterstitialAd.testAdUnitId,
        //Change Interstitial AdUnitId with Admob ID
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          print("IntersttialAd $event");
        });
  }

  final DBPrinterManager dbPrinterManager = new DBPrinterManager();
  final _formkey = new GlobalKey<FormState>();
  Printer prt;
  int updateindex;

  List<Printer> prtlist;
  TextEditingController urltext = new TextEditingController();
  TextEditingController lictext = new TextEditingController();
  TextEditingController iptext = new TextEditingController();
  TextEditingController printername = new TextEditingController();
  TextEditingController printeraddress = new TextEditingController();
  String localIp = '';
  List<String> devices = [];
  bool isDiscovering = false;
  int found = -1;
  TextEditingController portController = TextEditingController(text: '9100');
  Timer _timerForInter;
  Ads appAds;
  bool radioitem = false;
  final String appId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544~3347511713'
      : 'ca-app-pub-3940256099942544~1458002511';

  final String bannerUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  final String screenUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
  final String videoUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
  bool _loading = true;
// Future<void> doSomeAsyncStuff() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//        setState(() {
//                 bluetoothname=  prefs.getString("bluname");
//          print(bluetoothname);
//               });
// }
  localConnection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String device = prefs.getString("bluetooth");
    if (device != null && device.length > 0) {
      var map = jsonDecode(device);
      BluetoothDevice bluetoothDevice = new BluetoothDevice.fromMap(map);
      bluetooth.connect(bluetoothDevice).catchError((error) {
        setState(() => _connected = false);
          print("${DateTime.now()}" +
                                                "   localConnection   " +
                                               "Bluetooth connection ${_connected}");
                                            saveLogFile(
                                                "${DateTime.now()}" +
                                                    "  localConnection   " +
                                                   "Bluetooth connection ${_connected}",
                                                "app.txt");
      });
      setState(() => _connected = true);
        print("${DateTime.now()}" +
                                                "   localConnection   " +
                                               "Bluetooth connection ${_connected}");
                                            saveLogFile(
                                                "${DateTime.now()}" +
                                                    "  localConnection   " +
                                                   "Bluetooth connection ${_connected}",
                                                "app.txt");
      setState(() {
        bluetoothname = bluetoothDevice;
        local_device = bluetoothname.name;
      });
      //return bluetoothDevice;
    } else {
      return null;
    }
  }

  Future<bool> saveLogFile(String url, String fileName) async {
    Directory directory;
    try {
      if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          directory = await getExternalStorageDirectory();
          String newPath = "";
          print(directory);
          List<String> paths = directory.path.split("/");
          for (int x = 1; x < paths.length; x++) {
            String folder = paths[x];
            if (folder != "Android") {
              newPath += "/" + folder;
            } else {
              break;
            }
          }
          newPath = newPath + "/ESmartPOS-nigel";
          directory = Directory(newPath);
        } else {
          return false;
        }
      } else {
        if (await _requestPermission(Permission.photos)) {
          directory = await getTemporaryDirectory();
        } else {
          return false;
        }
      }
      File saveFile = File(directory.path + "/$fileName");
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        saveFile.writeAsStringSync(url + "\n", mode: FileMode.append);

        // saveFile.write(ioSink);
        // await saveFile.writeAsString(
        // url);
        //  dio.download(url, saveFile.path,
        //     onReceiveProgress: (value1, value2) {
        //       setState(() {
        //         progress = value1 / value2;
        //       });
        //     });
        if (Platform.isIOS) {
          await ImageGallerySaver.saveFile(saveFile.path,
              isReturnPathOfIOS: true);
        }
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    saveLogFile("${DateTime.now()}" + "  appStart Successfully ", "app.txt");
    // initSavetoPath();
    kotLocalip();
    localConnection();
    _getId();
    data();

    var eventListener = (MobileAdEvent event) {
      if (event == MobileAdEvent.opened) {
        print("The opened ad is clicked on.");
      }
    };

    appAds = Ads(
      appId,
      bannerUnitId: bannerUnitId,
      screenUnitId: screenUnitId,
      keywords: <String>['ibm', 'computers'],
      contentUrl: 'http://www.ibm.com',
      childDirected: false,
      testDevices: ['Samsung_Galaxy_SII_API_26:5554'],
      testing: false,
      listener: eventListener,
    );

    appAds.setVideoAd(
      adUnitId: videoUnitId,
      keywords: ['dart', 'java'],
      contentUrl: 'http://www.publang.org',
      childDirected: true,
      testDevices: null,
      listener: (RewardedVideoAdEvent event,
          {String rewardType, int rewardAmount}) {
        print("The ad was sent a reward amount.");
      },
    );
    fetchdata();
  }

  Testerapp complexTutorial;
  data() async {
    try {
      final dataList = await dbPrinterManager.getprinterList();

      localdatalist = dataList
          .map(
            (item) => Printer(
              address: item.address, name: item.name,

              ip: item.ip,
              lic: item.lic,
              url: item.url,
              // difficulty: item['difficulty'],
            ),
          )
          .toList();

      if (localdatalist.length == 0 || localdatalist.last.url == null)
// if (widget.urlchangetext == "" || widget.urlchangetext == null)
      {
        //  log.d(" app start");
        setState(() {
          url_Text = "https://irestoraplus.easypos4u.com/printTest.php";
          //"https://techsapphire.net";
          urltext.text = url_Text;
          iptext.text = localurlip;
          //  iptext.text = widget.ip_text;
        });
        //   log.d("app finish");
      } else {
//log.d("our URL start");
        //urltext.text;

        setState(() {
          url_Text = localdatalist.last.url;
          // url_Text = localul;
          urltext.text = localdatalist.last.url;
          iptext.text = localdatalist.last.ip;
          // iptext.text =localurlip;
        });
        //log.d("our URL finish");
      }
      setState(() {
        _loading = false;
      });
    } catch (ex) {
//log.d(ex);
    }
  }

  bool deviceAdd = false;
  var url = "https://techsapphire.net/2815-2/";
  fetchdata() async {
    final http.Response response = await http.get(url);
    // response.contain("");
// var  data = json.decode(response.body);

    setState(() {
      response.body.contains('51e7ce01b5e9d919');
      print(response.body.contains('3234dfsvsdf2'));
      deviceAdd = response.body.contains('51e7ce01b5e9d919');
    });
    if (deviceAdd == true) {
      _timerForInter = Timer.periodic(Duration(minutes: 12), (result) {
        appAds.showVideoAd(state: this);
        // _interstitialAd = createInterstitialAd()
        //             ..load()
        //             ..show();
      });
    }
    //  print(data);
  }

  getappid() async {
    String projectAppID;
// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      projectAppID = await GetVersion.appID;
      print(projectAppID);
    } on PlatformException {
      projectAppID = 'Failed to get app ID.';
    }
  }

  String getdeviceid;
  Future<String> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor;
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;

      setState(() {
        getdeviceid = androidDeviceInfo.androidId;
      });
    }
  }

  List<Printer> localdatalist = [];
  Future<void> fetchAprinterdata() async {
    final dataList = await dbPrinterManager.getprinterList();

    localdatalist = dataList
        .map(
          (item) => Printer(
            address: item.address, name: item.name,

            ip: item.ip,
            lic: item.lic,
            url: item.url,
            // difficulty: item['difficulty'],
          ),
        )
        .toList();

    setState(() {
      localurlip = localdatalist.last.ip;
      localul = localdatalist.last.url;
      iptext.text = localurlip;
      urltext.text = localul;
    });

    print(localurlip);
//  return  setUrlValue();
  }

  @override
  void dispose() {
    _timerForInter.cancel();
    //  _interstitialAd.dispose();

    super.dispose();
  }

  String url_Text;
  String localTestUrl;

  String localurlip;
  String localul;
  setUrlValue() async {
    if (urltext.text == "" || urltext.text == null)
// if (widget.urlchangetext == "" || widget.urlchangetext == null)
    {
      url_Text = "https://techsapphire.net";
      setState(() {
        urltext.text = url_Text;
        //   iptext.text =localurlip;
        //  iptext.text = widget.ip_text;
      });
    } else {
      url_Text = urltext.text;
      //widget.urlchangetext;
      setState(() {
        // url_Text = localul;
        urltext.text = url_Text;
        iptext.text = localurlip;
        // iptext.text =localurlip;
      });
    }
  }
checkItemForBluetooth()async{

   for (int j = 0;
                                          j < restaurant.data.length;
                                          j++) {
                                        if (restaurant.data[j].type == "logo") {
                                          imageurlapp = restaurant.data[j].data;

                                          //    var url =imageurlapp.url;
                                          // var response = await get(url);

                                          // var documentDirectory = await getExternalStorageDirectory();
                                          // var firstPath = documentDirectory.path + "/images";

                                          // await Directory(firstPath).create(recursive: true);

                                          // var filePathAndName = documentDirectory.path + '/images/pic.jpg';
                                          // File file2 = new File(filePathAndName);
                                          // file2.writeAsBytesSync(response.bodyBytes);
                                          // setState(() {

                                          //   imageData = filePathAndName;
                                          //   dataLoaded = true;

                                          // });
                                          //  final ByteData imageData1 = await NetworkAssetBundle(Uri.parse(imageurlapp.url)).load("");
                                          //   // final ByteData data = await rootBundle.load('asset/techlogo.png');
                                          // final Uint8List bytes = imageData1.buffer.asUint8List();
                                          // final Image image = decodeImage(bytes);
                                          try {
                                            var response = await http.get(
                                                Uri.parse(imageurlapp.url));
                                            Uint8List bytesNetwork =
                                                response.bodyBytes;
                                            Uint8List imageBytesFromNetwork =
                                                bytesNetwork.buffer.asUint8List(
                                                    bytesNetwork.offsetInBytes,
                                                    bytesNetwork.lengthInBytes);
                                            bluetooth.printImageBytes(
                                                imageBytesFromNetwork);
                                          } catch (e) {
                                            print("${DateTime.now()}" +
                                                "    inAppBody(Bluetooth - Logo Error)   " +
                                                e.message);
                                            saveLogFile(
                                                "${DateTime.now()}" +
                                                    "  inAppBody(Bluetooth - Logo Error)   " +
                                                    e.message,
                                                "app.txt");
                                          }

                                          // //  _asyncMethod(imageurlapp.url);

                                        }
                                        if (restaurant.data[j].type ==
                                            "header") {
                                          datalist = restaurant.data[j].data;
                                          for (int y = 1;
                                              y < datalist.subTitles.length;
                                              y++) {
                                            bluetooth.printCustom(
                                                datalist.subTitles[y], 1, 1);
                                          }
                                          bluetooth.write(
                                              "________________________________________________");

                                          // datalist.subTitles[y]
                                        }
                                        if (restaurant.data[j].type ==
                                            "summary") {
                                          datalistsummary =
                                              restaurant.data[j].data;
                                          bluetooth.printLeftRight(
                                              datalistsummary.summary[0].key,
                                              datalistsummary.summary[0].value
                                                  .toString(),
                                              1,
                                              format: "%-25s %15s %n");
                                          bluetooth.write(
                                              "________________________________________________");
                                        }

                                        if (restaurant.data[j].type ==
                                            "bigsummary") {
                                          databigsummary =
                                              restaurant.data[j].data;
                                          for (int e = 0;
                                              e <
                                                  databigsummary
                                                      .bigsummary.length;
                                              e++) {
                                            bluetooth.printLeftRight(
                                                databigsummary
                                                    .bigsummary[e].key,
                                                databigsummary
                                                    .bigsummary[e].value
                                                    .toString(),
                                                1,
                                                format: "%-25s %15s %n");
                                          }
                                          bluetooth.write(
                                              "________________________________________________");
                                        }

                                        if (restaurant.data[j].type ==
                                            "Receipt") {
                                          receiptlist = restaurant.data[j].data;
                                          for (int d = 0;
                                              d <
                                                  receiptlist
                                                      .receiptText.length;
                                              d++) {
                                            bluetooth.printCustom(
                                                receiptlist.receiptText[d],
                                                1,
                                                1);
                                          }
                                        }
                                        if (restaurant.data[j].type == "item") {
                                          datalistitem =
                                              restaurant.data[j].data;
                                          bluetooth.write(
                                              "________________________________________________");
                                          bluetooth.printLeftRight(
                                              'Selected Item :', "", 1,
                                              format: "%-25s %15s %n");

                                          for (int k = 0;
                                              k < datalistitem.itemdata.length;
                                              k++) {
                                            var printsplit = splitByLength(
                                                datalistitem
                                                    .itemdata[k].itemName,
                                                30);

                                            bluetooth.printLeftRight(
                                                datalistitem
                                                        .itemdata[k].quantity
                                                        .toString() +
                                                    " x " +
                                                    printsplit[0],
                                                datalistitem
                                                    .itemdata[k].itemAmount
                                                    .toString(),
                                                1,
                                                format: "%-25s %15s %n");

                                            if (printsplit.length > 1) {
                                              int skip = 1;
                                              for (int t = 1;
                                                  t < printsplit.length;
                                                  t++) {
                                                // bluetooth.printCustom( printsplit[t], 1, 1);

                                                bluetooth.printLeftRight(
                                                    printsplit[t], "", 1,
                                                    format: "%-25s %15s %n");
                                              }
                                            }
                                            for (int l = 0;
                                                l <
                                                    datalistitem.itemdata[k]
                                                        .toppings.length;
                                                l++) {
                                              bluetooth.printLeftRight(
                                                  "   " +
                                                      " x " +
                                                      datalistitem.itemdata[k]
                                                          .toppings[l],
                                                  "",
                                                  1,
                                                  format: "%-25s %15s %n");
                                            }
                                            for (int m = 0;
                                                m <
                                                    datalistitem.itemdata[k]
                                                        .items.length;
                                                m++) {
                                              bluetooth.printLeftRight(
                                                  datalistitem.itemdata[k]
                                                      .items[m].itemName,
                                                  "",
                                                  1,
                                                  format: "%-25s %15s %n");

                                              for (int n = 0;
                                                  n <
                                                      datalistitem
                                                          .itemdata[k]
                                                          .items[m]
                                                          .toppings
                                                          .length;
                                                  n++) {
                                                bluetooth.printLeftRight(
                                                    "  " +
                                                        "x " +
                                                        datalistitem
                                                            .itemdata[k]
                                                            .items[m]
                                                            .toppings[n],
                                                    "",
                                                    1,
                                                    format: "%-25s %15s %n");
                                              }
                                            }
                                          }
                                          bluetooth.write(
                                              "________________________________________________");
                                        }
                                        if (restaurant.data[j].type ==
                                            "columndetails") {
                                          taxlist = restaurant.data[j].data;
                                          bluetooth.print3Column(
                                              taxlist.columnheader.column1,
                                              taxlist.columnheader.column2,
                                              taxlist.columnheader.column4,
                                              1);

                                          for (int k = 0;
                                              k < taxlist.columndata.length;
                                              k++) {
                                            bluetooth.print3Column(
                                                taxlist.columndata[k].column1,
                                                taxlist.columndata[k].column2,
                                                taxlist.columndata[k].column4,
                                                1);
                                          }
                                        }
                                        if (restaurant.data[j].type ==
                                            "footer") {
                                          footerlist = restaurant.data[j].data;
                                          for (int d = 0;
                                              d < footerlist.footerText.length;
                                              d++) {
                                            bluetooth.printLeftRight(
                                                footerlist.footerText[d]
                                                    .replaceAll("\n", ""),
                                                "",
                                                1,
                                                format: "%s %s %n");
                                          }
                                        }
                                      }
                                      bluetooth.paperCut();
                                    }
  void discover(BuildContext ctx) async {
    setState(() {
      isDiscovering = true;
      devices.clear();
      found = -1;
    });

    String ip;
    try {
      ip = await Wifi.ip;
      print('local ip:\t$ip');
    } catch (e) {
      final snackBar = SnackBar(
          content: Text('WiFi is not connected', textAlign: TextAlign.center));
      Scaffold.of(ctx).showSnackBar(snackBar);
      return;
    }
    setState(() {
      localIp = ip;
    });

    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    int port = 9100;
    try {
      port = int.parse(portController.text);
    } catch (e) {
      portController.text = port.toString();
    }
    print('subnet:\t$subnet, port:\t$port');

    final stream = NetworkAnalyzer.discover2(subnet, port);

    stream.listen((NetworkAddress addr) {
      if (addr.exists) {
        print('Found device: ${addr.ip}');
        setState(() {
          devices.add(addr.ip);
          found = devices.length;
        });
      }
    })
      ..onDone(() {
        setState(() {
          isDiscovering = false;
          found = devices.length;
        });
      })
      ..onError((dynamic e) {
        final snackBar = SnackBar(
            content: Text('Unexpected exception', textAlign: TextAlign.center));
        Scaffold.of(ctx).showSnackBar(snackBar);
      });
  }

  Testerapp restaurant;
  var printerlist;
  var seen = Set<String>();
  Image imagevalue;
  var itemdatalist;
  var imageurlapp;
  var datalist;
  var datalistitem;
  var datalistsummary;
  var databigsummary;
  var taxlist;
  var footerlist;
  var receiptlist;
  var kitchenlength;
 var df;
//  String imageData;
//   bool dataLoaded = false;
//   var urlist;
//  String imgurl;
//  _asyncMethod() async {
//     for (int s = 0; s < restaurant.data.length; s++){
//      urlist = restaurant.data[s].data;
// setState(() {
//    imgurl = urlist.url;
// });
//     }

//     var response = await get(imgurl);
//     var documentDirectory = await getApplicationDocumentsDirectory();
//     var firstPath = documentDirectory.path + "/images";
//     var filePathAndName = documentDirectory.path + '/images/pic.jpg';

//     await Directory(firstPath).create(recursive: true);
//     File file2 = new File(filePathAndName);
//     file2.writeAsBytesSync(response.bodyBytes);
//     setState(() {
//       imageData = filePathAndName;
//       dataLoaded = true;
//     });
//   }
  Image image;
  _asyncMethod(imageurl) async {
    var url = imageurl;
    var response = await get(url);
    var documentDirectory = await getApplicationDocumentsDirectory();
    var firstPath = documentDirectory.path + "/images";
    var filePathAndName = documentDirectory.path + '/images/pic.jpg';

    await Directory(firstPath).create(recursive: true);
    File file2 = new File(filePathAndName);
    file2.writeAsBytesSync(response.bodyBytes);
    final ByteData data = await rootBundle.load(filePathAndName);
    final Uint8List bytes = data.buffer.asUint8List();
    setState(() {
      image = decodeImage(bytes);
      dataLoaded = true;
    });
    print(image);
//     final ByteData imageData1 = await NetworkAssetBundle(Uri.parse(imageurl)).load("");
// final Uint8List bytes = imageData1.buffer.asUint8List();
// setState(() {
//   var df = Image.memory(bytes);
// });

    setState(() {
      imageData = filePathAndName;

      dataLoaded = true;
    });
  }

  Image fg;
  String imageData;
  bool dataLoaded = false;
  var imageurl;

  void submitStudent(BuildContext context) {
    if (_formkey.currentState.validate()) {
      if (prt == null) {
        Printer st = new Printer(
            name: printername.text,
            address: printeraddress.text,
            ip: iptext.text,
            lic: lictext.text,
            url: urltext.text);
        dbPrinterManager.insertprinter(st).then((value) => {
              printername.clear(),
              printeraddress.clear(),
              print("printerlist Data Add to database $value"),
            });
      } else {
        prt.name = printername.text;
        prt.address = printeraddress.text;
        prt.ip = iptext.text;
        prt.lic = lictext.text;
        prt.url = urltext.text;
        // dbStudentManager.update(prt).then((value) {
        //   setState(() {
        //     prtlist[updateindex].name = printername.text;
        //     prtlist[updateindex].address = printeraddress.text;
        //   });
        //   printername.clear();
        //   printeraddress.clear();
        //   prt = null;
        // });
      }
    }
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => Lanprintss(
                // urlchangetext: localdatalist[0].url,
                // ip_text: localdatalist[0].ip,
                )),
        (route) => false);
  }

  void submitprinterdetails(BuildContext context) {
    if (_formkey.currentState.validate()) {
      if (prt == null) {
        Printer st = new Printer(
            name: printername.text,
            address: printeraddress.text,
            ip: iptext.text,
            lic: lictext.text,
            url: urltext.text);
        dbPrinterManager.insertprinter(st).then((value) => {
              printername.clear(),
              printeraddress.clear(),
              print("printerlist Data Add to database $value"),
            });
      } else {
        prt.name = printername.text;
        prt.address = printeraddress.text;
        prt.ip = iptext.text;
        prt.lic = lictext.text;
        prt.url = urltext.text;
        // dbStudentManager.update(prt).then((value) {
        //   setState(() {
        //     prtlist[updateindex].name = printername.text;
        //     prtlist[updateindex].address = printeraddress.text;
        //   });
        //   printername.clear();
        //   printeraddress.clear();
        //   prt = null;
        // });
      }
    }
  }

  static Completer _completer = new Completer<String>();
  var _tag = "MyApp";
  var _myLogFileName = "MyLogFile";
  var toggle = false;
  var logStatus = '';
  Future<void> kotPrintReceiptFormat(NetworkPrinter printer, var kotDataList) async {
    for (int j = 0; j < restaurant.data.length; j++) {
      if (restaurant.data[j].type == "header") {
        datalist = restaurant.data[j].data;

        printer.row([
          PosColumn(
              text: datalist.topTitle,
              width: 11,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.center,
                  width: PosTextSize.size3)),
          PosColumn(
            text: '',
            width: 1,
          ),
        ]);
        printer.text("");
        for (int y = 0; y < datalist.address.length; y++) {
          printer.row([
            PosColumn(
                text: datalist.address[y],
                width: 11,
                styles: PosStyles(
                    align: PosAlign.center, width: PosTextSize.size1)),
            PosColumn(
              text: '',
              width: 1,
            ),
          ]);
        }
        printer.text("");
        for (int y = 1; y < datalist.subTitles.length; y++) {
          printer.row([
            PosColumn(
                text: datalist.subTitles[y],
                width: 11,
                styles: PosStyles(
                    align: PosAlign.center, width: PosTextSize.size1)),
            PosColumn(
              text: '',
              width: 1,
            ),
          ]);
        }

        printer.hr();
      }
    }
    for (int r = 0; r < kotDataList.itemdata.length; r++) {
      var printsplit = splitByLength(kotDataList.itemdata[r].itemName, 30);
      printer.text("");

      printer.row([
        PosColumn(
            text: '# Item :',
            width: 5,
            styles: PosStyles(
                bold: true, align: PosAlign.left, width: PosTextSize.size1)),
        PosColumn(
            text: '',
            width: 7,
            styles: PosStyles(
                bold: true, align: PosAlign.right, width: PosTextSize.size1)),
      ]);
      printer.row([
        PosColumn(
            text: kotDataList.itemdata[r].quantity.toString() + " x " + printsplit[0],
            width: 8,
            styles: PosStyles(
                bold: true, align: PosAlign.left, width: PosTextSize.size1)),
        PosColumn(
            text: "",
            width: 4,
            styles: PosStyles(align: PosAlign.right, width: PosTextSize.size1)),
      ]);

      if (printsplit.length > 1) {
        int skip = 1;
        for (int t = 1; t < printsplit.length; t++) {
          printer.row([
            PosColumn(
                text: printsplit[t],
                width: 12,
                styles:
                    PosStyles(align: PosAlign.left, width: PosTextSize.size1)),
          ]);
        }
      }
      for (int l = 0; l < kotDataList.itemdata[r].toppings.length; l++) {
        printer.row([
          PosColumn(
              text: "  " + "x " + kotDataList.itemdata[r].toppings[l],
              width: 10,
              styles:
                  PosStyles(align: PosAlign.left, width: PosTextSize.size1)),
          PosColumn(
              text: "",
              width: 2,
              styles:
                  PosStyles(align: PosAlign.right, width: PosTextSize.size1)),
        ]);
      }
      for (int m = 0; m < kotDataList.itemdata[r].items.length; m++) {
        printer.row([
          PosColumn(
              text: kotDataList.itemdata[r].items[m].itemName,
              width: 10,
              styles:
                  PosStyles(align: PosAlign.left, width: PosTextSize.size1)),
          PosColumn(
              text: "",
              width: 2,
              styles:
                  PosStyles(align: PosAlign.right, width: PosTextSize.size1)),
        ]);
        for (int n = 0; n < kotDataList.itemdata[r].items[m].toppings.length; n++) {
          printer.row([
            PosColumn(
                text: "  " + "x " + kotDataList.itemdata[r].items[m].toppings[n],
                width: 10,
                styles:
                    PosStyles(align: PosAlign.left, width: PosTextSize.size1)),
            PosColumn(
                text: "",
                width: 2,
                styles:
                    PosStyles(align: PosAlign.right, width: PosTextSize.size1)),
          ]);
        }
      }
    }

    printer.cut();
  }

  Future<void> lanPrintReceiptFormat(NetworkPrinter printer) async {
    
    for (int j = 0; j < restaurant.data.length; j++) {
      if (restaurant.data[j].type == "logo") {
        imageurlapp = restaurant.data[j].data;
        //  _asyncMethod(imageurlapp.url);
        try {
          //logs();
          final ByteData imageData1 =
              await NetworkAssetBundle(Uri.parse(imageurlapp.url)).load("");
          // final ByteData data = await rootBundle.load('asset/techlogo.png');
          final Uint8List bytes = imageData1.buffer.asUint8List();
          final Image image = decodeImage(bytes);
          printer.image(image);
        } catch (e) {
          saveLogFile(
              "${DateTime.now()}" +
                  "  lanPrintReceiptFormat - LogoError   " +
                  e.message,
              "app.txt");
              //exit(restaurant.data[j].data);
            // break;
//  throw "Couldn't resolve network Image.";
        }
      }
      if (restaurant.data[j].type == "header") {
        datalist = restaurant.data[j].data;
        for (int y = 1; y < datalist.subTitles.length; y++) {
          printer.row([
            PosColumn(
                text: datalist.subTitles[y],
                width: 12,
                styles:
                    PosStyles(align: PosAlign.left, width: PosTextSize.size1)),
          ]);
        }

        printer.hr();
      }
      if (restaurant.data[j].type == "item") {
        datalistitem = restaurant.data[j].data;
        printer.hr();
        printer.row([
          PosColumn(
              text: 'Selected Item :',
              width: 5,
              styles: PosStyles(
                  bold: true, align: PosAlign.left, width: PosTextSize.size1)),
          PosColumn(
              text: '',
              width: 7,
              styles: PosStyles(
                  bold: true, align: PosAlign.right, width: PosTextSize.size1)),
        ]);
        for (int k = 0; k < datalistitem.itemdata.length; k++) {
          var printsplit = splitByLength(datalistitem.itemdata[k].itemName, 30);
          printer.text("");
          printer.row([
            PosColumn(
                text: datalistitem.itemdata[k].quantity.toString() +
                    " x " +
                    printsplit[0],
                width: 8,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.left,
                    width: PosTextSize.size1)),
            PosColumn(
                text: datalistitem.itemdata[k].itemAmount.toString(),
                width: 4,
                styles:
                    PosStyles(align: PosAlign.right, width: PosTextSize.size1)),
          ]);
          if (printsplit.length > 1) {
            int skip = 1;
            for (int t = 1; t < printsplit.length; t++) {
              printer.row([
                PosColumn(
                    text: printsplit[t],
                    width: 12,
                    styles: PosStyles(
                        align: PosAlign.left, width: PosTextSize.size1)),
              ]);
              // bluetooth.printLeftRight(
              //     printsplit[t], "", 1,
              //     format: "%-30s %15s %n");

            }
          }
          for (int l = 0; l < datalistitem.itemdata[k].toppings.length; l++) {
            printer.row([
              PosColumn(
                  text: "  " + "x " + datalistitem.itemdata[k].toppings[l],
                  width: 10,
                  styles: PosStyles(
                      align: PosAlign.left, width: PosTextSize.size1)),
              PosColumn(
                  text: "",
                  width: 2,
                  styles: PosStyles(
                      align: PosAlign.right, width: PosTextSize.size1)),
            ]);
          }
          for (int m = 0; m < datalistitem.itemdata[k].items.length; m++) {
            printer.row([
              PosColumn(
                  text: datalistitem.itemdata[k].items[m].itemName,
                  width: 10,
                  styles: PosStyles(
                      align: PosAlign.left, width: PosTextSize.size1)),
              PosColumn(
                  text: "",
                  width: 2,
                  styles: PosStyles(
                      align: PosAlign.right, width: PosTextSize.size1)),
            ]);
            for (int n = 0;
                n < datalistitem.itemdata[k].items[m].toppings.length;
                n++) {
              printer.row([
                PosColumn(
                    text: "  " +
                        "x " +
                        datalistitem.itemdata[k].items[m].toppings[n],
                    width: 10,
                    styles: PosStyles(
                        align: PosAlign.left, width: PosTextSize.size1)),
                PosColumn(
                    text: "",
                    width: 2,
                    styles: PosStyles(
                        align: PosAlign.right, width: PosTextSize.size1)),
              ]);
            }
          }
        }
        printer.hr();
      }
      if (restaurant.data[j].type == "summary") {
        datalistsummary = restaurant.data[j].data;
        //  printer.hr();
        printer.row([
          PosColumn(
              text: datalistsummary.summary[0].key,
              width: 5,
              styles:
                  PosStyles(align: PosAlign.left, width: PosTextSize.size1)),
          PosColumn(
              text: datalistsummary.summary[0].value.toString(),
              width: 7,
              styles:
                  PosStyles(align: PosAlign.right, width: PosTextSize.size1)),
        ]);
        printer.hr();
      }
      if (restaurant.data[j].type == "bigsummary") {
        databigsummary = restaurant.data[j].data;
        for (int e = 0; e < databigsummary.bigsummary.length; e++) {
          printer.row([
            PosColumn(
                text: databigsummary.bigsummary[e].key,
                width: 5,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.left,
                    width: PosTextSize.size1)),
            PosColumn(
                text: databigsummary.bigsummary[e].value.toString(),
                width: 7,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.right,
                    width: PosTextSize.size1)),
          ]);
        }
        printer.hr();
      }
      if (restaurant.data[j].type == "columndetails") {
        taxlist = restaurant.data[j].data;
        printer.row([
          PosColumn(
              text: taxlist.columnheader.column1,
              width: 4,
              styles: PosStyles(
                  bold: true, align: PosAlign.left, width: PosTextSize.size1)),
          PosColumn(
              text: taxlist.columnheader.column2,
              width: 5,
              styles: PosStyles(
                  bold: true,
                  align: PosAlign.center,
                  width: PosTextSize.size1)),
          // PosColumn(
          //     text: 'Price', width: 2, styles: PosStyles(align: PosAlign.right,width: PosTextSize.size1)),
          PosColumn(
              text: taxlist.columnheader.column4,
              width: 3,
              styles: PosStyles(
                  bold: true, align: PosAlign.right, width: PosTextSize.size1)),
        ]);
        for (int k = 0; k < taxlist.columndata.length; k++) {
          printer.row([
            PosColumn(
                text: taxlist.columndata[k].column1,
                width: 4,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.left,
                    width: PosTextSize.size1)),
            PosColumn(
                text: taxlist.columndata[k].column2,
                width: 5,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.center,
                    width: PosTextSize.size1)),
            PosColumn(
                text: taxlist.columndata[k].column4,
                width: 3,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.right,
                    width: PosTextSize.size1)),
          ]);
        }
        printer.hr();
      }
      if (restaurant.data[j].type == "Receipt") {
        receiptlist = restaurant.data[j].data;
        for (int d = 0; d < receiptlist.receiptText.length; d++) {
          printer.row([
            PosColumn(
                text: receiptlist.receiptText[d],
                width: 12,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.left,
                    width: PosTextSize.size1)),
            // PosColumn(
            //   text: '',
            //   width: 1,
            //   styles: PosStyles(
            //       bold: true, align: PosAlign.right, width: PosTextSize.size1),
            // ),
          ]);
        }
      }
      if (restaurant.data[j].type == "footer") {
        footerlist = restaurant.data[j].data;
        for (int d = 0; d < footerlist.footerText.length; d++) {
          //     printer.row([
          //   PosColumn(
          //       text: footerlist.footerText[d],
          //       width: 12,
          //       styles: PosStyles(
          //           bold: true,
          //           align: PosAlign.left,
          //           width: PosTextSize.size1)),

          // ]);

          printer.row([
            PosColumn(
                text: footerlist.footerText[d].replaceAll("\n", ""),
                width: 11,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.left,
                    width: PosTextSize.size1)),
            PosColumn(
                text: '',
                width: 1,
                styles: PosStyles(
                    bold: true,
                    align: PosAlign.right,
                    width: PosTextSize.size1)),
          ]);
        }
      }
    }
    printer.feed(1);
    printer.cut();
  }

  // Future<void> kotPrintReceiptFormat(NetworkPrinter printer) async {
  //   for (int j = 0; j < restaurant.data.length; j++) {
  //     if (restaurant.data[j].type == "header") {
  //       datalist = restaurant.data[j].data;

  //       printer.row([
  //         PosColumn(
  //             text: datalist.topTitle,
  //             width: 11,
  //             styles: PosStyles(
  //                 bold: true,
  //                 align: PosAlign.center,
  //                 width: PosTextSize.size3)),
  //         PosColumn(
  //           text: '',
  //           width: 1,
  //         ),
  //       ]);
  //       printer.text("");
  //       for (int y = 0; y < datalist.address.length; y++) {
  //         printer.row([
  //           PosColumn(
  //               text: datalist.address[y],
  //               width: 11,
  //               styles: PosStyles(
  //                   align: PosAlign.center, width: PosTextSize.size1)),
  //           PosColumn(
  //             text: '',
  //             width: 1,
  //           ),
  //         ]);
  //       }
  //       printer.text("");
  //       for (int y = 1; y < datalist.subTitles.length; y++) {
  //         printer.row([
  //           PosColumn(
  //               text: datalist.subTitles[y],
  //               width: 11,
  //               styles: PosStyles(
  //                   align: PosAlign.center, width: PosTextSize.size1)),
  //           PosColumn(
  //             text: '',
  //             width: 1,
  //           ),
  //         ]);
  //       }

  //       printer.hr();
  //     }

  //     if (restaurant.data[j].type == "kitchen_print") {
  //       kitchenlength = restaurant.data[j];
  //       if (kitchen_localdata.length == 0) {
  //         for (int j = 0; j < prtlist.length; j++) {
  //           if (kitchenlength.printerName == prtlist[j].name) {
  //             for (int r = 0; r < kitchenlength.data.itemdata.length; r++) {

  //               var printsplit =
  //                   splitByLength(kitchenlength.data.itemdata[r].itemName, 30);
  //               printer.text("");

  //               printer.row([
  //                 PosColumn(
  //                     text: '# Item :',
  //                     width: 5,
  //                     styles: PosStyles(
  //                         bold: true,
  //                         align: PosAlign.left,
  //                         width: PosTextSize.size1)),
  //                 PosColumn(
  //                     text: '',
  //                     width: 7,
  //                     styles: PosStyles(
  //                         bold: true,
  //                         align: PosAlign.right,
  //                         width: PosTextSize.size1)),
  //               ]);
  //               printer.row([
  //                 PosColumn(
  //                     text: kitchenlength.data.itemdata[r].quantity.toString() +
  //                         " x " +
  //                         printsplit[0],
  //                     width: 8,
  //                     styles: PosStyles(
  //                         bold: true,
  //                         align: PosAlign.left,
  //                         width: PosTextSize.size1)),
  //                 PosColumn(
  //                     text: "",
  //                     width: 4,
  //                     styles: PosStyles(
  //                         align: PosAlign.right, width: PosTextSize.size1)),
  //               ]);
  //               if (printsplit.length > 1) {
  //                 int skip = 1;
  //                 for (int t = 1; t < printsplit.length; t++) {
  //                   printer.row([
  //                     PosColumn(
  //                         text: printsplit[t],
  //                         width: 12,
  //                         styles: PosStyles(
  //                             align: PosAlign.left, width: PosTextSize.size1)),
  //                   ]);
  //                 }
  //               }
  //               for (int l = 0;
  //                   l < kitchenlength.data.itemdata[r].toppings.length;
  //                   l++) {
  //                 printer.row([
  //                   PosColumn(
  //                       text: "  " +
  //                           "x " +
  //                           kitchenlength.data.itemdata[r].toppings[l],
  //                       width: 10,
  //                       styles: PosStyles(
  //                           align: PosAlign.left, width: PosTextSize.size1)),
  //                   PosColumn(
  //                       text: "",
  //                       width: 2,
  //                       styles: PosStyles(
  //                           align: PosAlign.right, width: PosTextSize.size1)),
  //                 ]);
  //               }
  //               for (int m = 0;
  //                   m < kitchenlength.data.itemdata[r].items.length;
  //                   m++) {
  //                 printer.row([
  //                   PosColumn(
  //                       text: kitchenlength.data.itemdata[r].items[m].itemName,
  //                       width: 10,
  //                       styles: PosStyles(
  //                           align: PosAlign.left, width: PosTextSize.size1)),
  //                   PosColumn(
  //                       text: "",
  //                       width: 2,
  //                       styles: PosStyles(
  //                           align: PosAlign.right, width: PosTextSize.size1)),
  //                 ]);
  //                 for (int n = 0;
  //                     n <
  //                         kitchenlength
  //                             .data.itemdata[r].items[m].toppings.length;
  //                     n++) {
  //                   printer.row([
  //                     PosColumn(
  //                         text: "  " +
  //                             "x " +
  //                             kitchenlength
  //                                 .data.itemdata[r].items[m].toppings[n],
  //                         width: 10,
  //                         styles: PosStyles(
  //                             align: PosAlign.left, width: PosTextSize.size1)),
  //                     PosColumn(
  //                         text: "",
  //                         width: 2,
  //                         styles: PosStyles(
  //                             align: PosAlign.right, width: PosTextSize.size1)),
  //                   ]);
  //                 }
  //               }
  //             }
  //             //  printer.text(kitchenlength.data.itemdata[j].itemName);
  //           }
  //         }
  //       } else {
  //         for (int t = 0; t < kitchen_localdata.length; t++) {
  //           if (kitchenlength.printerName == kitchen_localdata[t].name) {
  //             for (int k = 0; k < kitchenlength.data.itemdata.length; k++) {
  //               var printsplit =
  //                   splitByLength(kitchenlength.data.itemdata[k].itemName, 30);
  //               printer.text("");
  //               printer.row([
  //                 PosColumn(
  //                     text: '# Item :',
  //                     width: 5,
  //                     styles: PosStyles(
  //                         bold: true,
  //                         align: PosAlign.left,
  //                         width: PosTextSize.size1)),
  //                 PosColumn(
  //                     text: '',
  //                     width: 7,
  //                     styles: PosStyles(
  //                         bold: true,
  //                         align: PosAlign.right,
  //                         width: PosTextSize.size1)),
  //               ]);
  //               printer.row([
  //                 PosColumn(
  //                     text: kitchenlength.data.itemdata[k].quantity.toString() +
  //                         " x " +
  //                         printsplit[0],
  //                     width: 8,
  //                     styles: PosStyles(
  //                         bold: true,
  //                         align: PosAlign.left,
  //                         width: PosTextSize.size1)),
  //                 PosColumn(
  //                     text: "",
  //                     width: 4,
  //                     styles: PosStyles(
  //                         align: PosAlign.right, width: PosTextSize.size1)),
  //               ]);
  //               if (printsplit.length > 1) {
  //                 int skip = 1;
  //                 for (int t = 1; t < printsplit.length; t++) {
  //                   printer.row([
  //                     PosColumn(
  //                         text: printsplit[t],
  //                         width: 12,
  //                         styles: PosStyles(
  //                             align: PosAlign.left, width: PosTextSize.size1)),
  //                   ]);
  //                 }
  //               }
  //               for (int l = 0;
  //                   l < kitchenlength.data.itemdata[k].toppings.length;
  //                   l++) {
  //                 printer.row([
  //                   PosColumn(
  //                       text: "  " +
  //                           "x " +
  //                           kitchenlength.data.itemdata[k].toppings[l],
  //                       width: 10,
  //                       styles: PosStyles(
  //                           align: PosAlign.left, width: PosTextSize.size1)),
  //                   PosColumn(
  //                       text: "",
  //                       width: 2,
  //                       styles: PosStyles(
  //                           align: PosAlign.right, width: PosTextSize.size1)),
  //                 ]);
  //               }
  //               for (int m = 0;
  //                   m < kitchenlength.data.itemdata[k].items.length;
  //                   m++) {
  //                 printer.row([
  //                   PosColumn(
  //                       text: kitchenlength.data.itemdata[k].items[m].itemName,
  //                       width: 10,
  //                       styles: PosStyles(
  //                           align: PosAlign.left, width: PosTextSize.size1)),
  //                   PosColumn(
  //                       text: "",
  //                       width: 2,
  //                       styles: PosStyles(
  //                           align: PosAlign.right, width: PosTextSize.size1)),
  //                 ]);
  //                 for (int n = 0;
  //                     n <
  //                         kitchenlength
  //                             .data.itemdata[k].items[m].toppings.length;
  //                     n++) {
  //                   printer.row([
  //                     PosColumn(
  //                         text: "  " +
  //                             "x " +
  //                             kitchenlength
  //                                 .data.itemdata[k].items[m].toppings[n],
  //                         width: 10,
  //                         styles: PosStyles(
  //                             align: PosAlign.left, width: PosTextSize.size1)),
  //                     PosColumn(
  //                         text: "",
  //                         width: 2,
  //                         styles: PosStyles(
  //                             align: PosAlign.right, width: PosTextSize.size1)),
  //                   ]);
  //                 }
  //               }
  //                 break ;
  //             }
  //             //  printer.text(kitchenlength.data.itemdata[t].itemName);
  //           }
  //         }
  //       }
  //     }
  //   }

  //   printer.cut();
  // }

  List<Printer> kitchen_localdata = [];
  kotLocalip() async {
    final dataList = await dbPrinterManager.getprinterList();

    localdatalist = dataList
        .map(
          (item) => Printer(
            address: item.address,
            name: item.name,
          ),
        )
        .toList();
    print(localdatalist);
    setState(() {
      kitchen_localdata = localdatalist;
    });
    print(kitchen_localdata);
  }

  Future<void> kotPrintIpConfig() async {
    if (kitchen_localdata.length == 0) {
      FutureBuilder(
        future: dbPrinterManager.getprinterList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            setState(() {
              prtlist = snapshot.data;
            });
          }

          return CircularProgressIndicator();
        },
      );
      for (int j = 0; j < restaurant.data.length; j++) {
        if (restaurant.data[j].type == "kitchen_print") {
          kitchenlength = restaurant.data[j];
          for (int k = 0; k < prtlist.length; k++) {
            if (kitchenlength.printerName == prtlist[k].name) {
              getKotPrintIp(
                  prtlist[k].address, context, restaurant.data[j].data);
            }
            print(prtlist[k].name);
          }
        }
      }
    } else {
      for (int j = 0; j < restaurant.data.length; j++) {
        if (restaurant.data[j].type == "kitchen_print") {
          kitchenlength = restaurant.data[j];
          for (int l = 0; l < kitchen_localdata.length; l++) {
            if (kitchenlength.printerName == kitchen_localdata[l].name) {
              getKotPrintIp(kitchen_localdata[l].address, context,
                  restaurant.data[j].data);
            }
            print(kitchen_localdata[l].name);
          }
        }
      }
    }
  }

  List<String> splitByLength(String value, int length) {
    List<String> pieces = [];

    for (int i = 0; i < value.length; i += length) {
      int offset = i + length;
      pieces.add(
          value.substring(i, offset >= value.length ? value.length : offset));
    }
    return pieces;
  }

  void getKotPrintIp(String printerIp, BuildContext ctx, var kichenDataList) async {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(printerIp, port: 9100);

    if (res == PosPrintResult.success) {
      await kotPrintReceiptFormat(printer, kichenDataList);

      printer.disconnect();
    }
  }

  void lanPrint(String printerIp, BuildContext ctx) async {
    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(paper, profile);

    final PosPrintResult res = await printer.connect(printerIp, port: 9100);
    print("${DateTime.now()}" + "   lanPrint   " + res.msg);
    saveLogFile("${DateTime.now()}" + "   lanPrint  " + res.msg, "app.txt");
    if (res == PosPrintResult.success) {
      await lanPrintReceiptFormat(printer);

      printer.disconnect();
    }
  }

  _launchURL() async {
    const url = 'https://techsapphire.net/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _launchmail() async {
    const url = 'mailto:contact@techsapphire.net';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _launchphone() async {
    const url = 'tel://+91-9360223756';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice _device;
  bool _connected = false;
  String pathImage;

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      new SnackBar(
        content: new Text(
          message,
          style: new TextStyle(
            color: Colors.white,
          ),
        ),
        duration: duration,
      ),
    );
  }

//  initSavetoPath() async {
//     //read and write
//     //image max 300px X 300px
//     final filename = 'yourlogo.png';
//     var bytes = await rootBundle.load("asset/ss.png");
//     String dir = (await getApplicationDocumentsDirectory()).path;
//     writeToFile(bytes, '$dir/$filename');
//     setState(() {
//       pathImage = '$dir/$filename';
//     });
//   }

  Future<void> initPlatformState() async {
    bool isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      // TODO - Error
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            print("bluetooth device state: connected");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnected");
          });
          break;
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnect requested");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth turning off");
          });
          break;
        case BlueThermalPrinter.STATE_OFF:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth off");
          });
          break;
        case BlueThermalPrinter.STATE_ON:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth on");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_ON:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth turning on");
          });
          break;
        case BlueThermalPrinter.ERROR:
          setState(() {
            _connected = false;
            print("bluetooth device state: error");
          });
          break;
        default:
          print(state);
          break;
      }
    });
    if (!mounted) return;
    setState(() {
      _devices = devices;
    });
// if(devices[0].name==blname){
//    setState(() {
//         _connected = true;
//       });
// }
    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  var urlText;
  bool isANumber = true;
  WebViewController controller;
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text(local_device == null ? 'NONE' : local_device),
      ));
    } else {
      _devices.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

// String bluetoothname;
  BluetoothDevice bluetoothname;
  String local_device;
  void _connect() {
    if (_device == null) {
      show('No device selected.');
    } else {
      bluetooth.isConnected.then((isConnected) async {
        if (!isConnected) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();

          prefs.setString("bluetooth", jsonEncode(_device.toMap()));

          String device = prefs.getString("bluetooth");
          if (device != null && device.length > 0) {
            var map = jsonDecode(device);
            BluetoothDevice bluetoothDevice = new BluetoothDevice.fromMap(map);
            bluetooth.connect(bluetoothDevice).catchError((error) {
              setState(() => _connected = false);
                print("${DateTime.now()}" +
                                                "   _connect   " +
                                               "Bluetooth connection ${_connected}");
                                            saveLogFile(
                                                "${DateTime.now()}" +
                                                    "  _connect   " +
                                                   "Bluetooth connection ${_connected}",
                                                "app.txt");
            });
            setState(() => _connected = true);
               print("${DateTime.now()}" +
                                                "   _connect   " +
                                               "Bluetooth connection ${_connected}");
                                            saveLogFile(
                                                "${DateTime.now()}" +
                                                    "  _connect   " +
                                                   "Bluetooth connection ${_connected}",
                                                "app.txt");
            setState(() {
              bluetoothname = bluetoothDevice;
              local_device = bluetoothname.name;
            });
            //return bluetoothDevice;
          } else {
            return null;
          }
        }
        //       if (!isConnected) {
        //     SharedPreferences prefs = await SharedPreferences.getInstance();
        //          prefs.setString('bluname', _device.name);
        //      setState(() {
        //               bluetoothname=  prefs.getString("bluname");
        //        print(bluetoothname);
        //             });

        //  bluetooth.connect(_device).catchError((error) {
        //           setState(() => _connected = false);
        //         });
        //         setState(() => _connected = true);

        //       }
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  @override
  Widget build(BuildContext context) {
    void setValidator(valid) {
      setState(() {
        isANumber = valid;
      });
    }

    double width = MediaQuery.of(context).size.width;
    // ignore: missing_return
    return WillPopScope(
        onWillPop: () async {
          if (await controller.canGoBack()) {
            await controller.goBack();
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          key: _key,
          drawer: Drawer(
            child: Scaffold(
                bottomNavigationBar: Padding(
                    padding: EdgeInsets.only(left: 50, right: 50),
                    child: RaisedButton(
                        color: Colors.blue,
                        //  color: Color(0xff0D2F69),
                        shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(18.0),
                          side: BorderSide(color: Colors.black),
                        ),
                        child: Text(
                          "SAVE",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onPressed: () async {
                          submitStudent(context);
                        })),
                resizeToAvoidBottomInset: true,
                appBar: AppBar(
                    actions: [
                      IconButton(
                          icon: Icon(Icons.info),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) => new AlertDialog(
                                    content: Container(
                                        height: 250,
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: 10,
                                            ),
                                            FlatButton(
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                onPressed: () {
                                                  _launchURL();
                                                },
                                                child: Text(
                                                  "https://techsapphire.net/",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18),
                                                )),
                                            FlatButton(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              onPressed: () {
                                                _launchmail();
                                              },
                                              child: Text(
                                                  "contact@techsapphire.net",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                            ),
                                            FlatButton(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              onPressed: () {
                                                _launchphone();
                                              },
                                              child: Text(
                                                  "Call us +91-9360223756",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                            ),
                                            Text(getdeviceid)
                                          ],
                                        ))));
                          })
                    ],
                    title: Center(
                      child: Text(
                        "Printer Detials",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    )),
                body: SingleChildScrollView(
                    child: Container(
                        color: Colors.grey[100],
                        child: Form(
                            key: _formkey,
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: 20, left: 30, right: 30),
                                  child: TextField(
                                    controller: urltext,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(),
                                      labelText: 'Url',
                                      hintText: 'Url',
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: 10, left: 30, right: 30),
                                  child: TextField(
                                    controller: lictext,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(),
                                      labelText: 'License no.',
                                      hintText: 'License no.',
                                    ),
                                  ),
                                ),
                                radioitem == true
                                    ? Container(
                                        height: 150,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: ListView(
                                            children: <Widget>[
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    'Device:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 30,
                                                  ),
                                                  Expanded(
                                                    child: DropdownButton(
                                                      items: _getDeviceItems(),
                                                      onChanged: (value) =>
                                                          setState(() =>
                                                              _device = value),
                                                      value: _device,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: <Widget>[
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            primary:
                                                                Colors.brown),
                                                    onPressed: () {
                                                      initPlatformState();
                                                    },
                                                    child: Text(
                                                      'Refresh',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            primary: _connected
                                                                ? Colors.red
                                                                : Colors.green),
                                                    onPressed: _connected
                                                        ? _disconnect
                                                        : _connect,
                                                    child: Text(
                                                      _connected
                                                          ? 'Disconnect'
                                                          : 'Connect',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Padding(
                                              //   padding:
                                              //       const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                                              //   child: ElevatedButton(
                                              //     style: ElevatedButton.styleFrom(primary: Colors.brown),
                                              //     onPressed: () {

                                              //     },
                                              //     child: Text('PRINT TEST',
                                              //         style: TextStyle(color: Colors.white)),
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: EdgeInsets.only(
                                            top: 10, left: 30, right: 30),
                                        child: TextField(
                                          controller: iptext,
                                          decoration: InputDecoration(
                                            fillColor: Colors.white,
                                            filled: true,
                                            border: OutlineInputBorder(),
                                            labelText: 'IP no.',
                                            hintText: 'IP no.',
                                          ),
                                        ),
                                      ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: 20, left: 30, right: 30),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: radioitem,
                                          onChanged: (bool value) {
                                            setState(() {
                                              radioitem = value;
                                              print(radioitem);
                                            });
                                          },
                                        ),
                                        Text("Bluetooth")
                                      ],
                                    )),
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: 10, left: 30, right: 30),
                                    child: ListTile(
                                      title: Text(
                                        "Kitchen",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      trailing: IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            size: 25,
                                            color: Colors.blue,
                                            // color: Color(0xff0D2F69),
                                          ),
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    new AlertDialog(
                                                        // backgroundColor:
                                                        //     Color(0xffD5E2F1),
                                                        title: Center(
                                                            child: Text(
                                                          "Kitchen printer",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        )),
                                                        content: Container(
                                                            // color:
                                                            //     Color(0xffD5E2F1),
                                                            height: 250,
                                                            child: Column(
                                                              children: <
                                                                  Widget>[
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              15),
                                                                  child:
                                                                      TextField(
                                                                    onChanged:
                                                                        (inputValue) {
                                                                      if (inputValue
                                                                          .isEmpty) {
                                                                        setValidator(
                                                                            true);
                                                                      } else {
                                                                        setValidator(
                                                                            false);
                                                                      }
                                                                    },
                                                                    controller:
                                                                        printername,
                                                                    decoration:
                                                                        InputDecoration(
                                                                      fillColor:
                                                                          Colors
                                                                              .white,
                                                                      filled:
                                                                          true,
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                      labelText:
                                                                          'Printer Name',
                                                                      hintText:
                                                                          'Printer Name',
                                                                      //  errorText: isANumber ? null : "Please enter a printer name first"
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              15),
                                                                  child:
                                                                      TextField(
                                                                    onChanged:
                                                                        (inputValue) {
                                                                      if (inputValue
                                                                          .isEmpty) {
                                                                        setValidator(
                                                                            true);
                                                                      } else {
                                                                        setValidator(
                                                                            false);
                                                                      }
                                                                    },
                                                                    controller:
                                                                        printeraddress,
                                                                    decoration:
                                                                        InputDecoration(
                                                                      fillColor:
                                                                          Colors
                                                                              .white,
                                                                      filled:
                                                                          true,
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                      labelText:
                                                                          'Printer address',
                                                                      hintText:
                                                                          'Printer address',
                                                                      // errorText: isANumber ? null : "Please enter a printer name first"
                                                                    ),
                                                                  ),
                                                                ),
                                                                RaisedButton(
                                                                    color: Colors
                                                                        .blue,
                                                                    // color: Color(
                                                                    //     0xff0D2F69),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          new BorderRadius.circular(
                                                                              18.0),
                                                                      side: BorderSide(
                                                                          color:
                                                                              Colors.black),
                                                                    ),
                                                                    child: Text(
                                                                      "SUBMIT",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              16),
                                                                    ),
                                                                    onPressed:
                                                                        () async {
                                                                      submitprinterdetails(
                                                                          context);
                                                                      setState(
                                                                          () {
                                                                        dbPrinterManager
                                                                            .getprinterList();
                                                                      });
                                                                      Navigator.pop(
                                                                          context);
                                                                    })
                                                              ],
                                                            ))));
                                          }),
                                    )),
                                FutureBuilder(
                                  future: dbPrinterManager.getprinterList(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      prtlist = snapshot.data;

                                      return Padding(
                                          padding: EdgeInsets.only(),
                                          child: Container(
                                              //  color: Colors.blue,
                                              height: 250,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: prtlist == null
                                                    ? 0
                                                    : prtlist.length,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  Printer st = prtlist[index];
                                                  if (st.name == "" &&
                                                      st.address == "") {
                                                    return Text("");
                                                  } else {
                                                    return Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 10,
                                                                right: 10),
                                                        child: Card(
                                                            color: Colors.white,
                                                            borderOnForeground:
                                                                true,
                                                            elevation: 10,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <
                                                                  Widget>[
                                                                ListTile(
                                                                  trailing:
                                                                      IconButton(
                                                                    onPressed:
                                                                        () {
                                                                      dbPrinterManager
                                                                          .deleteprinter(
                                                                              st.id);
                                                                      setState(
                                                                          () {
                                                                        prtlist.removeAt(
                                                                            index);
                                                                      });
                                                                    },
                                                                    icon: Icon(
                                                                      Icons
                                                                          .delete,
                                                                      // color:
                                                                      //     Color(0xff0D2F69),
                                                                    ),
                                                                  ),
                                                                  title: Text(
                                                                      'Name: ${st.name}',
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.black)),
                                                                  subtitle:
                                                                      Text(
                                                                    'Address: ${st.address}',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                ),
                                                              ],
                                                            )));
                                                  }
                                                },
                                              )));
                                    }

                                    return CircularProgressIndicator(
                                      color: Colors.red,
                                    );
                                  },
                                )
                              ],
                            ))))),
          ),
          body: Stack(
            children: [
              _loading != true
                  ? new WebView(
                      initialUrl:
            "https://app.esmartpos.com/eprintTest.php",
                  // "https://app.esmartpos.com/",
               //  url_Text,
                      javascriptMode: JavascriptMode.unrestricted,
                      onWebViewCreated: (WebViewController wc) {
                        controller = wc;
                      },
                      javascriptChannels: <JavascriptChannel>{
                          JavascriptChannel(
                              name: 'messageHandler',
                              onMessageReceived:
                                  (JavascriptMessage message) async {
                                //  print(message.message);
                                try {
                                  setState(() {
                                    restaurant = Testerapp.fromJson(
                                        jsonDecode(message.message));
                                  });
                                  bluetooth.isConnected
                                      .then((isConnected) async {
                                    if (isConnected) {
                                      // bluetooth.printImage(pathImage);
                                       for (int j = 0;
                                          j < restaurant.data.length;
                                          j++){


    // bluetooth.paperCut();
                 if (restaurant.data[j].type == "item"){
                  checkItemForBluetooth();
 try {
  if( localdatalist!=0){
       lanPrint(
                                                localdatalist.last.ip, context);
                                                return null;
  }else{
    return null;
  }
                                     
                                          } catch (e) {
                                            print("${DateTime.now()}" +
                                                "   inAppBody(lanprint)   " +
                                                e.message);
                                            saveLogFile(
                                                "${DateTime.now()}" +
                                                    "  inAppBody(lanprint)   " +
                                                    e.message,
                                                "app.txt");
                                          }
                                         
                                    
                                       }else{

                                       
                                            
                                
                                         kitchenlength = restaurant.data[j];       
                                          if (kitchen_localdata.length == 0) {
                                            for (int j = 0;
                                                j < prtlist.length;
                                                j++) {
                                              if (kitchenlength.printerName ==
                                                  prtlist[j].name) {
                                                return kotPrintIpConfig();
                                              }
                                            }
                                          } else {
                                            for (int t = 0;
                                                t < kitchen_localdata.length;
                                                t++) {
                                              if (kitchenlength.printerName ==
                                                  kitchen_localdata[t].name) {
                                                return kotPrintIpConfig();
                                              }
                                            }
                                          
                                    
                                   
                                      }}
                                          }
                                    
                                      bluetooth.paperCut();
                                 
                                    } else {
                                      setState(() {
                                        restaurant = Testerapp.fromJson(
                                            jsonDecode(message.message));
                                      });
 
                                    
                                      for (int j = 0;
                                          j < restaurant.data.length;
                                          j++) {
                                                  if (restaurant.data[j].type == "item"){
 try {
  if( localdatalist!=0){
       lanPrint(
                                                localdatalist.last.ip, context);
                                                return null;
  }else{
    return null;
  }
                                     
                                          } catch (e) {
                                            print("${DateTime.now()}" +
                                                "   inAppBody(lanprint)   " +
                                                e.message);
                                            saveLogFile(
                                                "${DateTime.now()}" +
                                                    "  inAppBody(lanprint)   " +
                                                    e.message,
                                                "app.txt");
                                          }
                                         
                                    } else {
                                         kitchenlength = restaurant.data[j];       
                                          if (kitchen_localdata.length == 0) {
                                            for (int j = 0;
                                                j < prtlist.length;
                                                j++) {
                                              if (kitchenlength.printerName ==
                                                  prtlist[j].name) {
                                                return kotPrintIpConfig();
                                              }
                                            }
                                          } else {
                                            for (int t = 0;
                                                t < kitchen_localdata.length;
                                                t++) {
                                              if (kitchenlength.printerName ==
                                                  kitchen_localdata[t].name) {
                                                return kotPrintIpConfig();
                                              }
                                            }
                                          }
                                    } 
                                   
                                      }
                               
                                    }
                                  });
                                } catch (e) {
                                  saveLogFile(
                                      "${DateTime.now()}" +
                                          "  Json-Error   " +
                                          e.message,
                                      "app.txt");
                                }
                              })
                        })
                  : CircularProgressIndicator(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _key.currentState.openEndDrawer();
                    },
                    child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          // color: Color(0xffcccfc4),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(60.0),
                          ),
                        ),
                        child: Icon(
                          Icons.menu,
                          size: 30,
                          color: Colors.grey[300],
                          // color: Color(0xffcccfc4),
                        )),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}