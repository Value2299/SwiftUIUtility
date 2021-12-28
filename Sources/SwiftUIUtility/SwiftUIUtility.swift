
import Foundation
import UniformTypeIdentifiers
import SwiftUI
import Combine

// MARK: HELPER CLASS
public class Utils {
    public static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    public static var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    
    public static let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        return jsonDecoder
    }()
    public static let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        return jsonEncoder
    }()

    public static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache.shared
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()
    
    @inlinable public static func decode<T: Codable>(_ type: T.Type, from data: Data) -> T? {
        do {
            return try jsonDecoder.decode(type, from: data)
        } catch let error {
            print("Error decoding. \(error)")
            return nil
        }
    }
    @inlinable public static func encode<T: Codable>(_ data: T) -> Data? {
        do {
            return try jsonEncoder.encode(data)
        } catch let error {
            print("Error encoding. \(error)")
            return nil
        }
    }
}

public class AutoSave {
    @Published private var buffer = true
    private var save: ()->()
    private var cancellable = Set<AnyCancellable>()
    public init(bufferTime: Double = 3, _ save: @escaping () -> ()) {
        self.save = save
        $buffer.debounce(for: .seconds(bufferTime), scheduler: DispatchQueue.main).sink { [weak self] _ in
            self?.save()
        }.store(in: &cancellable)
    }
    func toggle() { buffer.toggle() }
}

#if os(macOS)
public class Typing {
    public static func end() {
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
}
#endif
// MARK: Custom type
public enum SearchPhase {
    case none, searching, done, noResult
}
public enum BackgroundContent {
    case color(Color)
    case material(Material)
    case hierarchy(HierarchicalShapeStyle)
    var color: Color? {
        if case .color(let value) = self { return value }
        return nil
    }
    var material: Material? {
        if case .material(let value) = self { return value }
        return nil
    }
    var hierarchy: HierarchicalShapeStyle? {
        if case .hierarchy(let value) = self { return value }
        return nil
    }
}

// MARK: Equatable
extension Equatable {
//    @inlinable public func into<S>(_ action: (Self) throws -> (S?)) rethrows -> S? {
//        try action(self)
//    }
    @inlinable public func into<Result>(_ action: (Self) throws -> Result) rethrows -> Result {
        try action(self)
    }
}


// MARK: Int
extension Int {
    /// Converts 1~10 into a Chinese String
    /// ```
    /// 10 -> "十"
    /// 100 -> "100"
    /// ```
    public func asCN() -> String { Int.cnNumberDict[self] ?? "\(self)" }
    public static let cnNumberDict = [1:"一", 2:"二", 3:"三", 4:"四", 5:"五", 6:"六", 7:"七", 8:"八", 9:"九", 10:"十", 11:"十一", 12:"十二", 13:"十三", 14:"十四", 15:"十五", 16:"十六", 17:"十七", 18:"十八", 19:"十九", 20:"二十"]
    
    public func asRome() -> String { Int.romeNumberDict[self] ?? "\(self)" }
    public static let romeNumberDict = [1:"Ⅰ", 2:"Ⅱ", 3:"Ⅲ", 4:"Ⅳ", 5:"Ⅴ", 6:"Ⅵ", 7:"Ⅶ", 8:"Ⅷ", 9:"Ⅸ", 10:"Ⅹ", 11:"Ⅺ", 12:"Ⅻ"]
    
    @inlinable public func mod(_ x: Int) -> Int {
        guard x > 0 else { return self }
        let result = self % x
        return result >= 0 ? result : (result + x)
    }
    /// returns double
    @inlinable public func divide(_ divider: Int) -> Double {
        precondition(divider != 0, "divide by zero")
        return Double(self) / Double(divider)
    }
    /// ```
    /// -1.d(2) = -1
    ///  -1 / 2 = 0
    @inlinable public func d(_ divider: Int) -> Int {
        Int((divide(divider)).rounded(.down))
    }
}



// MARK: String
extension String {
    @inlinable public var isNotEmpty: Bool { !isEmpty }
    
    /// - returns:
    /// isEmpty ? nil : self
    @inlinable public var validate: String? { isEmpty ? nil : self }
    
