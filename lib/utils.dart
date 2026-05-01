import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##0.00', 'zh_CN');

String formatAmount(double amount, {String currency = 'CNY'}) {
  final symbol = currency == 'CNY' ? '¥' : currency == 'BTC' ? '₿' : '\$';
  return '$symbol${_fmt.format(amount.abs())}';
}

String formatDate(DateTime dt) => DateFormat('MM-dd HH:mm').format(dt);

// 按资产名称查找 icon 图片路径，找不到返回 null
const _iconMap = {
  '微信': 'assets/icons/微信.png',
  '支付宝': 'assets/icons/支付宝.png',
  '网商银行': 'assets/icons/网商银行.png',
  '工商银行': 'assets/icons/工商银行.png',
  '徽商银行': 'assets/icons/徽商银行.png',
  '邮储银行': 'assets/icons/邮储银行.png',
  '同花顺': 'assets/icons/同花顺.png',
  'OKX': 'assets/icons/OKX.png',
  'Bitget': 'assets/icons/Bitget.png',
  '支付宝花呗': 'assets/icons/花呗.PNG',
  '花呗': 'assets/icons/花呗.PNG',
  '京东白条': 'assets/icons/京东白条.png',
};

String? assetIconPath(String name) => _iconMap[name];
