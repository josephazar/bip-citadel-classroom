#!/usr/bin/env python3
"""Rebuild the same-origin browser companion and retire old offline caches."""
import importlib.util, shutil, subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('demo',root/'scripts/android-demo.py');demo=importlib.util.module_from_spec(spec);spec.loader.exec_module(demo)
subprocess.run([demo.tool('flutter'),'build','web','--release','--no-web-resources-cdn','--pwa-strategy=none'],cwd=root/'lab-client',env=demo.ENV,check=True)
shutil.copytree(root/'lab-client/build/web',root/'public',dirs_exist_ok=True)
shutil.copy2(root/'lab-client/web/retire-service-worker.js',root/'public/flutter_service_worker.js')
print('Web companion rebuilt; legacy offline caches will be retired.')