    /// Add suffix with seperator, only when suffix is not empty
    public func addSuffix(_ suffix: String, seperator: String = " ") -> String {
         suffix.isEmpty ? self : (self + seperator + suffix)
    }
    
    @inlinable public func ifEmpty(_ placeholder: String) -> String {
        isEmpty ? placeholder : self
    }
    
    
    public func includeChinese() -> Bool {
        for ch in self.unicodeScalars {
            // Chinese character range: 0x4e00 ~ 0x9fff
            if (0x4e00 < ch.value  && ch.value < 0x9fff) {
                return true
            }
        }
        return false
    }
    public func transformToPinyin(withBlank: Bool = false) -> String {
        if !includeChinese() { return self.lowercased() }
        let stringRef = NSMutableString(string: self) as CFMutableString
        // converted to pinyin with phonetic symbols
        CFStringTransform(stringRef, nil, kCFStringTransformToLatin, false)
        // remove the phonetic symbol
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false)
        var pinyin = stringRef as String
        if !withBlank {
            pinyin = pinyin.replacingOccurrences(of: " ", with: "")
        }
        return pinyin
    }
    
    public func getPinyinHead() -> String {
        transformToPinyin(withBlank: true)
            .capitalized
            .filter { $0.isUppercase }
    }
}

// MARK: Character
extension Character {
    public var isEmoji: Bool {
        if let firstScalar = unicodeScalars.first, firstScalar.properties.isEmoji {
            return (firstScalar.value >= 0x238d || unicodeScalars.count > 1)
        } else {
            return false
        }
    }
}

// MARK: Comparable
extension Comparable {
    public func clamp(_ minValue: Self?, _ maxValue: Self?) -> Self {
        var result = self
        minValue?.into { result = max($0, result) }
        maxValue?.into { result = min($0, result) }
        return result
    }
}


// MARK: Collection
extension Collection {
    public var isNotEmpty: Bool { !isEmpty }
    
    @inlinable public subscript (safe index: Index?) -> Element? {
        guard let index = index else { return nil }
        return indices.contains(index) ? self[index] : nil
    }
    
}

extension Collection where Element: Identifiable {
    public subscript (_ id: Element.ID?) -> Element? {
        self.first { $0.id == id }
    }
}

extension Sequence where Iterator.Element: Hashable {
    public func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
    
    @inlinable public func histogram() -> [Iterator.Element:Int] {
        reduce(into: [:]) { counts, el in counts[el, default: 0] += 1 }
    }
}

extension Array {
    @inlinable public var only: Element? { count == 1 ? first : nil }
    
    @inlinable public func group<Key: Equatable>(by key: @escaping (Element)->(Key)) -> [(Key, Self)] {
        compactGroup(by: key)
    }
    @inlinable public func compactGroup<Key: Equatable>(by key: @escaping (Element)->(Key?)) -> [(Key, Self)] {
        reduce(into: []) { result, el in
            if let key = key(el) {
                if let i = result.firstIndex(where: { $0.0 == key }) {
                    result[i].1.append(el)
                } else {
                    result.append((key, [el]))
                }
            }
        }
    }
    
    @inlinable public var paired: [(Element, Element)] {
        (0..<(count - 1)).map { (self[$0], self[$0+1]) }
    }
    @inlinable public var pairedWithPrevious: [(Element?, Element)] {
        isEmpty ? [] : ([(nil, self[0])] + paired)
    }
    @inlinable public var pairedWithNext: [(Element, Element?)] {
        isEmpty ? [] : (paired + [(self[count-1], nil)])
    }

    @inlinable public func forEachPair(action: (Element, Element)->()) {
        for i in 0..<(count - 1) {
            action(self[i], self[i+1])
        }
    }
    @inlinable public func forEachWithPrevious(action: (Element?, Element)->()) {
        if let first = first { action(nil, first) }
        self.forEachPair(action: action)
    }
    @inlinable public func forEachWithNext(action: (Element, Element?)->()) {
        self.forEachPair(action: action)
        if let last = last { action(last, nil) }
    }

