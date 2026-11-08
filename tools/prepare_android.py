"""Verify official archives and assemble an isolated, local APK export toolchain."""
from pathlib import Path
import hashlib
import json
import shutil
import xml.etree.ElementTree as ET
import zipfile

root = Path(__file__).resolve().parents[1]
work = root / ".android-build"
repo = ET.parse(work / "repository.xml")
release = json.loads((work / "release.json").read_text())

def verify(file, expected, algorithm):
    with file.open("rb") as stream:
        actual = hashlib.file_digest(stream, algorithm).hexdigest()
    if actual.lower() != expected.lower():
        raise RuntimeError(f"Checksum mismatch: {file.name}")
    print(f"Verified {file.name}: {actual}", flush=True)

asset = next(a for a in release["assets"] if a["name"] == "Godot_v4.7.2-stable_export_templates.tpz")
if asset.get("digest"):
    algorithm, digest = asset["digest"].split(":")
    verify(work / "templates.tpz", digest, algorithm)

for package, filename in (("build-tools;35.0.1", "build-tools.zip"), ("platform-tools", "platform-tools.zip")):
    remote = next(x for x in repo.getroot() if x.tag.endswith("remotePackage") and x.get("path") == package)
    archives = remote.find("archives")
    archive = next(a for a in archives if a.findtext("host-os") == "windows")
    checksum = archive.find("complete/checksum")
    verify(work / filename, checksum.text, checksum.get("type", "sha1"))

def extract(archive, destination, predicate=lambda name: True, strip_first=False):
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as source:
        for entry in source.infolist():
            if entry.is_dir() or not predicate(entry.filename):
                continue
            name = entry.filename.split("/", 1)[-1] if strip_first else entry.filename
            target = (destination / name).resolve()
            if not target.is_relative_to(destination.resolve()):
                raise RuntimeError("Archive path outside workspace")
            target.parent.mkdir(parents=True, exist_ok=True)
            with source.open(entry) as inp, target.open("wb") as out:
                shutil.copyfileobj(inp, out)

extract(work / "templates.tpz", work / "templates", lambda n: n.endswith(("android_debug.apk", "android_release.apk", "version.txt")), True)
extract(work / "build-tools.zip", work / "sdk" / "build-tools" / "35.0.1", strip_first=True)
extract(work / "platform-tools.zip", work / "sdk")
engine = Path(shutil.which("Godot_v4.7.2-stable_win64_console.exe")).resolve().parent
portable = work / "godot"
portable.mkdir(exist_ok=True)
for filename in ("Godot_v4.7.2-stable_win64.exe", "Godot_v4.7.2-stable_win64_console.exe"):
    shutil.copy2(engine / filename, portable / filename)
(portable / "_sc_").touch()
settings = portable / "editor_data" / "editor_settings-4.7.tres"
settings.parent.mkdir(exist_ok=True)
java = Path("C:/Program Files/Java/jdk-21.0.12.1")
if not (java / "bin" / "java.exe").exists():
    raise RuntimeError("JDK not found")
settings.write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/java_sdk_path = "' + java.as_posix() + '"\nexport/android/android_sdk_path = "' + (work / "sdk").as_posix() + '"\n', encoding="utf-8")
print("Local toolchain prepared in .android-build", flush=True)
