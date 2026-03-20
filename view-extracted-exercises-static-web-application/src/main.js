import { createApp } from "vue";

import App from "./App.vue";
import { createAppRouter } from "./router.js";
import { createExtractedDataRepository } from "./domain/storage.js";
import { createExtractedDataStore } from "./stores/extracted-data.js";
import "./style.css";

const repository = createExtractedDataRepository();
const store = createExtractedDataStore({ repository, legacyStorage: window.localStorage });
const router = createAppRouter(store);
const app = createApp(App);

app.provide("extractedDataStore", store);
app.use(router);
app.mount("#app");

store.initialize().then(() => {
  router.replace(router.currentRoute.value.fullPath);
});
