import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../TimeAndDate/time_and_date.dart';
import '../Utility/utility.dart';

class WidgetUIBuilder{

  Widget getCheckBoxWidget(List<dynamic> checkBoxTitles, void Function(String? answer, Map<dynamic, dynamic>) callback) {
    bool firstIndicatorCheckBoxValue = false;
    List<String> selectedCheckBox = [];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: checkBoxTitles.length,
      itemBuilder: (context, firstIndicatorCheckBoxIndex){
        return Padding(
          padding: const EdgeInsets.all(8),
          child: StatefulBuilder(
            builder: (statefulContext, statefulSetState){
              return InkWell(
                onTap: (){
                  if(firstIndicatorCheckBoxValue == false){
                    selectedCheckBox.add(checkBoxTitles[firstIndicatorCheckBoxIndex]["title"].toString());
                    firstIndicatorCheckBoxValue = true;
                  }else{
                    selectedCheckBox.remove(checkBoxTitles[firstIndicatorCheckBoxIndex]["title"].toString());
                    firstIndicatorCheckBoxValue = false;
                  }

                  Map<dynamic, dynamic> widgetData = {};
                  widgetData["title"] = checkBoxTitles[firstIndicatorCheckBoxIndex]["title"].toString();
                  widgetData["key"] = checkBoxTitles[firstIndicatorCheckBoxIndex]["key"].toString();

                  if(selectedCheckBox.isEmpty){
                    callback("None", widgetData);
                  }else{
                    callback(jsonEncode(selectedCheckBox), widgetData);
                  }
                  Utility().printLog("Selected: ${selectedCheckBox.length}");
                  statefulSetState(() {});
                },

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                        value: firstIndicatorCheckBoxValue,
                        onChanged: (value){
                          if(value == false){
                            selectedCheckBox.add(checkBoxTitles[firstIndicatorCheckBoxIndex]["title"].toString());
                          }else{
                            selectedCheckBox.remove(checkBoxTitles[firstIndicatorCheckBoxIndex]["title"].toString());
                          }

                          Map<dynamic, dynamic> widgetData = {};
                          widgetData["title"] = checkBoxTitles[firstIndicatorCheckBoxIndex]["title"].toString();
                          widgetData["key"] = checkBoxTitles[firstIndicatorCheckBoxIndex]["key"].toString();

                          if(selectedCheckBox.isEmpty){
                            callback("None", widgetData);
                          }else{
                            callback(jsonEncode(selectedCheckBox), widgetData);
                          }
                          Utility().printLog("Selected: ${selectedCheckBox.length}");
                          statefulSetState(() {});
                        }
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                          checkBoxTitles[firstIndicatorCheckBoxIndex]["title"].toString()
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget getRadioButtonWidget(List<dynamic> radioButtonTitles, void Function(String? answer, Map<dynamic, dynamic> widgetData) callback) {
    String? radioButtonValue;

    return StatefulBuilder(
      builder: (statefulContext, statefulSetState){
        return ListView.builder(
          shrinkWrap: true,
          itemCount: radioButtonTitles.length,
          itemBuilder: (context, radioIndex){
            return RadioListTile<String>(
              title: Text(radioButtonTitles[radioIndex]["title"].toString()),
              value: radioButtonTitles[radioIndex]["title"].toString(),
              groupValue: radioButtonValue,
              onChanged: (value) {
                radioButtonValue = value!;
                Map<dynamic, dynamic> widgetData = {};
                widgetData["title"] = radioButtonTitles[radioIndex]["title"].toString();
                widgetData["key"] = radioButtonTitles[radioIndex]["key"].toString();

                callback(radioButtonValue, widgetData);
                statefulSetState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget getTextInputWidget(String type, void Function(String? answer) callback) {

    return TextFormField(
      textInputAction: TextInputAction.next,
      maxLines: 1,
      autofocus: false,
      inputFormatters:type.startsWith("num") ? [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,10}')),
      ] : [],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
          labelStyle: TextStyle(color: Colors.black),
          focusColor: Colors.black,
          hintStyle: TextStyle(color: Colors.black),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black)
          ),
          border: OutlineInputBorder()
      ),

      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (text){
        callback(text);
      },
    );
  }

  Widget getDatePickerWidget(BuildContext context, void Function(String? answer) callback){
    String? selectedDate;
    return StatefulBuilder(
      builder: (stateContext, statefulSetState){
        return InkWell(
          onTap: () async {
            selectedDate = await TimeAndDate().showDatePickerDialog(context);
            callback(selectedDate);
            statefulSetState((){});
          },

          splashColor: Colors.blue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/calendar.png",
                width: 20,
                height: 20,
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                selectedDate == null ? "Tap to select date" : selectedDate!,
                style: const TextStyle(
                    fontSize: 14
                ),
              )
            ],
          ),
        );
      },
    );
  }
}