    /// - returns:
    /// returns the next element of the first element for which predicate returns true. If no next element, returns the previous element or nil when no other element. If no elements in the collection satisfy the given predicate, returns first.
    @inlinable public func nextOf(loopThrough: Bool = false, where predicate: (Element) -> Bool) -> Element? {
        // nil only when the last element satisfy the predicate
        self[safe: (firstIndex(where: predicate) ?? -1) + 1] ??
        // then returns the one before the last one
        (loopThrough ? dropLast().first : dropLast().last)
    }
    @inlinable public func prevOf(loopThrough: Bool = false, where predicate: (Element) -> Bool) -> Element? {
        // nil only when the first element satisfy the predicate
        self[safe: (firstIndex(where: predicate) ?? 1) - 1] ??
        // then returns the one before the last one
        (loopThrough ? dropFirst().last : dropFirst().first)
    }
}
extension Array where Element: Identifiable {
    @inlinable public mutating func remove(at id: Element.ID) {
        if let i = firstIndex(where: { $0.id == id }) {
            self.remove(at: i)
        }
    }
    
    @inlinable public func nextOf(loopThrough: Bool = false, _ element: Element) -> Element? {
        nextOf(loopThrough: loopThrough, where: { $0.id == element.id })
    }
    @inlinable public func prevOf(loopThrough: Bool = false, _ element: Element) -> Element? {
        prevOf(loopThrough: loopThrough, where: { $0.id == element.id })
    }
}



// MARK: View
extension View {
    @inlinable public func clearFocusOnAppear<V: Hashable>(_ focused: FocusState<V?>.Binding) -> some View {
        onAppear { after(0.1) { focused.wrappedValue = nil } }
    }
}


// MARK: Date
let calendar = Calendar.current
extension DateFormatter {
    convenience public init(_ format: String) {
        self.init()
        self.dateFormat = format
    }
}
extension Date {
    public init?(_ string: String, as formatter: String) {
        guard let date = DateFormatter(formatter).date(from: string)
        else { return nil }
        self.init(timeInterval: 0, since: date)
    }

    public func asString(_ formatter: String) -> String {
        DateFormatter(formatter).string(from: self)
    }
    
    static public var now: Date { Date() }

    /// Return weekday component as string
    /// ```
    /// Sunday -> "Sunday"
    public func getDayString(_ format: Date.FormatStyle.Symbol.Weekday = .wide) -> String {
        self.formatted(.dateTime.weekday(format))
//        DateFormatter("EEEE").string(from: self)
    }
    
    public var year: Int { self.asInt(by: .year) }
    public var month: Int { self.asInt(by: .month) }
    /// ```
    /// Sunday -> 1
    public var weekday: Int { self.asInt(by: .weekday) }
    public var date: Int { self.asInt(by: .day) }
    public var hour: Int { self.asInt(by: .hour) }
    public var min: Int { self.asInt(by: .minute) }
    public var weekOfYear: Int { self.asInt(by: .weekOfYear) }

    /// Return component as an Int
    /// - 2020/1/2 03:04
    /// ```
    /// .month -> 1
    /// .second -> 4
    private func asInt(by format: Calendar.Component) -> Int {
        calendar.component(format, from: self)
    }

    
    public func start(of component: Calendar.Component) -> Date {
        calendar.dateInterval(of: component, for: self)?.start ?? self
    }
    public func end(of component: Calendar.Component) -> Date {
        calendar.dateInterval(of: component, for: self)?.end ?? self
    }

    public func yesterday() -> Date { add(day: -1) }
    public func tomorrow() -> Date { add(day: 1) }
    
    public func prevWeek() -> Date { add(week: -1) }
    public func nextWeek() -> Date { add(week: 1) }
    
    public func prevMonth() -> Date { add(month: -1) }
    public func nextMonth() -> Date { add(month: 1) }
    
    public func prevYear() -> Date { add(year: -1) }
    public func nextYear() -> Date { add(year: 1) }

    public func add(day: Int) -> Date { addComponent(.day, value: day) }
    public func add(week: Int) -> Date { add(day: week * 7) }
    public func add(month: Int) -> Date { addComponent(.month, value: month) }
    public func add(year: Int) -> Date { addComponent(.year, value: year) }
    
