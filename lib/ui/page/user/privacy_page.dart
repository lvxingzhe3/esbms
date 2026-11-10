import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customAppBar.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/typography/gf_typography.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroud,
      appBar: CustomAppBar(
        isBackButton: true,
        title:
            customTitleText(S.of(context).agreement, color: AppColor.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Center(
                        child: Text(
                          'Sinota esBMS 隐私政策',
                          style: TextStyle(
                              color: AppColor.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    GFTypography(
                      showDivider: false,
                      textColor: AppColor.white,
                      text:
                          '${'  ' * 4}欢迎您访问我们的产品。 Sinota esBMS （包括App等产品提供的服务，以下简称“产品和服务”）是由 深圳市昔诺达科技有限公司 （以下简称“我们”）开发并运营的。 确保用户的数据安全和隐私保护是我们的首要任务， 本隐私政策载明了您访问和使用我们的产品和服务时所收集的数据及其处理方式。 ',
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}请您在继续使用我们的产品前务必认真仔细阅读并确认充分理解本隐私政策全部规则和要点， 一旦您选择使用，即视为您同意本隐私政策的全部内容，同意我们按其收集和使用您的相关信息。 如您在在阅读过程中，对本政策有任何疑问，可联系我们的客服咨询， 请通过 产品中的反馈方式与我们取得联系。 如您不同意相关协议或其中的任何条款的，您应停止使用我们的产品和服务。'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}本隐私政策帮助您了解以下内容：'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}一、我们如何收集和使用您的个人信息；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}二、我们如何存储和保护您的个人信息；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}三、我们如何共享、转让、公开披露您的个人信息；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}四、我们如何使用 Cookie 和其他追踪技术；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}五、您如何管理个人信息；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}六、我们如何处理未成年人个人信息；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}七、账号注销说明；'),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: GFTypography(
                          showDivider: false,
                          textColor: AppColor.white,
                          text: '一、我们如何收集和使用您的个人信息'),
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}1、个人信息是指以电子或者其他方式记录的能够单独或者与其他信息， 结合识别特定自然人身份或者反映特定自然人活动情况的各种信息。 我们根据《中华人民共和国网络安全法》和《信息安全技术个人信息安全规范》（GB/T 35273-2017） 以及其它相关法律法规的要求，并严格遵循正当、合法、必要的原则， 出于您使用我们提供的服务和/或产品等过程中而收集和使用您的个人信息，包括但不限于电话号码等。\r\n       2、设备信息包括设备型号、操作系统版本，唯一设备标识符，IP地址、网络类型，以保障应用正常运行和崩溃排查。\r\n       3、位置信息包括精确GPS位置、基站信息、WiFi列表信息以为您提供准确的地图服务和位置相关功能。\r\n        4、 蓝牙信息包括蓝牙设备名称、MAC地址、连接状态以实现设备连接、数据传输和功能控制。'),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: GFTypography(
                          showDivider: false,
                          textColor: AppColor.white,
                          text: '二、我们如何存储和保护您的个人信息'),
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}作为一般规则，我们仅在实现信息收集目的所需的时间内保留您的个人信息。 我们会在对于管理与您之间的关系严格必要的时间内保留您的个人信息 （例如，当您开立帐户，从我们的产品获取服务时）。 出于遵守法律义务或为证明某项权利或合同满足适用的诉讼时效要求的目的， 我们可能需要在上述期限到期后保留您存档的个人信息，并且无法按您的要求删除。 当您的个人信息对于我们的法定义务或法定时效对应的目的或档案不再必要时， 我们确保将其完全删除或匿名化。 '),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}我们使用符合业界标准的安全防护措施保护您提供的个人信息，并加密其中的关键数据， 防止其遭到未经授权访问、公开披露、使用、修改、损坏或丢失。我们会采取一切合理可行的措施，保护您的个人信息。 我们会使用加密技术确保数据的保密性；我们会使用受信赖的保护机制防止数据遭到恶意攻击。 '),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: GFTypography(
                          showDivider: false,
                          textColor: AppColor.white,
                          text: '三、我们如何共享、转让、公开披露您的个人信息 '),
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}在管理我们的日常业务活动所需要时，为追求合法利益以更好地服务客户， 我们将合规且恰当的使用您的个人信息。出于对业务和各个方面的综合考虑， 我们仅自身使用这些数据，不与任何第三方分享。'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}我们可能会根据法律法规规定，或按政府主管部门的强制性要求，对外共享您的个人信息。 在符合法律法规的前提下，当我们收到上述披露信息的请求时，我们会要求必须出具与之相应的法律文件，如传票或调查函。 我们坚信，对于要求我们提供的信息，应该在法律允许的范围内尽可能保持透明。'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}在以下情形中，共享、转让、公开披露您的个人信息无需事先征得您的授权同意：'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}1、与国家安全、国防安全直接相关的；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}2、与犯罪侦查、起诉、审判和判决执行等直接相关的；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}3、出于维护您或其他个人的生命、财产等重大合法权益但又很难得到本人同意的；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}4、您自行向社会公众公开的个人信息；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}5、从合法公开披露的信息中收集个人信息的，如合法的新闻报道、政府信息公开等渠道；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}6、根据个人信息主体要求签订和履行合同所必需的； '),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}7、用于维护所提供的产品或服务的安全稳定运行所必需的，例如发现、处置产品或服务的故障；'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text: '${'  ' * 4}8、法律法规规定的其他情形。 '),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: GFTypography(
                          showDivider: false,
                          textColor: AppColor.white,
                          text: '四、我们如何使用 Cookie 和其他追踪技术'),
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}为确保产品正常运转，我们会在您的计算机或移动设备上存储名为 Cookie 的小数据文件。 Cookie 通常包含标识符、产品名称以及一些号码和字符。 借助于 Cookie，我们能够存储您的偏好或商品等数据，并用以判断注册用户是否已经登录， 提升服务和产品质量及优化用户体验。'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}我们出于不同的目的使用各种Cookie，包括：严格必要型Cookie、性能Cookie、营销Cookie和功能Cookie。 某些Cookie可能由外部第三方提供，以向我们的产品提供其它功能。 我们不会将 Cookie 用于本政策所述目的之外的任何用途。您可根据自己的偏好管理或删除 Cookie。 您可以清除计算机上或手机中保存的所有 Cookie，大部分网络浏览器都设有阻止或禁用 Cookie 的功能， 您可对浏览器进行配置。阻止或禁用 Cookie 功能后，可能影响您使用或不能充分使用我们的产品和服务。 '),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: GFTypography(
                          showDivider: false,
                          textColor: AppColor.white,
                          text: '五、您如何管理个人信息'),
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}共享： 我们不会与任何公司、组织和个人分享您的个人信息，但以下情况除外：1）获得您的明确同意后；2）根据法律法规规定或按政府主管部门的强制性要求'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}转让、公开披露： 原则上不会发生，如发生将遵循法律法规并在发生前告知您。'),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: GFTypography(
                          showDivider: false,
                          textColor: AppColor.white,
                          text: '六、我们如何处理未成年人个人信息'),
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}1.我们非常重视对未成年人个人信息的保护。本产品主要面向成年人（18周岁以上）。'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}2.如您为14周岁以下的儿童，请您务必在征得您的父母或监护人明确同意的前提下使用我们的产品和服务，并在监护人指导下仔细阅读本政策。'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}3.我们不会主动收集14周岁以下儿童的个人信息。对于经监护人同意而收集的儿童个人信息，我们只会在法律法规允许、监护人明确同意或保护儿童所必要的情况下使用或披露。'),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}4.如果您是儿童的监护人，当您对您所监护的儿童的个人信息有疑问时，您可以通过第八节的联系方式与我们联系。'),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: GFTypography(
                          showDivider: false,
                          textColor: AppColor.white,
                          text: '七、账号注销说明'),
                    ),
                    GFTypography(
                        showDivider: false,
                        textColor: AppColor.white,
                        text:
                            '${'  ' * 4}本APP账号不支持用户注销，由运营方统一管理。 如果您不再需要使用该账号，可以发送账号停用申请邮件至：lmx@sinota-sz.com， 运营方核验身份后，将在15个工作日内完成账号停用，并清理账号关联收集的个人信息。'),
                  ],
                ))),
      ),
    );
  }
}
