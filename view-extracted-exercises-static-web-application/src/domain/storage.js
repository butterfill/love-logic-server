import { openDB } from "idb";

const LEGACY_STORAGE_KEY = "view-extracted-exercises-static-web-application:data";
const DATABASE_NAME = "view-extracted-exercises-static-web-application";
const DATABASE_VERSION = 1;
const DOCUMENT_STORE = "documents";
const CURRENT_DOCUMENT_KEY = "current";

export function createExtractedDataRepository({ databaseName = DATABASE_NAME } = {}) {
  let databasePromise;

  function getDatabase() {
    if (!databasePromise) {
      databasePromise = openDB(databaseName, DATABASE_VERSION, {
        upgrade(database) {
          if (!database.objectStoreNames.contains(DOCUMENT_STORE)) {
            database.createObjectStore(DOCUMENT_STORE);
          }
        }
      });
    }

    return databasePromise;
  }

  return {
    async loadDocument() {
      const database = await getDatabase();
      return (await database.get(DOCUMENT_STORE, CURRENT_DOCUMENT_KEY)) ?? null;
    },
    async saveDocument(document) {
      const database = await getDatabase();
      await database.put(DOCUMENT_STORE, document, CURRENT_DOCUMENT_KEY);
    },
    async clearDocument() {
      const database = await getDatabase();
      await database.delete(DOCUMENT_STORE, CURRENT_DOCUMENT_KEY);
    }
  };
}

export function clearLegacyExtractedData(storage) {
  if (!storage?.getItem || !storage?.removeItem) {
    return false;
  }

  if (storage.getItem(LEGACY_STORAGE_KEY) === null) {
    return false;
  }

  storage.removeItem(LEGACY_STORAGE_KEY);
  return true;
}

export { LEGACY_STORAGE_KEY };