    private func addComponent(_ component: Calendar.Component, value: Int) -> Date {
        calendar.date(byAdding: component, value: value, to: self) ?? self
    }
    
    public func dayCount(of component: Calendar.Component) -> Int {
        calendar.range(of: .day, in: component, for: self)?.count ?? 1
    }
    
    public func interval(of components: Calendar.Component..., since: Date) -> DateComponents {
        calendar.dateComponents(Set(components), from: since, to: self)
    }
    
    public func day(since: Date) -> Int? { interval(of: .day, since: since).day }
    public func month(since: Date) -> Int? { interval(of: .month, since: since).month }
    public func year(since: Date) -> Int? { interval(of: .year, since: since).year }
    public func hour(since: Date) -> Int? { interval(of: .hour, since: since).hour }
    public func minute(since: Date) -> Int? { interval(of: .minute, since: since).minute }

    public func allDateInThis(_ time: Calendar.Component) -> [Date] {
        let start = start(of: time)
        return (0..<dayCount(of: time)).map { start.add(day: $0) }
    }

}
#if os(iOS)
public typealias NSImage = UIImage
#endif
// MARK: NSImage
extension NSImage {
    public var width: CGFloat { size.width }
    public var height: CGFloat { size.height }
#if os(macOS)
    public func resize(width: CGFloat) -> NSImage? {
        let height = self.height / self.width * width
        let canvas = NSRect(x: 0, y: 0, width: width, height: height)
        
        if let rep = self.bestRepresentation(for: canvas, context: nil, hints: nil) {
            let size = NSSize(width: width, height: height)
            let smallImage = NSImage(size: size, flipped: false) { _ in
                rep.draw(in: canvas)
            }
            return smallImage
        }
        return nil
    }
    @inlinable public func toImage() -> Image? { Image(nsImage: self) }
    @inlinable public func toPng() -> Data? { tiffRepresentation?.toBitmap()?.png }
    @inlinable public func toCache() -> Data? { tiffRepresentation?.toBitmap()?.cache }
#endif
}


// MARK: URL
extension URL {
    public func getData() async -> Data? {
        do {
            let (data, _) = try await Utils.urlSession.data(for: URLRequest(url: self))
            return data
        } catch {
            return nil
        }
    }
}



// MARK: Data
#if os(macOS)
extension Data {
    public var url: URL {
        NSURL(absoluteURLWithDataRepresentation: self, relativeTo: nil) as URL
    }
    
    @inlinable public func toNSImage() -> NSImage? { NSImage(data: self) }
    @inlinable public func toImage() -> Image? { toNSImage()?.toImage() }
    @inlinable public func toBitmap() -> NSBitmapImageRep? { NSBitmapImageRep(data: self) }
}

extension NSBitmapImageRep {
    @inlinable public var png: Data? { representation(using: .png, properties: [:]) }
    @inlinable public var cache: Data? {
        self.size.width > 600 ?
        representation(using: .jpeg2000, properties: [.compressionFactor: 0.5]) :
        representation(using: .jpeg2000, properties: [.compressionFactor: 1])
    }
}
#endif


// MARK: onDrop & NSItemProvider
extension Array where Element == NSItemProvider {
    @discardableResult
    public func loadFirstObjects(using load: @escaping (Data) -> Void) -> Bool {
        guard
            let item = first,
            let identifier = item.registeredTypeIdentifiers.first
        else { return false }

        item.loadItem(forTypeIdentifier: identifier, options: nil) { (data, error) in
            DispatchQueue.main.async {
                guard let data = data as? Data else { return }
                load(data)
            }
        }
        return true
    }
}



// MARK: Core Data
extension NSPredicate {
    public static var all = NSPredicate(format: "TRUEPREDICATE")
    public static var none = NSPredicate(format: "FALSEPREDICATE")
}



// MARK: FileManager
public class LocalFileManager {
    public static let shared = LocalFileManager()
    private let manager = FileManager.default
    private init() { }
    
