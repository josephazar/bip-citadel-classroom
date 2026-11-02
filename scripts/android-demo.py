#!/usr/bin/env python3
"""Reproducible Android classroom launcher. Keeps keys, logs and PID state in ignored .local/."""
import argparse, base64, json, os, shutil, signal, ssl, subprocess, sys, time, urllib.request
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
FIXED = "const isFixed = true;" in (ROOT / 'lab-client/lib/demo_config.dart').read_text()
PORT = 3261 if FIXED else 3260
PACKAGE = 'online.citadel.classroom.' + ('fixed' if FIXED else 'vulnerable')
LOCAL = ROOT / '.local'
LOCAL.mkdir(mode=0o700, exist_ok=True)
SDK = Path(os.environ.get('ANDROID_HOME', str(Path.home() / 'Library/Android/sdk')))
if not SDK.exists(): SDK = Path.home() / 'Android/Sdk'
ENV = dict(os.environ, ANDROID_HOME=str(SDK), ANDROID_SDK_ROOT=str(SDK))
ENV['PATH'] = os.pathsep.join([str(Path.home() / 'flutter/bin'), str(SDK / 'platform-tools'), str(SDK / 'emulator'), '/opt/homebrew/bin', ENV.get('PATH', '')])
JAVA = Path.home() / 'Applications/Android Studio.app/Contents/jbr/Contents/Home'
if JAVA.exists() and not ENV.get('JAVA_HOME'): ENV['JAVA_HOME'] = str(JAVA)
URL = ('https' if FIXED else 'http') + f'://10.0.2.2:{PORT}'
STATE = LOCAL / 'backend.json'

def tool(name):
    found = shutil.which(name, path=ENV['PATH'])
    if not found: raise SystemExit(f'{name} is missing. Install Node 22+, Flutter, Android SDK/emulator and Java; see README.md.')
    return found

def run(args, **kwargs):
    return subprocess.run(args, env=ENV, check=True, **kwargs)

def stamp(pid):
    return subprocess.run(['ps', '-p', str(pid), '-o', 'lstart='], capture_output=True, text=True).stdout.strip()

