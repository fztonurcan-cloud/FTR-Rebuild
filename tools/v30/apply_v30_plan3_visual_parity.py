#!/usr/bin/env python3
"""Apply the final user-approved Plan 3 visual-parity layer to a built v30 core APK.

STRICT SCOPE
============
This step is presentation-only and is allowed to change exactly these existing
non-signature APK entries relative to the already QA-passed v30 core APK:

- assets/app/app_logo.png
- assets/app/v30-three-plan.css
- assets/app/v30-three-plan.js
- res/Cx.png
- res/Wn.png
- res/Ko.png

The canonical exact Plan 3 logo inside assets/app/brand/ftr-logo-exact.png is
never modified. The same exact PNG bytes are copied to the legacy app-logo and
all three Android launcher-image payloads so the phone launcher and in-app brand
show the same approved artwork without regeneration, tracing, recolor, filter,
or resize.

The startup/welcome presentation is implemented by appending a narrow premium
welcome renderer to the already-added v30 CSS/JS. Existing lessons, quizzes,
Movement Studio logic/content, notes, favorites, auth, notifications, FTR AI,
Clinical Scales data/scoring, anatomy ID maps, and all other APK payload entries
must remain byte/CRC identical to the input v30 core APK.

Output is re-aligned and re-signed with the locked certificate. Physical phone
QA is still mandatory; this script never marks an APK FINAL/LOCKED.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

EXPECTED_CERT_SHA256 = "8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2"
EXPECTED_BRAND_SHA256 = "4168f34bfee9a8cfe240758561a3c94845206ada891da5b9730b6fc1e4702d75"
EXPECTED_BRAND_BYTES = 23175
EXPECTED_BRAND_DIMS = (112, 112)
EXPECTED_PLAN1_FRONT_SHA256 = "f6d50400ddbdd31805a82c5b020040ca3c5fcc864fe83be32fa65c81f6ad2028"
EXPECTED_LIGAMENT_ID_SHA256 = "171d2bd119d3e08530d5c6bad77c6a5b6cf66283fdf5455f01a9cb61fcc75eb7"

BRAND_RUNTIME = "assets/app/brand/ftr-logo-exact.png"
APP_LOGO = "assets/app/app_logo.png"
HOST_CSS = "assets/app/v30-three-plan.css"
HOST_JS = "assets/app/v30-three-plan.js"
LIGAMENT_FRONT = "assets/app/anatomy3d/atlas/ligament-front.png"
LIGAMENT_ID = "assets/app/anatomy3d/atlas/ligament-id.png"
MUSCLE_FRONT = "assets/app/anatomy3d/atlas/muscle-front.png"
LAUNCHER_IMAGES = ("res/Cx.png", "res/Wn.png", "res/Ko.png")

# These are the exact old v29.9-derived image payloads. We refuse to patch an
# unexpected base/core APK even when a file happens to have the same path.
OLD_ALT_ICON_SHA256 = "b074a39d3b4ea211a3d3239b63f7430accfa7b9f6e36c7f31e13c05ab60f1297"
OLD_MAIN_ICON_SHA256 = "e20bda4d1e9f9d5b4b93acd40f4917e6454f07cf60c187e3c8887d0c8aad0e1c"

WELCOME_CSS = r'''

/* === v30 Plan 3: exact-brand premium startup / welcome parity === */
#ftrWelcome.ftr-welcome{
  background:#020b14!important;
  color:#f6f9fc!important;
  font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif!important;
}
#ftrWelcome>.ftr-welcome-art,
#ftrWelcome>.ftr-welcome-start-hit{display:none!important}
.ftr-v30-welcome-shell{
  position:absolute;inset:0;overflow:hidden;box-sizing:border-box;
  display:flex;flex-direction:column;
  padding:calc(env(safe-area-inset-top) + 30px) 25px calc(env(safe-area-inset-bottom) + 28px);
  background:
    radial-gradient(circle at 78% 25%,rgba(21,130,198,.25),transparent 29%),
    radial-gradient(circle at 15% 78%,rgba(38,188,219,.12),transparent 32%),
    linear-gradient(180deg,#020b14 0%,#051421 55%,#020a12 100%);
  isolation:isolate;
}
.ftr-v30-welcome-shell:before{
  content:"";position:absolute;z-index:-1;left:-28%;right:-28%;bottom:-12%;height:38%;
  border-radius:50% 50% 0 0;background:linear-gradient(180deg,rgba(18,124,180,.15),rgba(4,17,29,0));
  border-top:1px solid rgba(65,197,238,.18);transform:rotate(-4deg);
}
.ftr-v30-welcome-brand{display:flex;align-items:center;justify-content:center;gap:12px;flex:0 0 auto}
.ftr-v30-welcome-brand img{
  width:66px;height:66px;object-fit:contain;border-radius:50%;
  filter:drop-shadow(0 0 14px rgba(45,180,233,.24));
}
.ftr-v30-welcome-brand div{display:flex;flex-direction:column;gap:5px}
.ftr-v30-welcome-brand b{font-size:22px;line-height:1;font-weight:950;letter-spacing:.035em}
.ftr-v30-welcome-brand small{font-size:9px;color:#91a9bb;letter-spacing:.16em;font-weight:800}
.ftr-v30-welcome-copy{position:relative;z-index:3;margin-top:7.3vh;max-width:78%}
.ftr-v30-welcome-copy>span{display:block;color:#35c7f1;font-size:9px;font-weight:900;letter-spacing:.13em;margin-bottom:13px}
.ftr-v30-welcome-copy h1{margin:0 0 13px;font-size:clamp(29px,8.7vw,43px);line-height:1.02;letter-spacing:-.045em;font-weight:950}
.ftr-v30-welcome-copy h1 em{font-style:normal;color:#38c8ef}
.ftr-v30-welcome-copy p{margin:0;color:#b8c6d2;font-size:clamp(12px,3.4vw,16px);line-height:1.55;max-width:330px}
.ftr-v30-welcome-anatomy{
  position:absolute;z-index:1;right:-10%;top:25%;width:min(74vw,430px);height:48%;
  object-fit:contain;object-position:right center;opacity:.96;
  filter:drop-shadow(0 0 22px rgba(23,125,191,.34));
  -webkit-mask-image:linear-gradient(180deg,transparent 0%,#000 10%,#000 78%,transparent 100%);
  mask-image:linear-gradient(180deg,transparent 0%,#000 10%,#000 78%,transparent 100%);
}
.ftr-v30-welcome-glow{
  position:absolute;z-index:0;right:-22%;top:31%;width:78vw;height:78vw;border-radius:50%;
  background:radial-gradient(circle,rgba(23,141,205,.17),rgba(23,141,205,0) 67%);filter:blur(2px);
}
.ftr-v30-welcome-footer{margin-top:auto;position:relative;z-index:5;display:grid;gap:14px}
.ftr-v30-welcome-start{
  width:100%;height:66px;border:1px solid rgba(88,220,245,.42);border-radius:22px;
  padding:0 22px;background:linear-gradient(100deg,#08759b,#12a9bd 55%,#32c9bc);
  color:white;display:flex;align-items:center;justify-content:space-between;
  font:900 19px/1 Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
  letter-spacing:.025em;box-shadow:0 16px 32px rgba(0,0,0,.26),inset 0 1px rgba(255,255,255,.18);
  cursor:pointer;-webkit-tap-highlight-color:transparent;
}
.ftr-v30-welcome-start:active{transform:scale(.99);filter:brightness(.96)}
.ftr-v30-welcome-start span{font-size:29px;font-weight:400;line-height:1}
.ftr-v30-welcome-footer small{text-align:center;color:#71879a;font-size:9px;letter-spacing:.12em;font-weight:800}
@media(max-width:390px){
  .ftr-v30-welcome-shell{padding-left:20px;padding-right:20px}.ftr-v30-welcome-brand img{width:60px;height:60px}
  .ftr-v30-welcome-brand b{font-size:20px}.ftr-v30-welcome-copy{margin-top:6.2vh}.ftr-v30-welcome-anatomy{right:-15%;width:79vw}
  .ftr-v30-welcome-start{height:62px;border-radius:20px}
}
@media(max-height:690px){
  .ftr-v30-welcome-copy{margin-top:3.5vh}.ftr-v30-welcome-anatomy{top:24%;height:43%}.ftr-v30-welcome-start{height:58px}
}
'''

WELCOME_JS = r'''

/* v30 Plan 3 exact-brand startup renderer. Presentation only. */
(() => {
  'use strict';
  if (window.__FTR_V30_PREMIUM_WELCOME__) return;
  window.__FTR_V30_PREMIUM_WELCOME__ = true;

  function installPremiumWelcome() {
    const welcome = document.getElementById('ftrWelcome');
    if (!welcome || welcome.dataset.v30PremiumWelcome === '1') return false;
    welcome.dataset.v30PremiumWelcome = '1';
    welcome.setAttribute('aria-label','FTR Akademi premium başlangıç ekranı');
    welcome.innerHTML = `
      <section class="ftr-v30-welcome-shell" aria-label="FTR Akademi — başla">
        <div class="ftr-v30-welcome-brand">
          <img src="./brand/ftr-logo-exact.png" alt="" aria-hidden="true">
          <div><b>FTR AKADEMİ</b><small>FİZYOTERAPİ BİLGİ PLATFORMU</small></div>
        </div>
        <div class="ftr-v30-welcome-copy">
          <span>FİZYOTERAPİ • REHABİLİTASYON • EĞİTİM</span>
          <h1>Bilgiyle güçlen.<br><em>Hareketle ilerle.</em></h1>
          <p>Dersler, 3D anatomi, hareket stüdyosu ve klinik değerlendirme araçları tek akademik çalışma alanında.</p>
        </div>
        <div class="ftr-v30-welcome-glow" aria-hidden="true"></div>
        <img class="ftr-v30-welcome-anatomy" src="./anatomy3d/atlas/muscle-front.png" alt="" aria-hidden="true">
        <div class="ftr-v30-welcome-footer">
          <button class="ftr-v30-welcome-start" type="button" aria-label="Başla"><b>BAŞLA</b><span>→</span></button>
          <small>FTR AKADEMİ • OFFLINE ÖĞRENME ALANI</small>
        </div>
      </section>`;
    const start = welcome.querySelector('.ftr-v30-welcome-start');
    start?.addEventListener('click', () => welcome.classList.add('is-hidden'));
    return true;
  }

  if (!installPremiumWelcome()) {
    const observer = new MutationObserver(() => {
      if (installPremiumWelcome()) observer.disconnect();
    });
    observer.observe(document.documentElement,{childList:true,subtree:true});
  }
})();
'''


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(8 * 1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def png_dimensions(data: bytes) -> tuple[int, int]:
    if len(data) < 24 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        raise SystemExit('PLAN 3 BLOCKED: exact brand is not a PNG')
    return int.from_bytes(data[16:20],'big'), int.from_bytes(data[20:24],'big')


def signature_entries(names: list[str]) -> list[str]:
    out: list[str] = []
    for name in names:
        upper = name.upper()
        if upper == 'META-INF/MANIFEST.MF' or re.fullmatch(r'META-INF/[^/]+\.(SF|RSA|DSA|EC)', upper):
            out.append(name)
    return out


def run(args: list[str], *, cwd: Path | None = None, env: dict[str,str] | None = None,
        capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,cwd=cwd,env=env,text=True,check=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.STDOUT if capture else None,
    )


def signing_values(path: Path) -> tuple[str,str]:
    alias = password = ''
    for raw in path.read_text(encoding='utf-8').splitlines():
        if raw.startswith('Alias:'):
            alias = raw.split(':',1)[1].strip()
        elif raw.startswith('Store/Key Password:'):
            password = raw.split(':',1)[1].strip()
    if not alias or not password:
        raise SystemExit('Signing metadata missing Alias or Store/Key Password')
    return alias,password


def verify_signing(apksigner: Path, output: Path) -> dict[str,object]:
    result = run([str(apksigner.resolve()),'verify','--verbose','--print-certs',str(output)],capture=True)
    text = result.stdout or ''
    def scheme(number: int) -> bool:
        m = re.search(rf'Verified using v{number} scheme[^:]*:\s*(true|false)',text,re.I)
        if not m:
            raise SystemExit(f'APK signature output missing v{number}')
        return m.group(1).lower() == 'true'
    v1,v2 = scheme(1),scheme(2)
    if not v1 or not v2:
        raise SystemExit(f'APK must verify v1+v2; v1={v1}, v2={v2}')
    count = re.search(r'Number of signers:\s*(\d+)',text,re.I)
    if not count or int(count.group(1)) != 1:
        raise SystemExit('Expected exactly one APK signer')
    cert = re.search(r'(?:Signer #1\s*|V2 Signer:\s*)certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)',text,re.I)
    if not cert:
        raise SystemExit('Certificate SHA-256 missing')
    cert_sha = re.sub(r'[^0-9A-Fa-f]','',cert.group(1)).lower()
    if cert_sha != EXPECTED_CERT_SHA256:
        raise SystemExit(f'Wrong signing certificate: {cert_sha}')
    return {'v1':v1,'v2':v2,'signer_count':1,'certificate_sha256':cert_sha}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--core-apk',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--zipalign',type=Path,required=True)
    parser.add_argument('--apksigner',type=Path,required=True)
    parser.add_argument('--keystore',type=Path,required=True)
    parser.add_argument('--signing-metadata',type=Path,required=True)
    parser.add_argument('--report',type=Path,required=True)
    args = parser.parse_args()

    core = args.core_apk.resolve()
    output = args.output.resolve()
    report_path = args.report.resolve()
    if not core.is_file():
        raise SystemExit(f'Core v30 APK missing: {core}')
    if output.exists() or report_path.exists():
        raise SystemExit('Refusing to overwrite output/report')
    for required in (args.zipalign,args.apksigner,args.keystore,args.signing_metadata):
        if not required.resolve().is_file():
            raise SystemExit(f'Required signing/build input missing: {required}')

    repo = Path(__file__).resolve().parents[2]
    brand_path = repo / 'tools' / 'brand' / 'ftr-logo-exact.png'
    brand_lock = repo / 'tools' / 'brand' / 'ftr-logo-exact.sha256'
    if not brand_path.is_file() or not brand_lock.is_file():
        raise SystemExit('PLAN 3 BLOCKED: canonical exact logo/lock missing')
    brand = brand_path.read_bytes()
    locked = brand_lock.read_text(encoding='utf-8').strip().lower()
    actual_brand_sha = sha256_bytes(brand)
    if locked != EXPECTED_BRAND_SHA256 or actual_brand_sha != EXPECTED_BRAND_SHA256:
        raise SystemExit('PLAN 3 BLOCKED: canonical exact brand SHA mismatch')
    if len(brand) != EXPECTED_BRAND_BYTES or png_dimensions(brand) != EXPECTED_BRAND_DIMS:
        raise SystemExit('PLAN 3 BLOCKED: canonical exact brand byte/dimension lock changed')

    with zipfile.ZipFile(core) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise SystemExit('Core v30 APK contains duplicate ZIP entries')
        required_runtime = [BRAND_RUNTIME,APP_LOGO,HOST_CSS,HOST_JS,LIGAMENT_FRONT,LIGAMENT_ID,MUSCLE_FRONT,*LAUNCHER_IMAGES]
        missing = [name for name in required_runtime if name not in names]
        if missing:
            raise SystemExit(f'PLAN 3 BLOCKED: core runtime entries missing: {missing}')
        if sha256_bytes(archive.read(BRAND_RUNTIME)) != EXPECTED_BRAND_SHA256:
            raise SystemExit('PLAN 3 BLOCKED: core exact runtime brand changed')
        if sha256_bytes(archive.read(LIGAMENT_FRONT)) != EXPECTED_PLAN1_FRONT_SHA256:
            raise SystemExit('PLAN 1 BLOCKED: core ligament beauty layer mismatch')
        if sha256_bytes(archive.read(LIGAMENT_ID)) != EXPECTED_LIGAMENT_ID_SHA256:
            raise SystemExit('PLAN 1 BLOCKED: core ligament ID map mismatch')
        old_hashes = {
            APP_LOGO: sha256_bytes(archive.read(APP_LOGO)),
            LAUNCHER_IMAGES[0]: sha256_bytes(archive.read(LAUNCHER_IMAGES[0])),
            LAUNCHER_IMAGES[1]: sha256_bytes(archive.read(LAUNCHER_IMAGES[1])),
            LAUNCHER_IMAGES[2]: sha256_bytes(archive.read(LAUNCHER_IMAGES[2])),
        }
        if old_hashes[APP_LOGO] != OLD_MAIN_ICON_SHA256 or old_hashes[LAUNCHER_IMAGES[2]] != OLD_MAIN_ICON_SHA256:
            raise SystemExit('PLAN 3 BLOCKED: main legacy icon payload is not the expected v29.9 image')
        if old_hashes[LAUNCHER_IMAGES[0]] != OLD_ALT_ICON_SHA256 or old_hashes[LAUNCHER_IMAGES[1]] != OLD_ALT_ICON_SHA256:
            raise SystemExit('PLAN 3 BLOCKED: alternate launcher payload is not the expected v29.9 image')
        css = archive.read(HOST_CSS).decode('utf-8')
        js = archive.read(HOST_JS).decode('utf-8')
        if 'v30 Plan 3: exact-brand premium startup' in css or '__FTR_V30_PREMIUM_WELCOME__' in js:
            raise SystemExit('PLAN 3 BLOCKED: visual parity appears already applied')
        core_payload = {
            item.filename:(item.file_size,item.CRC)
            for item in archive.infolist()
            if item.filename not in signature_entries(names)
        }
        core_ligament_id = archive.read(LIGAMENT_ID)
        core_ligament_front = archive.read(LIGAMENT_FRONT)
        core_clinical = {
            name:(archive.getinfo(name).file_size,archive.getinfo(name).CRC)
            for name in names if name.startswith('assets/app/clinical-scales/')
        }

    alias,password = signing_values(args.signing_metadata.resolve())
    output.parent.mkdir(parents=True,exist_ok=True)
    report_path.parent.mkdir(parents=True,exist_ok=True)

    with tempfile.TemporaryDirectory(prefix='ftr-v30-plan3-visual-') as temp_name:
        temp = Path(temp_name)
        stage = temp / 'stage'
        for target in [APP_LOGO,HOST_CSS,HOST_JS,*LAUNCHER_IMAGES]:
            (stage / target).parent.mkdir(parents=True,exist_ok=True)
        (stage / APP_LOGO).write_bytes(brand)
        for target in LAUNCHER_IMAGES:
            (stage / target).write_bytes(brand)
        (stage / HOST_CSS).write_text(css + WELCOME_CSS,encoding='utf-8')
        (stage / HOST_JS).write_text(js + WELCOME_JS,encoding='utf-8')

        work = temp / 'visual-unaligned.apk'
        aligned = temp / 'visual-aligned.apk'
        shutil.copyfile(core,work)
        with zipfile.ZipFile(work) as archive:
            work_names = archive.namelist()
        removals = signature_entries(work_names) + [APP_LOGO,HOST_CSS,HOST_JS,*LAUNCHER_IMAGES]
        run(['zip','-q','-d',str(work),*removals])
        run(['zip','-q','-9','-D','-r',str(work),APP_LOGO,HOST_CSS,HOST_JS,*LAUNCHER_IMAGES],cwd=stage)
        run([str(args.zipalign.resolve()),'-p','-f','4',str(work),str(aligned)])
        env = os.environ.copy(); env['FTR_V30_KS_PASS'] = password
        run([
            str(args.apksigner.resolve()),'sign','--ks',str(args.keystore.resolve()),
            '--ks-key-alias',alias,'--ks-pass','env:FTR_V30_KS_PASS','--key-pass','env:FTR_V30_KS_PASS',
            '--v1-signing-enabled','true','--v2-signing-enabled','true','--v3-signing-enabled','false','--v4-signing-enabled','false',
            '--out',str(output),str(aligned),
        ],env=env)

    signing = verify_signing(args.apksigner.resolve(),output)
    run([str(args.zipalign.resolve()),'-c','-p','4',str(output)])

    with zipfile.ZipFile(output) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise SystemExit('Final APK contains duplicate ZIP entries')
        bad = archive.testzip()
        if bad:
            raise SystemExit(f'Final ZIP integrity failure: {bad}')
        final_payload = {
            item.filename:(item.file_size,item.CRC)
            for item in archive.infolist()
            if item.filename not in signature_entries(names)
        }
        expected_changed = {APP_LOGO,HOST_CSS,HOST_JS,*LAUNCHER_IMAGES}
        changed = sorted(name for name,old in core_payload.items() if name in final_payload and final_payload[name] != old)
        removed = sorted(name for name in core_payload if name not in final_payload)
        added = sorted(name for name in final_payload if name not in core_payload)
        if set(changed) != expected_changed:
            raise SystemExit(f'OUT-OF-SCOPE final payload change: {changed}')
        if removed or added:
            raise SystemExit(f'OUT-OF-SCOPE final payload add/remove: added={added}, removed={removed}')
        for target in [BRAND_RUNTIME,APP_LOGO,*LAUNCHER_IMAGES]:
            if sha256_bytes(archive.read(target)) != EXPECTED_BRAND_SHA256:
                raise SystemExit(f'PLAN 3 BLOCKED: final exact-logo parity failed at {target}')
        if archive.read(LIGAMENT_ID) != core_ligament_id or sha256_bytes(archive.read(LIGAMENT_ID)) != EXPECTED_LIGAMENT_ID_SHA256:
            raise SystemExit('PLAN 1 BLOCKED: final visual parity changed ligament ID map')
        if archive.read(LIGAMENT_FRONT) != core_ligament_front or sha256_bytes(archive.read(LIGAMENT_FRONT)) != EXPECTED_PLAN1_FRONT_SHA256:
            raise SystemExit('PLAN 1 BLOCKED: final visual parity changed ligament beauty layer')
        final_clinical = {
            name:(archive.getinfo(name).file_size,archive.getinfo(name).CRC)
            for name in names if name.startswith('assets/app/clinical-scales/')
        }
        if final_clinical != core_clinical:
            raise SystemExit('PLAN 2 BLOCKED: final visual parity changed Clinical Scales payload')
        final_css = archive.read(HOST_CSS).decode('utf-8')
        final_js = archive.read(HOST_JS).decode('utf-8')
        css_tokens = ('exact-brand premium startup / welcome parity','.ftr-v30-welcome-shell','.ftr-v30-welcome-start')
        js_tokens = ('__FTR_V30_PREMIUM_WELCOME__','./brand/ftr-logo-exact.png','./anatomy3d/atlas/muscle-front.png','>BAŞLA<')
        if any(token not in final_css for token in css_tokens) or any(token not in final_js for token in js_tokens):
            raise SystemExit('PLAN 3 BLOCKED: premium startup renderer missing after packaging')

    report = {
        'version':'v30-three-plan-premium-visual-parity',
        'status':'BUILD_STATIC_QA_PASS_PHONE_QA_REQUIRED',
        'core_apk':{'file':core.name,'bytes':core.stat().st_size,'sha256':sha256(core),'modified':False},
        'output':{'file':output.name,'bytes':output.stat().st_size,'sha256':sha256(output)},
        'signing':signing,
        'plan3_visual_parity':{
            'exact_brand_sha256':EXPECTED_BRAND_SHA256,
            'canonical_brand_unchanged':True,
            'app_logo_same_exact_bytes':True,
            'android_launcher_entries_same_exact_bytes':list(LAUNCHER_IMAGES),
            'startup_exact_brand':True,
            'startup_anatomy_asset':MUSCLE_FRONT,
            'startup_button':'BAŞLA',
            'changed_existing_vs_core':changed,
            'added_vs_core':added,
            'removed_vs_core':removed,
        },
        'protected_scope':{
            'plan1_ligament_id_unchanged':True,
            'plan1_ligament_front_unchanged':True,
            'plan2_clinical_payload_unchanged':True,
            'all_non_allowed_core_payload_byte_crc_unchanged':True,
            'lessons_quizzes_movement_content_notes_favorites_auth_notifications_ftr_ai_untouched':True,
        },
        'physical_phone_qa':'PENDING_USER_RETEST',
        'final_locked':False,
    }
    report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__ == '__main__':
    main()
