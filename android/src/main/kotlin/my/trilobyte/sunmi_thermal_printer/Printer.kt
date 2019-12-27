package my.trilobyte.sunmi_thermal_printer

import com.sunmi.printerhelper.utils.BluetoothUtil
import com.sunmi.printerhelper.utils.ESCUtil
import android.graphics.BitmapFactory

class Printer {
    val PAPER_WIDTH_MM = 58
    val PRINT_WIDTH_MM = 48
    val DOTS_PER_LINE = 384

    fun call(bytes: ByteArray) = BluetoothUtil.sendData(bytes)

    private var connected = false
        get() = field

    var charSet: CharSet = CharSet.UTF8
        set(value: CharSet) {
            field = value
            call(ESCUtil.setCodeSystem(field.param))
        }

    var bold: Boolean = false
        set(value: Boolean) {
            field = value
        }

    var invert: Boolean = false
        set(value: Boolean) {
            field = value
        }

    init {
        connect()
        charSet = CharSet.UTF8
    }

    fun connect() {
        connected = BluetoothUtil.connectBlueTooth()
        if (connected) call(ESCUtil.init_printer()) else throw Exception("Could not connect to printer")
    }

    fun print(str: String? = null) {
        var printStr = str ?: ""
        if (printStr.isEmpty()) return
        call(printStr.toByteArray())
    }

    fun println(str: String? = null) {
        var printStr = str ?: ""
        if (printStr.isNotEmpty()) print(printStr)
        newLine()
    }

    fun bitmap(bytes: ByteArray) =
            call(ESCUtil.printBitmap(BitmapFactory.decodeByteArray(bytes, 0, bytes.size)))

    fun newLine(value: Int? = null) = call(ESCUtil.nextLine(value ?: 1))

    fun bold(value: Boolean? = null) {
        bold = value ?: !bold
        call(if (bold) ESCUtil.boldOn() else ESCUtil.boldOff())
    }

    fun underline(value: String) =
        call(when (value.toUpperCase()) {
            Underline.Thin.value -> ESCUtil.underlineWithOneDotWidthOn()
            Underline.Thick.value -> ESCUtil.underlineWithTwoDotWidthOn()
            Underline.None.value -> ESCUtil.underlineOff()
            else -> throw Exception("Invalid Underline Setting")
    })

    fun fontSize(width: Int, height: Int) {
        val byteWidth: Int = (bounded(width, 1, 16) - 1) shl 4
        val byteHeight: Int = (bounded(height, 1, 16) -1).rem(16)
        call(ESCUtil.setFontSize((byteWidth or byteHeight)))
    }

    fun bounded(value: Int, low: Int, high: Int) : Int {
        if (low > high) throw Exception("Invalid bounds")
        return if (value < low) low else if (value > high) high else value
    }

    fun darkness(value: Int) = call(ESCUtil.setPrinterDarkness(value))

    fun align(align: String) =
        call(when (align.toUpperCase()) {
            Alignment.Center.value -> ESCUtil.alignCenter()
            Alignment.Left.value -> ESCUtil.alignLeft()
            Alignment.Right.value -> ESCUtil.alignRight()
            else -> throw Exception("Invalid Alignment")
    })

    fun qr(data: String, moduleSize: Int, errorLevel: Int) =
            call(ESCUtil.getPrintQRCode(data, moduleSize, errorLevel))
    fun qr2(data1: String, data2: String, moduleSize: Int, errorLevel: Int) =
            call(ESCUtil.getPrintDoubleQRCode(data1, data2, moduleSize, errorLevel))

    fun barcode(data: String, symbology: Int, height: Int, width: Int, textPos: Int) =
            call(ESCUtil.getPrintBarCode(data, symbology, height, width, textPos))

    fun lineSpacing(value: Int? = null) = call(ESCUtil.lineSpacing(value ?: 30))

    fun invoke(task: String, params: Array<Any?>? = null) {
        when (task) {
            "align" -> align(params!![0] as String)
            "barcode" -> barcode(params!![0] as String, params!![1] as Int, params!![2] as Int, params!![3] as Int, params!![4] as Int)
            "bitmap" -> bitmap(params!![0] as ByteArray)
            "bold" -> bold(params!![0] as Boolean?)
            "darkness" -> darkness(params!![0] as Int)
            "fontSize" -> fontSize(params!![0] as Int, params!![1] as Int)
            "lineSpacing" -> lineSpacing(params!![0] as Int?)
            "newLine" -> newLine(params!![0] as Int?)
            "print" -> print(params!![0] as String?)
            "println" -> println(params!![0] as String?)
            "qr" -> qr(params!![0] as String, params!![1] as Int, params!![2] as Int)
            "qr2" -> qr2(params!![0] as String, params!![1] as String, params!![2] as Int, params!![3] as Int)
            "underline" -> underline(params!![0] as String)
            else -> throw Exception("Method not found")
        }
    }

}
