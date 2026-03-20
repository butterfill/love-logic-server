const STORAGE_KEY = "view-extracted-exercises-static-web-application:data";

export function saveExtractedData(storage, document) {
  storage.setItem(STORAGE_KEY, JSON.stringify(document));
}

export function loadExtractedData(storage) {
  const raw = storage.getItem(STORAGE_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function clearExtractedData(storage) {
  storage.removeItem(STORAGE_KEY);
}

export { STORAGE_KEY };
