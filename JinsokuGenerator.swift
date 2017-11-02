import Foundation
import Files

public final class JinsokuGenerator {
    
    static let template = "Templates"
    static let moduleFolderName = "Module"
    static let placeholder = "FirstModule"
    
    private let arguments: [String]
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    public func run() throws {
        guard arguments.count > 1 else {
            throw Error.missingFileName
        }
        
        // The first argument is the execution path
        let componentName = arguments[1]
        
        let templeteModule = arguments.count == 3 ? arguments[2] : "Viper"
        
        let moduleFolder: Folder
        do {
            moduleFolder = try createRootModule()
        } catch {
            throw Error.failedToCreateModuleFolder
        }
        
        do {
            try readDocument(suffix: componentName, templeteModule: templeteModule, moduleFolder: moduleFolder)
        } catch {
            throw Error.noTemplates
        }
    }
    
    func createRootModule() throws -> Folder {
        let moduleFolder = try Folder.current.createSubfolderIfNeeded(withName: JinsokuGenerator.moduleFolderName)
        print("created module folder")
        return moduleFolder
    }
    
    func readDocument(suffix: String, templeteModule: String, moduleFolder: Folder) throws {
        print("🙆‍♂️ Templete Module --> \(templeteModule)")
        let templateFolder: Folder
        do {
            templateFolder = try Folder.current.subfolder(atPath: "\(JinsokuGenerator.template)/\(templeteModule)")
        } catch {
            throw Error.noTemplateFolderFinded
        }
        let folder = try moduleFolder.createSubfolderIfNeeded(withName: suffix)
        try folder.empty()
        try templateFolder.makeSubfolderSequence(recursive: true).forEach { subFolder in
            print ("📁 added folder --> \(subFolder.name)")
            for file in subFolder.files {
                try duplicate(file, withPrefix: suffix, inFolder: try folder.createSubfolderIfNeeded(withName: subFolder.name))
            }
        }
    }
    
    func duplicate(_ file: File, withPrefix prefix: String, inFolder folder:Folder) throws {
        let modifiedFile = try folder.createFile(named: "\(file.name.replacingOccurrences(of: JinsokuGenerator.placeholder, with: prefix))")
        print("     📦 Generated ==> \(modifiedFile.name)")
        let documentAsString = try file.readAsString()
        try modifiedFile.write(string: documentAsString.replacingOccurrences(of: JinsokuGenerator.placeholder, with: prefix))
    }
}

public extension JinsokuGenerator {
    enum Error: Swift.Error {
        case missingFileName
        case failedToCreateFile
        case failedToCreateModuleFolder
        case noTemplates
        case noTemplateFolderFinded
    }
}

/// run script
let tool = JinsokuGenerator()

do {
    try tool.run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
