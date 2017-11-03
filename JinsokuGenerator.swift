import Foundation
import Files

public final class JinsokuGenerator {
    
    static var nameKey = "-n"
    static var templateFolderName = "Templates"
    static let templateFolderKey = "-tf"
    static var outputFolderName = "Output"
    static let moduleFolderKey = "-of"
    static var componentFolderName = "Viper"
    static let componentFolderKey = "-c"
    static var placeholder = "FirstModule"
    static let placeholderKey = "-ph"
    static let helperKey = "--help"
    
    private var argumentsDictionary: [String: String] = [JinsokuGenerator.nameKey: "",
                                                         JinsokuGenerator.componentFolderKey: JinsokuGenerator.componentFolderName,
                                                         JinsokuGenerator.templateFolderKey: JinsokuGenerator.templateFolderName,
                                                         JinsokuGenerator.moduleFolderKey: JinsokuGenerator.outputFolderName,
                                                         JinsokuGenerator.placeholderKey: JinsokuGenerator.placeholder
    ]
    
    private let arguments: [String]
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    func configureParams() throws {
        let keys = stride(from: 1, to: arguments.count, by: 2).map { arguments[$0] }
        let values = stride(from: 2, to: arguments.count, by: 2).map { arguments[$0] }
        for key in keys {
            switch key {
            case JinsokuGenerator.helperKey:
                try printHelp()
            case key where argumentsDictionary.keys.contains(key):
                guard let index = keys.index(of: key) else {
                    throw Error.noArgumentsDefined
                }
                argumentsDictionary[key] = values[index]
            default:
                throw Error.noArgumentsDefined
            }
        }
        guard let name = argumentsDictionary[JinsokuGenerator.nameKey] else { throw Error.missingFileName }
        if name.count == 0 { print("pete") }
    }
    
    func printHelp() throws {
        print("""

            \t INPUT:
            \t =====

            \t-n Select the name for the module. This parameter is mandatory.
            \t   It changes the placeholder in your template
            \t-tf Select the name for the Templates folder. By default is "Templates"
            \t-of Name For Output Folder. By default is "Output"
            \t-c Component selected in templates folder. By default is  "Viper"
            \t-ph PlaceHolder in your Template. By default is "FirstModule"

            \t OUTPUT
            \t ======

            \tYour module selected(-c) in templates folder(-tf) is created in your output folder (-of).
            \tThe placeholder(-ph) is replaced for your selected name(-nk).

            """)
        throw Error.showHelper
    }
    
    public func run() throws {
        try configureParams()
        
        guard arguments.count != 1 && arguments.count % 2 != 0 else {
            throw Error.missingFileName
        }
        
        // The first argument is the execution path
        guard let componentName = argumentsDictionary[JinsokuGenerator.nameKey] else { throw Error.missingFileName }
        guard let templateModule = argumentsDictionary[JinsokuGenerator.componentFolderKey] else { throw Error.noTemplates }
        
        let moduleFolder : Folder
        do {
            moduleFolder = try createRootModule()
        } catch {
            throw Error.failedToCreateModuleFolder
        }
        
        do {
            try readDocument(suffix: componentName, templateModule: templateModule, moduleFolder: moduleFolder)
        } catch {
            throw Error.noTemplates
        }
    }
    
    func createRootModule() throws -> Folder {
        let moduleFolder = try Folder.current.createSubfolderIfNeeded(withName: JinsokuGenerator.outputFolderName)
        return moduleFolder
    }
    
    func readDocument(suffix: String, templateModule: String, moduleFolder: Folder) throws {
        print("🙆‍♂️  Templete Module --> \(templateModule)")
        let templateFolder: Folder
        do {
            guard let templateFolderName = argumentsDictionary[JinsokuGenerator.templateFolderKey]  else { throw Error.noTemplateFolderFinded }
            templateFolder = try Folder.current.subfolder(atPath: "\(templateFolderName)/\(templateModule)")
        } catch {
            throw Error.noTemplateFolderFinded
        }
        let folder = try moduleFolder.createSubfolderIfNeeded(withName: suffix)
        try folder.empty()
        for file in templateFolder.files {
            try duplicate(file, withPrefix: suffix, inFolder: folder)
        }
        try templateFolder.makeSubfolderSequence(recursive: true).forEach { subFolder in
            let subFolderPath = subFolder.path
            let last = subFolder.path.components(separatedBy: templateFolder.path).last ?? ""
            let subFolderPathDifference = last
            print ("📁  added folder --> \(subFolder.name)")
            for file in subFolder.files {
                try duplicate(file, withPrefix: suffix, inFolder: try folder.createSubfolderIfNeeded(withName: subFolderPathDifference))
            }
        }
    }
    
    func duplicate(_ file: File, withPrefix prefix: String, inFolder folder:Folder) throws {
        guard let placeholder = argumentsDictionary[JinsokuGenerator.placeholderKey]  else { throw Error.noTemplateFolderFinded }
        let modifiedFile = try folder.createFile(named: "\(file.name.replacingOccurrences(of: placeholder, with: prefix))")
        print("     📦  Generated \(modifiedFile.name)")
        let documentAsString = try file.readAsString()
        try modifiedFile.write(string: documentAsString.replacingOccurrences(of: placeholder, with: prefix))
    }
    
}

public extension JinsokuGenerator {
    enum Error: Swift.Error {
        case missingFileName
        case failedToCreateFile
        case failedToCreateModuleFolder
        case noTemplates
        case noTemplateFolderFinded
        case showHelper
        case noArgumentsDefined
    }
}

/// run script
let tool = JinsokuGenerator()

do {
    try tool.run()
} catch JinsokuGenerator.Error.showHelper{
} catch {
    print("Whoops! An error occurred: \(error)")
}