    public func getJSON<T: Codable>(fileName: String, folderName: String, type: T.Type) -> T? {
        getFileData(.mine(folderName), fileName, .json)?.into {
            Utils.decode(type, from: $0)
        }
    }
    public func saveJSON<T: Codable>(fileName: String, folderName: String, data: T) {
        if let data = Utils.encode(data) {
            createFolderIfNeeded(folderName: folderName)
            saveFileData(data, .mine(folderName), fileName, .json)
        }
    }
    public func getImage(imageName: String, folderName: String) -> NSImage? {
        getFileURL(.mine(folderName), imageName, .png)?.into {
            #if os(macOS)
            NSImage(contentsOf: $0)
            #else
            UIImage(contentsOfFile: $0.path)
            #endif
        }
    }
    public func getImageFromCache(imageName: String) -> NSImage? {
        getFileURL(.cache, imageName, .jpeg)?.into {
            #if os(macOS)
            NSImage(contentsOf: $0)
            #else
            UIImage(contentsOfFile: $0.path)
            #endif
        }
    }
    public func saveImage(imageData: Data?, imageName: String, folderName: String) {
        createFolderIfNeeded(folderName: folderName)
        saveFileData(imageData, .mine(folderName), imageName, .png)
    }
    public func saveImageToCache(data: Data?, imageName: String) {
        saveFileData(data, .cache, imageName, .jpeg)
    }
    public func downloadImage(imageData: Data?, imageName: String) {
        if let data = imageData {
            saveFileData(data, .download, imageName, .png)
        }
    }
    
    public enum Folder {
        case mine(String)
        case download
        case cache
        var url: URL? {
            switch self {
            case .mine(let name):
                return getURL(.documentDirectory)?.safeAppend(name)
            case .download:
                return getURL(.downloadsDirectory)
            case .cache:
                return getURL(.cachesDirectory)
            }
        }
        private func getURL(_ folder: FileManager.SearchPathDirectory) -> URL? {
            FileManager.default.urls(for: folder, in: .userDomainMask).first
        }
    }
    
    private func getFileURL(_ folder: Folder, _ name: String, _ ex: UTType) -> URL? {
        folder.url?.safeAppend(name, ex)
    }
    private func getFileData(_ folder: Folder, _ name: String, _ ex: UTType) -> Data? {
        getFileURL(folder, name, ex)?.into { url in
            do {
                return try Data(contentsOf: url)
            } catch let error {
                print("Error reading file: \(name)\(ex). \(error)")
                return nil
            }
        }
    }
    private func saveFileData(_ data: Data?, _ folder: Folder, _ name: String, _ ex: UTType) {
        if let url = getFileURL(folder, name, ex) {
            do {
                if let data = data {
                    try data.write(to: url)
                } else {
                    try? manager.removeItem(at: url)
                }
            } catch let error {
                print("Error saving file: \(name)\(ex). \(error)")
            }
        }
    }

    private func createFolderIfNeeded(folderName: String) {
        guard let url = Folder.mine(folderName).url else { return }
        if !manager.fileExists(atPath: url.path) {
            do {
                try manager.createDirectory(at: url, withIntermediateDirectories: true)
            } catch let error {
                print("Error creating directory. FolderName: \(folderName). \(error)")
            }
        }
    }
}
private extension URL {
    /// returns nil if appending nil or empty string
    func safeAppend(_ pathComponent: String?) -> URL? {
        pathComponent?.validate?.into { self.appendingPathComponent($0) }
    }
    func safeAppend(_ name: String?, _ ex: UTType) -> URL? {
        safeAppend(name)?.appendingPathExtension(for: ex)
    }
}



// MARK: Public
@inlinable public func after(_ seconds: Double, _ action: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: action)
}


// MARK: Timer
extension Timer {
    @inlinable public static func after(_ seconds: TimeInterval, _ action: @escaping (Timer)->()) -> Timer {
        scheduledTimer(withTimeInterval: seconds, repeats: false, block: action)
    }
}


// MARK: Image
extension Image {
    #if os(iOS)
    public typealias NSImage = UIImage
    #endif
    @inlinable public func resizeToFit() -> some View { resizable().scaledToFit() }
    @inlinable public func resizeToFill() -> some View { resizable().scaledToFill() }
}


