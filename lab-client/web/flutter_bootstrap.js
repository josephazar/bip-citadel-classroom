{{flutter_js}}
{{flutter_build_config}}
(async () => {
  if ('serviceWorker' in navigator) {
    for (const registration of await navigator.serviceWorker.getRegistrations()) await registration.unregister();
  }
  if ('caches' in window) {
    for (const name of await caches.keys()) {
      if (['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest'].includes(name)) await caches.delete(name);
    }
  }
  _flutter.loader.load();
})();
