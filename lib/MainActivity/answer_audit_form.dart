import 'dart:convert';
import 'dart:typed_data';
import 'package:audit_tracker/BottomSheetDialog/mov_files.dart';
import 'package:audit_tracker/Dialogs/classic_dialog.dart';
import 'package:audit_tracker/Dialogs/loading_dialog.dart';
import 'package:audit_tracker/MessageToaster/message_toaster.dart';
import 'package:audit_tracker/Utility/utility.dart';
import 'package:audit_tracker/WidgetBuilder/widget_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime_type/mime_type.dart';
import '../Utility/default_values.dart';
import 'dart:html' as html;

/// COMPLEXITIES STARTS HERE, PLEASE ANALYZE EVERY SINGLE WIDGET RENDERED BASED FROM THE DATA ON FIREBASE *
/// EVERY WIDGETS RENDERED HERE ARE ALL BASED FROM THE ADMINISTRATOR REQUIREMENTS.
/// TO RENDER THE WIDGETS, CONDITIONAL STATEMENTS ARE USED.
/// FIRST INDICATORS ARE THE PARENT WIDGETS. SUB-INDICATORS ARE MID WIDGETS AND INNER-SUB-INDICATORS ARE CHILDREN.
/// TO MAKE IT SIMPLE, THERE ARE 3 STAGES ON HOW THE WIDGETS ARE BUILT AND RENDERED.
/// HEADACHES MAY OCCUR WHILE ANALYZING THIS CODE, PLEASE MAKE SURE YOU HAVE YOUR MEDICINE.

class AnswerAuditForm extends StatefulWidget{
  const AnswerAuditForm({super.key, required this.formTitle, required this.fieldPushKey, required this.userZoneId, required this.userName});
  final String formTitle;
  final String fieldPushKey;
  final String userZoneId;
  final String userName;
  

  @override
  State<StatefulWidget> createState() => AnswerAuditFormState();

}

