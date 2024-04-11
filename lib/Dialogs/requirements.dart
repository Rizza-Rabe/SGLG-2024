
import 'dart:convert';

import 'package:flutter/material.dart';

import '../Utility/default_values.dart';
import '../Utility/utility.dart';

class Requirements {

  void showRequirementsDialog(BuildContext mainContext, List<dynamic> requirements) async {

    showDialog(
      barrierDismissible: true,
      useSafeArea: true,
      context: mainContext,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: DefaultValues().dialogContentPadding(),
          content: SizedBox(
            width: DefaultValues().getDefaultWidth(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Requirements",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Flexible(
                  child: SingleChildScrollView(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: requirements.length,
                      itemBuilder: (context, index){
                        List<dynamic> values = [];
                        Utility().printLog("Values: ${requirements[index]["value"].toString()}");
                        values = requirements[index]["value"] as List<dynamic>;

                        return ListTile(
                          title: Text(
                            requirements[index]["condition"].toString() == "must" ? "The following fields must have an answer:" :
                            requirements[index]["condition"].toString() == "any" ? "Any of the following fields must have an answer:" :
                            requirements[index]["condition"].toString() == "all" ? "All the following fields must have an answer:" :
                            "No condition supplied.",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            ),
                          ),

                          subtitle: values.isEmpty ? const Text("No values found") :
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: values.length,
                            itemBuilder: (context2, index2){
                              return Container(
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: ListTile(
                                  title: Text(
                                      values[index2]["query"].toString()
                                  ),
                                ),
                              );
                            },
                          )
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: InkWell(
                    onTap: (){
                      Navigator.of(mainContext).pop();
                    },

                    splashColor: Colors.blue[200],
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        "Close",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ),
        );
      }
    );
  }
}