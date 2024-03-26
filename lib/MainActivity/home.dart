import 'dart:collection';

import 'package:audit_tracker/BottomSheetDialog/change_password.dart';
import 'package:audit_tracker/BottomSheetDialog/my_account_dialog.dart';
import 'package:audit_tracker/Dialogs/about_us.dart';
import 'package:audit_tracker/Dialogs/classic_dialog.dart';
import 'package:audit_tracker/Dialogs/loading_dialog.dart';
import 'package:audit_tracker/MainActivity/answer_audit_form.dart';
import 'package:audit_tracker/Utility/utility.dart';
import 'package:audit_tracker/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Utility/default_values.dart';

class Home extends StatefulWidget{
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home>{
  final _loadingDialog = LoadingDialog();
  final _classicDialog = ClassicDialog();
  final _myAccountDialog = MyAccountDialog();
  final _changePassword = ChangePassword();
  final _areaList = List<Map<dynamic, dynamic>>() = [];

  String? _userName = "Loading....";
  String? _userFullname = "Loading...";
  String _userZoneId = "Loading...";
  String _userAddress = "Loading...";
  String _indicatorTitle = "Loading forms...";
  String? _userProfilePicture = DefaultValues().defaultProfilePicture();
  String? _userPassword;
  DocumentSnapshot? _documentSnapshot;
  late SharedPreferences _preferences;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initializeLogic();
    });
    super.initState();
  }

  void _initializeLogic() async {
    _preferences = await SharedPreferences.getInstance();
    _userName = _preferences.getString("userName");
    Utility().printLog("User name: $_userName");
    Utility().printLog("User password: ${_preferences.getString("userPassword")}");
    _getUserData();
    _loadAreaList();
  }

  void _getUserData() async {
    var isFirestoreLoaded = false;
    _loadingDialog.showLoadingDialog(context);
    await Future.delayed(const Duration(milliseconds: 500));

    DocumentReference documentReference = FirebaseFirestore.instance.collection("user_data").doc(_userName);
    documentReference.snapshots().listen((snapshot) {
      if(mounted && !isFirestoreLoaded) _loadingDialog.dismissDialog(context);
      if(snapshot.exists){
        _documentSnapshot = snapshot;
        try{
          if(_documentSnapshot?["userFullName"] == null || _documentSnapshot?["userFullName"] ==  "null"){
            _userFullname = "User123";
          }else {
            _userFullname = _documentSnapshot?["userFullName"].toString();
          }
          if(_documentSnapshot?["userProfilePicture"].toString() != "null"){
            _userProfilePicture = _documentSnapshot?["userProfilePicture"].toString();
          }

          _userZoneId = _documentSnapshot!["userZoneId"].toString();
          _userAddress = _documentSnapshot!["userAddress"].toString();
          _userPassword = _documentSnapshot!["userPassword"].toString();

          if(_documentSnapshot?["userType"].toString() == "admin"){
            _classicDialog.setTitle("Oops!");
            _classicDialog.setMessage("Administrator account cannot be log-in on client website. Please use the official administrator website.");
            _classicDialog.setCancelable(false);
            _classicDialog.setPositiveButtonTitle("Log out");
            _classicDialog.showOneButtonDialog(context, () async {

              _loadingDialog.showLoadingDialog(context);
              await Future.delayed(const Duration(milliseconds: 800));
              _preferences.setString("userName", "null");
              _preferences.setString("userPassword", "null");
              _preferences.setString("userZoneId", "null");
              if(_preferences.getString("userName") == "null" && _preferences.getString("userPassword") == "null"){
                if(mounted) _loadingDialog.dismissDialog(context);
                await Future.delayed(const Duration(milliseconds: 400));
                if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp()));
              }
            });
          }else if(_documentSnapshot?["userPassword"].toString() == "DILG_PROV" || _userPassword!.length < 10){
            _classicDialog.setTitle("Change Password Required");
            _classicDialog.setMessage("New account is required to change the password. Please change your password first to get started.");
            _classicDialog.setCancelable(false);
            _classicDialog.setPositiveButtonTitle("Change Password");
            _classicDialog.showOneButtonDialog(context, () {
              _changePassword.showChangePasswordDialog(context, _userName!, _documentSnapshot!["userPassword"].toString());
            });
          }

          isFirestoreLoaded = true;
          setState(() {});
        }catch(a){
          Utility().printLog("Error: ${a.toString()}");
        }
      }else {
        _classicDialog.setTitle("Username does not exist.");
        _classicDialog.setMessage("We cannot find your user data. Please restart the app and try again.");
        _classicDialog.setPositiveButtonTitle("Close");
        _classicDialog.setCancelable(false);
        _classicDialog.showOneButtonDialog(context, () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp()));
        });
      }
    });
  }

  void _loadAreaList() async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref("System");
    DataSnapshot dataSnapshot;
    try{
      dataSnapshot = await databaseReference.child("auditInfo").child("fields").get();
    }catch(a){
      _classicDialog.setTitle("An error occurred!");
      _classicDialog.setMessage(a.toString());
      _classicDialog.setPositiveButtonTitle("Close");
      _classicDialog.setCancelable(false);
      if(mounted) _classicDialog.showOneButtonDialog(context, () { });
      return;
    }

    if(dataSnapshot.exists){
      final Map<dynamic, dynamic> map = dataSnapshot.value as Map<dynamic, dynamic>;
      map.forEach((key, value) {
        _areaList.add(value);
      });
      setState(() {});
    }else {
      _indicatorTitle = "No fields yet";
      setState(() {});
    }

    Utility().printLog("Found ${_areaList.length} fields");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            title: Text(
              'Audit Tracker - LGU',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: DefaultValues().getAppbarDefaultFontSize()
              ),
            ),
            backgroundColor: Colors.blue,
            iconTheme: const IconThemeData(
                color: Colors.white
            ),
          ),

          drawer: SafeArea(
            child: Drawer(
              child: ListView(
                children: [
                  Container(
                    color: Colors.blue,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15),
                          width: 80,
                          height: 80,
                          child: ClipOval(
                            child: Image.network(
                                _userProfilePicture!
                            ),
                          ),
                        ),

                        Text(
                          _userFullname!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          _userAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                        "Zone ID: $_userZoneId",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                  ),

                  Container(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                      margin: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            splashColor: Colors.white24,
                            onTap: (){
                              Navigator.of(context).pop();
                              HashMap<String, dynamic> userData = HashMap();
                              userData["userProfilePicture"] = _userProfilePicture;
                              userData["userName"] = _userName;
                              userData["userFullName"] = _userFullname;
                              userData["userAddress"] = _userAddress;
                              userData["userZoneId"] = _userZoneId;
                              userData["userPassword"] = _userPassword;
                              _myAccountDialog.showMyAccountDialog(context, userData);

                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/user.png',
                                    height: 25,
                                    width: 25,
                                  ),

                                  const SizedBox(
                                    width: 20,
                                  ),

                                  const Text(
                                    'My Account',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),

                                  const Spacer(),

                                  Image.asset(
                                    'assets/arrow_right.png',
                                    height: 25,
                                    width: 25,
                                  ),
                                ],
                              ),
                            )
                        ),
                      )
                  ),

                  Container(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                      margin: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            splashColor: Colors.white24,
                            onTap: (){
                              Navigator.of(context).pop();

                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/manual.png',
                                    height: 25,
                                    width: 25,
                                  ),

                                  const SizedBox(
                                    width: 20,
                                  ),

                                  const Text(
                                    'User Manual',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),

                                  const Spacer(),

                                  Image.asset(
                                    'assets/arrow_right.png',
                                    height: 25,
                                    width: 25,
                                  ),
                                ],
                              ),
                            )
                        ),
                      )
                  ),

                  Container(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                      margin: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            splashColor: Colors.white24,
                            onTap: (){
                              Navigator.of(context).pop();
                              AboutUs aboutUs = AboutUs();
                              aboutUs.showAboutUsDialog(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/about.png',
                                    height: 25,
                                    width: 25,
                                  ),

                                  const SizedBox(
                                    width: 20,
                                  ),

                                  const Text(
                                    'About Us',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),

                                  const Spacer(),

                                  Image.asset(
                                    'assets/arrow_right.png',
                                    height: 25,
                                    width: 25,
                                  ),
                                ],
                              ),
                            )
                        ),
                      )
                  ),

                  Container(
                      padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                      margin: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            splashColor: Colors.white24,
                            onTap: (){
                              Navigator.of(context).pop();
                              _classicDialog.setTitle("Log out?");
                              _classicDialog.setMessage("Are you sure you want to log out?");
                              _classicDialog.setCancelable(false);
                              _classicDialog.setPositiveButtonTitle("Log out");
                              _classicDialog.setNegativeButtonTitle("Cancel");
                              _classicDialog.showTwoButtonDialogWithFunc(context, (positiveClicked) async {
                                _loadingDialog.showLoadingDialog(context);
                                await Future.delayed(const Duration(milliseconds: 800));
                                _preferences.setString("userName", "null");
                                _preferences.setString("userPassword", "null");
                                if(_preferences.getString("userName") == "null" && _preferences.getString("userPassword") == "null"){
                                  if(mounted) _loadingDialog.dismissDialog(context);
                                  await Future.delayed(const Duration(milliseconds: 400));
                                  if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp()));
                                }
                              }, (negativeClicked) {

                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/logout.png',
                                    height: 25,
                                    width: 25,
                                  ),

                                  const SizedBox(
                                    width: 20,
                                  ),

                                  const Text(
                                    'Log out',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),

                                  const Spacer(),

                                  Image.asset(
                                    'assets/arrow_right.png',
                                    height: 25,
                                    width: 25,
                                  ),
                                ],
                              ),
                            )
                        ),
                      )
                  ),
                ],
              ),
            ),
          ),

          body: Column(
            children: [
              const SizedBox(
                  height: 25
              ),

              const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 25, right: 10),
                    child: Text(
                      "Available Audit Forms",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25
                      ),
                    ),
                  )
              ),

              const SizedBox(
                height: 10,
              ),

              const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 25, right: 10),
                    child: Text(
                      "All audit forms will display here once the administrator add forms.",
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  )
              ),

              const SizedBox(
                height: 20,
              ),

              Flexible(
                child: (_areaList.isEmpty) ? Align(
                    alignment: Alignment.center,
                    child: Text(
                      _indicatorTitle,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 25
                      ),
                    )
                ): SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (MediaQuery.of(context).size.width.toInt() ~/ 290 < 2) ? 2 : MediaQuery.of(context).size.width.toInt() ~/ 290, // Number of items in each row
                      crossAxisSpacing: 8, // Spacing between items horizontally
                      mainAxisSpacing: 8, // Spacing between items vertically
                    ),
                    itemCount: _areaList.length,
                    itemBuilder: (gridContext, gridIndex){
                      Map<dynamic, dynamic> indicatorsMap = {};
                      Map<dynamic, dynamic> requirementsMap = {};
                      List<dynamic> indicatorList = [];
                      List<dynamic> requirementsList = [];

                      try{
                        indicatorsMap = _areaList[gridIndex]["indicators"];
                      }catch(a){
                        indicatorList.clear();
                      }
                      try{
                        requirementsMap= _areaList[gridIndex]["requirements"];
                      }catch(a){
                        requirementsMap.clear();
                      }
                      indicatorsMap.forEach((key, value) {
                        indicatorList.add(value);
                      });
                      requirementsMap.forEach((key, value) {
                        requirementsList.add(value);
                      });

                      return Container(
                        margin: const EdgeInsets.all(3),
                        child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      _areaList[gridIndex]["title"].toString(),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Image.asset(
                                    "assets/forms.png",
                                    width: 70,
                                    height: 70,
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Date: ${_areaList[gridIndex]["timestamp"].toString()}",
                                      style: const TextStyle(
                                          fontSize: 13
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child:
                                      Text(
                                        "Description: ${_areaList[gridIndex]["description"].toString()}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13
                                        ),
                                      ),
                                    )
                                  ),

                                  const Spacer(),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: IgnorePointer(
                                          ignoring: indicatorList.isEmpty,
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius: BorderRadius.circular(10)
                                            ),
                                            child: InkWell(
                                                onTap: (){
                                                  _classicDialog.setTitle(_areaList[gridIndex]["title"].toString());
                                                  _classicDialog.setMessage("Date: ${_areaList[gridIndex]["timestamp"].toString()}\n\n"
                                                      "Description: ${_areaList[gridIndex]["description"].toString()}");
                                                  _classicDialog.setCancelable(false);
                                                  _classicDialog.setPositiveButtonTitle("Close");
                                                  _classicDialog.showOneButtonDialog(context, () { });
                                                },

                                                borderRadius: BorderRadius.circular(10),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Text(
                                                    indicatorList.isEmpty ? "Not available" : "View Info.",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: indicatorList.isEmpty ? Colors.grey : Colors.blue
                                                    ),
                                                  ),
                                                )
                                            ),
                                          )
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      Expanded(
                                        child: IgnorePointer(
                                          ignoring: indicatorList.isEmpty,
                                          child: Ink(
                                            decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(10)
                                            ),
                                            child: InkWell(
                                                onTap: (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => AnswerAuditForm(
                                                    formTitle: _areaList[gridIndex]["title"].toString(),
                                                    fieldPushKey: _areaList[gridIndex]["pushKey"].toString(),
                                                    userZoneId: _userZoneId,
                                                    userName: _userName!)
                                                  ));
                                                },

                                                borderRadius: BorderRadius.circular(10),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Text(
                                                    indicatorList.isEmpty ? "Not available" : "Answer Template",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: indicatorList.isEmpty ? Colors.grey : Colors.blue
                                                    ),
                                                  ),
                                                )
                                            ),
                                          )
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                        ),
                      );
                    },
                  )
                )
              )
            ],
          ),
        ),
      ),
    );
  }

}