// MARK: CG
extension CGRect {
    @inlinable public var topLeading:     CGPoint { .init(x: 0,     y: 0) }
    @inlinable public var top:            CGPoint { .init(x: midX,  y: 0) }
    @inlinable public var topTrailing:    CGPoint { .init(x: width, y: 0) }
    @inlinable public var leading:        CGPoint { .init(x: 0,     y: midY) }
    @inlinable public var trailing:       CGPoint { .init(x: width, y: midY) }
    @inlinable public var bottomLeading:  CGPoint { .init(x: 0,     y: height) }
    @inlinable public var bottom:         CGPoint { .init(x: midX,  y: height) }
    @inlinable public var bottomTrailing: CGPoint { .init(x: width, y: height) }
}

extension CGPoint {
    public init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
    
    @inlinable public func translate(_ p: CGPoint) -> Self { self.translate(p.x, p.y) }
    @inlinable public func translate(_ x: CGFloat, _ y: CGFloat) -> Self {
        self.applying(CGAffineTransform(translationX: x, y: y))
    }

    @inlinable public func scale(_ p: CGPoint) -> Self { self.scale(p.x, p.y) }
    @inlinable public func scale(_ x: CGFloat, _ y: CGFloat) -> Self {
        self.applying(CGAffineTransform(scaleX: x, y: y))
    }
}

// MARK: Angle
extension Angle {
    public static let top: Angle = .degrees(-90)
    public static let trailing: Angle = .degrees(0)
    public static let bottom: Angle = .degrees(90)
    public static let leading: Angle = .degrees(180)
}


// MARK: Geometry
extension GeometryProxy {
    @inlinable public var width: CGFloat { size.width }
    @inlinable public var height: CGFloat { size.height }
}



// MARK: View
extension View {
    @inlinable public func rounded(_ radius: CGFloat = 10) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
    
    @inlinable public func backgroundColor(_ color: Color) -> some View {
        background(color)
    }
    
    @inlinable public func greedyFrame(alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
    @inlinable public func greedyHeight(_ maxHeight: CGFloat = .infinity, alignment: Alignment = .center) -> some View {
        frame(maxHeight: maxHeight, alignment: alignment)
    }
    @inlinable public func greedyWidth(_ maxWidth: CGFloat = .infinity, alignment: Alignment = .center) -> some View {
        frame(maxWidth: maxWidth, alignment: alignment)
    }
    
    @inlinable public func frame(_ width: CGFloat, _ height: CGFloat, alignment: Alignment = .center) -> some View {
        frame(width: width, height: height, alignment: alignment)
    }
    @inlinable public func frame(_ size: CGFloat, alignment: Alignment = .center) -> some View {
        frame(width: size, height: size, alignment: alignment)
    }
    @inlinable public func width(_ width: CGFloat, alignment: Alignment = .center) -> some View {
        frame(width: width, alignment: alignment)
    }
    @inlinable public func height(_ height: CGFloat, alignment: Alignment = .center) -> some View {
        frame(height: height, alignment: alignment)
    }
    
    @inlinable public func leading() -> some View { greedyWidth(alignment: .leading) }
    @inlinable public func trailing() -> some View { greedyWidth(alignment: .trailing) }
    @inlinable public func top() -> some View { greedyHeight(alignment: .top) }
    @inlinable public func bottom() -> some View { greedyHeight(alignment: .bottom) }
    

    @inlinable public func hide() -> some View { frame(0).padding(0).opacity(0) }
    
}


// MARK: Stack Wrapper
protocol Container: View {
    associatedtype Content
    init(content: @escaping () -> Content)
}
extension Container {
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.init(content: content)
    }
}

extension View {
    @inlinable public func hStack(alignment: VerticalAlignment = .top, spacing: CGFloat = 8) -> some View {
        HStack(alignment: alignment, spacing: spacing) { self }
    }
    @inlinable public func vStack(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 8) -> some View {
        VStack(alignment: alignment, spacing: spacing) { self }
    }
    
