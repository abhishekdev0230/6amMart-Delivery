import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/helper/custom_validator_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _countryDialCode;
  String? _countryCode;

  @override
  void initState() {
    super.initState();

    final splashController = Get.find<SplashController>();
    final authController = Get.find<AuthController>();

    String fallbackCountry = splashController.configModel?.country ?? 'IN'; // fallback to India
    CountryCode countryCode = CountryCode.fromCountryCode(fallbackCountry);

    _countryDialCode = authController.getUserCountryDialCode().isNotEmpty
        ? authController.getUserCountryDialCode()
        : countryCode.dialCode ?? '+91'; // fallback to +91

    _countryCode = authController.getUserCountryCode().isNotEmpty
        ? authController.getUserCountryCode()
        : countryCode.code ?? 'IN'; // fallback to IN

    _phoneController.text = authController.getUserNumber();
    _passwordController.text = authController.getUserPassword();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: SizedBox(
          width: 1170,
          child: GetBuilder<AuthController>(builder: (authController) {

            return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 50),

              Image.asset(Images.signLogo,height: 150,),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Text('sign_in'.tr.toUpperCase(), style: robotoBlack.copyWith(fontSize: 30)),
              const SizedBox(height: 50),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: Theme.of(context).cardColor,
                  boxShadow: Get.isDarkMode ? null : [BoxShadow(color: Colors.grey[200]!, spreadRadius: 1, blurRadius: 5)],
                ),
                child: Column(children: [

                  CustomTextFieldWidget(
                    maxLength: 10,
                    hintText: 'phone'.tr,
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    nextFocus: _passwordFocus,
                    inputType: TextInputType.phone,
                    divider: true,
                    isPhone: true,
                    border: false,
                    onCountryChanged: (CountryCode countryCode) {
                      _countryDialCode = countryCode.dialCode;
                      _countryCode = countryCode.code;
                    },
                    countryDialCode: _countryCode ?? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code,
                  ),

                  CustomTextFieldWidget(
                    hintText: 'password'.tr,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    inputAction: TextInputAction.done,
                    inputType: TextInputType.visiblePassword,
                    prefixIcon: Icons.lock,
                    isPassword: true,
                    border: false,
                    onSubmit: (text) => GetPlatform.isWeb ? _login(
                      authController, _phoneController, _passwordController, _countryDialCode!, _countryCode!, context,
                    ) : null,
                  ),

                ]),
              ),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(
                  child: ListTile(
                    onTap: () => authController.toggleRememberMe(),
                    leading: Checkbox(
                      activeColor: Theme.of(context).primaryColor,
                      value: authController.isActiveRememberMe,
                      onChanged: (bool? isChecked) => authController.toggleRememberMe(),
                    ),
                    title: Text('remember_me'.tr),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    horizontalTitleGap: 0,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(RouteHelper.getForgotPassRoute()),
                  child: Text('${'forgot_password'.tr}?'),
                ),
              ]),
              const SizedBox(height: 50),

              CustomButtonWidget(
                buttonText: 'sign_in'.tr,
                isLoading: authController.isLoading,
                onPressed: () => _login(authController, _phoneController, _passwordController, _countryDialCode!, _countryCode!, context),
              ),
              SizedBox(height: Get.find<SplashController>().configModel!.toggleDmRegistration! ? Dimensions.paddingSizeSmall : 0),

              Get.find<SplashController>().configModel!.toggleDmRegistration! ? TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(1, 40),
                ),
                onPressed: () {
                  Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute());
                },
                child: RichText(text: TextSpan(children: [
                  TextSpan(text: '${'join_as_a'.tr} ', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                  TextSpan(text: 'delivery_man'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
                ])),
              ) : const SizedBox(),

            ]);
          }),
        ),
      )),
    );
  }

  void _login(AuthController authController, TextEditingController phoneText, TextEditingController passText, String countryDialCode, String countryCode, BuildContext context) async {
    String phone = phoneText.text.trim();
    String password = passText.text.trim();

    String numberWithCountryCode = countryDialCode + phone;
    PhoneValid phoneValid = await CustomValidatorHelper.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (phone.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    }else if (!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
    }else if (password.isEmpty) {
      showCustomSnackBar('enter_password'.tr);
    }else if (password.length < 6) {
      showCustomSnackBar('password_should_be'.tr);
    }else {
      authController.login(numberWithCountryCode, password).then((status) async {
        if (status.isSuccess) {
          if (authController.isActiveRememberMe) {
            authController.saveUserNumberAndPassword(phone, password, countryDialCode, countryCode);
          } else {
            authController.clearUserNumberAndPassword();
          }
          await Get.find<ProfileController>().getProfile();
          Get.offAllNamed(RouteHelper.getInitialRoute());
        }else {
          showCustomSnackBar(status.message);
        }
      });
    }
  }
}
