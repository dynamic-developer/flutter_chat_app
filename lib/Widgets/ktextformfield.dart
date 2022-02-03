import 'package:flutter/material.dart';

Widget kTextFormFieldWidget({
  required TextEditingController controller,
  String? lable,
  TextInputAction textInputAction = TextInputAction.done,
  String? Function(String?)? validator,
  void Function(String)? onFieldSubmitted,
  TextInputType keyboardType = TextInputType.text,
  int? maxLength,
}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        style: const TextStyle(fontSize: 16),
        maxLength: maxLength,
        controller: controller,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.indigo),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.indigo, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          label: Text(lable ?? "Lable"),
          fillColor: Colors.indigo.shade100,
          labelStyle: TextStyle(color: Colors.indigo),
          filled: true,
          border: InputBorder.none,
        ),
      ),
    );