    @inlinable public func hScrollView(edgeOffset: CGFloat = 0) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            self.padding(.horizontal, edgeOffset)
        }
        .padding(.horizontal, -edgeOffset)
    }
    @inlinable public func vScrollView(edgeOffset: CGFloat = 0) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            self.padding(.vertical, edgeOffset)
        }
        .padding(.vertical, -edgeOffset)
    }
    @inlinable public func carousel(alignment: VerticalAlignment = .top, spacing: CGFloat = 8, padding: CGFloat = 0, edgeOffset: CGFloat = 0) -> some View {
        self.hStack(alignment: alignment, spacing: spacing).padding(.horizontal, padding).hScrollView(edgeOffset: edgeOffset)
    }
    @inlinable public func catalogue(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 8, padding: CGFloat = 0, edgeOffset: CGFloat = 0) -> some View {
        self.vStack(alignment: alignment, spacing: spacing).padding(.vertical, padding).vScrollView(edgeOffset: edgeOffset)
    }
}

// MARK: Color
class defaultTheme: ColorTheme {
    let bg = Color.clear

    let bg2 = Color.clear
    
    let text2 = Color.secondary
    let shadow = Color.black
    
    let accent = Color.accentColor
}

extension Color {
    
    static func setTheme(_ theme: ColorTheme) {
        Self.theme = theme
    }
    
    static var theme: ColorTheme = defaultTheme()
    
    static let bg = theme.bg
    static let bg2 = theme.bg2
    
    static let accent = theme.accent
    
    static let text2 = theme.text2
    
    static func white(_ value: CGFloat) -> Color {
        Color(white: value.clamp(0, 1))
    }
    
    static let shadow = theme.shadow // black
    static func shadow(_ opacity: CGFloat) -> Color {
        opacity.into { ($0 > 1) ? ($0 / 10) : $0 }.clamp(0, 1)
            .into { shadow.opacity($0) }
    }
    
    static let glass = bg.opacity(0.00001)
    static func glass(_ opacity: CGFloat) -> Color {
        opacity.into { ($0 > 1) ? ($0 / 10) : $0 }.clamp(0, 1)
            .into { bg.opacity($0) }
    }

}

protocol ColorTheme {
    var bg: Color { get }
    var bg2: Color { get }
    var text2: Color { get }
    var shadow: Color { get }
    var accent: Color { get }
}






// MARK: Hover
public struct HoverHelper<V: View>: View {
    @State private var onHover = false
    let content: V
    public var body: some View {
        content
            .onHover { onHover = $0 }
            .scaleEffect(onHover ? 1.1 : 1)
            .animation(.spring(), value: onHover)
    }
}
extension View {
    public func hover() -> some View {
        HoverHelper(content: self)
    }
}

// MARK: Background
extension View {
    public func background(content: BackgroundContent) -> some View {
        self.background(
            ZStack {
                if let color = content.color {
                    Rectangle().fill(color)
                } else if let material = content.material {
                    Rectangle().fill(material)
                } else if let hierarchy = content.hierarchy {
                    Rectangle().fill(hierarchy)
                }
            }
        )
    }
}

// MARK: Alert
extension View {
    public func deleteAlert(isPresented: Binding<Bool>, title: String, message: String = "此操作无法撤销", action: @escaping () -> ()) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button("删除", role: .destructive, action: action)
        } message: {
            Text(message)
        }
    }
}


// MARK: Menu
public struct MyMenuItem<T: Equatable>: View {
    
    let isOn: Binding<Bool>
    let title: String
    
    public init(_ title: String, selected: Binding<T>, option: T) {
        self.title = title
        self.isOn = Binding<Bool>(
            get: { return selected.wrappedValue == option },
            set: { _ in
                if selected.wrappedValue != option {
                    selected.wrappedValue = option
                }
            })
    }
    
    public var body: some View {
        Toggle(isOn: isOn) { Text(title) }
    }
}



// MARK: Button
public struct RoundedButton: View {
    
    let image: String?
    let text: String?
    let color: Color
    let action: () -> ()
    
