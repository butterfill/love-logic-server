import { openDB } from "idb";

const LEGACY_STORAGE_KEY = "view-extracted-exercises-static-web-application:data";
const DATABASE_NAME = "view-extracted-exercises-static-web-application";
const DATABASE_VERSION = 2;
const SNAPSHOT_STORE = "snapshots";
const CURRENT_SNAPSHOT_KEY = "current";

export function createExtractedDataRepository({ databaseName = DATABASE_NAME } = {}) {
  let databasePromise;

  function getDatabase() {
    if (!databasePromise) {
      databasePromise = openDB(databaseName, DATABASE_VERSION, {
        upgrade(database, oldVersion) {
          if (oldVersion < 1 && !database.objectStoreNames.contains(SNAPSHOT_STORE)) {
            database.createObjectStore(SNAPSHOT_STORE);
          }

          if (oldVersion === 1) {
            if (!database.objectStoreNames.contains(SNAPSHOT_STORE)) {
              database.createObjectStore(SNAPSHOT_STORE);
            }
          }
        }
      });
    }

    return databasePromise;
  }

  return {
    async loadSnapshot() {
      const database = await getDatabase();
      return (await database.get(SNAPSHOT_STORE, CURRENT_SNAPSHOT_KEY)) ?? null;
    },
    async saveSnapshot(snapshot) {
      const database = await getDatabase();
      await database.put(SNAPSHOT_STORE, snapshot, CURRENT_SNAPSHOT_KEY);
    },
    async clearSnapshot() {
      const database = await getDatabase();
      await database.delete(SNAPSHOT_STORE, CURRENT_SNAPSHOT_KEY);
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
