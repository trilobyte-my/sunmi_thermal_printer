package my.trilobyte.sunmi_thermal_printer

enum class CharSet(val param: Byte) {
    GB18030(0x00.toByte()),
    BIG5(0x01.toByte()),
    KSC5601(0x02.toByte()),
    UTF8(0xff.toByte()),
}
