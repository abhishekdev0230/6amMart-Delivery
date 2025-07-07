import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/confirmation_dialog_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_alert_dialog_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/order_shimmer_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/order_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/title_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/count_card_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/earning_widget.dart';
import 'package:sixam_mart_delivery/features/order/screens/running_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late final AppLifecycleListener _listener;
  bool _isNotificationPermissionGranted = true;
  bool _isBatteryOptimizationGranted = true;

  @override
  void initState() {
    super.initState();

    _checkSystemNotification();

    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );

    _loadData();

    Future.delayed(const Duration(milliseconds: 200), () {
      checkPermission();
    });
  }

  Future<void> _loadData() async {
    Get.find<OrderController>().getIgnoreList();
    Get.find<OrderController>().removeFromIgnoreList();
    await Get.find<ProfileController>().getProfile();
    await Get.find<OrderController>().getCurrentOrders();
    await Get.find<NotificationController>().getNotificationList();
  }

  _checkSystemNotification() async {
    if(await Permission.notification.status.isDenied || await Permission.notification.status.isPermanentlyDenied) {
      await Get.find<AuthController>().setNotificationActive(false);
    }
  }

  // Listen to the app lifecycle state changes
  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        checkPermission();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        break;
    }
  }

  Future<void> checkPermission() async {
    var notificationStatus = await Permission.notification.status;
    var batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    if(notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
      setState(() {
        _isNotificationPermissionGranted = false;
        _isBatteryOptimizationGranted = true;
      });

      await Get.find<AuthController>().setNotificationActive(!notificationStatus.isDenied);

    } else if(batteryStatus.isDenied) {
      setState(() {
        _isBatteryOptimizationGranted = false;
        _isNotificationPermissionGranted = true;
      });
    } else {
      setState(() {
        _isNotificationPermissionGranted = true;
        _isBatteryOptimizationGranted = true;
      });
      Get.find<ProfileController>().setBackgroundNotificationActive(true);
    }

    if(batteryStatus.isDenied) {
      Get.find<ProfileController>().setBackgroundNotificationActive(false);
    }
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.request().isGranted) {
      checkPermission();
      return;
    } else {
      await openAppSettings();
    }

    checkPermission();
  }

  void requestBatteryOptimization() async {
    var status = await Permission.ignoreBatteryOptimizations.status;

    if (status.isGranted) {
      return;
    } else if(status.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    } else {
      openAppSettings();
    }

    checkPermission();
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        leading: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Image.asset(Images.logo, height: 30, width: 30),
        ),
        titleSpacing: 0, elevation: 0,
        title: Text(AppConstants.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(
          color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeDefault,
        )),
        actions: [
          IconButton(
            icon: GetBuilder<NotificationController>(builder: (notificationController) {
              return Stack(children: [

                Icon(Icons.notifications, size: 25, color: Theme.of(context).textTheme.bodyLarge!.color),

                notificationController.hasNotification ? Positioned(top: 0, right: 0, child: Container(
                  height: 10, width: 10, decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor, shape: BoxShape.circle,
                  border: Border.all(width: 1, color: Theme.of(context).cardColor),
                ),
                )) : const SizedBox(),

              ]);
            }),
            onPressed: () => Get.toNamed(RouteHelper.getNotificationRoute()),
          ),
          GetBuilder<ProfileController>(builder: (profileController) {
            return GetBuilder<OrderController>(builder: (orderController) {
              return (profileController.profileModel != null && orderController.currentOrderList != null) ? FlutterSwitch(
                width: 75, height: 30, valueFontSize: Dimensions.fontSizeExtraSmall, showOnOff: true,
                activeText: 'online'.tr, inactiveText: 'offline'.tr, activeColor: Theme.of(context).primaryColor,
                value: profileController.profileModel!.active == 1, onToggle: (bool isActive) async {
                  if(!isActive && orderController.currentOrderList!.isNotEmpty) {
                    showCustomSnackBar('you_can_not_go_offline_now'.tr);
                  }else {
                    if(!isActive) {
                      Get.dialog(ConfirmationDialogWidget(
                        icon: Images.warning, description: 'are_you_sure_to_offline'.tr,
                        onYesPressed: () {
                          Get.back();
                          profileController.updateActiveStatus();
                        },
                      ));
                    }else {
                      LocationPermission permission = await Geolocator.checkPermission();
                      if(permission == LocationPermission.denied || permission == LocationPermission.deniedForever || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
                        _checkPermission(() => profileController.updateActiveStatus());
                      }else {
                        profileController.updateActiveStatus();
                      }
                    }
                  }
                },
              ) : const SizedBox();
            });
          }),
          const SizedBox(width: Dimensions.paddingSizeSmall),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          return await _loadData();
        },
        child: Column(children: [

          if(!_isNotificationPermissionGranted)
            permissionWarning(isBatteryPermission: false, onTap: requestNotificationPermission, closeOnTap: () {
              setState(() {
                _isNotificationPermissionGranted = true;
              });
            }),

          if(!_isBatteryOptimizationGranted)
            permissionWarning(isBatteryPermission: true, onTap: requestBatteryOptimization, closeOnTap: () {
              setState(() {
                _isBatteryOptimizationGranted = true;
              });
            }),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: GetBuilder<ProfileController>(builder: (profileController) {

                return Column(children: [

                  GetBuilder<OrderController>(builder: (orderController) {
                    bool hasActiveOrder = orderController.currentOrderList == null || orderController.currentOrderList!.isNotEmpty;
                    bool hasMoreOrder = orderController.currentOrderList != null && orderController.currentOrderList!.length > 1;
                    return Column(children: [
                      hasActiveOrder ? TitleWidget(
                        title: 'active_order'.tr, onTap: hasMoreOrder ? () {
                          Get.toNamed(RouteHelper.getRunningOrderRoute(), arguments: const RunningOrderScreen());
                        } : null,
                      ) : const SizedBox(),
                      SizedBox(height: hasActiveOrder ? Dimensions.paddingSizeExtraSmall : 0),
                      orderController.currentOrderList == null ? OrderShimmerWidget(
                        isEnabled: orderController.currentOrderList == null,
                      ) : orderController.currentOrderList!.isNotEmpty ? OrderWidget(
                        orderModel: orderController.currentOrderList![0], isRunningOrder: true, orderIndex: 0,
                      ) : const SizedBox(),
                      SizedBox(height: hasActiveOrder ? Dimensions.paddingSizeDefault : 0),
                    ]);
                  }),

                  (profileController.profileModel != null && profileController.profileModel!.earnings == 1) ? Column(children: [

                    TitleWidget(title: 'earnings'.tr),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        color: Theme.of(context).primaryColor,
                      ),
                      child: Column(children: [

                        Row(mainAxisAlignment: MainAxisAlignment.start, children: [

                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Image.asset(Images.wallet, width: 60, height: 60),
                          const SizedBox(width: Dimensions.paddingSizeLarge),

                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            Text(
                              'balance'.tr,
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeSmall),

                            profileController.profileModel != null ? Text(
                              PriceConverterHelper.convertPrice(profileController.profileModel!.balance),
                              style: robotoBold.copyWith(fontSize: 24, color: Theme.of(context).cardColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ) : Container(height: 30, width: 60, color: Colors.white),

                          ]),
                        ]),
                        const SizedBox(height: 30),
                        Row(children: [

                          EarningWidget(
                            title: 'today'.tr,
                            amount: profileController.profileModel?.todaysEarning,
                          ),
                          Container(height: 30, width: 1, color: Theme.of(context).cardColor),

                          EarningWidget(
                            title: 'this_week'.tr,
                            amount: profileController.profileModel?.thisWeekEarning,
                          ),
                          Container(height: 30, width: 1, color: Theme.of(context).cardColor),

                          EarningWidget(
                            title: 'this_month'.tr,
                            amount: profileController.profileModel?.thisMonthEarning,
                          ),

                        ]),

                      ]),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ]) : const SizedBox(),

                  TitleWidget(title: 'orders'.tr),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Row(children: [

                    Expanded(child: CountCardWidget(
                      title: 'todays_orders'.tr, backgroundColor: Theme.of(context).secondaryHeaderColor, height: 180,
                      value: profileController.profileModel?.todaysOrderCount.toString(),
                    )),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(child: CountCardWidget(
                      title: 'this_week_orders'.tr, backgroundColor: Theme.of(context).colorScheme.error, height: 180,
                      value: profileController.profileModel?.thisWeekOrderCount.toString(),
                    )),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  CountCardWidget(
                    title: 'total_orders'.tr, backgroundColor: Theme.of(context).primaryColor, height: 140,
                    value: profileController.profileModel?.orderCount.toString(),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  profileController.profileModel != null ? Container(
                    height: 120, width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      border: Border.all(width: 2, color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: profileController.profileModel!.cashInHands! > 0 && profileController.profileModel!.earnings == 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                      children: [

                        Row(mainAxisAlignment: profileController.profileModel!.cashInHands! > 0 && profileController.profileModel!.earnings == 1 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center, children: [

                          Text(PriceConverterHelper.convertPrice(profileController.profileModel!.cashInHands), style: robotoBold.copyWith(fontSize: 30)),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          (profileController.profileModel!.cashInHands! > 0 && profileController.profileModel!.earnings == 1) ? CustomButtonWidget(
                            width: 110, height: 40,
                            buttonText: 'view_details'.tr,
                            backgroundColor: Theme.of(context).primaryColor,
                            onPressed: () => Get.toNamed(RouteHelper.getCashInHandRoute()),
                          ) : const SizedBox(),

                        ]),

                        Text('cash_in_your_hand'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),

                      ],
                    ),
                  ) : const CashInHandCardShimmer(),

                ]);
              }),
            ),
          ),
        ]),
      ),
    );
  }

  Widget permissionWarning({required bool isBatteryPermission, required Function() onTap, required Function() closeOnTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.7),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Row(children: [

                if(isBatteryPermission)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.warning_rounded, color: Colors.yellow,),
                  ),

                Expanded(
                  child: Row(children: [
                    Flexible(
                      child: Text(
                        isBatteryPermission ? 'for_better_performance_allow_notification_to_run_in_background'.tr
                            : 'notification_is_disabled_please_allow_notification'.tr,
                        maxLines: 2, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    const Icon(Icons.arrow_circle_right_rounded, color: Colors.white, size: 24,),
                  ]),
                ),

                const SizedBox(width: 20),
              ]),
            ),

            Positioned(
              top: 5, right: 5,
              child: InkWell(
                onTap: closeOnTap,
                child: const Icon(Icons.clear, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkPermission(Function callback) async {
    LocationPermission permission = await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();

    while(Get.isDialogOpen == true) {
      Get.back();
    }

    if(permission == LocationPermission.denied) {
      Get.dialog(CustomAlertDialogWidget(description: 'you_denied'.tr, onOkPressed: () async {
        Get.back();
        final perm = await Geolocator.requestPermission();
        if(perm == LocationPermission.deniedForever) await Geolocator.openAppSettings();
        if(GetPlatform.isAndroid) _checkPermission(callback);
      }));
    }else if(permission == LocationPermission.deniedForever || (GetPlatform.isIOS ? false : permission == LocationPermission.whileInUse)) {
      Get.dialog(CustomAlertDialogWidget(description:  permission == LocationPermission.whileInUse ? 'you_denied'.tr : 'you_denied_forever'.tr, onOkPressed: () async {
        Get.back();
        await Geolocator.openAppSettings();
        Future.delayed(const Duration(seconds: 3), () {
          if(GetPlatform.isAndroid) _checkPermission(callback);
        });
      }));
    }else {
      callback();
    }
  }
}

class CashInHandCardShimmer extends StatelessWidget {
  const CashInHandCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: const Duration(seconds: 2),
      enabled: true,
      child: Container(
        height: 120, width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          color: Colors.grey[300],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(height: 20, width: 150, color: Colors.white),
            const SizedBox(width: Dimensions.paddingSizeSmall),
    
            Container(height: 40, width: 100, color: Colors.white),
          ]),
    
          Row(children: [
            Container(height: 15, width: 200, color: Colors.white),
          ]),
    
        ]),
      ),
    );
  }
}
