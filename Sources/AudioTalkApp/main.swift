import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1

// MARK: - Minimal Models
struct DictItem: Codable { let token: String; let value: String }
struct MacroItem: Codable { let id: String; let plan: String }
struct Items<T: Codable>: Codable { let items: [T] }
struct SimpleOK: Codable { let ok: Bool }
struct NotationSessionResp: Codable { let id: String }
struct PlanOp: Codable { let type: String; let value: String }
struct Plan: Codable { let ops: [PlanOp] }
struct IntentResp: Codable { let plan: Plan; let tokens: [String] }
struct RenderResp: Codable { let ok: Bool; let artifacts: [String] }

actor AppState {
  private struct Persist: Codable {
    var dictionary: [String: String]
    var macros: [String: String]
    var notation: [String: String]
  }
  private var dictionary: [String: String] = [:]
  private var macros: [String: String] = [:]
  private var notation: [String: String] = [:]
  private let stateURL: URL

  init(baseDir: URL) {
    self.stateURL = baseDir.appending(path: "audiotalk.json")
    Task { await self.load() }
  }

  private func load() {
    do {
      let data = try Data(contentsOf: stateURL)
      let dec = JSONDecoder()
      let p = try dec.decode(Persist.self, from: data)
      self.dictionary = p.dictionary
      self.macros = p.macros
      self.notation = p.notation
    } catch {
      // First run or unreadable; start fresh
      self.dictionary = [:]
      self.macros = [:]
      self.notation = [:]
      try? self.save()
    }
  }

  private func save() throws {
    let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    let p = Persist(dictionary: dictionary, macros: macros, notation: notation)
    let data = try enc.encode(p)
    try FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: stateURL, options: .atomic)
  }

  // Dictionary
  func getDictionary() -> [DictItem] {
    dictionary.map { DictItem(token: $0.key, value: $0.value) }.sorted { $0.token < $1.token }
  }
  func upsertDictionary(_ items: [DictItem]) async throws {
    for it in items { dictionary[it.token] = it.value }
    try save()
  }

  // Macros
  func getMacros() -> [MacroItem] {
    macros.map { MacroItem(id: $0.key, plan: $0.value) }.sorted { $0.id < $1.id }
  }
  func upsertMacro(_ m: MacroItem) async throws {
    macros[m.id] = m.plan
    try save()
  }

  // Notation sessions
  func newNotationSession() async throws -> String {
    let id = UUID().uuidString
    notation[id] = ""
    try save()
    return id
  }
  func putScore(id: String, body: String) async throws {
    notation[id] = body
    try save()
  }
  func getScore(id: String) -> String? { notation[id] }
}

// MARK: - NIO HTTP Handler
final class HTTPHandler: ChannelInboundHandler {
  typealias InboundIn = HTTPServerRequestPart
  typealias OutboundOut = HTTPServerResponsePart

  private let state: AppState
  private var reqHead: HTTPRequestHead?
  private var bodyBuffer = ByteBufferAllocator().buffer(capacity: 0)

