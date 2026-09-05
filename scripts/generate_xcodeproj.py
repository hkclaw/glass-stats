#!/usr/bin/env python3
"""Emit a traditional (explicit-file) Xcode project that opens without XcodeGen."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "GlassStats.xcodeproj" / "project.pbxproj"

SWIFT = [
    ("GlassStatsApp.swift", "GlassStats"),
    ("App/ModuleSettings.swift", "App"),
    ("App/MonitorStore.swift", "App"),
    ("Models/SystemSnapshot.swift", "Models"),
    ("Sampling/MachSupport.swift", "Sampling"),
    ("Sampling/HostCPU.swift", "Sampling"),
    ("Sampling/HostMemory.swift", "Sampling"),
    ("Sampling/HostProcesses.swift", "Sampling"),
    ("Sampling/HostDisk.swift", "Sampling"),
    ("Sampling/HostNetwork.swift", "Sampling"),
    ("Sampling/HostBattery.swift", "Sampling"),
    ("Sampling/SystemSampler.swift", "Sampling"),
    ("UI/GlassTheme.swift", "UI"),
    ("UI/MenuBarLabel.swift", "UI"),
    ("UI/PopoverRootView.swift", "UI"),
    ("UI/UsageChart.swift", "UI"),
    ("UI/Modules/CPUModuleView.swift", "Modules"),
    ("UI/Modules/MemoryModuleView.swift", "Modules"),
    ("UI/Modules/TopProcessesView.swift", "Modules"),
    ("UI/Modules/DiskModuleView.swift", "Modules"),
    ("UI/Modules/NetworkModuleView.swift", "Modules"),
    ("UI/Modules/BatteryModuleView.swift", "Modules"),
    ("UI/Settings/SettingsView.swift", "Settings"),
]


def hid(n: int) -> str:
    return f"8F1A{n:020X}"


def main() -> None:
    ids = {
        "project": hid(1),
        "target": hid(2),
        "product": hid(3),
        "main_group": hid(4),
        "products": hid(5),
        "src_root": hid(6),
        "app": hid(7),
        "models": hid(8),
        "sampling": hid(9),
        "ui": hid(10),
        "modules": hid(11),
        "settings": hid(12),
        "sources": hid(13),
        "frameworks": hid(14),
        "resources": hid(15),
        "proj_configs": hid(16),
        "tgt_configs": hid(17),
        "proj_debug": hid(18),
        "proj_release": hid(19),
        "tgt_debug": hid(20),
        "tgt_release": hid(21),
        "assets": hid(22),
        "assets_build": hid(23),
        "entitlements": hid(24),
        "bridging": hid(25),
        "fw_group": hid(26),
    }

    file_refs = []
    build_files = []
    by_group: dict[str, list[str]] = {
        "GlassStats": [],
        "App": [],
        "Models": [],
        "Sampling": [],
        "UI": [],
        "Modules": [],
        "Settings": [],
    }

    for i, (rel, group) in enumerate(SWIFT, start=100):
        ref = hid(i)
        build = hid(i + 500)
        name = Path(rel).name
        path = rel
        file_refs.append(
            f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};"
        )
        # path should be just the filename when the group has the directory
        build_files.append(
            f"\t\t{build} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};"
        )
        by_group[group].append((ref, name, path))
        ids[f"ref_{rel}"] = ref
        ids[f"build_{rel}"] = build

    # Fix file ref paths: groups contain files by filename only.
    # App group path = App, so ModuleSettings.swift is enough.

    sources_list = "\n".join(
        f"\t\t\t\t{ids[f'build_{rel}']} /* {Path(rel).name} in Sources */," for rel, _ in SWIFT
    )

    def children(group: str) -> str:
        return "\n".join(f"\t\t\t\t{ref} /* {name} */," for ref, name, _ in by_group[group])

    # File refs for files living in nested folders need path = filename
    # because the PBXGroup has path = folder.

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
		{ids['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['assets']} /* Assets.xcassets */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{ids['product']} /* Glass Stats.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "Glass Stats.app"; sourceTree = BUILT_PRODUCTS_DIR; }};
{chr(10).join(file_refs)}
		{ids['assets']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
		{ids['entitlements']} /* GlassStats.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = GlassStats.entitlements; sourceTree = "<group>"; }};
		{ids['bridging']} /* GlassStats-Bridging-Header.h */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = "GlassStats-Bridging-Header.h"; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{ids['frameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{ids['main_group']} = {{
			isa = PBXGroup;
			children = (
				{ids['src_root']} /* GlassStats */,
				{ids['fw_group']} /* Frameworks */,
				{ids['products']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{ids['products']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{ids['product']} /* Glass Stats.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{ids['fw_group']} /* Frameworks */ = {{
			isa = PBXGroup;
			children = (
			);
			name = Frameworks;
			sourceTree = "<group>";
		}};
		{ids['src_root']} /* GlassStats */ = {{
			isa = PBXGroup;
			children = (
				{ids['app']} /* App */,
				{ids['models']} /* Models */,
				{ids['sampling']} /* Sampling */,
				{ids['ui']} /* UI */,
				{ids[f'ref_GlassStatsApp.swift']} /* GlassStatsApp.swift */,
				{ids['assets']} /* Assets.xcassets */,
				{ids['entitlements']} /* GlassStats.entitlements */,
				{ids['bridging']} /* GlassStats-Bridging-Header.h */,
			);
			path = GlassStats;
			sourceTree = "<group>";
		}};
		{ids['app']} /* App */ = {{
			isa = PBXGroup;
			children = (
{children('App')}
			);
			path = App;
			sourceTree = "<group>";
		}};
		{ids['models']} /* Models */ = {{
			isa = PBXGroup;
			children = (
{children('Models')}
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{ids['sampling']} /* Sampling */ = {{
			isa = PBXGroup;
			children = (
{children('Sampling')}
			);
			path = Sampling;
			sourceTree = "<group>";
		}};
		{ids['ui']} /* UI */ = {{
			isa = PBXGroup;
			children = (
				{ids['modules']} /* Modules */,
				{ids['settings']} /* Settings */,
{children('UI')}
			);
			path = UI;
			sourceTree = "<group>";
		}};
		{ids['modules']} /* Modules */ = {{
			isa = PBXGroup;
			children = (
{children('Modules')}
			);
			path = Modules;
			sourceTree = "<group>";
		}};
		{ids['settings']} /* Settings */ = {{
			isa = PBXGroup;
			children = (
{children('Settings')}
			);
			path = Settings;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{ids['target']} /* GlassStats */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['tgt_configs']} /* Build configuration list for PBXNativeTarget "GlassStats" */;
			buildPhases = (
				{ids['sources']} /* Sources */,
				{ids['frameworks']} /* Frameworks */,
				{ids['resources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = GlassStats;
			productName = GlassStats;
			productReference = {ids['product']} /* Glass Stats.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{ids['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{ids['target']} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {ids['proj_configs']} /* Build configuration list for PBXProject "GlassStats" */;
			compatibilityVersion = "Xcode 15.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {ids['main_group']};
			productRefGroup = {ids['products']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{ids['target']} /* GlassStats */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{ids['resources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{ids['assets_build']} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{ids['sources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{sources_list}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{ids['proj_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{ids['proj_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
			}};
			name = Release;
		}};
		{ids['tgt_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ARCHS = arm64;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = GlassStats/GlassStats.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_APP_SANDBOX = NO;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				EXCLUDED_ARCHS = x86_64;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "Glass Stats";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
				INFOPLIST_KEY_LSUIElement = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2026 hkclaw. MIT License. Not affiliated with Stats / exelban.";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.hkclaw.GlassStats;
				PRODUCT_NAME = "Glass Stats";
				SDKROOT = macosx;
				SUPPORTED_PLATFORMS = macosx;
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_OBJC_BRIDGING_HEADER = "GlassStats/GlassStats-Bridging-Header.h";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{ids['tgt_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ARCHS = arm64;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = GlassStats/GlassStats.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_APP_SANDBOX = NO;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				EXCLUDED_ARCHS = x86_64;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "Glass Stats";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.utilities";
				INFOPLIST_KEY_LSUIElement = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2026 hkclaw. MIT License. Not affiliated with Stats / exelban.";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.hkclaw.GlassStats;
				PRODUCT_NAME = "Glass Stats";
				SDKROOT = macosx;
				SUPPORTED_PLATFORMS = macosx;
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_OBJC_BRIDGING_HEADER = "GlassStats/GlassStats-Bridging-Header.h";
				SWIFT_VERSION = 5.0;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{ids['proj_configs']} /* Build configuration list for PBXProject "GlassStats" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['proj_debug']} /* Debug */,
				{ids['proj_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['tgt_configs']} /* Build configuration list for PBXNativeTarget "GlassStats" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['tgt_debug']} /* Debug */,
				{ids['tgt_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {ids['project']} /* Project object */;
}}
"""
    OUT.write_text(pbx)
    scheme = ROOT / "GlassStats.xcodeproj/xcshareddata/xcschemes/GlassStats.xcscheme"
    text = scheme.read_text()
    text = text.replace("A10000000000000000000010", ids["target"])
    scheme.write_text(text)
    print(f"wrote {OUT}")
    print(f"target id {ids['target']}")


if __name__ == "__main__":
    main()
