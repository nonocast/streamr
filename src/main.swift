import Foundation

func main() {
  let version = RTMP_LibVersion()
  print(String(format: "0x%08x", version))
  hello()
}

main()
