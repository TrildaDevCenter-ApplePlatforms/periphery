import Foundation
import ArgumentParser
import SystemPackage
import Shared

struct ScanCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code"
    )

    @Argument(help: "Arguments following '--' will be passed to the underlying build tool, which is either 'swift build' or 'xcodebuild' depending on your project")
    var buildArguments: [String] = defaultConfiguration.$buildArguments.defaultValue

    @Flag(help: "Enable guided setup")
    var setup: Bool = defaultConfiguration.guidedSetup

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: String?

    @Option(help: "Path to your project's .xcworkspace. Xcode projects only")
    var workspace: String?

    @Option(help: "Path to your project's .xcodeproj - supply this option if your project doesn't have an .xcworkspace. Xcode projects only")
    var project: String?

    @Option(parsing: .upToNextOption, help: "File target mapping configuration file paths. For use with third-party build systems")
    var fileTargetsPath: [FilePath] = defaultConfiguration.$fileTargetsPath.defaultValue

    @Option(parsing: .upToNextOption, help: "TODO") // TODO: Update, explain targets?
    var schemes: [String] = defaultConfiguration.$schemes.defaultValue

    @Option(help: "Output format (allowed: \(OutputFormat.allValueStrings.joined(separator: ", ")))")
    var format: OutputFormat = defaultConfiguration.$outputFormat.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from indexing. Declarations and references within these files will not be considered during analysis")
    var indexExclude: [String] = defaultConfiguration.$indexExclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from the results. Note that this option is purely cosmetic, these files will still be indexed")
    var reportExclude: [String] = defaultConfiguration.$reportExclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to include in the results. This option supersedes '--report-exclude'. Note that this option is purely cosmetic, these files will still be indexed")
    var reportInclude: [String] = defaultConfiguration.$reportInclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs for which all containing declarations will be retained")
    var retainFiles: [String] = defaultConfiguration.$retainFiles.defaultValue

    @Option(parsing: .upToNextOption, help: "Index store paths. Implies '--skip-build'")
    var indexStorePath: [FilePath] = defaultConfiguration.$indexStorePath.defaultValue

    @Flag(help: "Retain all public declarations, recommended for framework/library projects")
    var retainPublic: Bool = defaultConfiguration.$retainPublic.defaultValue

    @Flag(help: "Disable identification of redundant public accessibility")
    var disableRedundantPublicAnalysis: Bool = defaultConfiguration.$disableRedundantPublicAnalysis.defaultValue

    @Flag(help: "Disable identification of unused imports")
    var disableUnusedImportAnalysis: Bool = defaultConfiguration.$disableUnusedImportAnalysis.defaultValue

    @Flag(help: "Retain properties that are assigned, but never used")
    var retainAssignOnlyProperties: Bool = defaultConfiguration.$retainAssignOnlyProperties.defaultValue

    @Option(parsing: .upToNextOption, help: "Property types to retain if the property is assigned, but never read")
    var retainAssignOnlyPropertyTypes: [String] = defaultConfiguration.$retainAssignOnlyPropertyTypes.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Encodable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    var externalEncodableProtocols: [String] = defaultConfiguration.$externalEncodableProtocols.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Codable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    var externalCodableProtocols: [String] = defaultConfiguration.$externalCodableProtocols.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of XCTestCase subclasses that reside in external targets")
    var externalTestCaseClasses: [String] = defaultConfiguration.$externalTestCaseClasses.defaultValue

    @Flag(help: "Retain declarations that are exposed to Objective-C implicitly by inheriting NSObject classes, or explicitly with the @objc and @objcMembers attributes")
    var retainObjcAccessible: Bool = defaultConfiguration.$retainObjcAccessible.defaultValue

    @Flag(help: "Retain declarations that are exposed to Objective-C explicitly with the @objc and @objcMembers attributes")
    var retainObjcAnnotated: Bool = defaultConfiguration.$retainObjcAnnotated.defaultValue

    @Flag(help: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")
    var retainUnusedProtocolFuncParams: Bool = defaultConfiguration.$retainUnusedProtocolFuncParams.defaultValue

    @Flag(help: "Retain SwiftUI previews")
    var retainSwiftUIPreviews: Bool = defaultConfiguration.$retainSwiftUIPreviews.defaultValue

    @Flag(help: "Retain properties on Codable types (including Encodable and Decodable)")
    var retainCodableProperties: Bool = defaultConfiguration.$retainCodableProperties.defaultValue

    @Flag(help: "Retain properties on Encodable types only")
    var retainEncodableProperties: Bool = defaultConfiguration.$retainEncodableProperties.defaultValue

    @Flag(help: "Clean existing build artifacts before building")
    var cleanBuild: Bool = defaultConfiguration.$cleanBuild.defaultValue

    @Flag(help: "Skip the project build step")
    var skipBuild: Bool = defaultConfiguration.$skipBuild.defaultValue

    @Flag(help: "Skip schemes validation")
    var skipSchemesValidation: Bool = defaultConfiguration.$skipSchemesValidation.defaultValue

    @Flag(help: "Output result paths relative to the current directory")
    var relativeResults: Bool = defaultConfiguration.$relativeResults.defaultValue

    @Flag(help: "Exit with non-zero status if any unused code is found")
    var strict: Bool = defaultConfiguration.$strict.defaultValue

    @Flag(help: "Disable checking for updates")
    var disableUpdateCheck: Bool = defaultConfiguration.$disableUpdateCheck.defaultValue

    @Flag(help: "Enable verbose logging")
    var verbose: Bool = defaultConfiguration.$verbose.defaultValue

    @Flag(help: "Only output results")
    var quiet: Bool = defaultConfiguration.$quiet.defaultValue

    @Option(help: "Baseline file path used to filter results")
    var baseline: FilePath?

    @Option(help: "Baseline file path where results are written. Pass the same path to '--baseline' in subsequent scans to exclude the results recorded in the baseline.")
    var writeBaseline: FilePath?

    private static let defaultConfiguration = Configuration()

    func run() throws {
        let scanBehavior = ScanBehavior()

        if !setup {
            try scanBehavior.setup(config).get()
        }

        let configuration = Configuration.shared
        configuration.guidedSetup = setup
        configuration.$workspace.assign(workspace)
        configuration.$project.assign(project)
        configuration.$fileTargetsPath.assign(fileTargetsPath)
        configuration.$schemes.assign(schemes)
        configuration.$indexExclude.assign(indexExclude)
        configuration.$reportExclude.assign(reportExclude)
        configuration.$reportInclude.assign(reportInclude)
        configuration.$outputFormat.assign(format)
        configuration.$retainFiles.assign(retainFiles)
        configuration.$retainPublic.assign(retainPublic)
        configuration.$retainAssignOnlyProperties.assign(retainAssignOnlyProperties)
        configuration.$retainAssignOnlyPropertyTypes.assign(retainAssignOnlyPropertyTypes)
        configuration.$retainObjcAccessible.assign(retainObjcAccessible)
        configuration.$retainObjcAnnotated.assign(retainObjcAnnotated)
        configuration.$retainUnusedProtocolFuncParams.assign(retainUnusedProtocolFuncParams)
        configuration.$retainSwiftUIPreviews.assign(retainSwiftUIPreviews)
        configuration.$disableRedundantPublicAnalysis.assign(disableRedundantPublicAnalysis)
        configuration.$disableUnusedImportAnalysis.assign(disableUnusedImportAnalysis)
        configuration.$externalEncodableProtocols.assign(externalEncodableProtocols)
        configuration.$externalCodableProtocols.assign(externalCodableProtocols)
        configuration.$externalTestCaseClasses.assign(externalTestCaseClasses)
        configuration.$verbose.assign(verbose)
        configuration.$quiet.assign(quiet)
        configuration.$disableUpdateCheck.assign(disableUpdateCheck)
        configuration.$strict.assign(strict)
        configuration.$indexStorePath.assign(indexStorePath)
        configuration.$skipBuild.assign(skipBuild)
        configuration.$skipSchemesValidation.assign(skipSchemesValidation)
        configuration.$cleanBuild.assign(cleanBuild)
        configuration.$buildArguments.assign(buildArguments)
        configuration.$relativeResults.assign(relativeResults)
        configuration.$retainCodableProperties.assign(retainCodableProperties)
        configuration.$retainEncodableProperties.assign(retainEncodableProperties)
        configuration.$baseline.assign(baseline)
        configuration.$writeBaseline.assign(writeBaseline)

        try scanBehavior.main { project in
            try Scan().perform(project: project)
        }.get()
    }
}

extension OutputFormat: ExpressibleByArgument {}

extension FilePath: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
