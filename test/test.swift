import Foundation

@main
class Test {
  static func main() {
    // print("swift testing")
    DataTest().run()
  }
}

class DataTest {
  func run() {
    test1()
  }

  func test1() {
    let data = Data(bytes: [UInt8]([0x00, 0x01, 0x02, 0x03]), count: 4)
    print(data.hexString)

    data.withUnsafeBytes { buffer in
      for byte in buffer {
        print(byte)
      }
      // print(buffer.baseAddress)
      // print(buffer.count)
    }
  }
}