    public init(image: String? = nil, text: String? = nil, _ color: Color = .accentColor, action: @escaping () -> ()) {
        self.image = image
        self.text = text
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Button(action: action, label: {
            HStack {
                if let image = image { Image(systemName: image) }
                if let text = text { Text(text) }
            }
            .padding(8)
            .greedyFrame()
            .background(color)
            .clipShape(Capsule())
        })
        .buttonStyle(.plain)
    }
}


// MARK: Text
extension Text {
    @inlinable public func multiline(_ alignment: TextAlignment = .center) -> some View {
        self.multilineTextAlignment(alignment)
            .minimumScaleFactor(0.7)
            .lineLimit(2)
    }
}

// MARK: TextField
public struct MyTextField: View {
    
    let title: String
    @Binding var text: String
    let focused: Bool
    let commit: () -> ()
    
    @FocusState var isFocused: Bool
    
    public init(_ title: String = "", text: Binding<String>, focused: Bool = false, onCommit commit: @escaping () -> () = { }) {
        self.title = title
        self._text = text
        self.focused = focused
        self.commit = commit
    }
    
    @State private var dummy = false
    private var textFieldView: some View {
        TextField(title, text: $text, onCommit: {
            dummy.toggle()
            commit()
        })
        .focused($isFocused)
    }
    public var body: some View {
        ZStack {
            if dummy { textFieldView } else { textFieldView }
        }
        .textFieldStyle(.plain)
        .onChange(of: focused) { isFocused = $0 }
        .onTapGesture { }
    }
}

extension View {
    public func defaultTextFieldStyle() -> some View {
        textFieldStyle(.plain)
        .padding(.horizontal)
        .greedyFrame()
        .background(Color.bg)
        .rounded()
    }
}

/// Remove focus ring around text field
#if os(macOS)
extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}

extension NSButtonCell {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}


/// Remove TextEditor default background
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear
            drawsBackground = true
        }
    }
}
#endif

// MARK: Shape
public struct CustomRounded: Shape {
    var tl: CGFloat = 0.0 // topLeading
    var tt: CGFloat = 0.0 // topTrailing
    var bl: CGFloat = 0.0 // bottomLeading
    var bt: CGFloat = 0.0 // bottomTrailing
    private init(_ tl: CGFloat, _ tt: CGFloat, _ bl: CGFloat, _ bt: CGFloat) {
        self.tl = tl; self.tt = tt; self.bl = bl; self.bt = bt
    }
    public init(top: CGFloat = 0, bottom: CGFloat = 0) {
        self.init(top, top, bottom, bottom)
    }
    public init(leading: CGFloat = 0, trailing: CGFloat = 0) {
        self.init(leading, trailing, leading, trailing)
    }
    public init(topLeading: CGFloat = 0, topTrailing: CGFloat = 0, bottomLeading: CGFloat = 0, bottomTrailing: CGFloat = 0) {
        self.init(topLeading, topTrailing, bottomLeading, bottomTrailing)
    }

    public func path(in rect: CGRect) -> Path {
        Path { path in
            let w = rect.width
            let h = rect.height

            // Make sure we do not exceed the size of the rectangle
            let maxRadius = min(h, w) / 2.0
            let tl = min(self.tl, maxRadius)
            let tt = min(self.tt, maxRadius)
            let bl = min(self.bl, maxRadius)
            let bt = min(self.bt, maxRadius)
            
            path.move(to: .init(tl, 0))
            
            path.addLine(to: .init(w - tt, 0))
            path.addArc(center: .init(w - tt, tt), radius: tt,
                        startAngle: .top, endAngle: .trailing, clockwise: false)

            path.addLine(to: .init(w, h - bt))
            path.addArc(center: .init(w - bt, h - bt), radius: bt,
                        startAngle: .trailing, endAngle: .bottom, clockwise: false)

            path.addLine(to: .init(bl, h))
            path.addArc(center: .init(bl, h - bl), radius: bl,
                        startAngle: .bottom, endAngle: .leading, clockwise: false)

            path.addLine(to: .init(0, tl))
            path.addArc(center: .init(tl, tl), radius: tl,
                        startAngle: .leading, endAngle: .top, clockwise: false)
            
            path.closeSubpath()
        }
    }
}