  init(state: AppState) { self.state = state }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let part = unwrapInboundIn(data)
    switch part {
    case .head(let head):
      reqHead = head
      bodyBuffer.clear()
    case .body(var buf):
      if let bytes = buf.readBytes(length: buf.readableBytes) { bodyBuffer.writeBytes(bytes) }
    case .end:
      guard let head = reqHead else { return }
      let method = head.method.rawValue.uppercased()
      let pathOnly: String = {
        let full = head.uri
        if let q = full.firstIndex(of: "?") { return String(full[..<q]) }
        if let f = full.firstIndex(of: "#") { return String(full[..<f]) }
        return full
      }()
      let path = pathOnly
      let body = Data(bodyBuffer.readableBytesView)

      Task { [state] in
        let (status, headers, outData, plainBody) = await self.route(method: method, path: path, body: body, state: state)
        var responseHead = HTTPResponseHead(version: head.version, status: status)
        var outHeaders = HTTPHeaders()
        headers.forEach { outHeaders.add(name: $0.name, value: $0.value) }
        responseHead.headers = outHeaders
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        if let outData = outData {
          var buf = context.channel.allocator.buffer(capacity: outData.count)
          buf.writeBytes(outData)
          context.write(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
        } else if let text = plainBody {
          var buf = context.channel.allocator.buffer(capacity: text.utf8.count)
          buf.writeString(text)
          context.write(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
        }
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
      }
    }
  }

  private func jsonResponse<T: Encodable>(_ value: T, status: HTTPResponseStatus = .ok) -> (HTTPResponseStatus, [(name: String, value: String)], Data?, String?) {
    let enc = JSONEncoder(); enc.outputFormatting = [.sortedKeys]
    let data = (try? enc.encode(value)) ?? Data("{}".utf8)
    return (status, [("Content-Type", "application/json")], data, nil)
  }
  private func textResponse(_ text: String, status: HTTPResponseStatus = .ok, contentType: String = "text/plain; charset=utf-8") -> (HTTPResponseStatus, [(name: String, value: String)], Data?, String?) {
    return (status, [("Content-Type", contentType)], nil, text)
  }
  private func empty(status: HTTPResponseStatus) -> (HTTPResponseStatus, [(name: String, value: String)], Data?, String?) { (status, [], nil, nil) }

  private func route(method: String, path: String, body: Data, state: AppState) async -> (HTTPResponseStatus, [(name: String, value: String)], Data?, String?) {
    // Normalize prefix /audiotalk/v1
    func stripPrefix(_ p: String) -> String? {
      if p.hasPrefix("/audiotalk/v1") { return String(p.dropFirst("/audiotalk/v1".count)) }
      return nil
    }
    guard let local = stripPrefix(path) else { return textResponse("Not Found", status: .notFound) }

    // Routing
    switch (method, local) {
    case ("GET", "/dictionary"):
      return jsonResponse(Items(items: await state.getDictionary()))
    case ("POST", "/dictionary"):
      if let obj = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
        if let arr = obj["items"] as? [[String: Any]] {
          let items: [DictItem] = arr.compactMap { d in
            if let t = d["token"] as? String, let v = d["value"] as? String { return DictItem(token: t, value: v) }
            return nil
          }
          try? await state.upsertDictionary(items)
          return empty(status: .ok)
        } else if let t = obj["token"] as? String, let v = obj["value"] as? String {
          try? await state.upsertDictionary([DictItem(token: t, value: v)])
          return empty(status: .ok)
        }
      }
      return textResponse("Bad Request", status: .badRequest)

    case ("GET", "/macros"):
      return jsonResponse(Items(items: await state.getMacros()))
    case ("POST", "/macros"):
      if let obj = try? JSONDecoder().decode(MacroItem.self, from: body) {
        try? await state.upsertMacro(obj)
        return empty(status: .created)
      }
      return textResponse("Bad Request", status: .badRequest)

    case ("POST", "/intent"):
      // naive intent: tokenize, return stub plan
      var phrase = ""
      if let o = try? JSONSerialization.jsonObject(with: body) as? [String: Any] { phrase = (o["phrase"] as? String) ?? "" }
      let tokens = phrase.split(separator: " ").map { String($0) }
      let ops = tokens.map { PlanOp(type: "token", value: $0) }
      return jsonResponse(IntentResp(plan: Plan(ops: ops), tokens: tokens))
    case ("POST", "/intent/apply"):
      return jsonResponse(SimpleOK(ok: true))

    case ("POST", "/lesson/ab"):
      return jsonResponse(SimpleOK(ok: true))

    case ("POST", "/notation/sessions"):
      if let id = try? await state.newNotationSession() {
        return jsonResponse(NotationSessionResp(id: id), status: .created)
      }
      return textResponse("Internal Error", status: .internalServerError)

    default:
      break
    }

    // Dynamic routes
    let comps = local.split(separator: "/").map(String.init)
    if comps.count >= 3 && comps[0] == "notation" && comps[2] == "score" {
      let id = comps[1]
      if method == "PUT" {
        let text = String(data: body, encoding: .utf8) ?? ""
        try? await state.putScore(id: id, body: text)
        return empty(status: .ok)
      } else if method == "GET" {
        if let text = await state.getScore(id: id) {
          return textResponse(text, status: .ok, contentType: "text/plain; charset=utf-8")
        } else {
          return textResponse("Not Found", status: .notFound)
        }
      }
    }
    if comps.count >= 3 && comps[0] == "notation" && comps[2] == "render" {
      // Stub render
      return jsonResponse(RenderResp(ok: true, artifacts: []))
    }
    if comps.count >= 3 && comps[0] == "ump" && comps[2] == "send" {
      // Accept and return 202 Accepted
      return empty(status: .accepted)
    }

    return textResponse("Not Found", status: .notFound)
  }
}

@main
struct Main {
  static func main() throws {
    let port = Int(ProcessInfo.processInfo.environment["AUDIOTALK_PORT"] ?? "8080") ?? 8080
    let prefix = "/audiotalk/v1"
    let stateDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appending(path: ".state")
    let state = AppState(baseDir: stateDir)

    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    defer { try? group.syncShutdownGracefully() }

    let bootstrap = ServerBootstrap(group: group)
      .serverChannelOption(ChannelOptions.backlog, value: 256)
      .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
          channel.pipeline.addHandler(HTTPHandler(state: state))
        }
      }
      .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
      .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

    let channel = try bootstrap.bind(host: "127.0.0.1", port: port).wait()
    print("AudioTalkApp listening on http://127.0.0.1:\(port)\(prefix)")
    try channel.closeFuture.wait()
  }
}
