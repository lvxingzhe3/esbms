class BmsCmd {
  // 命令地址
  static int cmdAddress=0x05;
  //读保持寄存器
  static int readKeep=0x03;
  //读输入寄存器
  static int readInput=0x04;
  //写保持寄存器
  static int writeKeep=0x06;

  // 电池类型
  static int battype=40101;

  // 电池容量
  static int batcapacity=40601;

  // 累加电压
  static int sumvoltage=30001;

  //告警状态
  static int warnstate=30101;

  //电芯电压
  static int seriesvolnum=0X7919;

   //电芯温度
  static int seriestempnum=0X7d01;

  //单体过压告警
  static int overChargeWarn=41001;

   //单体过压告警延时
  static int overChargeWarnDelay=41002;

   //单体过压告警解除
  static int overChargeWarnLift=41003;

   //单体过压告警解除延时
  static int overChargeWarnLiftDelay=41004;
  
  //单体过压保护
  static int overChargeProt=41005;

   //单体过压保护延时
  static int overChargeProtDelay=41006;

   //单体过压保护解除
  static int overChargeProtLift=41007;

   //单体过压保护解除延时
  static int overChargeProtLiftDelay=41008;

  //设计容量
  static int designCapacity=40601;
  //循环次数
  static int cycleCount=40617;



}