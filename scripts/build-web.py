#!/usr/bin/env python3
"""Rebuild the same-origin browser companion and retire old offline caches."""
import importlib.util, shutil, subprocess, hashlib, re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('demo',root/'scripts/android-demo.py');demo=importlib.util.module_from_spec(spec);spec.loader.exec_module(demo)
subprocess.run([demo.tool('flutter'),'build','web','--release','--no-web-resources-cdn','--pwa-strategy=none'],cwd=root/'lab-client',env=demo.ENV,check=True)
shutil.copytree(root/'lab-client/build/web',root/'public',dirs_exist_ok=True)
shutil.copy2(root/'lab-client/web/retire-service-worker.js',root/'public/flutter_service_worker.js')
# Immutable URLs prevent an old browser response from masking a new deployment.
public=root/'public'
for item in public.iterdir():
    if re.fullmatch(r'(?:main\.[0-9a-f]{16}\.dart|flutter_bootstrap\.[0-9a-f]{16})\.js', item.name): item.unlink()
main=(public/'main.dart.js').read_bytes()
main_name='main.'+hashlib.sha256(main).hexdigest()[:16]+'.dart.js'
(public/main_name).write_bytes(main)
bootstrap=(public/'flutter_bootstrap.js').read_text()
bootstrap,n=re.subn(r'("mainJsPath"\s*:\s*)"main\.dart\.js"', lambda m:m[1]+'"'+main_name+'"',bootstrap)
assert n==1, 'Flutter bootstrap format changed; review the main script mapping.'
(public/'flutter_bootstrap.js').write_text(bootstrap)
boot_name='flutter_bootstrap.'+hashlib.sha256(bootstrap.encode()).hexdigest()[:16]+'.js'
(public/boot_name).write_text(bootstrap)
index=(public/'index.html').read_text().replace('src="flutter_bootstrap.js"','src="'+boot_name+'"')
(public/'index.html').write_text(index)
print('Web companion rebuilt with immutable scripts:',main_name,boot_name)