class AnswerAuditFormState extends State<AnswerAuditForm>{
  final _classicDialog = ClassicDialog();
  final _loadingDialog = LoadingDialog();
  final _indicatorAnswers = List<dynamic>() = [];
  final _indicators = List<dynamic>() = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initializeLogic();
    });
    super.initState();
  }

  void _initializeLogic() async {
    Utility().printLog("Form pushKey: ${widget.fieldPushKey}");

    await Future.delayed(const Duration(milliseconds: 150));
    _getFormDetails();
  }

  void _getFormDetails() async {
    _loadingDialog.showLoadingDialog(context);
    await Future.delayed(const Duration(milliseconds: 500));
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref("System");
    DataSnapshot dataSnapshot;
    try{
      dataSnapshot = await databaseReference.child("auditInfo").child("fields").child(widget.fieldPushKey).child("indicators").get();
    }catch(a){
      if(mounted) _loadingDialog.dismissDialog(context);
      _classicDialog.setTitle("An error occurred!");
      _classicDialog.setMessage(a.toString());
      _classicDialog.setPositiveButtonTitle("Close");
      _classicDialog.setCancelable(false);
      if(mounted) _classicDialog.showOneButtonDialog(context, () {});
      return;
    }

    if(!dataSnapshot.exists){
      if(mounted) _loadingDialog.dismissDialog(context);
      _classicDialog.setTitle("Audit form not exist");
      _classicDialog.setMessage("The audit form that you are trying to answer does not exist. This may be because the admin removed it from the list.");
      _classicDialog.setPositiveButtonTitle("Close");
      _classicDialog.setCancelable(false);
      if(mounted) _classicDialog.showOneButtonDialog(context, () {});
      return;
    }

    final Map<dynamic, dynamic> map = dataSnapshot.value as Map<dynamic, dynamic>;
    map.forEach((key, value) {
      _indicators.add(value);
    });

    // INDICATOR ANSWER BUILDER //
    for(int a = 0; a != _indicators.length; a++){
      Map<dynamic, dynamic> data1 = {};
      data1["question"] = _indicators[a]["query"].toString();
      data1["key"] = _indicators[a]["key"].toString();
      data1["pushKey"] = _indicators[a]["pushKey"].toString();
      data1["stage"] = 0;
      data1["mov"] = [];
      data1["answer"] = _indicators[a]["dataInputMethod"]["type"] == "null" || _indicators[a]["dataInputMethod"]["type"] == null ? "N/A" : "None";
      _indicatorAnswers.add(data1);
      Utility().printLog("** QUESTION ${(a + 1)}: ${_indicators[a]["query"].toString()}");

      // CHECK SECOND INDICATOR
      bool hasSecondIndicator = _indicators[a]["subIndicator"] != null;
      if(hasSecondIndicator){
        List<dynamic> secondIndicatorList = [];
        Map<dynamic, dynamic> innerSubIndicatorData = _indicators[a]["subIndicator"];
        innerSubIndicatorData.forEach((key, value) async {
          secondIndicatorList.add(value);
        });

        for(int c = 0; c != secondIndicatorList.length; c++){
          Map<dynamic, dynamic> data2 = {};
          data2["question"] = secondIndicatorList[c]["query"].toString();
          data2["key"] = secondIndicatorList[c]["key"].toString();
          data2["pushKey"] = secondIndicatorList[c]["pushKey"].toString();
          data2["stage"] = 1;
          data2["mov"] = [];
          data2["answer"] = secondIndicatorList[c]["dataInputMethod"]["type"] == "null" || secondIndicatorList[c]["dataInputMethod"]["type"] == null ? "N/A" : "None";
          _indicatorAnswers.add(data2);
          Utility().printLog("   >>>>> SEC. SUB-IND QUESTION ${(c + 1)}: ${secondIndicatorList[c]["query"]}");

          bool hasThirdIndicator = secondIndicatorList[c]["subIndicators"] != null;
          if(hasThirdIndicator){
            List<dynamic> thirdSubIndicator = [];
            Map<dynamic, dynamic> thirdSubIndicatorData = secondIndicatorList[c]["subIndicators"];
            thirdSubIndicatorData.forEach((key, value) async {
              thirdSubIndicator.add(value);
            });

            for(int d = 0; d != thirdSubIndicator.length; d++){
              Map<dynamic, dynamic> data3 = {};
              data3["question"] = thirdSubIndicator[d]["query"].toString();
              data3["key"] = thirdSubIndicator[d]["key"].toString();
              data3["pushKey"] = thirdSubIndicator[d]["pushKey"].toString();
              data3["stage"] = 2;
              data3["mov"] = [];
              data3["answer"] = thirdSubIndicator[d]["dataInputMethod"]["type"] == "null" || thirdSubIndicator[d]["dataInputMethod"]["type"] == null ? "N/A" : "None";
              _indicatorAnswers.add(data3);
              Utility().printLog("      ----- THIRD. SUB-IND QUESTION ${(d + 1)}: ${thirdSubIndicator[d]["query"]}");
            }
          }
        }

      }
      Utility().printLog("=========================");
    }

    Utility().printLog("TOTAL OF ${_indicatorAnswers.length} QUESTIONS FOUND");
    if(mounted) _loadingDialog.dismissDialog(context);
    Utility().printLog("Indicators data: $_indicators");
    Utility().printLog("Indicator count: ${_indicators.length}");
    setState(() {});
  }

  void _updateFirstIndicator(String newValue, String key) async {
    for (var item in _indicators) {
      if (item is Map && item.containsKey("subIndicator")) {
        Map<String, dynamic> subIndicator = item["subIndicator"];
        if (subIndicator.containsKey("key") && subIndicator["key"] == key) {
          subIndicator["answer"] = newValue;
          break;
        }
      }
    }

    Utility().printLog("Answer: $_indicators");
  }

  void _updateSecondIndicator(String newValue, String key) {
    for (var item in _indicators) {
      if (item is Map && item.containsKey("subIndicator")) {
        Map<String, dynamic> subIndicator = item["subIndicator"];
        for (var subKey in subIndicator.keys) {
          Map<String, dynamic> subIndicatorItem = subIndicator[subKey];
          if (subIndicatorItem.containsKey("key") && subIndicatorItem["key"] == key) {
            subIndicatorItem["answer"] = newValue;
            break;
          }
        }
      }
    }
    Utility().printLog("Answer: $_indicators");
  }

  void _updateLastIndicatorAnswers(String newValue, String key) async {
    for (var item in _indicators) {
      if (item is Map && item.containsKey("subIndicator")) {
        Map<String, dynamic> subIndicator = item["subIndicator"];
        for (var subKey in subIndicator.keys) {
          Map<String, dynamic> subIndicatorItem = subIndicator[subKey];
          if (subIndicatorItem.containsKey("subIndicators")) {
            Map<String, dynamic> subIndicators = subIndicatorItem["subIndicators"];
            for (var subIndKey in subIndicators.keys) {
              Map<String, dynamic> subIndicatorsItem = subIndicators[subIndKey];
              if (subIndicatorsItem.containsKey("key") && subIndicatorsItem["key"] == key) {
                subIndicatorsItem["answer"] = newValue;
                break;
              }
            }
          }
        }
      }
    }

    Utility().printLog("Answer: $_indicators");
  }

  void _submitAnswer(String userAnswer) async {
    _loadingDialog.showLoadingDialog(context);
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref("Compliance");
    Map<dynamic, dynamic> data = {};
    data["fieldPushKey"] = widget.fieldPushKey;
    data["fieldAnswers"] = userAnswer;
    data["timestamp"] = "TEST DATE";
    data["sender"] = widget.userName;
    data["status"] = "submitted";

    try{
      await databaseReference.child(widget.userZoneId).child(widget.fieldPushKey).set(data);
    }catch(a){
      if(mounted) _loadingDialog.dismissDialog(context);
      _classicDialog.setTitle("An error occurred!");
      _classicDialog.setMessage(a.toString());
      _classicDialog.setCancelable(false);
      _classicDialog.setPositiveButtonTitle("Close");
      if(mounted) _classicDialog.showOneButtonDialog(context, () { });
    }

    if(mounted) _loadingDialog.dismissDialog(context);
    MessageToaster().showSuccessMessage("Form submitted successfully");
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[200],
          appBar: AppBar(
            title: Text(
              widget.formTitle,
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

          body: SingleChildScrollView(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 15, bottom: 15),
                width: 900,
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Adjust the border radius as needed
                    side: const BorderSide(
                      color: Colors.black, // Set border color
                      width: 1.0,         // Set border width
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
/// ================================================== PARENT WIDGET BUILDER - (INDICATOR) BELOW =================================================================== ///
                    ListView.builder(
                    shrinkWrap: true,
                    itemCount: _indicators.length,
                    itemBuilder: (context, index2){

                      List<dynamic> firstIndicatorCheckBoxTitles = [];
                      List<dynamic> firstIndicatorRadioButtonTitles = [];
                      List<dynamic> forSecondInnerIndicatorData = [];

                      String? firstIndicatorType = _indicators[index2]["dataInputMethod"]["type"];
                      String? firstIndicatorValue = _indicators[index2]["dataInputMethod"]["value"];
                      String? firstIndicatorMOVType = _indicators[index2]["mov"];
                      bool hasSecondSubIndicator = _indicators[index2]["subIndicator"] != null;

                      if(hasSecondSubIndicator){
                        Map<dynamic, dynamic> innerSubIndicatorData = _indicators[index2]["subIndicator"];
                        innerSubIndicatorData.forEach((key, value) async {
                          forSecondInnerIndicatorData.add(value);
                        });
                        Utility().printLog("Inner sub indicator count: ${forSecondInnerIndicatorData.length}");
                      }

                      if(firstIndicatorType == "check_box"){
                        firstIndicatorCheckBoxTitles = jsonDecode(firstIndicatorValue!);
                        Utility().printLog("Check box decoded title counts: ${firstIndicatorCheckBoxTitles.length}");
                      }
                      if(firstIndicatorType == "radio_button"){
                        firstIndicatorRadioButtonTitles = jsonDecode(firstIndicatorValue!);
                        Utility().printLog("Radio button decoded title counts: ${firstIndicatorCheckBoxTitles.length}");
                      }
                      if(firstIndicatorType!.startsWith("num")){
                      }

                      return Container(
                          margin: const EdgeInsets.only(left: 3, right: 3, top: 1, bottom: 1),
                          child: Container(
                            margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[200]
                            ),
                            child: ListTile(
                                title: Container(
                                    padding: const EdgeInsets.all(3),
                                    child: Text(
                                      _indicators[index2]["query"].toString(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold
                                      ),
                                    )
                                ),

                                subtitle: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      const SizedBox(
                                        height: 15,
                                      ),

                                      firstIndicatorType == "check_box" ?
                                      WidgetUIBuilder().getCheckBoxWidget(firstIndicatorCheckBoxTitles, (answer, widgetData) async {
                                        Utility().printLog("Widget ID: ${_indicators[index2]["key"].toString()}");
                                        Utility().printLog("Widget question: ${_indicators[index2]["query"].toString()}");
                                        Utility().printLog("Widget answer: $answer");

                                        _updateFirstIndicator(answer!, _indicators[index2]["key"].toString());
                                        /**for(int a = 0; a != _indicatorAnswers.length; a++){
                                          if(_indicatorAnswers[a]["key"].toString() == _indicators[index2]["key"].toString()){
                                            Utility().printLog("Found matched key. Answer has been updated to $answer");
                                            _indicatorAnswers[a]["answer"] = answer;
                                            break;
                                          }
                                        }
                                        **/
                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                      }): firstIndicatorType == "radio_button" ?
                                      WidgetUIBuilder().getRadioButtonWidget(firstIndicatorRadioButtonTitles, (answer, widgetData) async {
                                        Utility().printLog("Widget ID: ${_indicators[index2]["key"].toString()}");
                                        Utility().printLog("Widget question: ${_indicators[index2]["query"].toString()}");
                                        Utility().printLog("Widget answer: $answer");

                                        _updateFirstIndicator(answer!, _indicators[index2]["key"].toString());
                                        /**
                                        for(int a = 0; a != _indicatorAnswers.length; a++){
                                          if(_indicatorAnswers[a]["key"].toString() == _indicators[index2]["key"].toString()){
                                            Utility().printLog("Found matched key. Answer has been updated to $answer");
                                            _indicatorAnswers[a]["answer"] = answer;
                                            break;
                                          }
                                        }
                                        **/
                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                      }): firstIndicatorType.startsWith("num") || firstIndicatorType.startsWith("str") ?
                                      WidgetUIBuilder().getTextInputWidget(firstIndicatorType, (answer) async {
                                        Utility().printLog("Widget ID: ${_indicators[index2]["key"].toString()}");
                                        Utility().printLog("Widget question: ${_indicators[index2]["query"].toString()}");
                                        Utility().printLog("Widget answer: $answer");

                                        _updateFirstIndicator(answer!, _indicators[index2]["key"].toString());
                                        /**
                                        for(int a = 0; a != _indicatorAnswers.length; a++){
                                          if(_indicatorAnswers[a]["key"].toString() == _indicators[index2]["key"].toString()){
                                            Utility().printLog("Found matched key. Answer has been updated to $answer");
                                            _indicatorAnswers[a]["answer"] = answer;
                                            break;
                                          }
                                        }

                                        **/
                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                      }): firstIndicatorType == "date" ?
                                      WidgetUIBuilder().getDatePickerWidget(context, (answer) async {
                                        Utility().printLog("Widget ID: ${_indicators[index2]["key"].toString()}");
                                        Utility().printLog("Widget question: ${_indicators[index2]["query"].toString()}");
                                        Utility().printLog("Widget answer: $answer");

                                        _updateFirstIndicator(answer!, _indicators[index2]["key"].toString());
                                        /**
                                        for(int a = 0; a != _indicatorAnswers.length; a++){
                                          if(_indicatorAnswers[a]["key"].toString() == _indicators[index2]["key"].toString()){
                                            Utility().printLog("Found matched key. Answer has been updated to $answer");
                                            _indicatorAnswers[a]["answer"] = answer;
                                            break;
                                          }
                                        }
                                        **/
                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                      }): hasSecondSubIndicator ?
                                      /// ==================================================== MID-WIDGET (SUB-INDICATORS) BELOW =================================================///
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: Colors.blue[100]
                                        ),
                                        padding: const EdgeInsets.all(5),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: forSecondInnerIndicatorData.length,
                                          itemBuilder: (context, secondSubIndicatorIndex){
                                            // VERY LOW ASF. //

                                            List<dynamic> secondInnerSubIndicatorRadioButtonTitle = [];
                                            List<dynamic> secondInnerSubIndicatorCheckBoxTitle = [];
                                            List<dynamic> forThirdInnerSubIndicatorData = [];

                                            Map<dynamic, dynamic> map = forSecondInnerIndicatorData[secondSubIndicatorIndex] as Map<dynamic, dynamic>;
                                            String? secondInnerSubIndicatorType = map["dataInputMethod"]["type"];
                                            String? secondInnerSubIndicatorValue = map["dataInputMethod"]["value"];
                                            String? secondIndicatorMov = map["mov"];

                                            if(secondInnerSubIndicatorType == "radio_button" && secondInnerSubIndicatorValue != null){
                                              secondInnerSubIndicatorRadioButtonTitle = jsonDecode(secondInnerSubIndicatorValue);
                                            }
                                            if(secondInnerSubIndicatorType == "check_box" && secondInnerSubIndicatorValue != null){
                                              secondInnerSubIndicatorCheckBoxTitle = jsonDecode(secondInnerSubIndicatorValue);
                                            }

                                            Map<dynamic, dynamic> veryInnerSubIndicator = {};
                                            bool hasVeryInnerSubIndicator = map["subIndicators"] != null;
                                            if(hasVeryInnerSubIndicator){
                                              veryInnerSubIndicator = map["subIndicators"] as Map<dynamic, dynamic>;
                                              veryInnerSubIndicator.forEach((key, value) async {
                                                forThirdInnerSubIndicatorData.add(value);
                                              });
                                            }

                                            return Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: StatefulBuilder(
                                                builder: (innerSubIndicatorContext, innerSubIndicatorSetState){

                                                  return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(
                                                          forSecondInnerIndicatorData[secondSubIndicatorIndex]["query"].toString(),
                                                          style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold
                                                          ),
                                                        ),
                                                      ),

                                                      const SizedBox(
                                                        height: 15,
                                                      ),

                                                      secondInnerSubIndicatorType == "check_box" ?
                                                      WidgetUIBuilder().getCheckBoxWidget(secondInnerSubIndicatorCheckBoxTitle, (answer, widgetData) async {
                                                        Utility().printLog("Widget ID: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString()}");
                                                        Utility().printLog("Widget question: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["query"].toString()}");
                                                        Utility().printLog("Widget answer: $answer");

                                                        _updateSecondIndicator(answer!, forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString());
                                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                                      }): secondInnerSubIndicatorType == "radio_button" ?
                                                      WidgetUIBuilder().getRadioButtonWidget(secondInnerSubIndicatorRadioButtonTitle, (answer, widgetData) async {
                                                        Utility().printLog("Widget ID: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString()}");
                                                        Utility().printLog("Widget question: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["query"].toString()}");
                                                        Utility().printLog("Widget answer: $answer");

                                                        _updateSecondIndicator(answer!, forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString());
                                                        /**
                                                        for(int a = 0; a != _indicatorAnswers.length; a++){
                                                          if(_indicatorAnswers[a]["key"].toString() == forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString()){
                                                            Utility().printLog("Found matched key. Answer has been updated to $answer");
                                                            _indicatorAnswers[a]["answer"] = answer;
                                                            break;
                                                          }
                                                        }
                                                        **/
                                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                                      }): secondInnerSubIndicatorType!.startsWith("num") || secondInnerSubIndicatorType.startsWith("str")?
                                                      WidgetUIBuilder().getTextInputWidget(secondInnerSubIndicatorType, (answer) async {
                                                        Utility().printLog("Widget ID: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString()}");
                                                        Utility().printLog("Widget question: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["query"].toString()}");
                                                        Utility().printLog("Widget answer: $answer");

                                                        _updateSecondIndicator(answer!, forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString());
                                                        /**
                                                        for(int a = 0; a != _indicatorAnswers.length; a++){
                                                          if(_indicatorAnswers[a]["key"].toString() == forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString()){
                                                            Utility().printLog("Found matched key. Answer has been updated to $answer");
                                                            _indicatorAnswers[a]["answer"] = answer;
                                                            break;
                                                          }
                                                        }
                                                        **/
                                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                                      }): secondInnerSubIndicatorType == "date" ?
                                                      WidgetUIBuilder().getDatePickerWidget(context, (answer) async {
                                                        Utility().printLog("Widget ID: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString()}");
                                                        Utility().printLog("Widget question: ${forSecondInnerIndicatorData[secondSubIndicatorIndex]["query"].toString()}");
                                                        Utility().printLog("Widget answer: $answer");

                                                        _updateSecondIndicator(answer!, forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString());
                                                        /**
                                                        for(int a = 0; a != _indicatorAnswers.length; a++){
                                                          if(_indicatorAnswers[a]["key"].toString() == forSecondInnerIndicatorData[secondSubIndicatorIndex]["key"].toString()){
                                                            Utility().printLog("Found matched key. Answer has been updated to $answer");
                                                            _indicatorAnswers[a]["answer"] = answer;
                                                            break;
                                                          }
                                                        }

                                                        **/
                                                        Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                                      }): const Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(
                                                            "No Lower Sub-Widget to render"
                                                        ),
                                                      ),

                                                      Align(
                                                          alignment: Alignment.centerRight,
                                                          child: IgnorePointer(
                                                            ignoring: secondIndicatorMov == null || secondIndicatorMov == "null",
                                                            child: InkWell(
                                                                onTap: () async {

                                                                },

                                                                splashColor: Colors.blue,
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(8),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Image.asset(
                                                                        "assets/upload.png",
                                                                        width: 20,
                                                                        height: 20,
                                                                      ),

                                                                      const SizedBox(
                                                                        width: 10,
                                                                      ),

                                                                      Text(
                                                                        secondIndicatorMov == "null" || secondIndicatorMov == null ? "Not applicable" : "Upload MOV file (0)",
                                                                        style: TextStyle(
                                                                            fontWeight: FontWeight.bold,
                                                                            fontSize: 14,
                                                                            color: secondIndicatorMov == "null" || secondIndicatorMov == null ? Colors.grey : Colors.black
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                )
                                                            ),
                                                          )
                                                      ),

                                                      /// =============================================================== LAST INDICATOR WIDGET =======================================================///
                                                      hasVeryInnerSubIndicator ?
                                                      ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: forThirdInnerSubIndicatorData.length,
                                                        itemBuilder: (context, thirdSubIndicatorIndex){
                                                          // VERY VERY LOW ASF. //

                                                          List<dynamic> thirdInnerSubIndicatorRadioButtonTitle = [];
                                                          List<dynamic> thirdInnerSubIndicatorCheckBoxTitle = [];
                                                          List<dynamic> thirdInnerSubIndicatorList = [];

                                                          Map<dynamic, dynamic> map = forThirdInnerSubIndicatorData[thirdSubIndicatorIndex] as Map<dynamic, dynamic>;
                                                          map.forEach((key, value) {
                                                            thirdInnerSubIndicatorList.add(value);
                                                          });

                                                          String? thirdSubIndicatorType = map["dataInputMethod"]["type"];
                                                          String? thirdSubIndicatorValue = map["dataInputMethod"]["value"];
                                                          String? thirdSubIndicatorMov = map["mov"];

                                                          if(thirdSubIndicatorType == "check_box"){
                                                            thirdInnerSubIndicatorCheckBoxTitle = jsonDecode(thirdSubIndicatorValue!);
                                                            Utility().printLog("Last sub indicator check box item count: ${thirdInnerSubIndicatorCheckBoxTitle.length}");
                                                          }

                                                          if(thirdSubIndicatorType == "radio_button"){
                                                            thirdInnerSubIndicatorRadioButtonTitle = jsonDecode(thirdSubIndicatorValue!);
                                                            Utility().printLog("Last sub indicator radio button item count: ${thirdInnerSubIndicatorRadioButtonTitle.length}");
                                                          }


                                                          return Padding(
                                                            padding: const EdgeInsets.all(8),
                                                            child: StatefulBuilder(
                                                              builder: (innerSubIndicatorContext, innerSubIndicatorSetState){
                                                                return Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Align(
                                                                      alignment: Alignment.centerLeft,
                                                                      child: Text(
                                                                        forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["query"],
                                                                        style: const TextStyle(
                                                                          fontSize: 14,
                                                                        ),
                                                                      ),
                                                                    ),

                                                                    const SizedBox(
                                                                      height: 15,
                                                                    ),

                                                                    thirdSubIndicatorType == "check_box" ?
                                                                    WidgetUIBuilder().getCheckBoxWidget(thirdInnerSubIndicatorCheckBoxTitle, (answer, widgetData) async {
                                                                      Utility().printLog("Widget ID: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()}");
                                                                      Utility().printLog("Widget question: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["query"].toString()}");
                                                                      Utility().printLog("Widget answer: $answer");

                                                                      _updateLastIndicatorAnswers(answer!, forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString());
                                                                      /**
                                                                      for(int a = 0; a != _indicatorAnswers.length; a++){
                                                                        if(_indicatorAnswers[a]["key"].toString() == forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()){
                                                                          Utility().printLog("Found matched key. Answer has been updated to $answer");
                                                                          _indicatorAnswers[a]["answer"] = answer;
                                                                          break;
                                                                        }
                                                                      }
                                                                      **/
                                                                      Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                                                    }): thirdSubIndicatorType == "radio_button" ?
                                                                    WidgetUIBuilder().getRadioButtonWidget(thirdInnerSubIndicatorRadioButtonTitle, (answer, widgetData) async {
                                                                      Utility().printLog("Widget ID: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()}");
                                                                      Utility().printLog("Widget question: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["query"].toString()}");
                                                                      Utility().printLog("Widget answer: $answer");

                                                                      _updateLastIndicatorAnswers(answer!, forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString());
                                                                      /**
                                                                      for(int a = 0; a != _indicatorAnswers.length; a++){
                                                                        if(_indicatorAnswers[a]["key"].toString() == forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()){
                                                                          Utility().printLog("Found matched key. Answer has been updated to $answer");
                                                                          _indicatorAnswers[a]["answer"] = answer;
                                                                          break;
                                                                        }
                                                                      }
                                                                      **/
                                                                      Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                                                    }): thirdSubIndicatorType!.startsWith("num") || thirdSubIndicatorType.startsWith("str") ?
                                                                    WidgetUIBuilder().getTextInputWidget(thirdSubIndicatorType, (answer) async {
                                                                      Utility().printLog("Widget ID: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()}");
                                                                      Utility().printLog("Widget question: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["query"].toString()}");
                                                                      Utility().printLog("Widget answer: $answer");

                                                                      _updateLastIndicatorAnswers(answer!, forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString());
                                                                      /**
                                                                      for(int a = 0; a != _indicatorAnswers.length; a++){
                                                                        if(_indicatorAnswers[a]["key"].toString() == forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()){
                                                                          Utility().printLog("Found matched key. Answer has been updated to $answer");
                                                                          _indicatorAnswers[a]["answer"] = answer;
                                                                          break;
                                                                        }
                                                                      }
                                                                      **/
                                                                      Utility().printLog("FULL ANSWER: $_indicatorAnswers");

                                                                    }): thirdSubIndicatorType == "date" ?
                                                                    WidgetUIBuilder().getDatePickerWidget(context, (answer) async {
                                                                      Utility().printLog("Widget ID: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()}");
                                                                      Utility().printLog("Widget question: ${forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["query"].toString()}");
                                                                      Utility().printLog("Widget answer: $answer");

                                                                      _updateLastIndicatorAnswers(answer!, forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString());
                                                                      /**
                                                                      for(int a = 0; a != _indicatorAnswers.length; a++){
                                                                        if(_indicatorAnswers[a]["key"].toString() == forThirdInnerSubIndicatorData[thirdSubIndicatorIndex]["key"].toString()){
                                                                          Utility().printLog("Found matched key. Answer has been updated to $answer");
                                                                          _indicatorAnswers[a]["answer"] = answer;
                                                                          break;
                                                                        }
                                                                      }
                                                                      **/
                                                                      Utility().printLog("FULL ANSWER: $_indicatorAnswers");
                                                                    }):const SizedBox(),

                                                                    Align(
                                                                        alignment: Alignment.centerRight,
                                                                        child: IgnorePointer(
                                                                          ignoring: thirdSubIndicatorMov == null || thirdSubIndicatorMov == "null",
                                                                          child: InkWell(
                                                                              onTap: () async {

                                                                              },

                                                                              splashColor: Colors.blue,
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(8),
                                                                                child: Row(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    Image.asset(
                                                                                      "assets/upload.png",
                                                                                      width: 20,
                                                                                      height: 20,
                                                                                    ),

                                                                                    const SizedBox(
                                                                                      width: 10,
                                                                                    ),

                                                                                    Text(
                                                                                      thirdSubIndicatorMov == "null" || thirdSubIndicatorMov == null ? "Not applicable" : "Upload MOV file (0)",
                                                                                      style: TextStyle(
                                                                                          fontWeight: FontWeight.bold,
                                                                                          fontSize: 14,
                                                                                          color: thirdSubIndicatorMov == "null" || thirdSubIndicatorMov == null ? Colors.grey : Colors.black
                                                                                      ),
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              )
                                                                          ),
                                                                        )
                                                                    )
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                          );
                                                        },
                                                      ): const SizedBox()
                                                    ],
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ): const Text(
                                          "No widget to render"
                                      ),

                                      Align(
                                          alignment: Alignment.centerRight,
                                          child: IgnorePointer(
                                            ignoring: firstIndicatorMOVType == null || firstIndicatorMOVType == "null",
                                            child: InkWell(
                                                onTap: () async {
                                                  MovFiles movFiles = MovFiles();
                                                  movFiles.showMovFilesDialogs(context, _indicators[index2]["movFiles"], widget.userZoneId, (newData){

                                                  });
                                                },

                                                splashColor: Colors.blue,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(8),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Image.asset(
                                                        "assets/upload.png",
                                                        width: 20,
                                                        height: 20,
                                                      ),

                                                      const SizedBox(
                                                        width: 10,
                                                      ),

                                                      Text(
                                                        firstIndicatorMOVType == "null" || firstIndicatorMOVType == null ? "Not applicable" : "Upload MOV file (0)",
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: firstIndicatorMOVType == "null" || firstIndicatorMOVType == null ? Colors.grey : Colors.black
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                )
                                            ),
                                          )
                                      )
                                    ],
                                  ),
                                )
                            ),
                          )
                      );
                    },
                  ),

                      const SizedBox(
                        height: 15,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                  onPressed: (){

                                  },

                                  style: ButtonStyle(
                                    textStyle: const MaterialStatePropertyAll(
                                        TextStyle(
                                            fontSize: 16
                                        )
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                        const Size(100, 45)
                                    ),
                                    overlayColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                        return Colors.white24;
                                      },
                                    ),
                                    backgroundColor: MaterialStateProperty.all(Colors.grey),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    "Save as Draft",
                                    style: TextStyle(
                                        color: Colors.white
                                    ),
                                  )
                              ),

                              const SizedBox(
                                width: 15,
                              ),

                              TextButton(
                                  onPressed: (){
                                    _classicDialog.setTitle("Submit Form?");
                                    _classicDialog.setMessage("Are you sure you want to submit the form? Please double check before submitting.");
                                    _classicDialog.setCancelable(false);
                                    _classicDialog.setPositiveButtonTitle("Submit");
                                    _classicDialog.setNegativeButtonTitle("Cancel");
                                    _classicDialog.showTwoButtonDialogWithFunc(context, (positiveClicked) {
                                      String userAnswer = jsonEncode(_indicators);
                                      _submitAnswer(userAnswer);
                                    }, (negativeClicked) {

                                    });
                                  },
                                  style: ButtonStyle(
                                    textStyle: const MaterialStatePropertyAll(
                                        TextStyle(
                                            fontSize: 16
                                        )
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                        const Size(100, 45)
                                    ),
                                    overlayColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                        return Colors.white24;
                                      },
                                    ),
                                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    "Submit Now",
                                    style: TextStyle(
                                        color: Colors.white
                                    ),
                                  )
                              ),
                            ],
                          ),
                        )
                      ),
                    ],
                  )
                ),
              ),
            ),
          )
        ),
      ),
    );
  }
}