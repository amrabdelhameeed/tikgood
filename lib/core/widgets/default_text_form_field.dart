// import 'package:eltarsh/core/localaization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tikgood/core/database/app_services_database_provider.dart';

// ignore: must_be_immutable
class DefaultTextFormField extends StatefulWidget {
  DefaultTextFormField(
      {Key? key,
      this.enabled = true,
      required this.hint,
      this.prefixText = '',
      this.controller,
      this.inputType,
      this.isPassword = false,
      this.validationText = "Please enter a valid value",
      this.radius = 20,
      this.validator,
      this.textColor,
      this.maxLines = 1,
      this.suffixIcon})
      : super(key: key);
  final String hint;
  final String prefixText;
  final Color? textColor;
  final TextEditingController? controller;
  final TextInputType? inputType;
  final bool isPassword;
  final String? validationText;
  double radius;
  final bool enabled;
  final String? Function(String?)? validator;
  final IconData? suffixIcon;
  final int maxLines;
  @override
  State<DefaultTextFormField> createState() => _DefaultTextFormFieldState();
}

class _DefaultTextFormFieldState extends State<DefaultTextFormField> {
  late bool isPass;

  late IconData suffix;

  @override
  void initState() {
    isPass = widget.isPassword;
    suffix = widget.suffixIcon ?? Icons.lock_open_rounded;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      controller: widget.controller,
      obscureText: isPass,
      keyboardType: widget.inputType,
      style: TextStyle(
        color: widget.textColor ??
            (AppServicesDBprovider.isDark() ? Colors.white : Colors.black),
      ),
      validator: widget.validator ??
          ((error) {
            if (widget.controller!.text.isEmpty) {
              return widget.validationText!; // .tr(context)
            }
            return null;
          }),
      decoration: InputDecoration(
        prefixText: widget.prefixText,
        suffixIcon: widget.isPassword
            ? MaterialButton(
                elevation: 0,
                minWidth: 15.w,
                onPressed: () {
                  setState(() {
                    isPass = !isPass;
                    suffix = isPass == false
                        ? Icons.lock_outline
                        : Icons.lock_open_rounded;
                  });
                },
                child: Icon(
                  suffix,
                ),
              )
            : (widget.suffixIcon != null ? Icon(suffix) : SizedBox()),
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
        hintText: widget.hint,
        errorStyle: const TextStyle(
            // fontFamily: 'SFPro',
            ),
        fillColor: Colors.transparent,
        filled: AppServicesDBprovider.isDark(),
        isDense: true,
        hintStyle: TextStyle(
          fontSize: 12.sp,
          color: widget.textColor ??
              (AppServicesDBprovider.isDark()
                  ? Colors.grey.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.4)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        errorMaxLines: 2,
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Colors.blue,
          ),
        ),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.red,
              width: 1.0,
            ),
            gapPadding: 0),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Colors.blue,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.0,
          ),
        ),
      ),
    );
  }
}
// widget.isPassword! ? showPass : false
