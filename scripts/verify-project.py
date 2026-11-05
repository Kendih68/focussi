from pathlib import Path
import json,plistlib,xml.etree.ElementTree as ET
root=Path.cwd()
project=plistlib.loads(__import__('subprocess').check_output(['plutil','-convert','xml1','-o','-',str(root/'focussi.xcodeproj/project.pbxproj')]))
objects=project['objects']
for obj in objects.values():
    if obj.get('isa')=='PBXFileReference' and obj.get('sourceTree')=='SOURCE_ROOT':
        assert (root/obj['path']).exists(),obj['path']
    for key in ['children','files','buildPhases','buildConfigurations','targets','dependencies','packageProductDependencies','packageReferences']:
        for ref in obj.get(key,[]): assert ref in objects,(key,ref)
    for key in ['fileRef','productRef','buildConfigurationList','mainGroup','productRefGroup','productReference','package','target','targetProxy','containerPortal']:
        if key in obj: assert obj[key] in objects,(key,obj[key])
for p in root.glob('focussi.xcodeproj/xcshareddata/xcschemes/*.xcscheme'): ET.parse(p)
for p in root.glob('focussi/Assets.xcassets/**/*.json'): json.loads(p.read_text())
appgroup=None
for p in [root/'focussi/focussi.entitlements',root/'focussiMonitor/focussiMonitor.entitlements']:
    data=plistlib.loads(p.read_bytes()); assert data['com.apple.developer.family-controls']
    group=data['com.apple.security.application-groups']; assert appgroup is None or group==appgroup;appgroup=group
assert appgroup[0] in (root/'Shared/ScreenTimeConfiguration.swift').read_text()
print('PASS project references, source files, shared scheme, asset manifests, matching app-group and Family Controls entitlements')