def certificate():
    key, cert = LOCAL / 'server-key.pem', LOCAL / 'server-cert.pem'
    if not key.exists() or not cert.exists():
        old = os.umask(0o077)
        try:
            config = LOCAL / 'openssl.cnf'
            config.write_text('[req]\ndistinguished_name=dn\nx509_extensions=ext\nprompt=no\n[dn]\nCN=BIP classroom local TLS\n[ext]\nsubjectAltName=DNS:localhost,IP:127.0.0.1,IP:10.0.2.2\nbasicConstraints=critical,CA:TRUE\nkeyUsage=critical,digitalSignature,keyEncipherment,keyCertSign\n')
            run([tool('openssl'), 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '90', '-keyout', str(key), '-out', str(cert), '-config', str(config)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        finally: os.umask(old)
    return key, cert

def start():
    if STATE.exists():
        item = json.loads(STATE.read_text())
        if stamp(item['pid']) == item['stamp']:
            if item.get('port', PORT) != PORT: raise SystemExit('A backend from the other branch is running. Run this launcher with stop, then run again.')
            print(f'Backend already running on {PORT}.'); return
    # Refuse to reuse an unrelated service on the same port.
    import socket
    with socket.socket() as sock:
        if sock.connect_ex(('127.0.0.1', PORT)) == 0: raise SystemExit(f'Port {PORT} is occupied. Nothing was stopped; use this launcher to stop its own backend.')
    if not (ROOT / 'node_modules').exists(): run([tool('npm'), 'ci'], cwd=ROOT)
    env = dict(ENV, PORT=str(PORT), HOST='127.0.0.1', NODE_ENV='development')
    context = None
    if FIXED:
        key, cert = certificate()
        env.update(TLS_KEY=str(key), TLS_CERT=str(cert))
        context = ssl.create_default_context(cafile=str(cert))
    with (LOCAL / 'backend.log').open('ab') as log:
        proc = subprocess.Popen([tool('node'), '--watch', 'src/server.js'], cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    STATE.write_text(json.dumps({'pid': proc.pid, 'stamp': stamp(proc.pid), 'port': PORT, 'package': PACKAGE}))
    for _ in range(60):
        try:
            with urllib.request.urlopen(URL.replace('10.0.2.2', '127.0.0.1') + '/healthz', context=context, timeout=1) as response:
                if json.load(response)['ok']: print(f'Backend ready: {URL}'); return
        except Exception: time.sleep(.2)
    raise SystemExit(f'Backend did not answer. Read {LOCAL / "backend.log"}.')

def stop():
    package = PACKAGE
    if STATE.exists():
        item = json.loads(STATE.read_text())
        package = item.get('package', PACKAGE)
        if stamp(item['pid']) == item['stamp'] and os.getpgid(item['pid']) == item['pid']:
            os.killpg(item['pid'], signal.SIGTERM)
            print('Stopped this copy’s backend.')
        STATE.unlink(missing_ok=True)
    # Stop this installed demo only; leave Gate, other services and emulator intact.
    adb = shutil.which('adb', path=ENV['PATH'])
    if adb:
        for device in devices(): subprocess.run([adb, '-s', device, 'shell', 'am', 'force-stop', package], env=ENV, capture_output=True)

def devices():
    rows = subprocess.run([tool('adb'), 'devices'], env=ENV, capture_output=True, text=True, check=True).stdout.splitlines()
    return [r.split()[0] for r in rows if len(r.split()) == 2 and r.split()[1] == 'device' and r.startswith('emulator-')]

def device():
    found = devices()
    if found: return found[0]
    avds = subprocess.run([tool('emulator'), '-list-avds'], env=ENV, capture_output=True, text=True, check=True).stdout.splitlines()
    preferred = 'BIP_Gate_API_35' if 'BIP_Gate_API_35' in avds else next(iter(avds), None)
    if not preferred: raise SystemExit('Create an Android Virtual Device first. See README.md.')
    with (LOCAL / 'emulator.log').open('ab') as log:
        subprocess.Popen([tool('emulator'), '-avd', preferred, '-no-snapshot-load', '-feature', '-Vulkan'], env=ENV, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    for _ in range(180):
        found = devices()
        if found:
            boot = subprocess.run([tool('adb'), '-s', found[0], 'shell', 'getprop', 'sys.boot_completed'], env=ENV, capture_output=True, text=True).stdout.strip()
            if boot == '1': return found[0]
        time.sleep(1)
    raise SystemExit('Emulator boot timed out. Check its window and rerun this command.')

def flutter_args():
    args = [f'--dart-define=API_URL={URL}']
    if FIXED:
        _, cert = certificate()
        args += ['--dart-define=LAB_CA_PEM_BASE64=' + base64.b64encode(cert.read_bytes()).decode()]
    return args

def main():
    action = argparse.ArgumentParser(description=__doc__)
    action.add_argument('action', choices=['run', 'start', 'stop', 'build', 'test'], nargs='?', default='run')
    args = action.parse_args()
    if args.action == 'stop': stop(); return
    start()
    if args.action == 'start': return
    client = ROOT / 'lab-client'
    run([tool('flutter'), 'pub', 'get', '--enforce-lockfile'], cwd=client)
    if args.action == 'build':
        run([tool('flutter'), 'build', 'apk', '--debug', *flutter_args()], cwd=client); return
    target = device()
    if args.action == 'test':
        run([tool('flutter'), 'test', 'integration_test/native_test.dart', '-d', target, '--no-enable-impeller', *flutter_args()], cwd=client); return
    run([tool('flutter'), 'run', '-d', target, '--no-enable-impeller', *flutter_args()], cwd=client)
    print('Flutter stopped. The API stays available until: python3 scripts/android-demo.py stop')

if __name__ == '__main__': main()
